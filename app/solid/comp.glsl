#version 430

#define WIDTH 5

layout(local_size_x = 5) in;

layout(std430, binding = 0) buffer ssbo0 {
    float input_data[WIDTH + 6];
};

layout(std430, binding = 1) buffer ssbo1 {
    float output_data[WIDTH];
};

void main(void)
{
	int index = int(gl_GlobalInvocationID.x);
	float x = input_data[WIDTH];
	float y = input_data[WIDTH + 1];
	float z = input_data[WIDTH + 2];
	float w = input_data[WIDTH + 3];
	float up = input_data[WIDTH + 4];
	float down = input_data[WIDTH + 5];
	if (index < WIDTH) {
	     float val = input_data[index];
	     float s = val * x + y;

	     const float accd_sign = down > up ? 1.0 : -1.0;
    	     const float upper_lim = accd_sign > 0.0 ? up : down;
    	     const float lower_lim = accd_sign > 0.0 ? down : up;
    	     float accd = (val < upper_lim) ? 0.0 : accd_sign;
	     accd += (val > lower_lim) ? 0.0 : -accd_sign;
    	     s += accd;

    	     s = (x == 0.0) ? (0.5 * z + w) : s;
	     
	     output_data[index] = s;
        }
}

