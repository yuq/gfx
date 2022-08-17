#include <stdio.h>
#include <assert.h>

#include <GL/glx.h>
#include <GL/gl.h>

#include <X11/Xlib.h>

#define TARGET_W 256
#define TARGET_H 256

int main(void)
{
	Display *dpy = XOpenDisplay(NULL);
	assert(dpy);

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
	GLXFBConfig *configs = glXChooseFBConfig(dpy, DefaultScreen(dpy), fb_attrs, &n);
	assert(configs && n > 0);

	int pbuff_attrs[] = {
		GLX_PBUFFER_WIDTH, TARGET_W,
		GLX_PBUFFER_HEIGHT, TARGET_H,
		GLX_PRESERVED_CONTENTS, True,
		GLX_LARGEST_PBUFFER, False,
		None
	};

	GLXPbuffer pbuff = glXCreatePbuffer(dpy, configs[0], pbuff_attrs);
	assert(pbuff);
	printf("yuq: app pbuff %lx\n", pbuff);

	unsigned int val = 0;
	glXQueryDrawable(dpy, pbuff, GLX_DRAWABLE_TYPE, &val);
	printf("val = %x\n", val);

	GLXContext ctx = glXCreateNewContext(dpy, configs[0], GLX_RGBA_TYPE, NULL, True);
	assert(ctx);

	assert(glXMakeContextCurrent(dpy, pbuff, pbuff, ctx));
	assert(glXMakeContextCurrent(dpy, 0, 0, 0));
	glXDestroyContext(dpy, ctx);

	ctx = glXCreateNewContext(dpy, configs[0], GLX_RGBA_TYPE, NULL, True);
	assert(ctx);

	assert(glXMakeContextCurrent(dpy, pbuff, pbuff, ctx));

	glXDestroyContext(dpy, ctx);

	glXDestroyPbuffer(dpy, pbuff);

	return 0;
}
