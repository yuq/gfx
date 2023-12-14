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

#define TARGET_SIZE 32
#define SAMPLE_NUM 2

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

void InitGLES(const char *vert, const char *frag)
{
	GLint linked;
	GLuint vertexShader;
	GLuint fragmentShader;
	assert((vertexShader = LoadShader(vert, GL_VERTEX_SHADER)) != 0);
	assert((fragmentShader = LoadShader(frag, GL_FRAGMENT_SHADER)) != 0);
	assert((program = glCreateProgram()) != 0);
	glAttachShader(program, vertexShader);
	glAttachShader(program, fragmentShader);
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
	glClearColor(0, 0, 0, 0);
	glViewport(0, 0, TARGET_SIZE, TARGET_SIZE);

	GLuint fbid;
	glGenFramebuffers(1, &fbid);
	glBindFramebuffer(GL_FRAMEBUFFER, fbid);

        GLuint rbid;
	glGenRenderbuffers(1, &rbid);
	glBindRenderbuffer(GL_RENDERBUFFER, rbid);
	glRenderbufferStorageMultisample(GL_RENDERBUFFER, SAMPLE_NUM, GL_RGBA, TARGET_SIZE, TARGET_SIZE);

	glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, rbid);

	CheckFrameBufferStatus();

	int sample_num = 0;
	glGetIntegerv(GL_SAMPLES, &sample_num);
	assert(sample_num == SAMPLE_NUM);

	assert(glIsEnabled(GL_MULTISAMPLE));

	assert(glGetError() == GL_NO_ERROR);

	InitGLES("vert.glsl", "frag.glsl");

	GLuint tex[SAMPLE_NUM];
	glGenTextures(SAMPLE_NUM, tex);
	for (int i = 0; i < SAMPLE_NUM; i++) {
		glBindTexture(GL_TEXTURE_2D, tex[i]);
		glTexStorage2D(GL_TEXTURE_2D, 1, GL_RG32F, TARGET_SIZE, TARGET_SIZE);
		glBindImageTexture(i, tex[i], 0, GL_FALSE, 0, GL_WRITE_ONLY, GL_RG32F);
	}
	assert(glGetError() == GL_NO_ERROR);

	GLfloat vertex[] = {
		-1, -1, 0,
		-1, 1, 0,
		1, -1, 0,
		1, 1, 0,
	};

	GLuint vao;
	glGenVertexArrays(1, &vao);
	glBindVertexArray(vao);

	GLuint vbo;
	glGenBuffers(1, &vbo);
	glBindBuffer(GL_ARRAY_BUFFER, vbo);
	glBufferData(GL_ARRAY_BUFFER, sizeof(vertex), vertex, GL_STATIC_DRAW);

	glEnableVertexAttribArray(0);
	glVertexAttribPointer(0, 3, GL_FLOAT, 0, 0, 0);
	assert(glGetError() == GL_NO_ERROR);

	glClear(GL_COLOR_BUFFER_BIT);

	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	assert(glGetError() == GL_NO_ERROR);

	glMemoryBarrier(GL_SHADER_IMAGE_ACCESS_BARRIER_BIT);
	glFinish();

	for (int i = 0; i < SAMPLE_NUM; i++) {
		float sample_pos[2];
		glGetMultisamplefv(GL_SAMPLE_POSITION, i, sample_pos);

		float *result = calloc(1, TARGET_SIZE * TARGET_SIZE * 8);
		glGetTextureImage(tex[i], 0, GL_RG, GL_FLOAT,
				  TARGET_SIZE * TARGET_SIZE * 8, result);
		assert(glGetError() == GL_NO_ERROR);

		for (int j = 0; j < TARGET_SIZE; j++) {
			for (int k = 0; k < TARGET_SIZE; k++) {
				float *data = result + (j * TARGET_SIZE + k) * 2; 
				if (sample_pos[0] != data[0] || sample_pos[1] != data[1]) {
					printf("sample pos at %d|%d|%d expect %f|%f get %f|%f\n",
					       i, j, k, sample_pos[0], sample_pos[1],
					       data[0], data[1]);
					return;
				}
			}
		}
	}

	printf("pass\n");
}

int main(void)
{
	RenderTargetInit();
	Render();
	return 0;
}
