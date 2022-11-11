#version 320 es

layout(location=0) in vec3 positionIn;
layout(location=1) in vec4 colorIn;

out vec4 colorIO;

void main()
{
    gl_Position = vec4(positionIn, 1);
    colorIO = colorIn;
}