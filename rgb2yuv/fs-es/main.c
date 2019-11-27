#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

#include <fcntl.h>
#include <unistd.h>

#include <gbm.h>
#include <png.h>

#include <epoxy/gl.h>
#include <epoxy/egl.h>

EGLDisplay display;
EGLContext context;
struct gbm_device *gbm;
GLuint program_y;
GLuint program_uv;

void *readImage(const char *filename, int *width, int *height)
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
	assert(color_type == PNG_COLOR_TYPE_RGB_ALPHA);
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

int writeImage(char* filename, int width, int height, int stride, void *buffer, char* title)
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
		     8, PNG_COLOR_TYPE_GRAY, PNG_INTERLACE_NONE,
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
		png_write_row(png_ptr, (png_bytep)buffer + i * stride);

	// End write
	png_write_end(png_ptr, NULL);

finalise:
	if (fp != NULL) fclose(fp);
	if (info_ptr != NULL) png_free_data(png_ptr, info_ptr, PNG_FREE_ALL, -1);
	if (png_ptr != NULL) png_destroy_write_struct(&png_ptr, (png_infopp)NULL);

	return code;
}

void init_context(void)
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

	assert(eglBindAPI(EGL_OPENGL_ES_API) == EGL_TRUE);

	const EGLint contextAttribs[] = {
		EGL_CONTEXT_MAJOR_VERSION, 3,
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

GLuint link_program(GLuint vs, GLuint fs)
{
	GLuint program;
	assert((program = glCreateProgram()) != 0);
	glAttachShader(program, vs);
	glAttachShader(program, fs);

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

	return program;
}

void init_gles(void)
{
	GLuint vs, fs1, fs2;
	assert((vs = LoadShader("vs.glsl", GL_VERTEX_SHADER)) != 0);
	assert((fs1 = LoadShader("fs-y.glsl", GL_FRAGMENT_SHADER)) != 0);
	assert((fs2 = LoadShader("fs-uv.glsl", GL_FRAGMENT_SHADER)) != 0);

	program_y = link_program(vs, fs1);
	program_uv = link_program(vs, fs2);
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

void rgb2yuv(const char *name)
{
	int w = 0, h = 0;
	void *data = readImage(name, &w, &h);
	assert(!(w & 3) && !(h & 1));
	printf("read image %s width=%d height=%d\n", name, w, h);

	glActiveTexture(GL_TEXTURE0);

	GLuint in_tex = 0;
        glGenTextures(1, &in_tex);
	glBindTexture(GL_TEXTURE_2D, in_tex);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, w, h, 0, GL_RGBA, GL_UNSIGNED_BYTE, data);
	assert(glGetError() == GL_NO_ERROR);
	free(data);

	GLuint out_tex = 0;
        glGenTextures(1, &out_tex);
	glBindTexture(GL_TEXTURE_2D, out_tex);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, w / 4, h * 3 / 2, 0, GL_RGBA,
		     GL_UNSIGNED_BYTE, NULL);
	assert(glGetError() == GL_NO_ERROR);

	GLuint fbo;
	glGenFramebuffers(1, &fbo); 
	glBindFramebuffer(GL_FRAMEBUFFER, fbo);
	glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, out_tex, 0);

	CheckFrameBufferStatus();

	GLfloat vertex[] = {
		-1, 1, 0,
		-1, -1, 0,
		1, -1, 0,
		1, 1, 0,
	};

	GLfloat texcoord[] = {
		0, 1,
		0, 0,
		1, 0,
		1, 1,
	};

	GLushort index[] = {
		0, 1, 3,
		1, 2, 3,
	};

	GLuint VBO[3];
	glGenBuffers(3, VBO);

	glBindBuffer(GL_ARRAY_BUFFER, VBO[0]);
	glBufferData(GL_ARRAY_BUFFER, 4 * sizeof(GLfloat) * 3, vertex, GL_STATIC_DRAW);
	GLint pos_y = glGetAttribLocation(program_y, "positionIn");
	glEnableVertexAttribArray(pos_y);
	glVertexAttribPointer(pos_y, 3, GL_FLOAT, 0, 0, 0);
	GLint pos_uv = glGetAttribLocation(program_uv, "positionIn");
	glEnableVertexAttribArray(pos_uv);
	glVertexAttribPointer(pos_uv, 3, GL_FLOAT, 0, 0, 0);

	glBindBuffer(GL_ARRAY_BUFFER, VBO[1]);
	glBufferData(GL_ARRAY_BUFFER, 4 * sizeof(GLfloat) * 2, texcoord, GL_STATIC_DRAW);
	GLint tex_y = glGetAttribLocation(program_y, "texcoordIn");
	glEnableVertexAttribArray(tex_y);
	glVertexAttribPointer(tex_y, 2, GL_FLOAT, 0, 0, 0);
	GLint tex_uv = glGetAttribLocation(program_uv, "texcoordIn");
	glEnableVertexAttribArray(tex_uv);
	glVertexAttribPointer(tex_uv, 2, GL_FLOAT, 0, 0, 0);

	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, VBO[2]);
	glBufferData(GL_ELEMENT_ARRAY_BUFFER, 6 * sizeof(GLushort), index, GL_STATIC_DRAW);

	assert(glGetError() == GL_NO_ERROR);

	glBindTexture(GL_TEXTURE_2D, in_tex);

	glUseProgram(program_y);

	GLint tex_map_y = glGetUniformLocation(program_y, "texMap");
	glUniform1i(tex_map_y, 0); // GL_TEXTURE0

	assert(glGetError() == GL_NO_ERROR);

	glViewport(0, 0, w / 4, h);
	glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_SHORT, 0);

	glUseProgram(program_uv);

	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

	GLint tex_map_uv = glGetUniformLocation(program_uv, "texMap");
	glUniform1i(tex_map_uv, 0); // GL_TEXTURE0

	assert(glGetError() == GL_NO_ERROR);

	glViewport(0, h, w / 4, h / 2);
	glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_SHORT, 0);

	data = malloc(w * h * 3 / 2);
	assert(data);

	glReadPixels(0, 0, w / 4, h * 3 / 2, GL_RGBA, GL_UNSIGNED_BYTE, data);
	assert(glGetError() == GL_NO_ERROR);

	assert(!writeImage("y.png", w, h, w, data, "hello"));
	assert(!writeImage("uv.png", w, h / 2, w, data + h * w, "hello"));

	free(data);
}

static void usage(const char *name)
{
	printf("usage: %s [xxx.png]\n", name);
}

int main(int argc, char **argv)
{
	if (argc > 2) {
		usage(argv[0]);
		return 0;
	}

	init_context();
	init_gles();
        rgb2yuv(argc == 2 ? argv[1] : "test.png");
	return 0;
}
