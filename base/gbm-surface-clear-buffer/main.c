#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <string.h>

#include <fcntl.h>
#include <unistd.h>

#include <gbm.h>

#include <epoxy/gl.h>
#include <epoxy/egl.h>

GLuint program;
EGLDisplay display;
EGLContext context;
struct gbm_device *gbm;

#define TARGET_WIDTH  32
#define TARGET_HEIGHT 32

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
	assert(epoxy_has_egl_extension(display, "EGL_KHR_surfaceless_context"));

	assert(eglBindAPI(EGL_OPENGL_API) == EGL_TRUE);

        const EGLint contextAttribs[] = {
		EGL_CONTEXT_MAJOR_VERSION, 4,
		EGL_CONTEXT_MINOR_VERSION, 3,
		EGL_NONE
	};
	assert((context = eglCreateContext(display, NULL, EGL_NO_CONTEXT, contextAttribs)) != EGL_NO_CONTEXT);

	assert(eglMakeCurrent(display, EGL_NO_SURFACE, EGL_NO_SURFACE, context) == EGL_TRUE);
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
  case GL_FRAMEBUFFER_INCOMPLETE_DIMENSIONS:
    printf("GL_FRAMEBUFFER_INCOMPLETE_DIMENSIONS\n");
    break;
  default:
    printf("Framebuffer error\n");
  }
}

void Render(void)
{
	GLuint fbid;
	glGenFramebuffers(1, &fbid);
	glBindFramebuffer(GL_FRAMEBUFFER, fbid);

	GLuint texid;
	glGenTextures(1, &texid);
	glBindTexture(GL_TEXTURE_2D, texid);
	glTexStorage2D(GL_TEXTURE_2D, 1, GL_DEPTH_COMPONENT24, TARGET_WIDTH, TARGET_HEIGHT);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAX_LEVEL, 0);
	glFramebufferTexture2D(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_TEXTURE_2D, texid, 0);

	CheckFrameBufferStatus();

	glViewport(0, 0, TARGET_WIDTH, TARGET_HEIGHT);

	float depth = 0.5;
        glClearBufferfv(GL_DEPTH, 0, &depth);

	assert(glGetError() == GL_NO_ERROR);

	GLuint result[TARGET_WIDTH * TARGET_HEIGHT] = {0};
	glGetTexImage(GL_TEXTURE_2D, 0, GL_DEPTH_COMPONENT, GL_UNSIGNED_INT, result);
	assert(glGetError() == GL_NO_ERROR);

	GLuint data = result[0];
	for (int i = 0; i < TARGET_HEIGHT; i++) {
		for (int j = 0; j < TARGET_WIDTH; j++) {
			GLuint r = result[i * TARGET_WIDTH + j];
			if (r != data) {
				printf("fail at %d/%d expect %x but get %x\n",
				       j, i, data, r);
				return;
			}
		}
	}
	printf("pass with result %x\n", data);
}

int main(void)
{
	RenderTargetInit();
	Render();
	return 0;
}
