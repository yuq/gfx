#version 310 es
const highp float vtxScale = 0.812500;
flat out highp ivec4 var0;
flat out highp mat4x2 var1;
layout(location=5) centroid out highp float frgVar2;
layout(location=6) flat out highp ivec3 frgVar3;
layout(location=7) smooth out highp vec4 frgVar4;
smooth out highp float var5;
out highp vec2 var6;
flat out highp uvec4 var7;
const vec2 triangle[3] = vec2[3](
	vec2( 0.8750,  1.0000),
	vec2(-0.8750,  0.5000),
	vec2( 0.3750, -0.6875)
);
const ivec4 var0Inits[3] = ivec4[3](
	ivec4(225, 71, 75, 238),
	ivec4(37, 249, 32, 218),
	ivec4(35, 245, 161, 98));
const mat4x2 var1Inits[3] = mat4x2[3](
	mat4x2( 0.1250,  0.5625,  0.3125,  0.7500,  0.6250,  0.0625,  0.3750,  0.8125),
	mat4x2( 0.8750,  0.8750,  0.2500,  0.5000,  0.6250,  0.6250,  0.6250,  0.0625),
	mat4x2( 0.1250,  0.0625,  0.2500,  0.6250,  0.4375,  0.6250,  1.0000,  0.3750));
const float frgVar2Inits[3] = float[3](
	float( 0.4375),
	float( 0.8125),
	float( 0.8750));
const ivec3 frgVar3Inits[3] = ivec3[3](
	ivec3(148, 58, 30),
	ivec3(122, 154, 115),
	ivec3(2, 229, 113));
const vec4 frgVar4Inits[3] = vec4[3](
	vec4( 0.7500,  0.3750,  0.5625,  0.1250),
	vec4( 0.5625,  0.3750,  0.5625,  0.6875),
	vec4( 0.8750,  0.7500,  0.5000,  0.0625));
const float var5Inits[3] = float[3](
	float( 0.6875),
	float( 0.5000),
	float( 0.9375));
const vec2 var6Inits[3] = vec2[3](
	vec2( 0.3125,  0.6250),
	vec2( 0.6250,  0.5000),
	vec2( 0.3125,  0.4375));
const uvec4 var7Inits[3] = uvec4[3](
	uvec4(227, 219, 251, 181),
	uvec4(11, 150, 19, 233),
	uvec4(7, 89, 2, 100));
void main (void)
{
	gl_Position = vec4(vtxScale * triangle[gl_VertexID], 0.0, 1.0);
	var0 = var0Inits[gl_VertexID];
	var1 = var1Inits[gl_VertexID];
	frgVar2 = frgVar2Inits[gl_VertexID];
	frgVar3 = frgVar3Inits[gl_VertexID];
	frgVar4 = frgVar4Inits[gl_VertexID];
	var5 = var5Inits[gl_VertexID];
	var6 = var6Inits[gl_VertexID];
	var7 = var7Inits[gl_VertexID];
}
