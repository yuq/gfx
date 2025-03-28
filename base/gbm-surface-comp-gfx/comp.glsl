#version 430 compatibility
layout(local_size_x = 1, local_size_y = 1) in;
layout(std430, binding=0) buffer color_buff
{
	vec4 color[1];
};

void main()
{
	color[0] = vec4(1, 0, 0, 1);
}
