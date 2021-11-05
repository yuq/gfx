#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

#include <epoxy/gl.h>
#include <epoxy/egl.h>

#define TARGET_W 256
#define TARGET_H 256

static void print_result(void)
{
	glReadBuffer(GL_BACK);

	GLubyte result[4];
	glReadPixels(TARGET_W/2, TARGET_H/2, 1, 1, GL_RGBA, GL_UNSIGNED_BYTE, result);
	printf("result: %x %x %x %x\n", result[0], result[1], result[2], result[3]);
}

int main(void)
{
	EGLDisplay display;
	assert((display = eglGetDisplay(EGL_DEFAULT_DISPLAY)) != EGL_NO_DISPLAY);

	EGLint majorVersion;
	EGLint minorVersion;
	assert(eglInitialize(display, &majorVersion, &minorVersion) == EGL_TRUE);

	assert(eglBindAPI(EGL_OPENGL_API) == EGL_TRUE);

	EGLConfig config;
	EGLint numConfigs;
	const EGLint configAttribs[] = {
		EGL_SURFACE_TYPE, EGL_PBUFFER_BIT,
		EGL_RED_SIZE, 8,
		EGL_GREEN_SIZE, 8,
		EGL_BLUE_SIZE, 8,
		EGL_DEPTH_SIZE, 24,
		EGL_NONE
	};
	assert(eglChooseConfig(display, configAttribs, &config, 1, &numConfigs) == EGL_TRUE);

	EGLSurface surface;
	EGLint attribList[] = {
		EGL_WIDTH, TARGET_W,
		EGL_HEIGHT, TARGET_H,
		EGL_NONE
	};
	surface = eglCreatePbufferSurface(display, config, attribList);

	EGLContext context;
	const EGLint contextAttribs[] = {
		EGL_CONTEXT_CLIENT_VERSION, 2,
		EGL_NONE
	};
	assert((context = eglCreateContext(display, config, EGL_NO_CONTEXT, contextAttribs)) != EGL_NO_CONTEXT);

	assert(eglMakeCurrent(display, surface, surface, context) == EGL_TRUE);

	glViewport(0, 0, TARGET_W, TARGET_H);

	glClearColor(1, 0, 0, 0);
	glClear(GL_COLOR_BUFFER_BIT);
	eglSwapBuffers(display, surface);

	print_result();

	glClearColor(0, 0, 1, 0);
	glClear(GL_COLOR_BUFFER_BIT);
	eglSwapBuffers(display, surface);

	print_result();

	return 0;
}
