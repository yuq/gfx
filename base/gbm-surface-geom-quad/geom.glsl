#version 460 compatibility

layout(triangles) in;
layout(triangle_strip, max_vertices=3) out;

layout(std430, binding=0) buffer data {
    uint result[];
};

void main(void)
{
    result[gl_PrimitiveIDIn] = 1;
}
