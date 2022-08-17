#version 430 compatibility
#extension GL_ARB_bindless_texture: enable

layout(bindless_sampler, binding = 0) uniform sampler2D tex;

in vec2 texv;
layout(location = 0) out vec4 out_color;

void main() {

     out_color = vec4(texture2D(tex, texv).xyz, 1.0);
}
