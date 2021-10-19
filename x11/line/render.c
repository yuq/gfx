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

    glClearColor(0.15f, 0.15f, 0.15f, 0.15f);
    glViewport(50, 50, 100, 100);
    //glEnable(GL_DEPTH_TEST);
    //glDisable(GL_DEPTH_TEST);
    //glEnable(GL_ALPHA_TEST);
    //glAlphaFunc(GL_LESS, 0.5);

    glUseProgram(program);
}

void render_init(int width, int height)
{
	windowWidth = width;
	windowHeight = height;
	initGLES();
}

#define BIG_INDEX 100

void render(void)
{
	/*
	GLfloat vertex[] = {
		0, 0, 0,
		0.5, 0, 0,
		0.5, 0.5, 0,
		0, 0.5, 0
	};
	*/
	GLfloat vertex[3 * 1024] = {
		[3 * 10] = -1, [3 * 10 + 1] = -1,
		[3 * BIG_INDEX] = -1, [3 * BIG_INDEX + 1] = 1,
		[3 * 1] = 1, [3 * 1 + 1] = 1,
		[3 * 15] = 1, [3 * 15 + 1] = -1,
	};

	GLushort index[] = {
		10, BIG_INDEX,2,2,15,10,50,51,52
	};
	
	GLint position = glGetAttribLocation(program, "positionIn");
	glEnableVertexAttribArray(position);
	glVertexAttribPointer(position, 3, GL_FLOAT, 0, 0, vertex);

	assert(glGetError() == GL_NO_ERROR);

	glClear(GL_COLOR_BUFFER_BIT);
	assert(glGetError() == GL_NO_ERROR);

	//glEnable(GL_SCISSOR_TEST);
	//glScissor(-100, -100, 256, 256);
	
	//glLineWidth(5);
	//glDrawArrays(GL_LINE_STRIP, 0, 4);
	//glDrawArrays(GL_POINTS, 0, 4);
	glDrawElements(GL_TRIANGLES, sizeof(index)/sizeof(GLushort), GL_UNSIGNED_SHORT, index);
  
	assert(glGetError() == GL_NO_ERROR);
}


