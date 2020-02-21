#version 430

layout(location = 0) in vec2 positionIn;

void main()
{
    gl_Position = vec4(positionIn, 0, 1);
}
