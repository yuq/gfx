#version 310 es

precision mediump float;
layout(location=0) uniform sampler2D tex_y;
layout(location=1) uniform sampler2D tex_u;
layout(location=2) uniform sampler2D tex_v;
in vec2 texcoord;
out vec4 fragColor;

void main() {
    float y = texture(tex_y, texcoord).r;
    float u = texture(tex_u, texcoord).r;
    float v = texture(tex_v, texcoord).r;

    // de-normalize
    u = u * 0.872 - 0.436;
    v = v * 1.23 - 0.615;

    vec3 yuv = vec3(y, u, v);

    mat3 conv_mat = mat3(
        1.0,  0.0,      1.13983,
        1.0, -0.39465, -0.58060,
        1.0,  2.03211,  0.0
    );

    fragColor = vec4(yuv * conv_mat, 1.0);
}
