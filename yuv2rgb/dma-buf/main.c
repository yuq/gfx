#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <string.h>

#include <fcntl.h>
#include <unistd.h>

#include <drm/drm_fourcc.h>

#include <gbm.h>
#include <png.h>

#include <epoxy/gl.h>
#include <epoxy/egl.h>

EGLDisplay display;
EGLContext context;
struct gbm_device *gbm;
GLuint program;

#define OFFSET_ALIGNMENT 256
#define PITCH_ALIGNMENT 256
#define ALIGN(x, a) (((x) + (a) - 1) & ~((a) - 1))

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
	assert(color_type == PNG_COLOR_TYPE_GRAY);
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
		EGL_CONTEXT_MAJOR_VERSION, 2,
		EGL_CONTEXT_MINOR_VERSION, 0,
		EGL_NONE
	};
	assert((context = eglCreateContext(display, NULL, EGL_NO_CONTEXT, contextAttribs)) != EGL_NO_CONTEXT);

	assert(eglMakeCurrent(display, EGL_NO_SURFACE, EGL_NO_SURFACE, context) == EGL_TRUE);

	assert(epoxy_has_egl_extension(display, "EGL_EXT_image_dma_buf_import"));
	assert(epoxy_has_gl_extension("GL_OES_EGL_image"));
	assert(epoxy_has_gl_extension("GL_OES_EGL_image_external"));
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
	GLuint vs, fs;
	assert((vs = LoadShader("vs.glsl", GL_VERTEX_SHADER)) != 0);
	assert((fs = LoadShader("fs.glsl", GL_FRAGMENT_SHADER)) != 0);

	program = link_program(vs, fs);
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

void copy_image(void *dst, void *src, int w, int h, int stride)
{
	for (int i = 0; i < h; i++) {
		memcpy(dst, src, w);
		dst += stride;
		src += w;
	}
}

