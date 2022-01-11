#version 430 compatibility
#extension GL_ARB_sparse_texture2: enable
#extension GL_ARB_sparse_texture_clamp: enable

layout(binding = 0) uniform sampler2D tex;
in vec2 texv;
layout(location = 0) out vec4 out_color;

void main() {
     vec4 texel;
     int code = sparseTextureClampARB(tex, texv, 1.0, texel);
     bool is_resident = sparseTexelsResidentARB(code);
     out_color = is_resident ? texel : vec4(1.0, 0.0, 0.0, 1.0);
}
