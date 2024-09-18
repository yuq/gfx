#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

#include <fcntl.h>
#include <unistd.h>

#include <drm/drm_fourcc.h>

#include <gbm.h>

#include <epoxy/egl.h>
#include <epoxy/gl.h>

#define TARGET_SIZE 256

#define MAX_PLANES 3

struct gpu_context {
	int fd;
	struct gbm_device *gbm;
	EGLDisplay dpy;
	EGLContext ctx;
};

void RenderTargetInit(const char *name, struct gpu_context *ctx)
{
	ctx->fd = open(name, O_RDWR);
	assert(ctx->fd >= 0);

	ctx->gbm = gbm_create_device(ctx->fd);
	assert(ctx->gbm != NULL);

	assert((ctx->dpy = eglGetDisplay(ctx->gbm)) != EGL_NO_DISPLAY);

	EGLint majorVersion;
	EGLint minorVersion;
	assert(eglInitialize(ctx->dpy, &majorVersion, &minorVersion) == EGL_TRUE);

	eglBindAPI(EGL_OPENGL_API);
  
	assert((ctx->ctx = eglCreateContext(ctx->dpy, NULL, EGL_NO_CONTEXT, NULL)) != EGL_NO_CONTEXT);

	assert(eglMakeCurrent(ctx->dpy, EGL_NO_SURFACE, EGL_NO_SURFACE, ctx->ctx) == EGL_TRUE);
}

void CheckFrameBufferStatus(void)
{
	GLenum status;
	status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
	switch(status) {
	case GL_FRAMEBUFFER_COMPLETE:
		printf("Framebuffer complete\n");
		break;
	case GL_FRAMEBUFFER_UNSUPPORTED:
		printf("Framebuffer unsuported\n");
		break;
	case GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT:
		printf("GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT\n");
		break;
	case GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT:
		printf("GL_FRAMEBUFFER_MISSING_ATTACHMENT\n");
		break;
	default:
		printf("Framebuffer error\n");
	}
}

void RenderAndCheck(struct gpu_context *gpu, float r, float g, float b, float a) {
	assert(eglMakeCurrent(gpu[0].dpy, EGL_NO_SURFACE, EGL_NO_SURFACE, gpu[0].ctx) == EGL_TRUE);

	// render on GPU0
	glClearColor(r, g, b, a);
        glClear(GL_COLOR_BUFFER_BIT);

	glFinish();

	assert(eglMakeCurrent(gpu[1].dpy, EGL_NO_SURFACE, EGL_NO_SURFACE, gpu[1].ctx) == EGL_TRUE);

	// check on GPU1
	uint32_t *data = calloc(1, TARGET_SIZE * TARGET_SIZE * 4);
	assert(data);
	glGetTexImage(GL_TEXTURE_2D, 0, GL_RGBA, GL_UNSIGNED_BYTE, data);

	uint32_t expect =
		(((uint32_t)(a * 255) & 0xff) << 24) |
		(((uint32_t)(b * 255) & 0xff) << 16) |
		(((uint32_t)(g * 255) & 0xff) << 8) |
		(((uint32_t)(r * 255) & 0xff) << 0);
	for (int i = 0; i < TARGET_SIZE * TARGET_SIZE; i++) {
		if (data[i] != expect) {
			printf("check buffer fail at %d: %x/%x\n", i, data[i], expect);
			return;
		}
	}
	printf("check buffer success\n");
	free(data);
}

