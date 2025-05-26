#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <string.h>

#include <fcntl.h>
#include <unistd.h>
#include <sys/stat.h>

#include <gbm.h>
#include <png.h>

#include <epoxy/gl.h>
#include <epoxy/egl.h>

#include <X11/Xlib.h>

//#define FEEDBACK

GLuint program;
EGLDisplay display;
EGLSurface surface;
EGLContext context;
struct gbm_device *gbm;
struct gbm_surface *gs;
Display *x11_display;

#define TARGET_W 800
#define TARGET_H 600

static EGLConfig get_gbm_config(void)
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

static void init_gbm_render_target(void)
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

	EGLConfig config = get_gbm_config();

	gs = gbm_surface_create(
		gbm, TARGET_W, TARGET_H, GBM_BO_FORMAT_ARGB8888,
		GBM_BO_USE_LINEAR|GBM_BO_USE_RENDERING);
	assert(gs);

	assert((surface = eglCreatePlatformWindowSurfaceEXT(display, config, gs, NULL)) != EGL_NO_SURFACE);

	assert((context = eglCreateContext(display, config, EGL_NO_CONTEXT, NULL)) != EGL_NO_CONTEXT);

	assert(eglMakeCurrent(display, surface, surface, context) == EGL_TRUE);

	printf("OpenGL version %s\n", glGetString(GL_VERSION));
}

static EGLNativeWindowType CreateNativeWindow(void)
{
	Display *display;
	assert((display = XOpenDisplay(NULL)) != NULL);
	x11_display = display;

	int screen = DefaultScreen(display);
	Window root = DefaultRootWindow(display);
	Window window =  XCreateWindow(display, root, 0, 0, TARGET_W, TARGET_H, 0,
				       DefaultDepth(display, screen), InputOutput,
				       DefaultVisual(display, screen), 
				       0, NULL);
	XMapWindow(display, window);
	XFlush(display);
	return (EGLNativeWindowType)window;
}

static void init_x11_render_target(void)
{
	EGLNativeWindowType window;
	window = CreateNativeWindow();

	assert((display = eglGetDisplay((EGLNativeDisplayType)x11_display)) != EGL_NO_DISPLAY);

	EGLint majorVersion;
	EGLint minorVersion;
	assert(eglInitialize(display, &majorVersion, &minorVersion) == EGL_TRUE);

	assert(eglBindAPI(EGL_OPENGL_API) == EGL_TRUE);

	EGLConfig config;
	EGLint numConfigs;
	const EGLint configAttribs[] = {
		EGL_SURFACE_TYPE, EGL_WINDOW_BIT,
		EGL_RED_SIZE, 8,
		EGL_GREEN_SIZE, 8,
		EGL_BLUE_SIZE, 8,
		EGL_DEPTH_SIZE, 24,
		EGL_NONE
	};
	assert(eglChooseConfig(display, configAttribs, &config, 1, &numConfigs) == EGL_TRUE);
	assert(numConfigs > 0);

	const EGLint attribList[] = {
		EGL_RENDER_BUFFER, EGL_BACK_BUFFER,
		EGL_NONE
	};
	assert((surface = eglCreateWindowSurface(display, config, window, attribList)) != EGL_NO_SURFACE);

	EGLint attr[] = {
		//EGL_CONTEXT_MAJOR_VERSION, 3,
		//EGL_CONTEXT_MINOR_VERSION, 3,
		//EGL_CONTEXT_OPENGL_PROFILE_MASK, EGL_CONTEXT_OPENGL_CORE_PROFILE_BIT,
		EGL_CONTEXT_OPENGL_DEBUG, EGL_TRUE,
		EGL_NONE,
	};
	assert((context = eglCreateContext(display, config, EGL_NO_CONTEXT, attr)) != EGL_NO_CONTEXT);

	assert(eglMakeCurrent(display, surface, surface, context) == EGL_TRUE);

	printf("OpenGL version %s\n", glGetString(GL_VERSION));
}

static GLuint LoadShader(const char *name, GLenum type)
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

