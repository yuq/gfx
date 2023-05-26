#version 430

layout(location = 0) in vec4 vertex;

layout(location = 0) out vec4 color;

void main()
{
    gl_Position = vertex;
    color = vec4(0, 1, 0, 1);
}
