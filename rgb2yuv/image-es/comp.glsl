#version 320 es
layout(local_size_x = 16, local_size_y = 16) in;
layout(rgba8, binding = 0) uniform readonly mediump image2D img_in;
layout(rgba8, binding = 1) uniform writeonly mediump image2D img_out;

void main()
{
	ivec2 base = imageSize(img_in);
	int x = int(gl_GlobalInvocationID.x);
	int y = int(gl_GlobalInvocationID.y);
	if (x * 4 >= base.x || y * 2 >= base.y)
	   return;

	mat3 conv_mat = mat3(
	     0.299,    0.587,    0.114,
	     -0.14713, -0.28886, 0.436,
	     0.615,    -0.51499, -0.10001
	);

	vec3 yuv[2][4];
	for (int i = 0; i < 2; i++) {
	    for (int j = 0; j < 4; j++) {
	    	ivec2 idx = ivec2(x * 4 + j, y * 2 + i);
		vec3 rgb = imageLoad(img_in, idx).rgb;
	    	yuv[i][j] = conv_mat * rgb;
	    }
	}

	imageStore(img_out, ivec2(x, y * 2),
		   vec4(yuv[0][0].r, yuv[0][1].r, yuv[0][2].r, yuv[0][3].r));
	imageStore(img_out, ivec2(x, y * 2 + 1),
		   vec4(yuv[1][0].r, yuv[1][1].r, yuv[1][2].r, yuv[1][3].r));

	vec2 uv0 = yuv[0][0].gb + yuv[0][1].gb + yuv[1][0].gb + yuv[1][1].gb;
	vec2 uv1 = yuv[0][2].gb + yuv[0][3].gb + yuv[1][2].gb + yuv[1][3].gb;
	imageStore(img_out, ivec2(x, base.y + y), vec4(uv0, uv1) / 4.0);
}
