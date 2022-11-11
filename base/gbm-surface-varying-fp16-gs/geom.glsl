#version 320 es

layout(triangles) in;
layout(triangle_strip, max_vertices=3) out;

in vec4 colorIO[];

out mediump vec4 color;
out mediump vec4 color2;

void main(void)
{
    gl_Position = gl_in[0].gl_Position;
    color = colorIO[0] / 2.0;
    color2 = colorIO[0] / 4.0;
    EmitVertex();

    gl_Position = gl_in[1].gl_Position;
    color = colorIO[1] / 2.0;
    color2 = colorIO[1] / 4.0;
    EmitVertex();

    gl_Position = gl_in[2].gl_Position;
    color = colorIO[2] / 2.0;
    color2 = colorIO[2] / 4.0;
    EmitVertex();
}
