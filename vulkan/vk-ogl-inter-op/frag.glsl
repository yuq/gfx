precision mediump float;

uniform sampler2D tex;
varying vec2 texUV;

void main() {
     gl_FragColor = texture2D(tex, texUV);
}
