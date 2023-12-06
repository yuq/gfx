#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

#include <fcntl.h>
#include <unistd.h>

#include <gbm.h>
#include <png.h>

#include <epoxy/gl.h>
#include <epoxy/egl.h>

bool use_passthough_geom_shader = false;

EGLDisplay display;
EGLSurface surface;
EGLContext context;
struct gbm_device *gbm;
struct gbm_surface *gs;

GLuint program;

#define TARGET_W 400
#define TARGET_H 300

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

	assert(eglBindAPI(EGL_OPENGL_ES_API) == EGL_TRUE);

	EGLConfig config = get_config();

	gs = gbm_surface_create(
		gbm, TARGET_W, TARGET_H, GBM_BO_FORMAT_ARGB8888,
		GBM_BO_USE_LINEAR|GBM_BO_USE_SCANOUT|GBM_BO_USE_RENDERING);
	assert(gs);

	assert((surface = eglCreatePlatformWindowSurfaceEXT(display, config, gs, NULL)) != EGL_NO_SURFACE);

	const EGLint contextAttribs[] = {
		EGL_CONTEXT_CLIENT_VERSION, 2,
		EGL_NONE
	};
	assert((context = eglCreateContext(display, config, EGL_NO_CONTEXT, contextAttribs)) != EGL_NO_CONTEXT);

	assert(eglMakeCurrent(display, surface, surface, context) == EGL_TRUE);
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

void LinkProgram(GLuint program)
{
	glLinkProgram(program);

	GLint linked;
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
}

void InitGLES(void)
{
	int num = 0;
	GLuint shader[5];
	assert((shader[num++] = LoadShader("vert.glsl", GL_VERTEX_SHADER)) != 0);
	assert((shader[num++] = LoadShader("tcs.glsl", GL_TESS_CONTROL_SHADER)) != 0);
	assert((shader[num++] = LoadShader("frag.glsl", GL_FRAGMENT_SHADER)) != 0);

	if (use_passthough_geom_shader) {
		assert((shader[num++] = LoadShader("tes.glsl", GL_TESS_EVALUATION_SHADER)) != 0);
		assert((shader[num++] = LoadShader("geom.glsl", GL_GEOMETRY_SHADER)) != 0);
	} else {
		assert((shader[num++] = LoadShader("tes2.glsl", GL_TESS_EVALUATION_SHADER)) != 0);
	}

	program = glCreateProgram();

	for (int i = 0; i < num; i++)
		glAttachShader(program, shader[i]);

	LinkProgram(program);

	glUseProgram(program);

	glClearColor(0, 0, 0, 1);
	glViewport(0, 0, 128, 128);
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

static int read_data(const char *name, void **data)
{
        FILE *f;
	int size;
	void *buff;

	assert((f = fopen(name, "rb")) != NULL);

	// get file size
	fseek(f, 0, SEEK_END);
	size = ftell(f);
	fseek(f, 0, SEEK_SET);

	assert((buff = malloc(size)) != NULL);
	assert(fread(buff, 1, size, f) == size);
	fclose(f);

	*data = buff;
	return size;
}

static GLuint create_buffer(GLenum target, const char *name)
{
	void *data;
	int size = read_data(name, &data);
	assert(size && data);

	GLuint buffer;
	glGenBuffers(1, &buffer);

	glBindBuffer(target, buffer);
	glBufferData(target, size, data, GL_STATIC_DRAW);

	assert(glGetError() == GL_NO_ERROR);

	free(data);
	return buffer;
}

void Render(void)
{
        GLuint vert_buf = create_buffer(GL_ARRAY_BUFFER, "data.raw");

	GLuint vao;
	glGenVertexArrays(1, &vao);
	glBindVertexArray(vao);
	glBindBuffer(GL_ARRAY_BUFFER, vert_buf);

	GLint position = glGetAttribLocation(program, "a_position");
	glVertexAttribPointer(position, 4, GL_FLOAT, GL_FALSE, 0, NULL);
	glEnableVertexAttribArray(position);

	GLint inner = glGetUniformLocation(program, "u_innerTessellationLevel");
	GLint outer = glGetUniformLocation(program, "u_outerTessellationLevel");
	glUniform1f(inner, 14);
	glUniform1f(outer, 14);

	glPatchParameteri(GL_PATCH_VERTICES, 4);

	glClear(GL_COLOR_BUFFER_BIT);

	assert(glGetError() == GL_NO_ERROR);

	glDrawArrays(GL_PATCHES, 0, 4);

	assert(glGetError() == GL_NO_ERROR);

	eglSwapBuffers(display, surface);

	GLubyte result[TARGET_W * TARGET_H * 4] = {0};
	glReadPixels(0, 0, TARGET_W, TARGET_H, GL_RGBA, GL_UNSIGNED_BYTE, result);
	assert(glGetError() == GL_NO_ERROR);

	assert(!writeImage("screenshot.png", TARGET_W, TARGET_H, result, "hello"));
}

int main(int argc, char **argv)
{
	use_passthough_geom_shader = argc > 1;

	RenderTargetInit();
	InitGLES();
	Render();
	return 0;
}
