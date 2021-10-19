attribute vec4 v_position;
attribute vec4 v_texcoord0;
attribute vec4 v_texcoord1;
varying vec2 source_texture;
varying vec2 mask_texture;
void main()
{
	gl_Position = v_position;
	source_texture = v_texcoord0.xy;
	mask_texture = v_texcoord1.xy;
}
