#version 430

layout (location = 0) out vec4 out_color;

layout(std430, binding=0) buffer color_buff
{
	vec4 color[1];
};

void main() {

     out_color = color[0];
}
