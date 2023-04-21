#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

#include <fcntl.h>
#include <unistd.h>

#include <gbm.h>

#include <epoxy/gl.h>
#include <epoxy/egl.h>

GLuint program;
EGLDisplay display;
EGLContext context;
struct gbm_device *gbm;

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

	assert((context = eglCreateContext(display, NULL, EGL_NO_CONTEXT, NULL)) != EGL_NO_CONTEXT);

	assert(eglMakeCurrent(display, EGL_NO_SURFACE, EGL_NO_SURFACE, context) == EGL_TRUE);

	printf("OpenGL version %s\n", glGetString(GL_VERSION));
}

GLuint LoadShader(const char *name, GLenum type)
{
	FILE *f;
	int size;
	char *buff;
	GLuint shader;
	GLint compiled;
	const GLchar *source[1];

	assert((f = fopen(name, "r")) != NULL);

	// get file size
	fseek(f, 0, SEEK_END);
	size = ftell(f);
	fseek(f, 0, SEEK_SET);

	assert((buff = malloc(size)) != NULL);
	assert(fread(buff, 1, size, f) == size);
	source[0] = buff;
	fclose(f);
	shader = glCreateShader(type);
	glShaderSource(shader, 1, source, &size);
	glCompileShader(shader);
	free(buff);
	glGetShaderiv(shader, GL_COMPILE_STATUS, &compiled);
	if (!compiled) {
		GLint infoLen = 0;
		glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &infoLen);
		if (infoLen > 1) {
			char *infoLog = malloc(infoLen);
			glGetShaderInfoLog(shader, infoLen, NULL, infoLog);
			fprintf(stderr, "Error compiling shader %s:\n%s\n", name, infoLog);
			free(infoLog);
		}
		glDeleteShader(shader);
		return 0;
	}

	return shader;
}

void InitGLES(void)
{
	GLint linked;
        GLuint shader;
	assert((shader = LoadShader("comp.glsl", GL_COMPUTE_SHADER)) != 0);
	assert((program = glCreateProgram()) != 0);
	glAttachShader(program, shader);
	glLinkProgram(program);
	glGetProgramiv(program, GL_LINK_STATUS, &linked);
	if (!linked) {
		GLint infoLen = 0;
		glGetProgramiv(program, GL_INFO_LOG_LENGTH, &infoLen);
		if (infoLen > 1) {
			char *infoLog = malloc(infoLen);
			glGetProgramInfoLog(program, infoLen, NULL, infoLog);
			fprintf(stderr, "Error linking program:\n%s\n", infoLog);
			free(infoLog);
		}
		glDeleteProgram(program);
		exit(1);
	}

	glUseProgram(program);
}

void Render(void)
{
	float data[] = {
		-1, 1, 0, 0,
	};

	GLuint ssbo;
	glGenBuffers(1, &ssbo);
	assert(glGetError() == GL_NO_ERROR);
	glBindBuffer(GL_SHADER_STORAGE_BUFFER, ssbo);
	assert(glGetError() == GL_NO_ERROR);
	glBufferData(GL_SHADER_STORAGE_BUFFER, sizeof(data), data, GL_DYNAMIC_READ);
	assert(glGetError() == GL_NO_ERROR);
	glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 0, ssbo);

	assert(glGetError() == GL_NO_ERROR);

	glDispatchCompute(1, 1, 1);
	glMemoryBarrier(GL_SHADER_IMAGE_ACCESS_BARRIER_BIT);

	assert(glGetError() == GL_NO_ERROR);

	glGetBufferSubData(GL_SHADER_STORAGE_BUFFER, 0, sizeof(data), data);

	assert(glGetError() == GL_NO_ERROR);

	printf("result: %f %f %f %f\n", data[0], data[1], data[2], data[3]);
}

int main(void)
{
	RenderTargetInit();
	InitGLES();
	Render();
	return 0;
}
