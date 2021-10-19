uniform sampler2D texture_map;
varying highp vec2 texcoord;

void main() {

     gl_FragColor = texture2D(texture_map, texcoord);
}
