#version 430

in vec3 color;

out vec4 fragColor;

uniform float color_f;

void main() {

     fragColor = vec4(color.rg, color.b + color_f, 1);
}
