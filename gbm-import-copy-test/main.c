#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

#include <fcntl.h>
#include <unistd.h>

#include <gbm.h>
#include <png.h>

#include <epoxy/gl.h>
#include <epoxy/egl.h>

struct context {
  EGLDisplay display;
  EGLContext context;
  struct gbm_device *gbm;
  const char *dev;
  struct gbm_bo *bo;
};

#define TARGET_SIZE 256

void GBMInit(struct context *ctx)
{
  int fd = open(ctx->dev, O_RDWR);
  assert(fd >= 0);

  ctx->gbm = gbm_create_device(fd);
  assert(ctx->gbm != NULL);
}

void EGLInit(struct context *ctx)
{
  assert((ctx->display = eglGetDisplay(ctx->gbm)) != EGL_NO_DISPLAY);

  EGLint majorVersion;
  EGLint minorVersion;
  assert(eglInitialize(ctx->display, &majorVersion, &minorVersion) == EGL_TRUE);

  assert(eglBindAPI(EGL_OPENGL_ES_API) == EGL_TRUE);

  const EGLint contextAttribs[] = {
    EGL_CONTEXT_CLIENT_VERSION, 2,
    EGL_NONE
  };
  assert((ctx->context = eglCreateContext(ctx->display, NULL, EGL_NO_CONTEXT, contextAttribs)) != EGL_NO_CONTEXT);

  assert(eglMakeCurrent(ctx->display, EGL_NO_SURFACE, EGL_NO_SURFACE, ctx->context) == EGL_TRUE);
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

void ExportBO(struct context *export, struct context *import)
{
  export->bo = gbm_bo_create(export->gbm, TARGET_SIZE, TARGET_SIZE, 
			     GBM_FORMAT_ARGB8888, 
			     //GBM_BO_USE_LINEAR |
			     GBM_BO_USE_RENDERING |
			     GBM_BO_USE_SCANOUT);
  int fd = gbm_bo_get_fd(export->bo);
  struct gbm_import_fd_data data;
  data.fd = fd;
  data.width = gbm_bo_get_width(export->bo);
  data.height = gbm_bo_get_height(export->bo);
  data.stride = gbm_bo_get_stride(export->bo);
  import->bo = gbm_bo_import(import->gbm, GBM_BO_IMPORT_FD, &data, 0);
}

GLuint CreateFBO(struct context *ctx, struct gbm_bo *bo)
{
  EGLImageKHR image = eglCreateImageKHR(ctx->display, ctx->context,
					EGL_NATIVE_PIXMAP_KHR, bo, NULL);
  assert(image != EGL_NO_IMAGE_KHR);
  
  GLuint texid;
  glGenTextures(1, &texid);
  glBindTexture(GL_TEXTURE_2D, texid);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
  glEGLImageTargetTexture2DOES(GL_TEXTURE_2D, image);
  
  GLuint fbid;
  glGenFramebuffers(1, &fbid);
  glBindFramebuffer(GL_FRAMEBUFFER, fbid);
  glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, texid, 0);
  /*
    GLuint rbid;
    glGenRenderbuffers(1, &rbid);
    glBindRenderbuffer(GL_RENDERBUFFER, rbid);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, TARGET_SIZE, TARGET_SIZE);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, rbid);
  //*/
  CheckFrameBufferStatus();

  return texid;
}

GLuint InitFBO(struct context *ctx, int linear)
{
  struct gbm_bo *bo = gbm_bo_create(ctx->gbm, TARGET_SIZE, TARGET_SIZE, 
				    GBM_FORMAT_ARGB8888, 
				    (linear ? GBM_BO_USE_LINEAR : 0) | 
				    GBM_BO_USE_SCANOUT);
  return CreateFBO(ctx, bo);
}

void InitSharedFBO(struct context *ctx)
{
  CreateFBO(ctx, ctx->bo);
}

GLuint InitGLES(const char *vert, const char *frag)
{
  GLuint program;
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

  glClearColor(0, 0, 0, 0);
  glViewport(0, 0, TARGET_SIZE, TARGET_SIZE);
  //glEnable(GL_DEPTH_TEST);

  glUseProgram(program);
  return program;
}


int writeImage(const char* filename, int width, int height, void *buffer, char* title)
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

void Render(GLuint program)
{
  GLfloat vertex[] = {
    -1, -1, 0,
    -1, 1, 0,
    1, 1, 0,
    1, -1, 0
  };
  GLuint index[] = {
    0, 1, 2
  };

  GLint position = glGetAttribLocation(program, "positionIn");
  glEnableVertexAttribArray(position);
  glVertexAttribPointer(position, 3, GL_FLOAT, 0, 0, vertex);

  glClear(GL_COLOR_BUFFER_BIT 
	  //| GL_DEPTH_BUFFER_BIT
	  );

  glDrawElements(GL_TRIANGLES, sizeof(index)/sizeof(GLuint), GL_UNSIGNED_INT, index);

  glFlush();
  //eglSwapBuffers(ctx->display, 0);
}

void CopyTexure(GLuint program, GLuint tid)
{
  GLfloat vertex[] = {
    -1, -1, 0,
    -1, 1, 0,
    1, 1, 0,
    1, -1, 0
  };
  GLfloat tex[] = {
    0, 0,
    0, 1,
    1, 1,
    1, 0
  };
  GLuint index[] = {
    0, 1, 2,
    0, 3, 2
  };

  GLint position = glGetAttribLocation(program, "positionIn");
  glEnableVertexAttribArray(position);
  glVertexAttribPointer(position, 3, GL_FLOAT, 0, 0, vertex);

  GLint texcord = glGetAttribLocation(program, "texcoordIn");
  glEnableVertexAttribArray(texcord);
  glVertexAttribPointer(texcord, 2, GL_FLOAT, 0, 0, tex);

  GLint texmap = glGetUniformLocation(program, "texture_map");
  glUniform1i(texmap, 0);
  glActiveTexture(GL_TEXTURE0);
  glBindTexture(GL_TEXTURE_2D, tid);

  glClear(GL_COLOR_BUFFER_BIT 
	  //| GL_DEPTH_BUFFER_BIT
	  );

  glDrawElements(GL_TRIANGLES, sizeof(index)/sizeof(GLuint), GL_UNSIGNED_INT, index);

  glFlush();
  //eglSwapBuffers(ctx->display, 0); 
}

void SaveFBO(const char *save)
{
  GLubyte result[TARGET_SIZE * TARGET_SIZE * 4] = {0};
  glReadPixels(0, 0, TARGET_SIZE, TARGET_SIZE, GL_RGBA, GL_UNSIGNED_BYTE, result);
  assert(glGetError() == GL_NO_ERROR);

  assert(!writeImage(save, TARGET_SIZE, TARGET_SIZE, result, "hello"));
}

int main(void)
{
  struct context master, slave;

  master.dev = "/dev/dri/renderD128";
  slave.dev = "/dev/dri/renderD129";

  GBMInit(&master);
  GBMInit(&slave);
  
  ExportBO(&master, &slave);

  EGLInit(&slave);
  
  GLuint tid = InitFBO(&slave, 0);
  Render(InitGLES("vert.glsl", "frag.glsl"));
  SaveFBO("render.png");

  InitSharedFBO(&slave);
  CopyTexure(InitGLES("copy_vert.glsl", "copy_frag.glsl"), tid);
  SaveFBO("copy_to_shared.png");

  EGLInit(&master);
  InitSharedFBO(&master);
  SaveFBO("show.png");
  
  return 0;
}


