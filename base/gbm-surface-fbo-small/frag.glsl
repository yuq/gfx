#version 430

layout (location = 0) out vec4 out_color;
layout (location = 1) uniform vec4 color;

void main() {
     out_color = color;
}
