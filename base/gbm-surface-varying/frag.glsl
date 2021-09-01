#version 430

noperspective in vec2 color_rg;
flat in float color_b;

out vec4 fragColor;

void main() {

     fragColor = vec4(color_rg, color_b, 1);
}