void yuv2rgb(const char *ypng, const char *upng, const char *vpng)
{
        int yw = 0, yh = 0;
	void *y = readImage(ypng, &yw, &yh);
	printf("read image %s width=%d height=%d\n", ypng, yw, yh);
	assert(y);
	assert(!(yw & 1) && !(yh & 1));

	int uw = 0, uh = 0;
	void *u = readImage(upng, &uw, &uh);
	printf("read image %s width=%d height=%d\n", upng, uw, uh);
	assert(u);
	assert(yw == uw * 2 && yh == uh * 2);

	int vw = 0, vh = 0;
	void *v = readImage(vpng, &vw, &vh);
	printf("read image %s width=%d height=%d\n", vpng, vw, vh);
	assert(v);
	assert(uw == vw && uh == vh);

	/* HAL_PIXEL_FORMAT_YV12 need cstride = align(ystride / 2, 16)
	 * amd gpu need both offset and pitch aligned to 256
	 * lima gpu need offset align to 64
	 */
	int cstride = ALIGN(yw / 2, PITCH_ALIGNMENT);
	int ystride = cstride * 2;
	int uoff = ALIGN(ystride * yh, OFFSET_ALIGNMENT);
	int voff = ALIGN(uoff + cstride * uh, OFFSET_ALIGNMENT);
	int bw = ystride, bh = (voff + cstride * vh + ystride - 1) / ystride;

	struct gbm_bo *bo =
		gbm_bo_create(gbm, bw, bh, GBM_FORMAT_R8,
			      GBM_BO_USE_LINEAR | GBM_BO_USE_RENDERING);
	assert(bo);

	uint32_t stride = 0;
	void *map_data = NULL;
	void *cpu = gbm_bo_map(bo, 0, 0, bw, bh, GBM_BO_TRANSFER_WRITE, &stride, &map_data);
	assert(cpu);
	assert(stride == ystride);

	copy_image(cpu, y, yw, yh, ystride);
	copy_image(cpu + uoff, u, uw, uh, cstride);
	copy_image(cpu + voff, v, vw, vh, cstride);

	gbm_bo_unmap(bo, map_data);

	int prime_fd = gbm_bo_get_fd(bo);
	assert(prime_fd >= 0);

	EGLint attrib_list[] = {
		EGL_WIDTH, yw,
		EGL_HEIGHT, yh,
		EGL_LINUX_DRM_FOURCC_EXT, DRM_FORMAT_YUV420,
		EGL_DMA_BUF_PLANE0_FD_EXT, prime_fd,
		EGL_DMA_BUF_PLANE0_OFFSET_EXT, 0,
		EGL_DMA_BUF_PLANE0_PITCH_EXT, ystride,
		EGL_DMA_BUF_PLANE1_FD_EXT, prime_fd,
		EGL_DMA_BUF_PLANE1_OFFSET_EXT, uoff,
		EGL_DMA_BUF_PLANE1_PITCH_EXT, cstride,
		EGL_DMA_BUF_PLANE2_FD_EXT, prime_fd,
		EGL_DMA_BUF_PLANE2_OFFSET_EXT, voff,
		EGL_DMA_BUF_PLANE2_PITCH_EXT, cstride,
		EGL_YUV_COLOR_SPACE_HINT_EXT, EGL_ITU_REC601_EXT,
		EGL_YUV_CHROMA_HORIZONTAL_SITING_HINT_EXT, EGL_YUV_CHROMA_SITING_0_5_EXT,
		EGL_YUV_CHROMA_VERTICAL_SITING_HINT_EXT, EGL_YUV_CHROMA_SITING_0_5_EXT,
		EGL_SAMPLE_RANGE_HINT_EXT, EGL_YUV_FULL_RANGE_EXT,
		EGL_NONE
	};
	EGLImageKHR image = eglCreateImageKHR(
		display, EGL_NO_CONTEXT, EGL_LINUX_DMA_BUF_EXT,
		NULL, attrib_list);
	assert(image != EGL_NO_IMAGE_KHR);
	assert(eglGetError() == EGL_SUCCESS);

	glActiveTexture(GL_TEXTURE0);

	GLuint in_tex = 0;
        glGenTextures(1, &in_tex);
	glBindTexture(GL_TEXTURE_EXTERNAL_OES, in_tex);
	glTexParameteri(GL_TEXTURE_EXTERNAL_OES, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_EXTERNAL_OES, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_EXTERNAL_OES, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
	glTexParameteri(GL_TEXTURE_EXTERNAL_OES, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
	glEGLImageTargetTexture2DOES(GL_TEXTURE_EXTERNAL_OES, image);
	assert(glGetError() == GL_NO_ERROR);

	GLint tex_sampler = glGetUniformLocation(program, "tex");
	glUniform1i(tex_sampler, 0);

	glActiveTexture(GL_TEXTURE1);

	GLuint out_tex = 0;
        glGenTextures(1, &out_tex);
	glBindTexture(GL_TEXTURE_2D, out_tex);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, yw, yh, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
	assert(glGetError() == GL_NO_ERROR);

	GLuint fbo;
	glGenFramebuffers(1, &fbo); 
	glBindFramebuffer(GL_FRAMEBUFFER, fbo);
	glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, out_tex, 0);

	CheckFrameBufferStatus();

        GLfloat vertex_attr[] = {
		-1,  1, 0, 0, 1,
		-1, -1, 0, 0, 0,
		 1, -1, 0, 1, 0,
		 1,  1, 0, 1, 1,
	};

	GLushort index[] = {
		0, 1, 3,
		1, 2, 3,
	};

	GLuint VBO[2];
	glGenBuffers(2, VBO);

	glBindBuffer(GL_ARRAY_BUFFER, VBO[0]);
	glBufferData(GL_ARRAY_BUFFER, 4 * sizeof(GLfloat) * 5, vertex_attr, GL_STATIC_DRAW);
	GLint pos = glGetAttribLocation(program, "positionIn");
	glEnableVertexAttribArray(pos);
	glVertexAttribPointer(pos, 3, GL_FLOAT, 0, 20, 0);
	GLint tex = glGetAttribLocation(program, "texcoordIn");
	glEnableVertexAttribArray(tex);
	glVertexAttribPointer(tex, 2, GL_FLOAT, 0, 20, (void *)12);

	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, VBO[1]);
	glBufferData(GL_ELEMENT_ARRAY_BUFFER, 6 * sizeof(GLushort), index, GL_STATIC_DRAW);

	assert(glGetError() == GL_NO_ERROR);

	glViewport(0, 0, yw, yh);
	glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_SHORT, 0);

	assert(glGetError() == GL_NO_ERROR);

	void *data = malloc(yw * yh * 4);
	assert(data);

	glReadPixels(0, 0, yw, yh, GL_RGBA, GL_UNSIGNED_BYTE, data);
	assert(glGetError() == GL_NO_ERROR);

	assert(!writeImage("rgb.png", yw, yh, yw * 4, data, "hello"));

	free(data);
}

static void usage(const char *name)
{
        printf("usage: %s [y.png u.png v.png]\n", name);
}

int main(int argc, char **argv)
{
        if (argc != 1 && argc != 4) {
		usage(argv[0]);
		return 0;
	}

	init_context();
	init_gles();

	if (argc == 4)
		yuv2rgb(argv[1], argv[2], argv[3]);
	else
		yuv2rgb("y.png", "u.png", "v.png");

	return 0;
}
