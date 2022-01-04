#version 430 compatibility
#extension GL_ARB_sparse_texture2: enable
layout(local_size_x = 16, local_size_y = 16) in;
layout(r8, binding = 0) uniform readonly mediump image2D img_in;
layout(rgba8, binding = 1) uniform writeonly mediump image2D img_out;

void main()
{
	vec4 texel;
	ivec2 pos = ivec2(gl_GlobalInvocationID.xy);
	int code = sparseImageLoadARB(img_in, pos, texel);
	bool is_resident = sparseTexelsResidentARB(code);
	vec4 color = is_resident ? texel : vec4(1.0, 0.0, 0.0, 1.0);
	imageStore(img_out, pos, color);
}
