#version 430 compatibility
#extension GL_ARB_sparse_texture2: enable

layout(binding = 0) uniform sampler2D tex;
in vec2 texv;
layout(location = 0) out vec4 out_color;

void main() {
     vec4 texel;
     int code = sparseTextureGatherOffsetsARB(
         tex, texv,
         ivec2[4](ivec2(0, 0), ivec2(5, 5), ivec2(6, 8), ivec2(10, 10)),
	 texel, 1);
     bool is_resident = sparseTexelsResidentARB(code);
     out_color = is_resident ? vec4(texel.xyz, 1.0) : vec4(1.0, 0.0, 0.0, 1.0);
}
