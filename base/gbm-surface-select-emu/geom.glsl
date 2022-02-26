#version 460 compatibility

layout(triangles) in;
layout(triangle_strip, max_vertices=3) out;

in int objIndex[];

layout(std430, binding=0) buffer select_output
{
    uint select_data[];
};

void main(void)
{
    int i = objIndex[0] * 3;

    // visible
    atomicExchange(select_data[i], 1);

    float dmin = min(gl_in[0].gl_Position.z, gl_in[1].gl_Position.z);
    dmin = min(dmin, gl_in[2].gl_Position.z);
    dmin = clamp(dmin, -1.0, 1.0);
    uint idmin = 0x80000000 + int(dmin * 2147483648.0);

    float dmax = max(gl_in[0].gl_Position.z, gl_in[1].gl_Position.z);
    dmax = max(dmax, gl_in[2].gl_Position.z);
    dmax = clamp(dmax, -1.0, 1.0);
    uint idmax = 0x80000000 + int(dmax * 2147483648.0);

    atomicMin(select_data[i + 1], idmin);
    atomicMax(select_data[i + 2], idmax);
}
