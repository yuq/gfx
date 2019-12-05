#version 430

uniform sampler2D texMap;
in vec2 texcoord;
out vec4 fragColor;

void main() {
    mat3 conv = mat3(
        0.299,    0.587,    0.114,
        -0.14713, -0.28886, 0.436,
        0.615,    -0.51499, -0.10001
    );
    vec3 rgb = texture(texMap, texcoord).rgb;
    float color = dot(conv[gl_ViewportIndex], rgb);
    // normalize to [0, 1]
    float offset[3] = float[](0.0, 0.436, 0.615);
    float scale[3] = float[](1.0, 0.872, 1.23);
    color = (color + offset[gl_ViewportIndex]) / scale[gl_ViewportIndex];
    fragColor = vec4(color, 0, 0, 1);
}
