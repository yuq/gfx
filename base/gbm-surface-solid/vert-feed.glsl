#version 330 compatibility

layout(location=0) in vec4 position;
layout(location=1) in uint normal;
layout(location=2) in vec2 tex;

out GeometryOut
{
    flat uint flat_normal;
    flat vec2 tex_top;
} gs_out;

void main(void)
{
	gl_Position = position;
	gs_out.flat_normal = normal;
	gs_out.tex_top = tex;
}
