precision mediump float;

varying vec4 color;
varying vec4 color2;

void main() {

     gl_FragColor = color + color2;
}
