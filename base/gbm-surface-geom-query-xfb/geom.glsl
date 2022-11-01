#version 460 compatibility

layout(points) in;
layout(points, max_vertices=32) out;

layout(stream = 0, xfb_buffer = 0, xfb_offset = 0) out int stream0;
layout(stream = 1, xfb_buffer = 1, xfb_offset = 0) out int stream1;
layout(stream = 2, xfb_buffer = 2, xfb_offset = 0) out int stream2;
layout(stream = 3, xfb_buffer = 3, xfb_offset = 0) out int stream3;

void main(void)
{
    gl_Position = gl_in[0].gl_Position;
    stream0 = 1;
    EmitVertex();

    stream1 = 1;
    EmitStreamVertex(1);
    stream1 = 2;
    EmitStreamVertex(1);

    stream2 = 1;
    EmitStreamVertex(2);
    stream2 = 2;
    EmitStreamVertex(2);
    stream2 = 3;
    EmitStreamVertex(2);

    stream3 = 1;
    EmitStreamVertex(3);
    stream3 = 2;
    EmitStreamVertex(3);
    stream3 = 3;
    EmitStreamVertex(3);
    stream3 = 4;
    EmitStreamVertex(3);
}