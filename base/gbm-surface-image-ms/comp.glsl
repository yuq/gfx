#version 430 compatibility
layout(local_size_x = 16, local_size_y = 16) in;
layout(rgba8, binding = 0) uniform writeonly mediump image2DMS img_out;

void main()
{
	ivec2 pos = ivec2(gl_GlobalInvocationID.xy);
	imageStore(img_out, pos, 0, vec4(1.0, 0.0, 0.0, 1.0));
	imageStore(img_out, pos, 1, vec4(0.0, 1.0, 0.0, 1.0));
	imageStore(img_out, pos, 2, vec4(0.0, 0.0, 1.0, 1.0));
	imageStore(img_out, pos, 3, vec4(1.0, 1.0, 0.0, 1.0));
}
