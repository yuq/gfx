//precision mediump float;

uniform sampler2DRect tex;
varying vec2 texv;


void main() {

     gl_FragColor = vec4(texture2DRect(tex, texv).xyz, 1.0);
}
