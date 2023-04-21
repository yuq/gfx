#version 430 compatibility
layout(local_size_x = 1, local_size_y = 1) in;
layout(std430, binding=0) buffer calc_data
{
	float rw_data[];
};

void main()
{
	rw_data[2] = pow(rw_data[0], rw_data[1]);
}
