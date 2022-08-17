#version 430 compatibility

layout (vertices = 3) out;

in vec3 position[];

out vec3 position_es[];

void main()
{
	position_es[gl_InvocationID] = position[gl_InvocationID];

	gl_TessLevelOuter[0] = 3;
	gl_TessLevelOuter[1] = 4;
	gl_TessLevelOuter[2] = 5;
	gl_TessLevelInner[0] = 3;
}
