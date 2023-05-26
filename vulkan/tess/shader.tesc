#version 430

layout (vertices = 3) out;

layout(location = 0) in vec4 color[];
layout(location = 0) out vec4 color_tess[];

void main()
{
    gl_out[gl_InvocationID].gl_Position = gl_in[gl_InvocationID].gl_Position;
    color_tess[gl_InvocationID] = color[gl_InvocationID];

    gl_TessLevelOuter[0] = 1;
    gl_TessLevelOuter[1] = 1;
    gl_TessLevelOuter[2] = 1;
    gl_TessLevelOuter[3] = 1;
    gl_TessLevelInner[0] = 1;
    gl_TessLevelInner[1] = 1;
}
