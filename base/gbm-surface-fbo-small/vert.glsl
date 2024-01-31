#version 430

layout (location = 0) in vec2 positionIn;
layout (location = 0) uniform float depth;

void main()
{
    gl_Position = vec4(positionIn, depth, 1);
}
