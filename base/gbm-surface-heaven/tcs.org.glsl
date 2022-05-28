#version 150

#extension GL_ARB_gpu_shader5 : enable
#extension GL_ARB_shader_bit_encoding : enable
#extension GL_ARB_tessellation_shader : enable

uniform mat4 s_projection;

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

vec4 getPosition(vec4 vertex) {
	return mul4(s_projection,vertex);
}

layout(vertices = 3) out;

in vec4 s_texcoord_0[];
in vec4 s_texcoord_1[];
in vec4 s_texcoord_2[];
in vec4 s_texcoord_3[];
in vec4 s_texcoord_9[];

out vec4 s_tess_texcoord_0[];
out vec4 s_tess_texcoord_1[];
out vec4 s_tess_texcoord_2[];
out vec4 s_tess_texcoord_3[];
out vec4 s_tess_texcoord_9[];


void main() {
	
	vec4 p0 = getPosition(gl_in[0].gl_Position);
	vec4 p1 = getPosition(gl_in[1].gl_Position);
	vec4 p2 = getPosition(gl_in[2].gl_Position);
	
	
	p0.xy /= p0.w;
	p1.xy /= p1.w;
	p2.xy /= p2.w;
	
	if(!all(lessThan(vec4(min(min(p0.xy,p1.xy),p2.xy),-max(max(p0.xy,p1.xy),p2.xy)),vec4(1.2)))) {
		gl_TessLevelOuter[0] = 0.0;
		gl_TessLevelOuter[1] = 0.0;
		gl_TessLevelOuter[2] = 0.0;
		gl_TessLevelInner[0] = 0.0;
		return;
	}
	
	float l0 = length(gl_in[1].gl_Position.xyz - gl_in[2].gl_Position.xyz);
	float l1 = length(gl_in[2].gl_Position.xyz - gl_in[0].gl_Position.xyz);
	float l2 = length(gl_in[0].gl_Position.xyz - gl_in[1].gl_Position.xyz);
	
	float f0 = (s_texcoord_9[1].w + s_texcoord_9[2].w) * clamp(l0 * s_material_tessellation_distance.z,0.0,1.0);
	float f1 = (s_texcoord_9[2].w + s_texcoord_9[0].w) * clamp(l1 * s_material_tessellation_distance.z,0.0,1.0);
	float f2 = (s_texcoord_9[0].w + s_texcoord_9[1].w) * clamp(l2 * s_material_tessellation_distance.z,0.0,1.0);
	
	gl_TessLevelOuter[0] = f0;
	gl_TessLevelOuter[1] = f1;
	gl_TessLevelOuter[2] = f2;
	gl_TessLevelInner[0] = (f0 + f1 + f2) * (1.0 / 3.0);

	gl_out[gl_InvocationID].gl_Position = gl_in[gl_InvocationID].gl_Position;
	s_tess_texcoord_0[gl_InvocationID] = s_texcoord_0[gl_InvocationID];
		
	s_tess_texcoord_1[gl_InvocationID] = s_texcoord_1[gl_InvocationID];
	s_tess_texcoord_2[gl_InvocationID] = s_texcoord_2[gl_InvocationID];
	s_tess_texcoord_3[gl_InvocationID] = s_texcoord_3[gl_InvocationID];
	
	s_tess_texcoord_9[gl_InvocationID] = s_texcoord_9[gl_InvocationID];
}
