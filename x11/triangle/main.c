#include <assert.h>
#include <stdio.h>
#include <sys/time.h>
#include <EGL/egl.h>

EGLDisplay display;
EGLSurface surface;
int windowWidth = 256;
int windowHeight = 256;

void render_init(int width, int height);
void render(void);

#include <X11/Xlib.h>

Display *x11_display;

EGLNativeWindowType CreateNativeWindow(void)
{
	Display *display;
	assert((display = XOpenDisplay(NULL)) != NULL);
	x11_display = display;

	int screen = DefaultScreen(display);
	Window root = DefaultRootWindow(display);
	Window window =  XCreateWindow(display, root, 0, 0, windowWidth, windowHeight, 0,
				       DefaultDepth(display, screen), InputOutput,
				       DefaultVisual(display, screen), 
				       0, NULL);
	XMapWindow(display, window);
	XFlush(display);
	return window;
}

void RenderTargetInit(EGLNativeWindowType nativeWindow)
{
	assert((display = eglGetDisplay(x11_display)) != EGL_NO_DISPLAY);

	EGLint majorVersion;
	EGLint minorVersion;
	assert(eglInitialize(display, &majorVersion, &minorVersion) == EGL_TRUE);
	printf("EGL version %d.%d\n", majorVersion, minorVersion);

	printf("EGL Version: \"%s\"\n", eglQueryString(display, EGL_VERSION));
	printf("EGL Vendor: \"%s\"\n", eglQueryString(display, EGL_VENDOR));
	printf("EGL Extensions: \"%s\"\n", eglQueryString(display, EGL_EXTENSIONS));

	EGLConfig config;
	EGLint numConfigs;
	const EGLint configAttribs[] = {
		EGL_SURFACE_TYPE, EGL_WINDOW_BIT,
		EGL_RED_SIZE, 8,
		EGL_GREEN_SIZE, 8,
		EGL_BLUE_SIZE, 8,
		EGL_DEPTH_SIZE, 24,
		EGL_NONE
	};
	assert(eglChooseConfig(display, configAttribs, &config, 1, &numConfigs) == EGL_TRUE);
	assert(numConfigs > 0);

	const EGLint attribList[] = {
		EGL_RENDER_BUFFER, EGL_BACK_BUFFER,
		EGL_NONE
	};
	assert((surface = eglCreateWindowSurface(display, config, nativeWindow, attribList)) != EGL_NO_SURFACE);

	EGLint width, height;
	assert(eglQuerySurface(display, surface, EGL_WIDTH, &width) == EGL_TRUE);
	assert(eglQuerySurface(display, surface, EGL_HEIGHT, &height) == EGL_TRUE);
	printf("Surface size: %dx%d\n", width, height);

	EGLContext context;
	const EGLint contextAttribs[] = {
		EGL_CONTEXT_CLIENT_VERSION, 2,
		EGL_NONE
	};
	assert((context = eglCreateContext(display, config, EGL_NO_CONTEXT, contextAttribs)) != EGL_NO_CONTEXT);

	assert(eglMakeCurrent(display, surface, surface, context) == EGL_TRUE);
}

int main(int argc, char *argv[])
{
	EGLNativeWindowType window;
	window = CreateNativeWindow();
	RenderTargetInit(window);

	render_init(windowWidth, windowHeight);

	render();
	eglSwapBuffers(display, surface);
	sleep(1);
	return 0;
}