static void InitGLES(void)
{
	GLint linked;
	GLuint vertexShader;
	GLuint geometryShader;
	GLuint fragmentShader;
	assert((vertexShader = LoadShader("vert.glsl", GL_VERTEX_SHADER)) != 0);
	assert((geometryShader = LoadShader("geom.glsl", GL_GEOMETRY_SHADER)) != 0);
	assert((fragmentShader = LoadShader("frag.glsl", GL_FRAGMENT_SHADER)) != 0);
	assert((program = glCreateProgram()) != 0);
	glAttachShader(program, vertexShader);
	glAttachShader(program, geometryShader);
	glAttachShader(program, fragmentShader);

#ifdef FEEDBACK
	const char *feedback[] = {
		"gl_Position",
		"GeometryOut.flat_normal",
		"GeometryOut.tex_top",
	};
	glTransformFeedbackVaryings(program, 3, feedback, GL_INTERLEAVED_ATTRIBS);
	assert(glGetError() == GL_NO_ERROR);
#endif
	
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
	glEnable(GL_DEPTH_TEST);

	glUseProgram(program);
}


static int writeImage(char* filename, int width, int height, void *buffer, char* title)
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

static void write_data(const char *name, void *data, int size)
{
	int fd = open(name, O_WRONLY|O_CREAT|O_TRUNC, S_IRUSR|S_IWUSR|S_IRGRP|S_IWGRP);
	assert(fd >= 0);

	assert(write(fd, data, size) == size);

	close(fd);
}

static void fill_buffer(const char *name, void *buffer, int offset, int max_size)
{
	void *data;
	int size = read_data(name, &data);
	assert(offset + size <= max_size);
	memcpy(buffer + offset, data, size);
	free(data);
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

static void load_uniform_buffer(const char *name, int index, int max_size)
{
	void *data;
	int size = read_data(name, &data);
	assert(size <= max_size);

	GLuint buffer;
	glGenBuffers(1, &buffer);
	glBindBuffer(GL_UNIFORM_BUFFER, buffer);
	glBufferData(GL_UNIFORM_BUFFER, max_size, NULL, GL_STATIC_DRAW);
	glBufferSubData(GL_UNIFORM_BUFFER, 0, size, data);
	glBindBufferBase(GL_UNIFORM_BUFFER, index, buffer);

	assert(glGetError() == GL_NO_ERROR);

	free(data);
}

static void render(void)
{
	InitGLES();

        glDepthRange(0, 1);

	glDisable(GL_BLEND);
	glDisable(GL_LINE_SMOOTH);
	
	glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
	glEnable(GL_POLYGON_OFFSET_FILL);
	glPolygonOffset(1, 3);

	glColor3f(0, 0, 0);
	glLineWidth(1);

	load_uniform_buffer("data_5.raw", 0, 2512);
        load_uniform_buffer("data_4.raw", 1, 256);

	GLuint data_buffer;
	glGenBuffers(1, &data_buffer);

	unsigned data_max_size = 0x100000;
	glBindBuffer(GL_ARRAY_BUFFER, data_buffer);
	glBufferStorage(GL_ARRAY_BUFFER, data_max_size, NULL, GL_MAP_WRITE_BIT | GL_MAP_PERSISTENT_BIT | GL_MAP_COHERENT_BIT);
	void *data_map = glMapBufferRange(GL_ARRAY_BUFFER, 0, data_max_size, GL_MAP_WRITE_BIT | GL_MAP_PERSISTENT_BIT | GL_MAP_COHERENT_BIT);
	assert(data_map);

	assert(glGetError() == GL_NO_ERROR);

	memset(data_map, 0, data_max_size);
	fill_buffer("data_1.raw", data_map, 0, data_max_size);
	fill_buffer("data_2.raw", data_map, 0xc4000, data_max_size);
	fill_buffer("data_3.raw", data_map, 0xdf000, data_max_size);

	glBindBuffer(GL_COPY_READ_BUFFER, data_buffer);

	GLuint vertex_buffer = create_buffer(GL_ARRAY_BUFFER, 459640, 343560);
	GLuint element_buffer = create_buffer(GL_ELEMENT_ARRAY_BUFFER, 0, 453728);
	GLuint per_pid_buffer = create_buffer(GL_UNIFORM_BUFFER, 916632, 512);
	GLuint texture_buffer = create_buffer(GL_TEXTURE_BUFFER, 803200, 113432);

	//glMemoryBarrier(GL_VERTEX_ATTRIB_ARRAY_BARRIER_BIT | GL_COMMAND_BARRIER_BIT);

	GLuint tex1;
	glGenTextures(1, &tex1);
	glActiveTexture(GL_TEXTURE1);
	glBindTexture(GL_TEXTURE_2D, tex1);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, 8, 2, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
	GLubyte data1[] = {0, 0, 255, 255, 0, 203, 255, 150, 0, 255, 102, 150, 101, 255, 0, 150, 255, 204, 0, 150, 255, 0, 0, 255, 255, 0, 0, 255, 255, 0, 0, 255};
	glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, 8, 1, GL_RGBA, GL_UNSIGNED_BYTE, data1);
	GLubyte data2[] = {150, 150, 150, 255, 150, 150, 150, 255, 150, 150, 150, 255, 150, 150, 150, 255, 150, 150, 150, 255, 150, 150, 150, 255, 150, 150, 150, 255, 150, 150, 150, 255};
	glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 1, 8, 1, GL_RGBA, GL_UNSIGNED_BYTE, data2);

	GLuint tex17;
	glGenTextures(1, &tex17);
	glActiveTexture(GL_TEXTURE17);
	glBindTexture(GL_TEXTURE_BUFFER, tex17);
	glTexBuffer(GL_TEXTURE_BUFFER, GL_R32F, texture_buffer);

	assert(glGetError() == GL_NO_ERROR);

	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, element_buffer);

	glEnableVertexAttribArray(0);
	glBindBuffer(GL_ARRAY_BUFFER, vertex_buffer);
	glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 12, NULL);

	glBindBufferRange(GL_UNIFORM_BUFFER, 2, per_pid_buffer, 0, 256);

	glUniform1i(0, 0);

	glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);
	assert(glGetError() == GL_NO_ERROR);

	const int num_elements = 56584;
