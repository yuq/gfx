#version 320 es
layout(lines) in;
layout(line_strip, max_vertices=2) out;

in highp vec4 v_evaluated_color[];
out highp vec4 v_fragment_color;

void main (void)
{
	for (int ndx = 0; ndx < gl_in.length(); ++ndx)
	{
		gl_Position = gl_in[ndx].gl_Position;
		v_fragment_color = v_evaluated_color[ndx];
		EmitVertex();
	}
}
