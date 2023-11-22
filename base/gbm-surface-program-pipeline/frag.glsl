#version 310 es
precision highp float;
out vec4 fragColor;
const highp float frgScale = 0.125000;
flat in highp ivec4 var0;
flat in highp mat4x2 var1;
layout(location=5) centroid in highp float frgVar2;
layout(location=6) flat in highp ivec3 frgVar3;
layout(location=7) smooth in highp vec4 frgVar4;
smooth in highp float var5;
in highp vec2 var6;
flat in highp uvec4 var7;
int imod (int n, int d)
{
	return (n < 0 ? d - 1 - (-1 - n) % d : n % d);
}
vec4 hsv (vec3 hsv){
	float h = hsv.x * 3.0;
	float r = max(0.0, 1.0 - h) + max(0.0, h - 2.0);
	float g = max(0.0, 1.0 - abs(h - 1.0));
	float b = max(0.0, 1.0 - abs(h - 2.0));
	vec3 hs = mix(vec3(1.0), vec3(r, g, b), hsv.y);
	return vec4(hsv.z * hs, 1.0);
}
void main (void)
{
	fragColor = vec4(vec3(frgScale), 1.0);
	switch (imod(int(0.5 * ( 1.7445 * gl_FragCoord.x -  1.8888 * gl_FragCoord.y)), 8))
	{
		case 0:
			fragColor *= (vec4(var0) / 255.0);
			break;
		case 1:
			fragColor *= hsv(transpose(var1)[0].xyz);
			break;
		case 2:
			fragColor *= hsv(vec3(frgVar2, 1.0, 1.0));
			break;
		case 3:
			fragColor *= vec4((vec3(frgVar3) / 255.0), 1.0);
			break;
		case 4:
			fragColor *= frgVar4;
			break;
		case 5:
			fragColor *= hsv(vec3(var5, 1.0, 1.0));
			break;
		case 6:
			fragColor *= hsv(vec3(var6, 1.0));
			break;
		case 7:
			fragColor *= (vec4(var7) / 255.0);
			break;
		case 8:
			fragColor = vec4(1.0, 0.0, 1.0, 1.0);
			break;
		case -1:
			fragColor = vec4(1.0, 1.0, 0.0, 1.0);
			break;
		default:
			fragColor = vec4(1.0, 1.0, 0.0, 1.0);
	}
}
