#ifdef GL_ES
precision mediump float;
#endif
#define RepeatNone               	      0
#define RepeatNormal                     1
#define RepeatPad                        2
#define RepeatReflect                    3
#define RepeatFix		      	      10
uniform int 			source_repeat_mode;
uniform int 			mask_repeat_mode;
vec2 rel_tex_coord(vec2 texture, vec4 wh, int repeat) 
{
	vec2 rel_tex; 
	rel_tex = texture * wh.xy; 
	if (repeat == RepeatFix + RepeatNone)
		return rel_tex; 
	else if (repeat == RepeatFix + RepeatNormal) 
		rel_tex = floor(rel_tex) + (fract(rel_tex) / wh.xy); 
	else if (repeat == RepeatFix + RepeatPad) { 
		if (rel_tex.x >= 1.0) 
			rel_tex.x = 1.0 - wh.z * wh.x / 2.; 
		else if (rel_tex.x < 0.0) 
			rel_tex.x = 0.0; 
		if (rel_tex.y >= 1.0) 
			rel_tex.y = 1.0 - wh.w * wh.y / 2.; 
		else if (rel_tex.y < 0.0) 
			rel_tex.y = 0.0; 
		rel_tex = rel_tex / wh.xy; 
	} else if (repeat == RepeatFix + RepeatReflect) {
		if ((1.0 - mod(abs(floor(rel_tex.x)), 2.0)) < 0.001)
			rel_tex.x = 2.0 - (1.0 - fract(rel_tex.x)) / wh.x;
		else 
			rel_tex.x = fract(rel_tex.x) / wh.x;
		if ((1.0 - mod(abs(floor(rel_tex.y)), 2.0)) < 0.001)
			rel_tex.y = 2.0 - (1.0 - fract(rel_tex.y)) / wh.y;
		else 
			rel_tex.y = fract(rel_tex.y) / wh.y;
	} 
	return rel_tex; 
}
 vec4 rel_sampler_rgba(sampler2D tex_image, vec2 tex, vec4 wh, int repeat)
{
	if (repeat >= RepeatFix) {
		tex = rel_tex_coord(tex, wh, repeat);
		if (repeat == RepeatFix + RepeatNone) {
			if (tex.x < 0.0 || tex.x >= 1.0 || 
			    tex.y < 0.0 || tex.y >= 1.0)
				return vec4(0.0, 0.0, 0.0, 0.0);
			tex = (fract(tex) / wh.xy);
		}
	}
	return texture2D(tex_image, tex);
}
 vec4 rel_sampler_rgbx(sampler2D tex_image, vec2 tex, vec4 wh, int repeat)
{
	if (repeat >= RepeatFix) {
		tex = rel_tex_coord(tex, wh, repeat);
		if (repeat == RepeatFix + RepeatNone) {
			if (tex.x < 0.0 || tex.x >= 1.0 || 
			    tex.y < 0.0 || tex.y >= 1.0)
				return vec4(0.0, 0.0, 0.0, 0.0);
			tex = (fract(tex) / wh.xy);
		}
	}
	return vec4(texture2D(tex_image, tex).rgb, 1.0);
}
uniform vec4 source;
vec4 get_source()
{
	return source;
}
varying vec2 mask_texture;
uniform sampler2D mask_sampler;
uniform vec4 mask_wh;
vec4 get_mask()
{
	return rel_sampler_rgba(mask_sampler, mask_texture,
			        mask_wh, mask_repeat_mode);
}
vec4 dest_swizzle(vec4 color)
{	return color;}

void main()
{
	gl_FragColor = dest_swizzle(get_source() * get_mask().a);
}

