#version 300 es

precision mediump float;
uniform sampler2D texMap;
in vec2 texcoord;
out vec4 fragColor;

void main() {
    ivec2 tex_size = textureSize(texMap, 0);
    float dx = 1.0 / float(tex_size.x);
    vec2 tex_pos = vec2(texcoord.x - 1.5 * dx, texcoord.y);
    vec3 conv = vec3(0.299, 0.587, 0.114);
    vec4 color;

    vec3 rgb = texture(texMap, tex_pos).rgb;
    color.r = dot(conv, rgb);
    tex_pos.x += dx;

    rgb = texture(texMap, tex_pos).rgb;
    color.g = dot(conv, rgb);
    tex_pos.x += dx;

    rgb = texture(texMap, tex_pos).rgb;
    color.b = dot(conv, rgb);
    tex_pos.x += dx;

    rgb = texture(texMap, tex_pos).rgb;
    color.a = dot(conv, rgb);

    fragColor = color;
}
