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

#define TARGET_WIDTH 1920
#define TARGET_HEIGHT 1080

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

	assert(eglBindAPI(EGL_OPENGL_API) == EGL_TRUE);

	EGLConfig config = get_config();

	gs = gbm_surface_create(
		gbm, TARGET_WIDTH, TARGET_HEIGHT, GBM_BO_FORMAT_ARGB8888,
		GBM_BO_USE_LINEAR|GBM_BO_USE_SCANOUT|GBM_BO_USE_RENDERING);
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
	GLuint tcsShader;
	GLuint tesShader;
	assert((vertexShader = LoadShader("vert.glsl", GL_VERTEX_SHADER)) != 0);
	assert((tcsShader = LoadShader("tcs.glsl", GL_TESS_CONTROL_SHADER)) != 0);
	assert((tesShader = LoadShader("tes.glsl", GL_TESS_EVALUATION_SHADER)) != 0);
	assert((fragmentShader = LoadShader("frag.glsl", GL_FRAGMENT_SHADER)) != 0);
	assert((program = glCreateProgram()) != 0);
	glAttachShader(program, vertexShader);
	glAttachShader(program, tcsShader);
	glAttachShader(program, tesShader);
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

	glClearColor(0, 0, 0, 1);
	glViewport(0, 0, TARGET_WIDTH, TARGET_HEIGHT);
	glEnable(GL_DEPTH_TEST);
	glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);

	glUseProgram(program);
}

void *readImage(char *filename, int *width, int *height)
{
	char header[8];    // 8 is the maximum size that can be checked

        /* open file and test for it being a png */
        FILE *fp = fopen(filename, "rb");
	assert(fp);
        fread(header, 1, 8, fp);
        assert(!png_sig_cmp(header, 0, 8));

        /* initialize stuff */
        png_structp png_ptr = png_create_read_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
	assert(png_ptr);

        png_infop info_ptr = png_create_info_struct(png_ptr);
	assert(info_ptr);

        assert(!setjmp(png_jmpbuf(png_ptr)));

        png_init_io(png_ptr, fp);
        png_set_sig_bytes(png_ptr, 8);

        png_read_info(png_ptr, info_ptr);

        *width = png_get_image_width(png_ptr, info_ptr);
        *height = png_get_image_height(png_ptr, info_ptr);
        int color_type = png_get_color_type(png_ptr, info_ptr);
	assert(color_type == PNG_COLOR_TYPE_RGB);
        int bit_depth = png_get_bit_depth(png_ptr, info_ptr);
	assert(bit_depth == 8);
	int pitch = png_get_rowbytes(png_ptr, info_ptr);

        int number_of_passes = png_set_interlace_handling(png_ptr);
        png_read_update_info(png_ptr, info_ptr);

        /* read file */
        assert(!setjmp(png_jmpbuf(png_ptr)));

	png_bytep buffer = malloc(*height * pitch);
	void *ret = buffer;
	assert(buffer);
        png_bytep *row_pointers = malloc(sizeof(png_bytep) * *height);
	assert(row_pointers);
        for (int i = 0; i < *height; i++) {
                row_pointers[i] = buffer;
		buffer += pitch;
	}

        png_read_image(png_ptr, row_pointers);

        fclose(fp);
	free(row_pointers);
	return ret;
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

static GLuint create_texture(int slot, int format, int size)
{
	char name[32];
	snprintf(name, 32, "s_texture_%d", slot);
	GLuint loc = glGetUniformLocation(program, name);
	glUniform1i(loc, slot);

	GLuint tex;
	glGenTextures(1, &tex);
	glActiveTexture(GL_TEXTURE0 + slot);
	glBindTexture(GL_TEXTURE_2D, tex);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
	glTexParameterfv(GL_TEXTURE_2D, GL_TEXTURE_BORDER_COLOR, (GLfloat []){0, 0, 0, 0});
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_NEAREST);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAX_ANISOTROPY_EXT, 1);

	glPixelStorei(GL_UNPACK_ALIGNMENT, 1);

	for (int i = 0; size > 0; i++, size >>= 1) {
		snprintf(name, 32, "texture-%d-%d.data", slot, i);

		void *data;
		int data_size = read_data(name, &data);
		assert(data_size && data);

		glCompressedTexImage2D(GL_TEXTURE_2D, i, format, size, size, 0,
				       data_size, data);

		free(data);
	}

	glPixelStorei(GL_UNPACK_ALIGNMENT, 4);
	return tex;
}

