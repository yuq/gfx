#version 430

layout(points) in;
layout(triangle_strip, max_vertices = 3) out;

layout(location = 0) out vec4 color;

void main()
{
    gl_Position = vec4(-1, -1, 0, 0.8);
    color = vec4(1, 0, 0, 1);
    EmitVertex();

    gl_Position = vec4(-1, 1, 0, 0.8);
    color = vec4(0, 1, 0, 1);
    EmitVertex();

    gl_Position = vec4(1, 1, 0, 0.8);
    color = vec4(0, 0, 1, 1);
    EmitVertex();
}
