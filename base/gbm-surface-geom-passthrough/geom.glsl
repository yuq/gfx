#version 320 es
layout(lines) in;
layout(line_strip, max_vertices=2) out;

void main (void)
{
	for (int ndx = 0; ndx < gl_in.length(); ++ndx)
	{
		gl_Position = gl_in[ndx].gl_Position;
		EmitVertex();
	}
}
