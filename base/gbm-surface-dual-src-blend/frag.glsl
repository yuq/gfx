#version 430

layout (location = 0, index = 0) out vec4 blend_color;
layout (location = 0, index = 1) out vec4 blend_param;

void main() {
     /* blend setting: final color is color * param */
     blend_color = vec4(1.0, 1.0, 1.0, 1);
     blend_param = vec4(1.0, 1.0, 0.0, 1);
}
