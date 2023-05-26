#version 430

layout(triangles) in;

layout(location = 0) in vec4 color_tess[];
layout(location = 0) out vec4 color_fs;

void main()
{
    gl_Position = gl_in[0].gl_Position * gl_TessCoord[0]
                + gl_in[1].gl_Position * gl_TessCoord[1]
                + gl_in[2].gl_Position * gl_TessCoord[2];

    color_fs = color_tess[0] * gl_TessCoord[0]
             + color_tess[1] * gl_TessCoord[1]
             + color_tess[2] * gl_TessCoord[2];
}
