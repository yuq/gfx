#version 430

layout (location = 0) out vec4 frag_color0;
layout (location = 1) out vec4 frag_color1;

void main() {

     frag_color0 = vec4(1.0, 0.0, 0.0, 1);
     frag_color1 = vec4(0.0, 1.0, 0.0, 1);
}
