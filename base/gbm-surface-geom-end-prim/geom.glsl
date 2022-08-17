#version 460 compatibility

layout(triangles) in;
layout(triangle_strip, max_vertices=256) out;

void main(void)
{
	gl_Position = gl_in[0].gl_Position;
	EmitVertex();
	EndPrimitive();

	gl_Position = gl_in[0].gl_Position;
	EmitVertex();
	gl_Position = gl_in[1].gl_Position;
	EmitVertex();
	gl_Position = gl_in[2].gl_Position;
	EmitVertex();
	EndPrimitive();

	gl_Position = vec4(1, 1, 0, 1);
	EmitVertex();
	gl_Position = vec4(1, -1, 0, 1);
	EmitVertex();
	EndPrimitive();

	gl_Position = vec4(-1, 1, 0, 1);
	EmitVertex();
	gl_Position = vec4(1, 1, 0, 1);
	EmitVertex();
	gl_Position = vec4(1, -1, 0, 1);
	EmitVertex();
	EndPrimitive();
}