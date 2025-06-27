#version 460 core
#extension GL_EXT_mesh_shader : require

layout(local_size_x = 1) in;

taskPayloadSharedEXT float scalar;

void main()
{
    scalar = 0.5;
    EmitMeshTasksEXT(1, 1, 1);
}
