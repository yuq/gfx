#version 430

layout(points) in;
layout(points, max_vertices = 32) out;

layout(location = 0) in vec4 position[];

layout(stream = 1, location = 1) out int stream1;
layout(stream = 2, location = 2) out int stream2;
layout(stream = 3, location = 3) out int stream3;

void main()
{
    gl_Position = position[0];
    gl_PointSize = 5;
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
