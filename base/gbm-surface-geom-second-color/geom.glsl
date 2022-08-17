#version 460 compatibility

layout(triangles) in;
layout(triangle_strip, max_vertices=3) out;

void main(void)
{
	for (int i = 0; i < 3; i++) {
	    gl_Position = gl_in[i].gl_Position;
	    gl_FrontSecondaryColor = vec4(0, 0.25, 0, 1.0);
	    EmitVertex();
	}
}
