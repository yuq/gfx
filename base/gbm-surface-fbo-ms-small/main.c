#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

#include <fcntl.h>
#include <unistd.h>

#include <gbm.h>
#include <png.h>

#include <epoxy/gl.h>
#include <epoxy/egl.h>

GLuint program;
EGLDisplay display;
EGLContext context;
struct gbm_device *gbm;

#define TARGET_SIZE 256
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

void CheckFrameBufferStatus(GLenum target)
{
  GLenum status;
  status = glCheckFramebufferStatus(target);
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
	GLuint ms_fbid;
	glGenFramebuffers(1, &ms_fbid);
	glBindFramebuffer(GL_DRAW_FRAMEBUFFER, ms_fbid);

        GLuint ms_color_rbid;
	glGenRenderbuffers(1, &ms_color_rbid);
	glBindRenderbuffer(GL_RENDERBUFFER, ms_color_rbid);
	glRenderbufferStorageMultisample(GL_RENDERBUFFER, SAMPLE_NUM, GL_RGBA, 16, 16);

	glFramebufferRenderbuffer(GL_DRAW_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, ms_color_rbid);

	GLuint ms_depth_stencil_rbid;
	glGenRenderbuffers(1, &ms_depth_stencil_rbid);
	glBindRenderbuffer(GL_RENDERBUFFER, ms_depth_stencil_rbid);
	glRenderbufferStorageMultisample(GL_RENDERBUFFER, SAMPLE_NUM, GL_DEPTH_STENCIL, 16, 16);

	glFramebufferRenderbuffer(GL_DRAW_FRAMEBUFFER, GL_DEPTH_STENCIL_ATTACHMENT, GL_RENDERBUFFER, ms_depth_stencil_rbid);

	CheckFrameBufferStatus(GL_DRAW_FRAMEBUFFER);

	int sample_num = 0;
	glGetIntegerv(GL_SAMPLES, &sample_num);
	assert(sample_num == SAMPLE_NUM);

	assert(glIsEnabled(GL_MULTISAMPLE));

	assert(glGetError() == GL_NO_ERROR);

	GLuint ss_fbid;
	glGenFramebuffers(1, &ss_fbid);
	glBindFramebuffer(GL_DRAW_FRAMEBUFFER, ss_fbid);

	GLuint ss_rbid;
	glGenRenderbuffers(1, &ss_rbid);
	glBindRenderbuffer(GL_RENDERBUFFER, ss_rbid);
	glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA, 16, 16);

	glFramebufferRenderbuffer(GL_DRAW_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, ss_rbid);

	CheckFrameBufferStatus(GL_DRAW_FRAMEBUFFER);

	GLuint fbid;
	glGenFramebuffers(1, &fbid);
	glBindFramebuffer(GL_DRAW_FRAMEBUFFER, fbid);

	GLuint rbid;
	glGenRenderbuffers(1, &rbid);
	glBindRenderbuffer(GL_RENDERBUFFER, rbid);
	glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA, TARGET_SIZE, TARGET_SIZE);

	glFramebufferRenderbuffer(GL_DRAW_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, rbid);

	CheckFrameBufferStatus(GL_DRAW_FRAMEBUFFER);

	InitGLES("vert.glsl", "frag.glsl");

	GLfloat vertex[] = {
		-1, -1,
		-1, 1,
		1, -1,
		1, 1,
	};

	GLuint vao;
	glGenVertexArrays(1, &vao);
	glBindVertexArray(vao);

	GLuint vbo;
	glGenBuffers(1, &vbo);
	glBindBuffer(GL_ARRAY_BUFFER, vbo);
	glBufferData(GL_ARRAY_BUFFER, sizeof(vertex), vertex, GL_STATIC_DRAW);

	glEnableVertexAttribArray(0);
	glVertexAttribPointer(0, 2, GL_FLOAT, 0, 0, 0);
	assert(glGetError() == GL_NO_ERROR);

	glClearColor(0, 0, 0, 0);
	glViewport(0, 0, 16, 16);
	glEnable(GL_DEPTH_TEST);
	glDepthFunc(GL_LESS);

	float red[] = {1, 0, 0, 1};
	float green[] = {0, 1, 0, 1};
	int tile_w = TARGET_SIZE / 16;
	int tile_h = TARGET_SIZE / 16;
	for (int i = 0; i < tile_h; i++) {
		for (int j = 0; j < tile_w; j++) {
			glBindFramebuffer(GL_DRAW_FRAMEBUFFER, ms_fbid);

			glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

			glUniform1f(0, 0);
			glUniform4fv(1, 1, red);

			glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
			assert(glGetError() == GL_NO_ERROR);

			glEnable(GL_STENCIL_TEST);
			glStencilOp(GL_KEEP, GL_KEEP, GL_INCR);
			glStencilFunc(GL_EQUAL, 0, 0xff);

			glClear(GL_STENCIL_BUFFER_BIT);

			glUniform1f(0, -0.5);
			glUniform4fv(1, 1, green);

			glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
			assert(glGetError() == GL_NO_ERROR);

			glDisable(GL_STENCIL_TEST);

			glBindFramebuffer(GL_READ_FRAMEBUFFER, ms_fbid);
			glBindFramebuffer(GL_DRAW_FRAMEBUFFER, ss_fbid);

			glBlitFramebuffer(0, 0, 16, 16, 0, 0, 16, 16,
					  GL_COLOR_BUFFER_BIT, GL_NEAREST);

			glBindFramebuffer(GL_READ_FRAMEBUFFER, ss_fbid);
			glBindFramebuffer(GL_DRAW_FRAMEBUFFER, fbid);

			glBlitFramebuffer(0, 0, 16, 16,
					 j * 16, i * 16, (j + 1) * 16, (i + 1) * 16,
					 GL_COLOR_BUFFER_BIT, GL_NEAREST);
		}
	}

	
	glBindFramebuffer(GL_READ_FRAMEBUFFER, fbid);
	GLubyte result[TARGET_SIZE * TARGET_SIZE * 4] = {0};
	glReadPixels(0, 0, TARGET_SIZE, TARGET_SIZE, GL_RGBA, GL_UNSIGNED_BYTE, result);
	assert(glGetError() == GL_NO_ERROR);

	assert(!writeImage("screenshot.png", TARGET_SIZE, TARGET_SIZE, result, "hello"));

	for (int i = 0; i < TARGET_SIZE; i++) {
		for (int j = 0; j < TARGET_SIZE; j++) {
			unsigned *data = (unsigned *)result;
			if (data[i * TARGET_SIZE + j] == 0) {
				printf("no data at %d/%d\n", i, j);
				return;
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
