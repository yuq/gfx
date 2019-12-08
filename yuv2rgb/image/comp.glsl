#version 430
layout(local_size_x = 16, local_size_y = 16) in;
layout(r8, binding = 0) uniform readonly mediump image2D img_y;
layout(r8, binding = 1) uniform readonly mediump image2D img_u;
layout(r8, binding = 2) uniform readonly mediump image2D img_v;
layout(rgba8, binding = 3) uniform writeonly mediump image2D img_out;

void main()
{
	ivec2 base = imageSize(img_y);
	ivec2 pos = ivec2(gl_GlobalInvocationID.xy);
	ivec2 pos2 = pos * 2;
	if (any(greaterThanEqual(pos2, base)))
	    return;

	float u = imageLoad(img_u, pos).r;
	float v = imageLoad(img_v, pos).r;

	// de-normalize
	u = u * 0.872 - 0.436;
	v = v * 1.23 - 0.615;

	mat3 conv_mat = mat3(
	     1.0,  0.0,      1.13983,
	     1.0, -0.39465, -0.58060,
	     1.0,  2.03211,  0.0
	);

	for (int i = 0; i < 2; i++) {
	    for (int j = 0; j < 2; j++) {
	    	ivec2 idx = pos2 + ivec2(j, i);
		float y = imageLoad(img_y, idx).r;
		vec3 yuv = vec3(y, u, v);
		imageStore(img_out, idx, vec4(yuv * conv_mat, 1.0));
	    }
	}
}
