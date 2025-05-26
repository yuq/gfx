#version 320 es
layout(isolines) in;

// note: No need to use precise gl_Position since we do not require gapless geometry
void main (void)
{
	gl_Position = mix(mix(gl_in[0].gl_Position, gl_in[1].gl_Position, gl_TessCoord.y), mix(gl_in[2].gl_Position, gl_in[3].gl_Position, gl_TessCoord.y), gl_TessCoord.x);
}
