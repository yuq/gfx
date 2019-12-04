#version 300 es

precision mediump float;
uniform sampler2D texMap;
out vec4 fragColor;

void main() {
    ivec2 tex_size = textureSize(texMap, 0);
    vec2 tex_coord = gl_FragCoord.xy / vec2(tex_size);
    vec3 conv = vec3(0.299, 0.587, 0.114);
    vec3 rgb = texture(texMap, tex_coord).rgb;
    fragColor = vec4(dot(conv, rgb), 0, 0, 1);
}
