#version 430 compatibility

layout(location = 0) in vec3 positionIn;
layout(location = 1) in vec2 texIn;

out vec2 texv;

void main()
{
    texv = texIn;
    gl_Position = vec4(positionIn, 1);
}
