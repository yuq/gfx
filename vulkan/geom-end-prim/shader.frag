#version 430

layout(location = 0) out vec4 fragColor;
layout(location = 0) flat in vec4 color;

void main() {
/*
    int end_prim_offset = int(round((gl_FragCoord.z - 0.5) * 8.0));
    const vec4 colors[3] = vec4[3](
        vec4(1.0, 0.0, 0.0, 1.0),
        vec4(0.0, 1.0, 0.0, 1.0),
        vec4(0.0, 0.0, 1.0, 1.0));
    fragColor = colors[end_prim_offset];
*/
    fragColor = color;
}
