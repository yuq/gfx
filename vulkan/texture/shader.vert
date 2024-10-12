#version 430

layout(location = 0) in vec2 positionIn;
layout(location = 1) in vec2 texIn;

layout(location = 0) out vec2 texUV;

void main()
{
	gl_Position = vec4(positionIn, 0, 1);
	texUV = texIn;
}
