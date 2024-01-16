#version 430 compatibility

layout(triangles, equal_spacing, ccw) in;

in vec3 position_es[];

vec3 interpolate3D(vec3 v0, vec3 v1, vec3 v2)
{
    return gl_TessCoord.x * v0 + gl_TessCoord.y * v1 + gl_TessCoord.z * v2;
}

void main()
{
	vec3 pos = interpolate3D(position_es[0], position_es[1], position_es[2]);
	gl_Position = vec4(pos, 1.0);
}
