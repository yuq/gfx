#version 150

#extension GL_ARB_gpu_shader5 : enable
#extension GL_ARB_shader_bit_encoding : enable
#extension GL_ARB_sample_shading : enable

uniform vec4 s_depth_range;

uniform vec3 s_material_detail;

in vec4 s_texcoord_0;
in vec4 s_texcoord_1;
in vec4 s_texcoord_2;
in vec4 s_texcoord_3;
in vec4 s_texcoord_4;
in vec4 s_texcoord_5;
in vec4 s_texcoord_6;
in vec4 s_texcoord_7;
in vec4 s_texcoord_8;
in vec4 s_texcoord_9;
in vec4 s_texcoord_10;


out vec4 s_frag_color;
out vec4 s_frag_data_0;
out vec4 s_frag_data_1;
out vec4 s_frag_data_2;
out vec4 s_frag_data_3;

vec4 texture2DAlpha(sampler2D s_texture,vec2 texcoord,float scale) {
	vec4 value = texture(s_texture,texcoord);
	
	return value;
}

vec4 setDeferredDepth(float distance,float volumetric) {
	vec3 deferred;
	distance = sqrt(distance) * 8388608.0;
	deferred.x = floor(distance * (1.0 / 65536.0));
	distance -= deferred.x * 65536.0;
	deferred.y = floor(distance * (1.0 / 256.0));
	distance -= deferred.y * 256.0;
	deferred.z = floor(distance);
	deferred = vec3(127.0,255.0,255.0) - deferred;
	
	return vec4(deferred * (1.0 / 255.0),volumetric);
	
}

vec4 setDeferredColor(vec3 color,float glow) {
	return vec4(color,glow * (1.0 / 16.0));
}

vec4 setDeferredNormal(vec3 normal,float power) {
	return vec4(normal * 0.5 + 0.5,power * (1.0 / 64.0));
}

uniform sampler2D s_texture_0;
uniform sampler2D s_texture_1;
uniform sampler2D s_texture_3;
uniform sampler2D s_texture_4;

uniform vec4 detail_transform;
uniform vec4 diffuse_color;
uniform float specular_power;


void main() {
		
	float distance = length(s_texcoord_1.xyz) * s_depth_range.w;

	s_frag_data_0 = setDeferredDepth(distance,1.0);
	
	vec2 texcoord = s_texcoord_0.xy;
	
	vec4 diffuse = texture2DAlpha(s_texture_0,texcoord,1.0);
	vec3 normal = texture(s_texture_1,texcoord).xyz;
		
	vec2 detail_texcoord = texcoord * detail_transform.xy + detail_transform.zw;
		
	vec4 detail_diffuse = texture(s_texture_3,detail_texcoord);
	vec2 detail_normal = texture(s_texture_4,detail_texcoord).xy;
		
	vec3 blend = s_material_detail * (diffuse.w * detail_diffuse.w);		
		
	diffuse.xyz = clamp(diffuse.xyz + (detail_diffuse.xyz * 2.0 - 1.0) * blend.x,0.0,1.0);
		
	normal.xy = normal.xy + detail_normal * blend.y;
	
	diffuse *= diffuse_color;
	
	normal.z = sqrt(clamp(1.0 - dot(normal.xy,normal.xy),0.0,1.0));
	
	s_frag_data_1 = setDeferredColor(diffuse.xyz,0.0);

	vec3 screen_normal;
	screen_normal.x = dot(s_texcoord_2.xyz,normal);
	screen_normal.y = dot(s_texcoord_3.xyz,normal);
	screen_normal.z = dot(s_texcoord_4.xyz,normal);
	s_frag_data_2 = setDeferredNormal(normalize(screen_normal),specular_power);	
}
