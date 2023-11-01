#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

#include <fcntl.h>
#include <unistd.h>

#include <gbm.h>
#include <png.h>

#include <epoxy/gl.h>
#include <epoxy/egl.h>

EGLDisplay display;
EGLContext context;
struct gbm_device *gbm;

#define TARGET_W 64
#define TARGET_H 64

void RenderTargetInit(void)
{
	assert(epoxy_has_egl_extension(EGL_NO_DISPLAY, "EGL_MESA_platform_gbm"));

	int fd = open("/dev/dri/renderD128", O_RDWR);
	assert(fd >= 0);

	gbm = gbm_create_device(fd);
	assert(gbm != NULL);

	assert((display = eglGetPlatformDisplayEXT(EGL_PLATFORM_GBM_MESA, gbm, NULL)) != EGL_NO_DISPLAY);

	EGLint majorVersion;
	EGLint minorVersion;
	assert(eglInitialize(display, &majorVersion, &minorVersion) == EGL_TRUE);

	assert(eglBindAPI(EGL_OPENGL_API) == EGL_TRUE);

	const EGLint contextAttribs[] = {
		EGL_CONTEXT_MAJOR_VERSION, 4,
		EGL_CONTEXT_MINOR_VERSION, 3,
		EGL_NONE
	};
	assert((context = eglCreateContext(display, NULL, EGL_NO_CONTEXT, contextAttribs)) != EGL_NO_CONTEXT);

	assert(eglMakeCurrent(display, EGL_NO_SURFACE, EGL_NO_SURFACE, context) == EGL_TRUE);
}

void SetupFB(GLuint fb, GLuint tex)
{
	glBindTexture(GL_TEXTURE_2D, tex);
	//glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, TARGET_W, TARGET_H, 0, GL_RGB, GL_BYTE, NULL);
	glTexStorage2D(GL_TEXTURE_2D, 1, GL_RGB8, TARGET_W, TARGET_H);

	glBindFramebuffer(GL_FRAMEBUFFER, fb);

	glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, tex, 0);
}

void ClearFB(GLuint fb, float color[3])
{
	glClearColor(color[0], color[1], color[2], 1.0f);
        glBindFramebuffer(GL_FRAMEBUFFER, fb);
        glClear(GL_COLOR_BUFFER_BIT);
}

int writeImage(char* filename, int width, int height, void *buffer, char* title)
{
	int code = 0;
	FILE *fp = NULL;
	png_structp png_ptr = NULL;
	png_infop info_ptr = NULL;

	// Open file for writing (binary mode)
	fp = fopen(filename, "wb");
	if (fp == NULL) {
		fprintf(stderr, "Could not open file %s for writing\n", filename);
		code = 1;
		goto finalise;
	}

	// Initialize write structure
	png_ptr = png_create_write_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
	if (png_ptr == NULL) {
		fprintf(stderr, "Could not allocate write struct\n");
		code = 1;
		goto finalise;
	}

	// Initialize info structure
	info_ptr = png_create_info_struct(png_ptr);
	if (info_ptr == NULL) {
		fprintf(stderr, "Could not allocate info struct\n");
		code = 1;
		goto finalise;
	}

	// Setup Exception handling
	if (setjmp(png_jmpbuf(png_ptr))) {
		fprintf(stderr, "Error during png creation\n");
		code = 1;
		goto finalise;
	}

	png_init_io(png_ptr, fp);

	// Write header (8 bit colour depth)
	png_set_IHDR(png_ptr, info_ptr, width, height,
		     8, PNG_COLOR_TYPE_RGB_ALPHA, PNG_INTERLACE_NONE,
		     PNG_COMPRESSION_TYPE_DEFAULT, PNG_FILTER_TYPE_DEFAULT);

	// Set title
	if (title != NULL) {
		png_text title_text;
		title_text.compression = PNG_TEXT_COMPRESSION_NONE;
		title_text.key = "Title";
		title_text.text = title;
		png_set_text(png_ptr, info_ptr, &title_text, 1);
	}

	png_write_info(png_ptr, info_ptr);

	// Write image data
	int i;
	for (i = 0; i < height; i++)
		png_write_row(png_ptr, (png_bytep)buffer + i * width * 4);

	// End write
	png_write_end(png_ptr, NULL);

finalise:
	if (fp != NULL) fclose(fp);
	if (info_ptr != NULL) png_free_data(png_ptr, info_ptr, PNG_FREE_ALL, -1);
	if (png_ptr != NULL) png_destroy_write_struct(&png_ptr, (png_infopp)NULL);

	return code;
}

void Render(void)
{
	GLuint texs[2];
	glGenTextures(2, texs);

	GLuint fbs[2];
	glGenFramebuffers(2, fbs);

	SetupFB(fbs[0], texs[0]);
	SetupFB(fbs[1], texs[1]);

	assert(glGetError() == GL_NO_ERROR);

	float red[] = {1, 0, 0};
	float green[] = {0, 1, 0};

	ClearFB(fbs[0], green);
	ClearFB(fbs[1], red);

	assert(glGetError() == GL_NO_ERROR);

	glCopyImageSubData(texs[0], GL_TEXTURE_2D, 0, 0, 0, 0,
                           texs[1], GL_TEXTURE_2D, 0, 17, 11, 0,
                           32, 32, 1);

	assert(glGetError() == GL_NO_ERROR);

	glBindFramebuffer(GL_READ_FRAMEBUFFER, fbs[1]);

	GLubyte result[TARGET_W * TARGET_H * 4] = {0};
	glReadPixels(0, 0, TARGET_W, TARGET_H, GL_RGBA, GL_UNSIGNED_BYTE, result);
	assert(glGetError() == GL_NO_ERROR);

	assert(!writeImage("screenshot.png", TARGET_W, TARGET_H, result, "hello"));

	for (int i = 17; i < 17 + 32; i++) {
		for (int j = 11; j < 11 + 32; j++) {
			uint32_t color = *(uint32_t *)(result + (j * TARGET_W + i) * 4);
			if (color != 0xff00ff00)
				printf("wrong color at %d %d %08x\n", i, j, color);
		}
	}
}

int main(void)
{
	RenderTargetInit();
	Render();
	return 0;
}
