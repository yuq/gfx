#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <math.h>
#include <GLES2/gl2.h>

static GLuint program;
static int windowWidth;
static int windowHeight;

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
    glViewport(0, 0, windowWidth, windowHeight);

    glUseProgram(program);
}

void render_init(int width, int height)
{
	windowWidth = width;
	windowHeight = height;
	initGLES();
}

#define VERTEX_NUM 100
#define WAVE_RANGE 0.1
#define NUM_LINE 10

void render(uint64_t idx)
{        
	GLfloat vertex[VERTEX_NUM * 3 * 3];
	for (int i = 0; i < VERTEX_NUM; i++) {
		vertex[i * 6 + 0] = i * 2.0 / VERTEX_NUM - 1;
		vertex[i * 6 + 1] = WAVE_RANGE * sin((i + idx) * 2 * M_PI / VERTEX_NUM) + 0.5;
		vertex[i * 6 + 2] = 0;

		vertex[i * 6 + 3] = i * 2.0 / VERTEX_NUM - 1;
		vertex[i * 6 + 4] = WAVE_RANGE * sin((i + idx) * 2 * M_PI / VERTEX_NUM) - 0.5;
		vertex[i * 6 + 5] = 0;
	}

	for (int i = 0; i < VERTEX_NUM; i++) {
		vertex[VERTEX_NUM * 6 + i * 3 + 0] = i * 2.0 / VERTEX_NUM - 1;
		vertex[VERTEX_NUM * 6 + i * 3 + 1] = WAVE_RANGE * sin((i + idx) * 2 * M_PI / VERTEX_NUM);
		vertex[VERTEX_NUM * 6 + i * 3 + 2] = 0;
	}

	GLint position = glGetAttribLocation(program, "positionIn");
	glEnableVertexAttribArray(position);
	glVertexAttribPointer(position, 3, GL_FLOAT, 0, 0, vertex);

	assert(glGetError() == GL_NO_ERROR);

	GLint color = glGetUniformLocation(program, "color");
	glUniform4f(color, 0.35, 0.35, 0.4, 1.0);

	glClear(GL_COLOR_BUFFER_BIT);
	assert(glGetError() == GL_NO_ERROR);

	glDrawArrays(GL_TRIANGLE_STRIP, 0, 2 * VERTEX_NUM);

	int offset = 0;
	GLshort index[VERTEX_NUM * 2];
	int num = VERTEX_NUM / NUM_LINE;
	for (int i = 0; i < VERTEX_NUM - 1; i++) {
		if ((i + idx) % num > num * 1 / 2)
			continue;
		index[offset * 2 + 0] = VERTEX_NUM * 2 + i;
		index[offset * 2 + 1] = VERTEX_NUM * 2 + i + 1;
		offset++;
	}
	glUniform4f(color, 0.9, 0.9, 0.9, 1.0);
	glLineWidth(10);
	glDrawElements(GL_LINES, offset * 2, GL_UNSIGNED_SHORT, index);
  
	assert(glGetError() == GL_NO_ERROR);
}


