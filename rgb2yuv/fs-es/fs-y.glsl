#version 300 es

precision mediump float;
uniform sampler2D texMap;
out vec4 fragColor;

void main() {
    ivec2 tex_size = textureSize(texMap, 0);
    float dx = 1.0 / float(tex_size.x);
    vec2 tex_coord = gl_FragCoord.xy / vec2(tex_size);
    vec2 tex_pos = vec2(tex_coord.x * 4.0 - 1.5 * dx, tex_coord.y);
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
