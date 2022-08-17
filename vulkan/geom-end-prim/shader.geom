#version 430

#define NUM_VERTEX 18

layout(points) in;
layout(triangle_strip, max_vertices = NUM_VERTEX) out;

layout(location = 0) in int end_prim_offset[];
layout(location = 0) flat out vec4 color;

vec2 spiral(int vertex_id)
{
    float pi = acos(-1.0);
    float radial_spacing = 1.5;
    float spiral_spacing = 0.5;
    float a = 4.0*pi*spiral_spacing/radial_spacing;
    float b = radial_spacing/(2*pi);
    float theta = sqrt(a*float(vertex_id + 1));
    float r = b*theta;
    if (vertex_id % 2 == 1) r += 1.0;
    float max_r = b*sqrt(a*float(NUM_VERTEX)) + 1.0;
    r /= max_r;
    vec2 tmp = r*vec2(cos(theta), sin(theta));
    // ensure reasonably aligned vertices
    return floor(tmp * 2048.0f) / 2048.0f;
}

void main()
{
    int i = 0;
    while (true) {
        if (i % 3 == end_prim_offset[0])
            EndPrimitive();
        if (i == NUM_VERTEX)
            break;
        //gl_Position = vec4(spiral(i++), end_prim_offset[0]/4.0, 1.0);
	gl_Position = vec4(spiral(i++), end_prim_offset[0]/4.0, 1.0);
	color = vec4(0, 0, 0, 1);
	color[end_prim_offset[0]] = 1;
        EmitVertex();
    }
}
