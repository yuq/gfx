#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

#include <fcntl.h>
#include <unistd.h>

#include <gbm.h>

#include <epoxy/gl.h>
#include <epoxy/egl.h>

EGLDisplay display;
EGLSurface surface;
EGLContext context;
struct gbm_device *gbm;
struct gbm_surface *gs;

#define TARGET_W 512
#define TARGET_H 512

void gluPickMatrix(
	GLdouble x,
 	GLdouble y,
 	GLdouble delX,
 	GLdouble delY,
 	GLint * viewport);

EGLConfig get_config(void)
{
	EGLint egl_config_attribs[] = {
		EGL_BUFFER_SIZE,	32,
		EGL_DEPTH_SIZE,		EGL_DONT_CARE,
		EGL_STENCIL_SIZE,	EGL_DONT_CARE,
		EGL_RENDERABLE_TYPE,	EGL_OPENGL_ES2_BIT,
		EGL_SURFACE_TYPE,	EGL_WINDOW_BIT,
		EGL_NONE,
	};

	EGLint num_configs;
	assert(eglGetConfigs(display, NULL, 0, &num_configs) == EGL_TRUE);

	EGLConfig *configs = malloc(num_configs * sizeof(EGLConfig));
	assert(eglChooseConfig(display, egl_config_attribs,
			       configs, num_configs, &num_configs) == EGL_TRUE);
	assert(num_configs);
	printf("num config %d\n", num_configs);

	// Find a config whose native visual ID is the desired GBM format.
	for (int i = 0; i < num_configs; ++i) {
		EGLint gbm_format;

		assert(eglGetConfigAttrib(display, configs[i],
					  EGL_NATIVE_VISUAL_ID, &gbm_format) == EGL_TRUE);
		printf("gbm format %x\n", gbm_format);

		if (gbm_format == GBM_FORMAT_ARGB8888) {
			EGLConfig ret = configs[i];
			free(configs);
			return ret;
		}
	}

	// Failed to find a config with matching GBM format.
	abort();
}

void RenderTargetInit(char *name)
{
	assert(epoxy_has_egl_extension(EGL_NO_DISPLAY, "EGL_MESA_platform_gbm"));

	int fd = open(name, O_RDWR);
	assert(fd >= 0);

	gbm = gbm_create_device(fd);
	assert(gbm != NULL);

	assert((display = eglGetPlatformDisplayEXT(EGL_PLATFORM_GBM_MESA, gbm, NULL)) != EGL_NO_DISPLAY);

	EGLint majorVersion;
	EGLint minorVersion;
	assert(eglInitialize(display, &majorVersion, &minorVersion) == EGL_TRUE);

	assert(eglBindAPI(EGL_OPENGL_API) == EGL_TRUE);

	EGLConfig config = get_config();

	gs = gbm_surface_create(
		gbm, TARGET_W, TARGET_H, GBM_BO_FORMAT_ARGB8888,
		GBM_BO_USE_LINEAR|GBM_BO_USE_SCANOUT|GBM_BO_USE_RENDERING);
	assert(gs);

	assert((surface = eglCreatePlatformWindowSurfaceEXT(display, config, gs, NULL)) != EGL_NO_SURFACE);

	assert((context = eglCreateContext(display, config, EGL_NO_CONTEXT, NULL)) != EGL_NO_CONTEXT);

	assert(eglMakeCurrent(display, surface, surface, context) == EGL_TRUE);

	glViewport(0, 0, TARGET_W, TARGET_H);
}

void Render(void)
{
#define OBJ_NUM 3
#define NAME_DEPTH 2
#define BUFF_SIZE (OBJ_NUM * (3 + NAME_DEPTH))
	GLuint select_buffer[BUFF_SIZE] = {0};
	glSelectBuffer(BUFF_SIZE, select_buffer);
	glRenderMode(GL_SELECT);

	//glDepthRange(0, 0.5);

	assert(glGetError() == GL_NO_ERROR);

	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	int viewport[] = {0, 0, TARGET_W, TARGET_H};
	gluPickMatrix(100, 100, 20, 20, viewport);

	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();

	assert(glGetError() == GL_NO_ERROR);
	
	glInitNames();

	assert(glGetError() == GL_NO_ERROR);

	glPushName(1);
	glPushName(2);
	glBegin(GL_QUADS);
	glVertex3f(-1, -1, 0);
	glVertex3f(-1, 1, 0);
	glVertex3f(1, 1, 0);
	glVertex3f(1, -1, 0);

	glVertex3f(-1, -1, -0.5);
	glVertex3f(-1, 1, -0.5);
	glVertex3f(1, 1, -0.5);
	glVertex3f(1, -1, -0.5);
	glEnd();

	glPopName();
	glPopName();
	glPushName(3);
	glBegin(GL_QUADS);
	glVertex3f(-1, -1, 1);
	glVertex3f(-1, 1, 1);
	glVertex3f(1, 1, 1);
	glVertex3f(1, -1, 1);

	glVertex3f(-1, -1, 0.5);
	glVertex3f(-1, 1, 0.5);
	glVertex3f(1, 1, 0.5);
	glVertex3f(1, -1, 0.5);
	glEnd();

	glPopName();
	glPushName(5);
	glBegin(GL_QUADS);
	glVertex3f(-1, -1, -1);
	glVertex3f(-1, 1, -1);
	glVertex3f(1, 1, -1);
	glVertex3f(1, -1, -1);
	glEnd();

	assert(glGetError() == GL_NO_ERROR);

	/* http://jerome.jouvie.free.fr/opengl-tutorials/Tutorial27.php
	 * Select buffer
	 * -------------
	 * The select buffer is a list of nbRecords records.
	 * Each records is composed of :
	 * 1st int : depth of the name stack
	 * 2nd int : minimum depth value
	 * 3rd int : maximum depth value
	 * x int(s) : list of name (number is defined in the 1st integer))
	 */
	int nbRecords = glRenderMode(GL_RENDER);
	if(nbRecords <= 0) return;

	int index = 0;
	for (int i = 0; i < nbRecords; i++) {
		printf("num name=%d min/max depth=%x/%x names: ",
		       select_buffer[index], select_buffer[index + 1],
		       select_buffer[index + 2]);

		int j;
		for (j = 0; j < select_buffer[index]; j++)
			printf("%d ", select_buffer[index + 3 + j]);
		printf("\n");

		index += 3 + j;
	}
}

int main(int argc, char **argv)
{
	char *name = "/dev/dri/renderD128";
	if (argc > 1)
		name = argv[1];

	RenderTargetInit(name);
	Render();
	return 0;
}
