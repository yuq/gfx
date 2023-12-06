#version 320 es
layout(isolines) in;

in highp vec4 v_patch_color[];
out highp vec4 v_fragment_color;

// note: No need to use precise gl_Position since we do not require gapless geometry
void main (void)
{
	vec2 normalizedCoord = (gl_TessCoord.xy * 2.0 - vec2(1.0));
	vec2 normalizedWeights = normalizedCoord * (vec2(1.0) - 0.3 * cos(normalizedCoord.yx * 1.57));
	vec2 weights = normalizedWeights * 0.5 + vec2(0.5);
	vec2 cweights = gl_TessCoord.xy;
	gl_Position = mix(mix(gl_in[0].gl_Position, gl_in[1].gl_Position, weights.y), mix(gl_in[2].gl_Position, gl_in[3].gl_Position, weights.y), weights.x);
	v_fragment_color = mix(mix(v_patch_color[0], v_patch_color[1], cweights.y), mix(v_patch_color[2], v_patch_color[3], cweights.y), cweights.x);
}
