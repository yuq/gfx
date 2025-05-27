#version 460 core
#extension GL_EXT_mesh_shader : require

layout(location = 0) out vec4 out_color;

layout(location = 0) perprimitiveEXT in vec4 color;

void main() {
     out_color = color;
}
