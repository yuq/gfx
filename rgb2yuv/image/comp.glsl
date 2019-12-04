#version 430
layout(local_size_x = 16, local_size_y = 16) in;
layout(rgba8, binding = 0) uniform readonly mediump image2D img_in;
layout(r8, binding = 1) uniform writeonly mediump image2D img_out;

void main()
{
	ivec2 idx0 = ivec2(gl_GlobalInvocationID.xy) * 2;
	ivec2 idx1 = ivec2(idx0.x + 1, idx0.y);
	ivec2 idx2 = ivec2(idx0.x, idx0.y + 1);
	ivec2 idx3 = ivec2(idx0.x + 1, idx0.y + 1);
	ivec2 base = imageSize(img_in);

	if (any(greaterThanEqual(idx3, base)))
	    return;

	vec3 rgb0 = imageLoad(img_in, idx0).rgb;
	vec3 rgb1 = imageLoad(img_in, idx1).rgb;
	vec3 rgb2 = imageLoad(img_in, idx2).rgb;
	vec3 rgb3 = imageLoad(img_in, idx3).rgb;

	mat3 conv_mat = mat3(
	     0.299,    0.587,    0.114,
	     -0.14713, -0.28886, 0.436,
	     0.615,    -0.51499, -0.10001
	);

	vec3 yuv0 = rgb0 * conv_mat;
	vec3 yuv1 = rgb1 * conv_mat;
	vec3 yuv2 = rgb2 * conv_mat;
	vec3 yuv3 = rgb3 * conv_mat;

	imageStore(img_out, idx0, vec4(yuv0.r));
	imageStore(img_out, idx1, vec4(yuv1.r));
	imageStore(img_out, idx2, vec4(yuv2.r));
	imageStore(img_out, idx3, vec4(yuv3.r));

	ivec2 uidx = ivec2(
	      int(gl_GlobalInvocationID.x) * 2,
	      base.y + int(gl_GlobalInvocationID.y));
	ivec2 vidx = ivec2(uidx.x + 1, uidx.y);
	vec2 uv = (yuv0.gb + yuv1.gb + yuv2.gb + yuv3.gb) / 4.0;
	imageStore(img_out, uidx, vec4(uv.x));
	imageStore(img_out, vidx, vec4(uv.y));
}
