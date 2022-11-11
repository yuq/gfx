#version 320 es

precision mediump float;

in vec4 color;
in vec4 color2;

out vec4 fragColor;

void main(void)
{
	fragColor = color + color2;
}
