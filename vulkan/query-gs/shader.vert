#version 430

layout(location = 0) in vec2 positionIn;

layout(location = 0) out vec4 position;

void main()
{
    position = vec4(positionIn, 0, 1);
}
