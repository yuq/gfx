#version 320 es
layout(vertices = 4) out;

uniform highp float u_innerTessellationLevel;
uniform highp float u_outerTessellationLevel;

void main (void)
{
	gl_out[gl_InvocationID].gl_Position = gl_in[gl_InvocationID].gl_Position;

	gl_TessLevelOuter[0] = u_outerTessellationLevel;
	gl_TessLevelOuter[1] = u_outerTessellationLevel;
}
