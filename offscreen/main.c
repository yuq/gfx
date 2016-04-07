#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

#include <fcntl.h>
#include <unistd.h>

#include <EGL/egl.h>
#include <gbm.h>
#include <png.h>

#ifdef _OGLES_20_
#include <GLES2/gl2.h>
#endif

#ifdef _OGLES_30_
#include <GLES3/gl3.h>
#endif

GLuint program;

#define TARGET_SIZE 256

void RenderTargetInit(void)
{
  int fd = open("/dev/dri/renderD128", O_RDWR);
  assert(fd >= 0);

  struct gbm_device *gbm = gbm_create_device(fd);
  assert(gbm != NULL);

  EGLDisplay display;
  assert((display = eglGetDisplay(gbm)) != EGL_NO_DISPLAY);

  EGLint majorVersion;
  EGLint minorVersion;
  assert(eglInitialize(display, &majorVersion, &minorVersion) == EGL_TRUE);

  EGLConfig config;
  EGLint numConfigs;
  const EGLint configAttribs[] = {
    EGL_SURFACE_TYPE, EGL_PBUFFER_BIT,
    EGL_RED_SIZE, 8,
    EGL_GREEN_SIZE, 8,
    EGL_BLUE_SIZE, 8,
    EGL_DEPTH_SIZE, 24,
    EGL_NONE
  };
  assert(eglChooseConfig(display, configAttribs, &config, 1, &numConfigs) == EGL_TRUE);

  EGLSurface surface;
  EGLint attribList[] = {
    EGL_WIDTH, 0,
    EGL_HEIGHT, 0,
    EGL_NONE
  };
  surface = eglCreatePbufferSurface(display, config, attribList);

  EGLContext context;
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

  //*
  GLuint fbid;
  glGenFramebuffers(1, &fbid);
  glBindFramebuffer(GL_FRAMEBUFFER, fbid);

  GLuint texid;
  glGenTextures(1, &texid);
  glBindTexture(GL_TEXTURE_2D, texid);
  glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
  #ifdef _OGLES_30_
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA32F, TARGET_SIZE, TARGET_SIZE, 0, GL_RGBA, GL_FLOAT, NULL);
  #endif
  #ifdef _OGLES_20_
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, TARGET_SIZE, TARGET_SIZE, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
  #endif
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
  glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, texid, 0);

  GLuint rbid;
  glGenRenderbuffers(1, &rbid);
  glBindRenderbuffer(GL_RENDERBUFFER, rbid);
  glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, TARGET_SIZE, TARGET_SIZE);
  glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, rbid);

  CheckFrameBufferStatus();
  //*/

  glClearColor(0, 0, 0, 0);
  glViewport(0, 0, TARGET_SIZE, TARGET_SIZE);
  glEnable(GL_DEPTH_TEST);

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
    1, -1, 0
  };
  GLuint index[] = {
    0, 1, 2
  };

  GLint position = glGetAttribLocation(program, "positionIn");
  glEnableVertexAttribArray(position);
  glVertexAttribPointer(position, 3, GL_FLOAT, 0, 0, vertex);

  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
  glDrawElements(GL_TRIANGLES, sizeof(index)/sizeof(GLuint), GL_UNSIGNED_INT, index);

  glFlush();

  #ifdef _OGLES_30_
  glReadBuffer(GL_COLOR_ATTACHMENT0);
  #endif

  GLubyte result[TARGET_SIZE * TARGET_SIZE * 4] = {0};
  glReadPixels(0, 0, TARGET_SIZE, TARGET_SIZE, GL_RGBA, GL_UNSIGNED_BYTE, result);
  assert(glGetError() == GL_NO_ERROR);
  /*
  int i, j;
  for (i = 0; i < TARGET_SIZE / 8; i++) {
    for (j = 0; j < TARGET_SIZE / 8; j++)
      printf("%08x ", result[i * TARGET_SIZE * 4 + j * 4]);
    printf("\n");
  }
  //*/
  assert(!writeImage("screenshot.png", TARGET_SIZE, TARGET_SIZE, result, "hello"));
}

int main(void)
{
  RenderTargetInit();
  InitGLES();
  Render();
  return 0;
}

