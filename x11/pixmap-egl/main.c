#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

#include <unistd.h>

#include <epoxy/gl.h>
#include <epoxy/egl.h>

#include <X11/Xlib.h>

#define TARGET_W 256
#define TARGET_H 256

static void print_result(void)
{
	GLubyte result[4];
	glReadPixels(TARGET_W/2, TARGET_H/2, 1, 1, GL_RGBA, GL_UNSIGNED_BYTE, result);
	printf("result: %x %x %x %x\n", result[0], result[1], result[2], result[3]);
}

int main(void)
{
	Display *display;
	assert((display = XOpenDisplay(NULL)) != NULL);

	int screen = DefaultScreen(display);
	Window root = DefaultRootWindow(display);
	Window window = XCreateSimpleWindow(display, root, 0, 0,
					    TARGET_W, TARGET_H, 0,
					    BlackPixel(display, 0),
					    WhitePixel(display, 0));
	XSelectInput(display, window, ExposureMask);
	XMapWindow(display, window);

	Pixmap pixmap = XCreatePixmap(display, window, TARGET_W, TARGET_H,
				      DefaultDepth(display, screen));
	
	XFlush(display);

	EGLDisplay dpy;
	assert((dpy = eglGetDisplay(display)) != EGL_NO_DISPLAY);

	EGLint majorVersion;
	EGLint minorVersion;
	assert(eglInitialize(dpy, &majorVersion, &minorVersion) == EGL_TRUE);

	assert(eglBindAPI(EGL_OPENGL_API) == EGL_TRUE);

	EGLConfig config;
	EGLint numConfigs;
	const EGLint configAttribs[] = {
		EGL_SURFACE_TYPE, EGL_PIXMAP_BIT,
		EGL_MATCH_NATIVE_PIXMAP, pixmap,
		EGL_RED_SIZE, 8,
		EGL_GREEN_SIZE, 8,
		EGL_BLUE_SIZE, 8,
		EGL_DEPTH_SIZE, 24,
		EGL_NONE
	};
	assert(eglChooseConfig(dpy, configAttribs, &config, 1, &numConfigs) == EGL_TRUE);

	EGLSurface surface = eglCreatePixmapSurface(dpy, config, pixmap, NULL);
	assert(surface != EGL_NO_SURFACE);

	EGLContext context = eglCreateContext(dpy, config, EGL_NO_CONTEXT, NULL);
	assert(context != EGL_NO_CONTEXT);

	assert(eglMakeCurrent(dpy, surface, surface, context) == EGL_TRUE);

	glViewport(0, 0, TARGET_W, TARGET_H);

	XEvent e;
	while (1) {
		XNextEvent(display, &e);
		if (e.type == Expose) {
			GC gc = DefaultGC(display, 0);
			XDrawString(display, window, gc, TARGET_W / 2 + 10, 20, "hello", 5);

			glClearColor(1, 0, 0, 0);
			glClear(GL_COLOR_BUFFER_BIT);
			glFlush();
			//eglSwapBuffers(dpy, surface);

			print_result();

			XCopyArea(display, pixmap, window, gc, 
				  0, 0, TARGET_W / 2, TARGET_H / 2, 0, 0);

			// for xserver really done the copy before next clear
			// because the pixmap is single buffered
			XFlush(display);
			sleep(1);

			glClearColor(0, 0, 1, 0);
			glClear(GL_COLOR_BUFFER_BIT);
			glFlush();
			//eglSwapBuffers(dpy, surface);

			print_result();

			XCopyArea(display, pixmap, window, gc, 
				  0, 0, TARGET_W / 2, TARGET_H / 2,
				  TARGET_W / 2, TARGET_H / 2);
		}
	}

	return 0;
}
