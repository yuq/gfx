#version 430

layout(location = 0) in vec3 color;

layout(location = 0) out vec4 fragColor;

//uniform vec3 color_v;
layout(location = 1) uniform float color_f;

void main() {

     fragColor = vec4(color.rg, color.b + color_f, 1);
}
