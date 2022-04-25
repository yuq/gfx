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

	int prime_fd = -1;
	int stride;
	int offset;
	assert(eglExportDMABUFImageMESA(gpu[0].dpy, image, &prime_fd, &stride, &offset));

	RenderTargetInit(f2, gpu + 1);
	assert(epoxy_has_egl_extension(gpu[1].dpy, "EGL_EXT_image_dma_buf_import"));

	EGLint attrib_list[] = {
		EGL_WIDTH, TARGET_SIZE,
		EGL_HEIGHT, TARGET_SIZE,
		EGL_LINUX_DRM_FOURCC_EXT, DRM_FORMAT_ABGR8888,
		EGL_DMA_BUF_PLANE0_FD_EXT, prime_fd,
		EGL_DMA_BUF_PLANE0_OFFSET_EXT, offset,
		EGL_DMA_BUF_PLANE0_PITCH_EXT, stride,
		EGL_NONE
	};
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
	
	return 0;
}
