#version 120

varying vec3 color;

uniform float color_f;

void main() {

     gl_FragColor = vec4(color.rg, color.b + color_f, 1.0);
}
