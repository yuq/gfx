#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <GLES2/gl2.h>

#define NUMRECT 512

static GLuint program;
static int windowWidth;
static int windowHeight;
static GLuint vertexVBO, indexVBO;

#ifndef GL_ALPHA_TEST
#define GL_ALPHA_TEST 0x0BC0
#endif

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

static void initGLES(void)
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
    glViewport(0, 0, windowWidth, windowHeight);

    glUseProgram(program);
}

void render_init(int width, int height)
{
	windowWidth = width;
	windowHeight = height;
	initGLES();
}

void set_uniform(const char *name, float *value)
{
	GLint uniform = glGetUniformLocation(program, name);
	glUniform4f(uniform, value[0], value[1], value[2], value[3]);
}

void render(void)
{
	float value[] = {0.01, 0.01, 0,01, 0.01};
	set_uniform("v0", value);
	set_uniform("u0", value);
	set_uniform("u1", value);
	set_uniform("u2", value);
	set_uniform("u3", value);
	set_uniform("u4", value);
	set_uniform("u5", value);
	set_uniform("u6", value);
	set_uniform("u7", value);
	set_uniform("u8", value);
	set_uniform("u9", value);
	/*
	set_uniform("u10", value);
	set_uniform("u11", value);
	set_uniform("u12", value);
	set_uniform("u13", value);
	set_uniform("u14", value);
	set_uniform("u15", value);
	set_uniform("u16", value);
	set_uniform("u17", value);
	set_uniform("u18", value);
	set_uniform("u19", value);
	*/
        GLfloat vertex[] = {
		-1, -1, 0,
		-1, 1, 0,
		1, 1, 0,
		1, -1, 0
	};

	GLint position = glGetAttribLocation(program, "positionIn");
	glEnableVertexAttribArray(position);
	glVertexAttribPointer(position, 3, GL_FLOAT, 0, 0, vertex);

	assert(glGetError() == GL_NO_ERROR);

	glClear(GL_COLOR_BUFFER_BIT);
	assert(glGetError() == GL_NO_ERROR);

	glDrawArrays(GL_TRIANGLES, 0, 3);
  
	assert(glGetError() == GL_NO_ERROR);
}


