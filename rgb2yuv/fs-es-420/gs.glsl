#version 320 es
#extension GL_OES_viewport_array : enable

layout(triangles, invocations = 3) in;
layout(triangle_strip, max_vertices = 3) out;

in vec2 texcoord[];
out vec2 tex_coord;

void main()
{
    gl_ViewportIndex = gl_InvocationID;
    for (int i = 0; i < 3; i++) {
        tex_coord = texcoord[i];
        gl_Position = gl_in[i].gl_Position;
        EmitVertex();
    }
    EndPrimitive();
}
