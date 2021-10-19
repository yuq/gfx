precision mediump float;

uniform sampler2D tex;
varying vec2 texv;


void main() {

     gl_FragColor = vec4(texture2D(tex, texv).xyz, 1.0);
}