void Render(void)
{
	GLint MaxPatchVertices = 0;
	glGetIntegerv(GL_MAX_PATCH_VERTICES, &MaxPatchVertices);
	printf("Max supported patch vertices %d\n", MaxPatchVertices);
	glPatchParameteri(GL_PATCH_VERTICES, 3);

        GLuint vert_buf = create_buffer(GL_ARRAY_BUFFER, "vertex.data");
	GLuint index_buf = create_buffer(GL_ELEMENT_ARRAY_BUFFER, "index.data");

	GLuint vao;
	glGenVertexArrays(1, &vao);
	glBindVertexArray(vao);
	glBindBuffer(GL_ARRAY_BUFFER, vert_buf);
	glVertexAttribPointer(3, 4, GL_HALF_FLOAT, GL_FALSE, 32, (void *)0x18);
	glVertexAttribPointer(2, 4, GL_HALF_FLOAT, GL_FALSE, 32, (void *)0x10);
	glVertexAttribPointer(1, 4, GL_HALF_FLOAT, GL_FALSE, 32, (void *)0x8);
	glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 32, (void *)0);
	glEnableVertexAttribArray(0);
	glEnableVertexAttribArray(1);
	glEnableVertexAttribArray(2);
	glEnableVertexAttribArray(3);
	glBindVertexArray(0);

	assert(glGetError() == GL_NO_ERROR);

	GLuint s_polygon_front = glGetUniformLocation(program, "s_polygon_front");
	glUniform1fv(s_polygon_front, 1, (GLfloat []){1});

	GLuint base_transform = glGetUniformLocation(program, "base_transform");
	glUniform4fv(base_transform, 1, (GLfloat []){1, 1, 0, 0});

	GLuint s_depth_range = glGetUniformLocation(program, "s_depth_range");
	glUniform4fv(s_depth_range, 1, (GLfloat []){0.3, 8002.15, 3.33333, 0.000124966});

	GLuint diffuse_color = glGetUniformLocation(program, "diffuse_color");
	glUniform4fv(diffuse_color, 1, (GLfloat []){1, 1, 1, 1});

	GLuint specular_power = glGetUniformLocation(program, "specular_power");
	glUniform1fv(specular_power, 1, (GLfloat []){8});

	GLuint s_projection = glGetUniformLocation(program, "s_projection");
	glUniformMatrix4fv(s_projection, 1, GL_FALSE, (GLfloat [])
			   {0.974279, 0, 0, 0,
			    0, 1.73205, 0, 0,
			    0, 0, -1.00007, -1,
			    0, 0, -0.600022, 0});

	GLuint s_camera_position = glGetUniformLocation(program, "s_camera_position");
	glUniform3fv(s_camera_position, 1, (GLfloat []){-9.53674e-07, -1.20397e-06, 9.53674e-07});

	GLuint detail_transform = glGetUniformLocation(program, "detail_transform");
	glUniform4fv(detail_transform, 1, (GLfloat []){0.25, 0.25, 0, 0});

	GLuint s_material_detail = glGetUniformLocation(program, "s_material_detail");
	glUniform3fv(s_material_detail, 1, (GLfloat []){0.3, 0, 0.2});

	GLuint s_material_tessellation_factor =
		glGetUniformLocation(program, "s_material_tessellation_factor");
	glUniform4fv(s_material_tessellation_factor, 1, (GLfloat []){0.45, 1, 15, 2});

	GLuint s_material_tessellation_distance =
		glGetUniformLocation(program, "s_material_tessellation_distance");
	glUniform3fv(s_material_tessellation_distance, 1, (GLfloat []){4.5, 0.0190476, 2.22222});

	GLuint s_instances = glGetUniformLocation(program, "s_instances");
	glUniform4fv(s_instances, 3, (GLfloat [])
		     {0.543567, 0.839366, 1.61582e-07, 12.867,
		      -1.91086e-05, 1.21616e-05, 1, -24.2076,
		      0.839366, -0.543567, 2.26191e-05, -14.3869});

	GLuint tex20 = create_texture(20, GL_COMPRESSED_RED_RGTC1, 512);
	GLuint tex16 = create_texture(16, GL_COMPRESSED_RED_RGTC1, 16);
	GLuint tex0 = create_texture(0, GL_COMPRESSED_RGBA_S3TC_DXT1_EXT, 2048);
	GLuint tex1 = create_texture(1, GL_COMPRESSED_SIGNED_RG_RGTC2, 512);
	GLuint tex2 = create_texture(2, GL_COMPRESSED_RGBA_S3TC_DXT1_EXT, 1024);
	GLuint tex3 = create_texture(3, GL_COMPRESSED_RGBA_S3TC_DXT1_EXT, 512);
	GLuint tex4 = create_texture(4, GL_COMPRESSED_SIGNED_RG_RGTC2, 16);

	glActiveTexture(GL_TEXTURE5);
	glBindTexture(GL_TEXTURE_2D, tex3);
	GLuint s_texture_5 = glGetUniformLocation(program, "s_texture_5");
	glUniform1i(s_texture_5, 5);

	glBindVertexArray(vao);
	glBindBuffer(GL_ARRAY_BUFFER, vert_buf);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, index_buf);

	glDrawElementsInstanced(GL_PATCHES, 2016, GL_UNSIGNED_SHORT, (void *)0x4c6bc, 1);

	assert(glGetError() == GL_NO_ERROR);

	eglSwapBuffers(display, surface);

	GLubyte *result = calloc(1, TARGET_WIDTH * TARGET_HEIGHT * 4);
	glReadPixels(0, 0, TARGET_WIDTH, TARGET_HEIGHT, GL_RGBA, GL_UNSIGNED_BYTE, result);
	assert(glGetError() == GL_NO_ERROR);

	assert(!writeImage("screenshot.png", TARGET_WIDTH, TARGET_HEIGHT, result, "hello"));
}

int main(void)
{
	RenderTargetInit();
	InitGLES();
	Render();
	return 0;
}
