#version 430 compatibility
layout(local_size_x = 16, local_size_y = 16) in;
layout(rgba8, binding = 0) uniform readonly mediump image2DMS img_in;
layout(rgba8, binding = 1) uniform writeonly mediump image2D img_out;

void main()
{
	ivec2 pos = ivec2(gl_GlobalInvocationID.xy);
	vec4 texel = imageLoad(img_in, pos, 3);
	vec4 color = vec4(texel.xyz, 1.0);
	imageStore(img_out, pos, color);
}
