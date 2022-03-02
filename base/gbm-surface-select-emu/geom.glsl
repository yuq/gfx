#version 460 compatibility

layout(triangles) in;
layout(triangle_strip, max_vertices=3) out;

in int objIndex[];

layout(std430, binding=0) buffer select_output
{
    uint select_data[];
};

#define NUM_CLIP_PLANES 6
#define MAX_VERTEX (3 + NUM_CLIP_PLANES)

vec3 get_intersection(vec3 v1, vec3 v2, float d1, float d2)
{
    float factor = d1 / (d1 - d2);
    return v1 + (v2 - v1) * factor;
}

bool clip_with_plane(inout vec3 vert[MAX_VERTEX], inout int num_vert, vec4 plane)
{
    bool all_vertex_clipped = true;

    float dist[MAX_VERTEX];
    for (int i = 0; i < num_vert; i++) {
        dist[i] = dot(vec4(vert[i], 1), plane);
	if (dist[i] >= 0)
	    all_vertex_clipped = false;
    }

    if (all_vertex_clipped)
        return true;

    vec3 saved;
    int index = 0;
    for (int i = 0; i < num_vert; i++) {
        if (dist[i] >= 0) {
	    if (index > i) {
	        vec3 tmp = vert[index];
		vert[index] = saved;
		saved = tmp;
	    } else if (index < i) {
	        vert[index] = vert[i];
            }
	    index++;
        } else {
	    int prev = i == 0 ? num_vert - 1 : i - 1;
	    // plane cross adjacent vertex
	    if (dist[prev] > 0) {
	        saved = vert[i];
	        vert[index++] = get_intersection(vert[prev], vert[i], dist[prev], dist[i]);
	    }

	    int next = i == num_vert - 1 ? 0 : i + 1;
	    if (dist[next] > 0) {
	        vec3 v;
		if (index > i) {
		    v = saved;
		    saved = vert[index];
		} else
		    v = vert[i];

		vert[index++] = get_intersection(vert[next], v, dist[next], dist[i]);
	    }
	}
    }
    num_vert = index;
    return false;
}

void main(void)
{
    vec3 vert[MAX_VERTEX];
    vert[0] = gl_in[0].gl_Position.xyz / gl_in[0].gl_Position.w;
    vert[1] = gl_in[1].gl_Position.xyz / gl_in[1].gl_Position.w;
    vert[2] = gl_in[2].gl_Position.xyz / gl_in[2].gl_Position.w;

    int num_vert = 3;

    // static clip planes
    if (clip_with_plane(vert, num_vert, vec4( 1, 0, 0, 1))) return;
    if (clip_with_plane(vert, num_vert, vec4(-1, 0, 0, 1))) return;
    if (clip_with_plane(vert, num_vert, vec4(0,  1, 0, 1))) return;
    if (clip_with_plane(vert, num_vert, vec4(0, -1, 0, 1))) return;
    if (clip_with_plane(vert, num_vert, vec4(0, 0,  1, 1))) return;
    if (clip_with_plane(vert, num_vert, vec4(0, 0, -1, 1))) return;
    // user clip planes

    float dmin = 1, dmax = -1;
    for (int i = 0; i < num_vert; i++) {
        dmin = min(dmin, vert[i].z);
        dmax = max(dmax, vert[i].z);
    }

    uint idmin = 0x80000000 + int(dmin * 2147483648.0);
    uint idmax = 0x80000000 + int(dmax * 2147483648.0);

    int i = objIndex[0] * 3;
    // visible
    atomicExchange(select_data[i], 1);
    atomicMin(select_data[i + 1], idmin);
    atomicMax(select_data[i + 2], idmax);
}
