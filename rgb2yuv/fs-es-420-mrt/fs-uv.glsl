#version 300 es

precision mediump float;
uniform sampler2D texMap;
layout(location = 0) out vec4 fragColor0;
layout(location = 1) out vec4 fragColor1;

void main() {
    ivec2 tex_size = textureSize(texMap, 0);
    vec2 tex_coord = 2.0 * gl_FragCoord.xy / vec2(tex_size);
    vec3 conv_u = vec3(-0.14713, -0.28886, 0.436);
    vec3 conv_v = vec3(0.615, -0.51499, -0.10001);
    vec3 rgb = texture(texMap, tex_coord).rgb;
    float u = (dot(conv_u, rgb) + 0.436) / 0.872;
    float v = (dot(conv_v, rgb) + 0.615) / 1.23;
    fragColor0 = vec4(u, 0 , 0, 1);
    fragColor1 = vec4(v, 0 , 0, 1);
}
