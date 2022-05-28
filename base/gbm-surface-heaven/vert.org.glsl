#version 150

#extension GL_ARB_gpu_shader5 : enable
#extension GL_ARB_shader_bit_encoding : enable

uniform vec3 s_camera_position;
uniform float s_polygon_front;

uniform vec4 s_material_tessellation_factor;
uniform vec3 s_material_tessellation_distance;

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


vec3 getTangentBasis(vec3 basis) {

	return normalize(basis);
	
}


vec4 getPosition(vec4 vertex) {
	
	return vertex;
	
}
	
in vec4 s_attribute_0;
in vec4 s_attribute_1;
in vec4 s_attribute_2;
in vec4 s_attribute_3;
in float s_attribute_4;
	
in vec4 s_attribute_13;
in vec4 s_attribute_14;
in vec4 s_attribute_15;

uniform sampler2D s_texture_16;


uniform vec4 s_instances[96];

	
uniform vec4 base_transform;
	
	
void main() {
		
	vec4 row_0,row_1,row_2;
		
	ivec3 instance = ivec3(gl_InstanceID * 3) + ivec3(0,1,2);
	row_0 = s_instances[instance.x];
	row_1 = s_instances[instance.y];
	row_2 = s_instances[instance.z];		
		
	vec4 position = vec4(s_attribute_0.x,s_attribute_0.y,s_attribute_2.w,1.0);
	vec4 vertex = vec4(dot(row_0,position),dot(row_1,position),dot(row_2,position),1.0);
		
	vec3 normal = getTangentBasis(vec3(dot(row_0.xyz,s_attribute_2.xyz),dot(row_1.xyz,s_attribute_2.xyz),dot(row_2.xyz,s_attribute_2.xyz)));
	vec3 tangent = getTangentBasis(vec3(dot(row_0.xyz,s_attribute_3.xyz),dot(row_1.xyz,s_attribute_3.xyz),dot(row_2.xyz,s_attribute_3.xyz)));
	vec3 binormal = cross(normal,tangent) * s_attribute_3.w;

	vec3 direction = s_attribute_2.xyz;
	float orientation = s_attribute_3.w;

	vec4 texcoord = s_attribute_1;
	texcoord.xy = texcoord.xy * base_transform.xy + base_transform.zw;		
		
	float factor = pow(clamp(1.0 - (length(vertex.xyz - s_camera_position) - s_material_tessellation_distance.x) * s_material_tessellation_distance.y,0.0,1.0),s_material_tessellation_factor.w);
	factor *= textureLod(s_texture_16,texcoord.xy,0.0).x * s_material_tessellation_factor.z;
	s_texcoord_9 = vec4(normal,clamp(factor,1.0,15.0) * 0.5);
		
	normal *= s_polygon_front;
		
	gl_Position = getPosition(vertex);
	s_texcoord_0 = texcoord;
		
	s_texcoord_1.xyz = vec3(tangent.x,binormal.x,normal.x);
	s_texcoord_2.xyz = vec3(tangent.y,binormal.y,normal.y);
	s_texcoord_3.xyz = vec3(tangent.z,binormal.z,normal.z);	
}
