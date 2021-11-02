#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <string.h>

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

#define TARGET_W 800
#define TARGET_H 600

EGLConfig get_config(void)
{
	EGLint egl_config_attribs[] = {
		EGL_BUFFER_SIZE,	32,
		EGL_DEPTH_SIZE,		EGL_DONT_CARE,
		EGL_STENCIL_SIZE,	EGL_DONT_CARE,
		EGL_RENDERABLE_TYPE,	EGL_OPENGL_ES2_BIT,
		EGL_SURFACE_TYPE,	EGL_WINDOW_BIT,
		//EGL_SAMPLES,            4,
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

	assert(eglBindAPI(EGL_OPENGL_API) == EGL_TRUE);

	EGLConfig config = get_config();

	gs = gbm_surface_create(
		gbm, TARGET_W, TARGET_H, GBM_BO_FORMAT_ARGB8888,
		GBM_BO_USE_LINEAR|GBM_BO_USE_RENDERING);
	assert(gs);

	assert((surface = eglCreatePlatformWindowSurfaceEXT(display, config, gs, NULL)) != EGL_NO_SURFACE);

	assert((context = eglCreateContext(display, config, EGL_NO_CONTEXT, NULL)) != EGL_NO_CONTEXT);

	assert(eglMakeCurrent(display, surface, surface, context) == EGL_TRUE);

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

	glClearColor(1, 1, 1, 1);
	glViewport(0, 0, TARGET_W, TARGET_H);
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

static GLuint create_buffer(GLenum target, int offset, int size)
{
	GLuint buffer;
	glGenBuffers(1, &buffer);

	glBindBuffer(target, buffer);
	glBufferData(target, size, NULL, GL_STATIC_COPY);
	glBindBuffer(target, 0);

	glInvalidateBufferData(buffer);

	glBindBuffer(GL_COPY_WRITE_BUFFER, buffer);
	glCopyBufferSubData(GL_COPY_READ_BUFFER, GL_COPY_WRITE_BUFFER, offset, 0, size);

	assert(glGetError() == GL_NO_ERROR);

	return buffer;
}

static void print_info(void *data)
{
	struct {
		unsigned count;
		unsigned instanceCount;
		unsigned firstIndex;
		unsigned baseVertex;
		unsigned baseInstance;
	} *draw = data + 3145728;
	unsigned *index = data + 409600;
	float *vertex = data + 573440;

#define MAX_Y 1024
	float ys[MAX_Y] = {0};
	int num_y = 0;

	for (int i = 0; i < 1024; i++) {
		for (int j = 0; j < draw->count; j++) {
			int vi = draw->baseVertex + index[draw->firstIndex + j];
			float y = vertex[vi * 3 + 1];
			int k;
			for (k = 0; k < num_y; k++) {
				if (ys[k] == y)
					break;
			}
			if (k == num_y) {
				if (num_y == MAX_Y)
					printf("warning: reach max Y\n");
				else
					ys[num_y++] = y;
			}
		}
		draw = (void *)draw + 32;
	}

	assert(num_y);	

	for (int i = num_y - 1; i > 0; i--) {
	        for (int j = 0; j < i; j++) {
			if (ys[j] > ys[j + 1]) {
				float tmp = ys[j + 1];
				ys[j + 1] = ys[j];
				ys[j] = tmp;
			}
		}
	}

	printf("print ys num %d\n", num_y);
	for (int i = 0; i < num_y; i++)
		printf("%f\n", ys[i]);
}

void Render(void)
{
	glDisable(GL_BLEND);
	glDisable(GL_LINE_SMOOTH);
	glEnable(GL_DITHER);
	glEnable(GL_MULTISAMPLE);
	glEnable(GL_POLYGON_OFFSET_FILL);

	glPolygonOffset(1, 0.0002);

	glColor3f(0, 0, 0);
	glLineWidth(1);

	void *data;
	int size = read_data("global.raw", &data);

	int global_size = 1712;
	assert(size >= global_size);

	GLuint global_buffer;
	glGenBuffers(1, &global_buffer);
	glBindBuffer(GL_UNIFORM_BUFFER, global_buffer);
	glBufferData(GL_UNIFORM_BUFFER, global_size, NULL, GL_STATIC_DRAW);
	glBufferSubData(GL_UNIFORM_BUFFER, 0, size, data);
	glBindBufferBase(GL_UNIFORM_BUFFER, 0, global_buffer);

	assert(glGetError() == GL_NO_ERROR);

	GLuint data_buffer;
	glGenBuffers(1, &data_buffer);

	unsigned data_max_size = 0x400000;
	glBindBuffer(GL_ARRAY_BUFFER, data_buffer);
	glBufferStorage(GL_ARRAY_BUFFER, data_max_size, NULL, GL_MAP_WRITE_BIT | GL_MAP_PERSISTENT_BIT | GL_MAP_COHERENT_BIT);
	void *data_map = glMapBufferRange(GL_ARRAY_BUFFER, 0, data_max_size, GL_MAP_WRITE_BIT | GL_MAP_PERSISTENT_BIT | GL_MAP_COHERENT_BIT);
	assert(data_map);

	assert(glGetError() == GL_NO_ERROR);

	glBindBuffer(GL_COPY_READ_BUFFER, data_buffer);

	GLuint vertex_buffer = create_buffer(GL_ARRAY_BUFFER, 573440, 442368);
	GLuint element_buffer = create_buffer(GL_ELEMENT_ARRAY_BUFFER, 409600, 163840);
	GLuint misc_buffer = create_buffer(GL_DRAW_INDIRECT_BUFFER, 3145728, 32768);
	GLuint per_pid_buffer = create_buffer(GL_SHADER_STORAGE_BUFFER, 2850816, 262144);

	size = read_data("data.raw", &data);
	assert(size <= data_max_size);
	memcpy(data_map, data, size);

	print_info(data);

	glMemoryBarrier(GL_VERTEX_ATTRIB_ARRAY_BARRIER_BIT | GL_COMMAND_BARRIER_BIT);

	assert(glGetError() == GL_NO_ERROR);
	
	glClear(GL_COLOR_BUFFER_BIT);
	assert(glGetError() == GL_NO_ERROR);

	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, element_buffer);

	glEnableVertexAttribArray(0);
	glBindBuffer(GL_ARRAY_BUFFER, vertex_buffer);
	glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 12, NULL);

	glEnableVertexAttribArray(2);
	glBindBuffer(GL_ARRAY_BUFFER, misc_buffer);
	glVertexAttribIPointer(2, 2, GL_UNSIGNED_INT, 32, (void *)0x14);
	glVertexAttribDivisor(2, 1);

	glBindBufferRange(GL_SHADER_STORAGE_BUFFER, 1, per_pid_buffer, 0, 262144);

	glBindBuffer(GL_DRAW_INDIRECT_BUFFER, misc_buffer);

	glMultiDrawElementsIndirect(GL_LINES, GL_UNSIGNED_INT, NULL, 1024, 32);
	
	assert(glGetError() == GL_NO_ERROR);

	eglSwapBuffers(display, surface);

	GLubyte result[TARGET_W * TARGET_H * 4] = {0};
	glReadPixels(0, 0, TARGET_W, TARGET_H, GL_RGBA, GL_UNSIGNED_BYTE, result);
	assert(glGetError() == GL_NO_ERROR);

	assert(!writeImage("screenshot.png", TARGET_W, TARGET_H, result, "hello"));
}

int main(void)
{
	RenderTargetInit();
	InitGLES();
	Render();
	return 0;
}
