#version 430

in vec3 color;
in vec3 color2;

out vec4 fragColor;

uniform int count;

void main() {

     float color_b = 0;
     int i;

     for (i = 0; i < count; i++) {
     	color_b += color2.b + color2.r + color2.g + color.b;
     }

     fragColor = vec4(color.rg, color_b, 1);
}
