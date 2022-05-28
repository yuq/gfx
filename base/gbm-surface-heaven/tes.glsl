#version 150

#extension GL_ARB_gpu_shader5 : enable
#extension GL_ARB_shader_bit_encoding : enable
#extension GL_ARB_tessellation_shader : enable

uniform mat4 s_projection;
uniform vec3 s_camera_position;

uniform vec4 s_material_tessellation_factor;
uniform vec3 s_material_tessellation_distance;

vec3 mul3(mat4 m,vec3 v) {
	return (m * vec4(v,0.0)).xyz;
}

vec3 mul3(vec3 v,mat4 m) {
	return (vec4(v,0.0) * m).xyz;
}

vec3 mul4(mat4 m,vec3 v) {
	return (m * vec4(v,1.0)).xyz;
}

vec4 mul4(mat4 m,vec4 v) {
	return m * v;
}

out vec4 s_texcoord_0;
out vec4 s_texcoord_1;
out vec4 s_texcoord_2;
out vec4 s_texcoord_3;
out vec4 s_texcoord_4;
out vec4 s_texcoord_5;
out vec4 s_texcoord_6;
out vec4 s_texcoord_7;
out vec4 s_texcoord_8;
out vec4 s_texcoord_9;
out vec4 s_texcoord_10;


vec4 getPosition(vec4 vertex) {
	return mul4(s_projection,vertex);
}

layout(triangles,fractional_odd_spacing,ccw) in;

uniform sampler2D s_texture_20;

in vec4 s_tess_texcoord_0[];
in vec4 s_tess_texcoord_1[];
in vec4 s_tess_texcoord_2[];
in vec4 s_tess_texcoord_3[];
in vec4 s_tess_texcoord_9[];


void main() {
	
	vec4 vertex = gl_in[0].gl_Position * gl_TessCoord.x + gl_in[1].gl_Position * gl_TessCoord.y + gl_in[2].gl_Position * gl_TessCoord.z;
	vec3 normal = s_tess_texcoord_9[0].xyz * gl_TessCoord.x + s_tess_texcoord_9[1].xyz * gl_TessCoord.y + s_tess_texcoord_9[2].xyz * gl_TessCoord.z;
	vec2 texcoord = s_tess_texcoord_0[0].xy * gl_TessCoord.x + s_tess_texcoord_0[1].xy * gl_TessCoord.y + s_tess_texcoord_0[2].xy * gl_TessCoord.z;
	float distance = length(vertex.xyz - s_camera_position);
	
	float lod = clamp((distance - s_material_tessellation_distance.x) * s_material_tessellation_distance.y,0.0,8.0);
	float offset = pow(clamp(1.0 - (distance - s_material_tessellation_distance.x) * s_material_tessellation_distance.y,0.0,1.0),s_material_tessellation_factor.y);
	offset *= (textureLod(s_texture_20,texcoord,lod).x - 127.0 / 255.0) * s_material_tessellation_factor.x;
	vertex.xyz += normal * offset;
		
	gl_Position = getPosition(vertex);
		
	s_texcoord_0.xy = texcoord;
	s_texcoord_0.zw = s_tess_texcoord_0[0].zw * gl_TessCoord.x + s_tess_texcoord_0[1].zw * gl_TessCoord.y + s_tess_texcoord_0[2].zw * gl_TessCoord.z;
		
	s_texcoord_1.xyz = vertex.xyz;
		
	s_texcoord_2 = s_tess_texcoord_1[0] * gl_TessCoord.x + s_tess_texcoord_1[1] * gl_TessCoord.y + s_tess_texcoord_1[2] * gl_TessCoord.z;
	s_texcoord_3 = s_tess_texcoord_2[0] * gl_TessCoord.x + s_tess_texcoord_2[1] * gl_TessCoord.y + s_tess_texcoord_2[2] * gl_TessCoord.z;
	s_texcoord_4 = s_tess_texcoord_3[0] * gl_TessCoord.x + s_tess_texcoord_3[1] * gl_TessCoord.y + s_tess_texcoord_3[2] * gl_TessCoord.z;
}
