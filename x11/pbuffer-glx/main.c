#include <stdio.h>
#include <assert.h>

#include <GL/glx.h>
#include <GL/gl.h>

#include <X11/Xlib.h>

#define TARGET_W 256
#define TARGET_H 256

static void print_result(int buff)
{
	glReadBuffer(buff);

	GLubyte result[4];
	glReadPixels(TARGET_W/2, TARGET_H/2, 1, 1, GL_RGBA, GL_UNSIGNED_BYTE, result);
	printf("result: %x %x %x %x\n", result[0], result[1], result[2], result[3]);
}

int main(void)
{
	Display *dpy1 = XOpenDisplay(NULL);
	assert(dpy1);

	int fb_attrs[] = {
		GLX_DOUBLEBUFFER, 0,
		GLX_RENDER_TYPE, GLX_RGBA_BIT,
		GLX_DRAWABLE_TYPE, GLX_PBUFFER_BIT | GLX_WINDOW_BIT,
		GLX_RED_SIZE, 8,
		GLX_GREEN_SIZE, 8,
		GLX_BLUE_SIZE, 8,
		None
	};

	int n;
	GLXFBConfig *configs1 = glXChooseFBConfig(dpy1, DefaultScreen(dpy1), fb_attrs, &n);
	assert(configs1 && n > 0);

	int pbuff_attrs[] = {
		GLX_PBUFFER_WIDTH, TARGET_W,
		GLX_PBUFFER_HEIGHT, TARGET_H,
		GLX_PRESERVED_CONTENTS, True,
		GLX_LARGEST_PBUFFER, False,
		None
	};

	GLXPbuffer pbuff = glXCreatePbuffer(dpy1, configs1[0], pbuff_attrs);
	assert(pbuff);

	GLXContext ctx1 = glXCreateNewContext(dpy1, configs1[0], GLX_RGBA_TYPE, NULL, True);
	assert(ctx1);

	assert(glXMakeContextCurrent(dpy1, pbuff, pbuff, ctx1));

	glViewport(0, 0, TARGET_W, TARGET_H);
	glClearColor(1.0, 0.0, 0.0, 0.0);
	glClear(GL_COLOR_BUFFER_BIT);

	glXSwapBuffers(dpy1, pbuff);

	print_result(GL_FRONT);

	Display *dpy2 = XOpenDisplay(NULL);
	assert(dpy2);

	assert(dpy1 != dpy2);

	GLXFBConfig *configs2 = glXChooseFBConfig(dpy2, DefaultScreen(dpy2), fb_attrs, &n);
	assert(configs2 && n > 0);

	GLXContext ctx2 = glXCreateNewContext(dpy2, configs2[0], GLX_RGBA_TYPE, NULL, True);
	assert(ctx2);

	assert(glXMakeContextCurrent(dpy2, pbuff, pbuff, ctx2));

	print_result(GL_FRONT);

	return 0;
}
