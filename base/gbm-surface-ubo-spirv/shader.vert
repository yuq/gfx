#version 430

layout(std140, binding=0) uniform Color {
    vec3 color_v;
};

layout(location = 0) in vec3 positionIn;

layout(location = 0) out vec3 color;

void main()
{
    gl_Position = vec4(positionIn, 1);
    color = color_v;
}