#ifdef FEEDBACK
	const int num_triangles = num_elements / 4 * 2;
	const int tbo_size = num_triangles * 3 * 28;
	GLuint tbo;
	glGenBuffers(1, &tbo);
        glBindBuffer(GL_ARRAY_BUFFER, tbo);
	glBufferData(GL_ARRAY_BUFFER, tbo_size, NULL, GL_STATIC_READ);
	glBindBufferBase(GL_TRANSFORM_FEEDBACK_BUFFER, 0, tbo);
	assert(glGetError() == GL_NO_ERROR);

	GLuint query;
	glGenQueries(1, &query);
	glBeginQuery(GL_TRANSFORM_FEEDBACK_PRIMITIVES_WRITTEN, query);
	glBeginTransformFeedback(GL_TRIANGLES);
	assert(glGetError() == GL_NO_ERROR);
#endif

	glDrawElements(GL_LINES_ADJACENCY, num_elements, GL_UNSIGNED_INT, NULL);
	assert(glGetError() == GL_NO_ERROR);

#ifdef FEEDBACK
	glEndTransformFeedback();
	glEndQuery(GL_TRANSFORM_FEEDBACK_PRIMITIVES_WRITTEN);
	assert(glGetError() == GL_NO_ERROR);
#endif

	eglSwapBuffers(display, surface);

#ifdef FEEDBACK
	GLuint primitives;
	glGetQueryObjectuiv(query, GL_QUERY_RESULT, &primitives);

	printf("feedback primitives %u\n", primitives);

	assert(primitives == num_triangles);

	char *feedback = calloc(1, tbo_size);
	glGetBufferSubData(GL_TRANSFORM_FEEDBACK_BUFFER, 0, tbo_size, feedback);
	assert(glGetError() == GL_NO_ERROR);
	write_data("feedback.data", feedback, tbo_size);
	free(feedback);
#endif
}

static void dump_screenshot(void)
{
	GLubyte result[TARGET_W * TARGET_H * 4] = {0};
	glReadPixels(0, 0, TARGET_W, TARGET_H, GL_RGBA, GL_UNSIGNED_BYTE, result);
	assert(glGetError() == GL_NO_ERROR);

	assert(!writeImage("screenshot.png", TARGET_W, TARGET_H, result, "hello"));
}

union fi {
   float f;
   int32_t i;
   uint32_t ui;
};

static inline float
uif(uint32_t ui)
{
   union fi fi;
   fi.ui = ui;
   return fi.f;
}

static inline unsigned
fui( float f )
{
   union fi fi;
   fi.f = f;
   return fi.ui;
}