int main(int argc, char **argv)
{
	char *f1 = "/dev/dri/renderD128";
	char *f2 = "/dev/dri/renderD128";
	if (argc > 1) {
		f1 = argv[1];
		if (argc > 2)
			f2 = argv[2];
	}

	struct gpu_context gpu[2];
	RenderTargetInit(f1, gpu);
	assert(epoxy_has_egl_extension(gpu[0].dpy, "EGL_MESA_image_dma_buf_export"));

	GLuint fbid;
	glGenFramebuffers(1, &fbid);
	glBindFramebuffer(GL_FRAMEBUFFER, fbid);

	GLuint texid;
	glGenTextures(1, &texid);
	glBindTexture(GL_TEXTURE_2D, texid);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, TARGET_SIZE, TARGET_SIZE, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
	glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, texid, 0);

	CheckFrameBufferStatus();

	EGLImage image = eglCreateImage(gpu[0].dpy, gpu[0].ctx, EGL_GL_TEXTURE_2D,
					(EGLClientBuffer)texid, NULL);
	assert(image != EGL_NO_IMAGE);

	int fourcc;
	int num_planes;
	uint64_t modifiers[MAX_PLANES] = {0};
	EGLBoolean ret = eglExportDMABUFImageQueryMESA(gpu[0].dpy, image, &fourcc, &num_planes, modifiers);
	assert(ret == EGL_TRUE);
	assert(num_planes <= MAX_PLANES);

	int fds[MAX_PLANES] = {0};
	int strides[MAX_PLANES] = {0};
	int offsets[MAX_PLANES] = {0};
	assert(eglExportDMABUFImageMESA(gpu[0].dpy, image, fds, strides, offsets));

	RenderTargetInit(f2, gpu + 1);
	assert(epoxy_has_egl_extension(gpu[1].dpy, "EGL_EXT_image_dma_buf_import"));
	assert(epoxy_has_egl_extension(gpu[1].dpy, "EGL_EXT_image_dma_buf_import_modifiers"));

	EGLint attrib_list[6 + MAX_PLANES * 10 + 1] = {0};
	unsigned num = 0;

	attrib_list[num++] = EGL_WIDTH;
	attrib_list[num++] = TARGET_SIZE;

	attrib_list[num++] = EGL_HEIGHT;
	attrib_list[num++] = TARGET_SIZE;

	attrib_list[num++] = EGL_LINUX_DRM_FOURCC_EXT;
	attrib_list[num++] = fourcc;

	attrib_list[num++] = EGL_DMA_BUF_PLANE0_FD_EXT;
	attrib_list[num++] = fds[0];
	attrib_list[num++] = EGL_DMA_BUF_PLANE0_OFFSET_EXT;
	attrib_list[num++] = offsets[0];
	attrib_list[num++] = EGL_DMA_BUF_PLANE0_PITCH_EXT;
	attrib_list[num++] = strides[0];
	attrib_list[num++] = EGL_DMA_BUF_PLANE0_MODIFIER_LO_EXT;
	attrib_list[num++] = modifiers[0];
	attrib_list[num++] = EGL_DMA_BUF_PLANE0_MODIFIER_HI_EXT;
	attrib_list[num++] = modifiers[0] >> 32;

	if (num_planes > 1) {
		attrib_list[num++] = EGL_DMA_BUF_PLANE1_FD_EXT;
		attrib_list[num++] = fds[1] >= 0 ? fds[1] : fds[0];
		attrib_list[num++] = EGL_DMA_BUF_PLANE1_OFFSET_EXT;
		attrib_list[num++] = offsets[1];
		attrib_list[num++] = EGL_DMA_BUF_PLANE1_PITCH_EXT;
		attrib_list[num++] = strides[1];
		attrib_list[num++] = EGL_DMA_BUF_PLANE1_MODIFIER_LO_EXT;
		attrib_list[num++] = modifiers[1];
		attrib_list[num++] = EGL_DMA_BUF_PLANE1_MODIFIER_HI_EXT;
		attrib_list[num++] = modifiers[1] >> 32;
	}

	if (num_planes > 2) {
		attrib_list[num++] = EGL_DMA_BUF_PLANE2_FD_EXT;
		attrib_list[num++] = fds[2] >= 0 ? fds[2] : fds[0];
		attrib_list[num++] = EGL_DMA_BUF_PLANE2_OFFSET_EXT;
		attrib_list[num++] = offsets[2];
		attrib_list[num++] = EGL_DMA_BUF_PLANE2_PITCH_EXT;
		attrib_list[num++] = strides[2];
		attrib_list[num++] = EGL_DMA_BUF_PLANE2_MODIFIER_LO_EXT;
		attrib_list[num++] = modifiers[2];
		attrib_list[num++] = EGL_DMA_BUF_PLANE2_MODIFIER_HI_EXT;
		attrib_list[num++] = modifiers[2] >> 32;
	}

	attrib_list[num++] = EGL_NONE;

	image = eglCreateImageKHR(
		gpu[1].dpy, EGL_NO_CONTEXT, EGL_LINUX_DMA_BUF_EXT,
		NULL, attrib_list);
	assert(image != EGL_NO_IMAGE_KHR);

	GLuint out_tex = 0;
        glGenTextures(1, &out_tex);
	glBindTexture(GL_TEXTURE_2D, out_tex);
	glEGLImageTargetTexture2DOES(GL_TEXTURE_2D, image);
	assert(glGetError() == GL_NO_ERROR);

	RenderAndCheck(gpu, 1, 0, 1, 0);
	RenderAndCheck(gpu, 0, 1, 1, 0);

	assert(glGetError() == GL_NO_ERROR);

	return 0;
}
