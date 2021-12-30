#version 430 compatibility
#extension GL_ARB_sparse_texture2: enable

layout(binding = 0) uniform sampler2D tex;
in vec2 texv;
layout(location = 0) out vec4 out_color;

void main() {
     vec4 texel;
     int code = sparseTextureARB(tex, texv, texel);
     bool is_resident = sparseTexelsResidentARB(code);
     if (is_resident)
          out_color = vec4(texel.xyz, 1.0);
     else
          out_color = vec4(1.0, 0.0, 0.0, 1.0);
}