static void diff_feedback(const char *f1, const char *f2)
{
	void *d1;
	int s1 = read_data(f1, &d1);

	void *d2;
	int s2 = read_data(f2, &d2);

	assert(s1 == s2);

	const int per_vertex_size = 28;
	const int per_quads_size = per_vertex_size * 6;
	const int num_quads = s1 / per_quads_size;

	for (int i = 0; i < num_quads; i++) {
		void *q1 = d1 + per_quads_size * i;
		void *q2 = d2 + per_quads_size * i;

	        for (int j = 0; j < 6; j++) {
			uint32_t *v1 = q1 + per_vertex_size * j;
			uint32_t *v2 = q2 + per_vertex_size * j;

			if (memcmp(v1, v2, per_vertex_size)) {
				/*
				printf("diff: %d/%d "
				       "v1[%f %f %f %f %u %f %f] "
				       "v2[%f %f %f %f %u %f %f]\n",
				       i, j,
				       uif(v1[0]), uif(v1[1]), uif(v1[2]), uif(v1[3]),
				       v1[4], uif(v1[5]), uif(v1[6]),
				       uif(v2[0]), uif(v2[1]), uif(v2[2]), uif(v2[3]),
				       v2[4], uif(v2[5]), uif(v2[6]));
				*/
				/*
				printf("diff: %d/%d "
				       "[%e %e %e %e %d %e %e]\n",
				       i, j,
				       uif(v1[0]) - uif(v2[0]),
				       uif(v1[1]) - uif(v2[1]),
				       uif(v1[2]) - uif(v2[2]),
				       uif(v1[3]) - uif(v2[3]),
				       (int)(v1[4] - v2[4]),
				       uif(v1[5]) - uif(v2[5]),
				       uif(v1[6]) - uif(v2[6]));
				*/
				printf("diff: %d/%d v1=%e/%x v2=%e/%x v1-v2=%e\n",
				       i, j,
				       uif(v1[5]), v1[5],
				       uif(v2[5]), v2[5],
				       uif(v1[5]) - uif(v2[5]));
			}
		}
	}

	free(d1);
	free(d2);
}

static void init_feedback(void)
{
	GLint linked;
	GLuint vertexShader;
	GLuint fragmentShader;
	assert((vertexShader = LoadShader("vert-feed.glsl", GL_VERTEX_SHADER)) != 0);
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
	glEnable(GL_DEPTH_TEST);

	glUseProgram(program);
}

static void render_feedback(const char *name)
{
	init_feedback();

	glDepthRange(0, 1);

	glDisable(GL_BLEND);
	glDisable(GL_LINE_SMOOTH);
	
	glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
	glEnable(GL_POLYGON_OFFSET_FILL);
	glPolygonOffset(1, 3);

	glColor3f(0, 0, 0);
	glLineWidth(1);

	void *feed;
	int feed_size = read_data(name, &feed);
	const int num_vertex = feed_size / 28;
	printf("feed vertex %d\n", num_vertex);

	load_uniform_buffer("data_5.raw", 0, 2512);
        load_uniform_buffer("data_4.raw", 1, 256);

	GLuint data_buffer;
	glGenBuffers(1, &data_buffer);

	unsigned data_max_size = 0x100000;
	glBindBuffer(GL_ARRAY_BUFFER, data_buffer);
	glBufferStorage(GL_ARRAY_BUFFER, data_max_size, NULL, GL_MAP_WRITE_BIT | GL_MAP_PERSISTENT_BIT | GL_MAP_COHERENT_BIT);
	void *data_map = glMapBufferRange(GL_ARRAY_BUFFER, 0, data_max_size, GL_MAP_WRITE_BIT | GL_MAP_PERSISTENT_BIT | GL_MAP_COHERENT_BIT);
	assert(data_map);

	assert(glGetError() == GL_NO_ERROR);

	memset(data_map, 0, data_max_size);
	fill_buffer("data_1.raw", data_map, 0, data_max_size);
	fill_buffer("data_2.raw", data_map, 0xc4000, data_max_size);
	fill_buffer("data_3.raw", data_map, 0xdf000, data_max_size);

	glBindBuffer(GL_COPY_READ_BUFFER, data_buffer);

	GLuint per_pid_buffer = create_buffer(GL_UNIFORM_BUFFER, 916632, 512);

	//glMemoryBarrier(GL_VERTEX_ATTRIB_ARRAY_BARRIER_BIT | GL_COMMAND_BARRIER_BIT);

	GLuint tex1;
	glGenTextures(1, &tex1);
	glActiveTexture(GL_TEXTURE1);
	glBindTexture(GL_TEXTURE_2D, tex1);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, 8, 2, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
	GLubyte data1[] = {0, 0, 255, 255, 0, 203, 255, 150, 0, 255, 102, 150, 101, 255, 0, 150, 255, 204, 0, 150, 255, 0, 0, 255, 255, 0, 0, 255, 255, 0, 0, 255};
	glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, 8, 1, GL_RGBA, GL_UNSIGNED_BYTE, data1);
	GLubyte data2[] = {150, 150, 150, 255, 150, 150, 150, 255, 150, 150, 150, 255, 150, 150, 150, 255, 150, 150, 150, 255, 150, 150, 150, 255, 150, 150, 150, 255, 150, 150, 150, 255};
	glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 1, 8, 1, GL_RGBA, GL_UNSIGNED_BYTE, data2);

	assert(glGetError() == GL_NO_ERROR);

	glBindBuffer(GL_ARRAY_BUFFER, 0);

	glEnableVertexAttribArray(0);
	glVertexAttribPointer(0, 4, GL_FLOAT, 0, 28, feed);	

	glEnableVertexAttribArray(1);
	glVertexAttribPointer(1, 1, GL_UNSIGNED_INT, 0, 28, feed + 16);

	glEnableVertexAttribArray(2);
	glVertexAttribPointer(2, 2, GL_FLOAT, 0, 28, feed + 20);

	glBindBufferRange(GL_UNIFORM_BUFFER, 2, per_pid_buffer, 0, 256);

	glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);
	assert(glGetError() == GL_NO_ERROR);

	glDrawArrays(GL_TRIANGLES, 0, num_vertex);
	assert(glGetError() == GL_NO_ERROR);

	eglSwapBuffers(display, surface);
}

