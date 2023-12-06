#version 320 es
in highp vec4 a_position;
out highp vec4 v_vertex_color;
void main (void)
{
	gl_Position = a_position;
	v_vertex_color = vec4(a_position.x * 0.5 + 0.5, a_position.y * 0.5 + 0.5, 1.0, 0.4);
}
