#version 460 core
#extension GL_EXT_mesh_shader : require

layout(local_size_x = 1) in;
layout(max_vertices=3, max_primitives=1) out;
layout(triangles) out;

layout(std430, binding = 0) buffer ms_ssbo
{
    vec4 colorIn;
};

perprimitiveEXT out vec4 color[];

void main()
{
    SetMeshOutputsEXT(3, 1);

    color[0] = colorIn;

    gl_MeshVerticesEXT[0].gl_Position = vec4(-1, -1, 0, 1);
    gl_MeshVerticesEXT[1].gl_Position = vec4(-1, 1, 0, 1);
    gl_MeshVerticesEXT[2].gl_Position = vec4(1, 1, 0, 1);

    gl_PrimitiveTriangleIndicesEXT[0] = uvec3(0, 1, 2);
}