static void calc(unsigned *data, int i)
{
	float val = uif(data[i]);
	float x = uif(0x41df76b2);
	float y = uif(0x3e000000);
	float s = val * x + y;
	//*
	float up = uif(0x3c92a307);
	float down = 0;
	float accd = val < up ? 0 : 1;
	accd += val > down ? 0 : -1;
	s += accd;
	//*/
	printf("s[%d] = %e/%x\n", i, s, fui(s));
}

static void init_cs(void)
{
	GLuint shader;
	assert((shader = LoadShader("comp.glsl", GL_COMPUTE_SHADER)) != 0);

	GLuint program;
	assert((program = glCreateProgram()) != 0);
	glAttachShader(program, shader);

	GLint linked;
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

static void render_cs(void)
{
	init_cs();

	void *data;
	int size = read_data("data_2.raw", &data);
	data += 384;

	unsigned *d = data;
#define CS_SIZE 5
	unsigned input[] = {
		d[40], d[42], d[46], d[49], d[51],
		0x41df76b2, 0x3e000000, 0x3f000000, 0x3e000000,
		0x00000000, 0x3c92a307,
	};

	GLuint ssbo0;
	glGenBuffers(1, &ssbo0);
	glBindBuffer(GL_SHADER_STORAGE_BUFFER, ssbo0);
	glBufferData(GL_SHADER_STORAGE_BUFFER, sizeof(input), &input, GL_DYNAMIC_COPY);
	glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 0, ssbo0);

	GLuint ssbo1;
	glGenBuffers(1, &ssbo1);
	glBindBuffer(GL_SHADER_STORAGE_BUFFER, ssbo1);
	glBufferData(GL_SHADER_STORAGE_BUFFER, CS_SIZE * sizeof(float), NULL, GL_DYNAMIC_COPY);
	glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 1, ssbo1);

	assert(glGetError() == GL_NO_ERROR);

	glDispatchCompute(CS_SIZE, 1, 1);
	glMemoryBarrier(GL_SHADER_IMAGE_ACCESS_BARRIER_BIT);

	assert(glGetError() == GL_NO_ERROR);

	unsigned results[CS_SIZE];
	glGetBufferSubData(GL_SHADER_STORAGE_BUFFER, 0, sizeof(results), results);
	assert(glGetError() == GL_NO_ERROR);
	for (int i = 0; i < CS_SIZE; i++)
		printf("%x ", results[i]);
	printf("\n");
}

int main(int argc, char **argv)
{
	bool use_x11 = argc == 2 && !strcmp(argv[1], "x11");
	bool render_diff = argc == 4 && !strcmp(argv[1], "diff");
	bool use_feedback = argc == 3 && !strcmp(argv[1], "feed");
	bool do_calc = argc == 2 && !strcmp(argv[1], "calc");
	bool do_cs = argc == 2 && !strcmp(argv[1], "cs");

	if (render_diff) {
		diff_feedback(argv[2], argv[3]);
		return 0;
	}

	if (do_calc) {
		void *data;
		int size = read_data("data_2.raw", &data);
		data += 384;
		calc(data, 40);
		calc(data, 42);
		calc(data, 46);
		calc(data, 49);
		calc(data, 51);
		return 0;
	}

	if (use_x11)
		init_x11_render_target();
	else
		init_gbm_render_target();

	if (use_feedback)
		render_feedback(argv[2]);
	else if (do_cs) {
		render_cs();
		return 0;
	} else
		render();

	if (use_x11)
		sleep(5);
	else
		dump_screenshot();

	return 0;
}
