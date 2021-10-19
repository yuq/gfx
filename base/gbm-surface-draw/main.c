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
EGLSurface surface;
EGLContext context;
struct gbm_device *gbm;
struct gbm_surface *gs;

#define TARGET_SIZE 256

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
		gbm, TARGET_SIZE, TARGET_SIZE, GBM_BO_FORMAT_ARGB8888,
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

void InitGLES(void)
{
	GLint linked;
	GLuint vertexShader;
	GLuint fragmentShader;
	assert((vertexShader = LoadShader("vert.glsl", GL_VERTEX_SHADER)) != 0);
	assert((fragmentShader = LoadShader("frag.glsl", GL_FRAGMENT_SHADER)) != 0);
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

	glClearColor(0, 0, 0, 0);
	glViewport(0, 0, TARGET_SIZE, TARGET_SIZE);
	//glEnable(GL_DEPTH_TEST);

	glUseProgram(program);
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
	GLfloat vertex[] = {
		-1, -1, 0,
		-1, 1, 0,
		1, 1, 0,

		-1, -1, 0,
		0, -1, 0,
		0, 0, 0,
	};
	GLfloat color[] = {
		1, 0, 0, 1,
		0, 1, 0, 1,
		0, 0, 1, 1,

		1, 0, 0, 1,
		0, 1, 0, 1,
		0, 0, 1, 1,
	};
	GLuint index[] = {
		0, 1, 2
	};

	GLint position = glGetAttribLocation(program, "positionIn");
	glEnableVertexAttribArray(position);
	glVertexAttribPointer(position, 3, GL_FLOAT, 0, 0, vertex);

	GLint colorIn = glGetAttribLocation(program, "colorIn");
	glEnableVertexAttribArray(colorIn);
	glVertexAttribPointer(colorIn, 4, GL_FLOAT, 0, 0, color);

	assert(glGetError() == GL_NO_ERROR);

	glClear(GL_COLOR_BUFFER_BIT 
		//| GL_DEPTH_BUFFER_BIT
		);
	printf("%x\n", glGetError());
	assert(glGetError() == GL_NO_ERROR);

	//glDrawElements(GL_TRIANGLES, sizeof(index)/sizeof(GLuint), GL_UNSIGNED_INT, index);
	glDrawArrays(GL_TRIANGLES, 0, 3);
	glDrawArrays(GL_TRIANGLES, 3, 3);

	assert(glGetError() == GL_NO_ERROR);

	eglSwapBuffers(display, surface);

#if 1
	GLubyte result[TARGET_SIZE * TARGET_SIZE * 4] = {0};
	glReadPixels(0, 0, TARGET_SIZE, TARGET_SIZE, GL_RGBA, GL_UNSIGNED_BYTE, result);
	assert(glGetError() == GL_NO_ERROR);
#else
	struct gbm_bo *bo = gbm_surface_lock_front_buffer(gs);
	assert(bo);

	uint32_t stride;
	void *map_data;
	GLubyte *result = gbm_bo_map(bo, 0, 0, TARGET_SIZE, TARGET_SIZE,
				     GBM_BO_TRANSFER_READ, &stride, &map_data);
	assert(result);
	assert(stride == TARGET_SIZE * 4);
#endif

	assert(!writeImage("screenshot.png", TARGET_SIZE, TARGET_SIZE, result, "hello"));
}

int main(void)
{
	RenderTargetInit();
	InitGLES();
	Render();
	return 0;
}
