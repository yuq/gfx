#version 460 compatibility

layout(triangles) in;
layout(triangle_strip, max_vertices=3) out;

layout(std430, binding=0) buffer select_data
{
    uint select_result[];
};

in uint select_result_index[];

// true: CCW & cull front, CW & cull back
// false: CCW & cull back, CW & cull front
#define CULLING_CONFIG false
#define ENABLE_BACK_FACE_CULLING

#define NUM_CLIP_PLANES 6
#define MAX_VERTEX (3 + NUM_CLIP_PLANES)

layout(std140, binding=0) uniform settings {
    float depth_scale;
    float depth_transport;
    float _pad0;
    float _pad1;
    vec4 clip_planes[NUM_CLIP_PLANES];
};

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

    /* Use +/0/- to denote the dist[i] sign, which means:
     * +: inside plane
     * -: outside plane
     * 0: just on the plane
     *
     * Some example:
     * ++++: all vertex not clipped
     * ----: all vertex clipped
     * +-++: one vertex clipped, need to insert two vertex at '-', array grow
     * +--+: two vertex clipped, need to insert two vertex at '--', array same
     * +---: three vertex clipped, need to insert two vertex at '---', array trim
     * +-0+: one vertex clipped, need to insert one vertex at '-', array same
     *
     * Plane clip only produce convex polygon, so '-' must be contigous, there's
     * no '+-+-', so one clip plane can only grow array by 1.
     */

    // when array grow or '-' has been replaced with inserted vertex, save the
    // original vert to be used by following calculation.
    vec3 saved;

    int index = 0;
    for (int i = 0; i < num_vert; i++) {
        if (dist[i] >= 0) {
	    // +/0 case, just keep the vert

	    if (index > i) {
	        // array grew case, vert[i] is inserted vertex or prev +/0 vertex
		vec3 tmp = vert[index];
		// current vertex is in 'saved'
		vert[index] = saved;
		// save next vertex
		saved = tmp;
	    } else if (index < i) {
	        // array trim case
	        vert[index] = vert[i];
            }
	    index++;
        } else {
	    // - case, we need to take care of sign change and insert vertex

	    int prev = i == 0 ? num_vert - 1 : i - 1;
	    if (dist[prev] > 0) {
	        // +- case, replace - with inserted vertex
		// assert(index <= i), array is sure to not grow here
		// but need to save vert[i] when index==i
	        saved = vert[i];
	        vert[index++] = get_intersection(vert[prev], vert[i], dist[prev], dist[i]);
	    }

	    int next = i == num_vert - 1 ? 0 : i + 1;
	    if (dist[next] > 0) {
	        // -+ case, may grow array
	        vec3 v;
		if (index > i) {
		    // +-+ case, grow array, current vertex in 'saved'
		    v = saved;
		    // save next + to 'saved', will replace it with inserted vertex
		    saved = vert[index];
		} else {
		    // --+ case, will replace last - with inserted vertex, no need
		    // to save last -, because + case won't use - value.
		    v = vert[i];
		}

		vert[index++] = get_intersection(vert[next], v, dist[next], dist[i]);
	    }
	}
    }
    num_vert = index;
    return false;
}

bool bounding_box_culling(vec3 v0, vec3 v1, vec3 v2)
{
    vec3 minv = min(min(v0, v1), v2);
    vec3 maxv = max(max(v0, v1), v2);
    return any(lessThan(maxv, vec3(-1, -1, -1))) ||
           any(greaterThan(minv, vec3(1, 1, 1)));
}

#ifdef ENABLE_BACK_FACE_CULLING
bool back_face_culling(vec3 v0, vec3 v1, vec3 v2)
{
    float det = (v0.x - v2.x) * (v1.y - v2.y) - (v0.y - v2.y) * (v1.x - v2.x);
    // det < 0 then z points to camera
    return det == 0 || (det < 0 ^^ CULLING_CONFIG);
}
#endif

bool has_nan_or_inf(vec3 v)
{
    return any(isnan(v)) || any(isinf(v));
}

void main(void)
{
    vec3 v1 = gl_in[0].gl_Position.xyz / gl_in[0].gl_Position.w;
    if (has_nan_or_inf(v1)) return;
    vec3 v2 = gl_in[1].gl_Position.xyz / gl_in[1].gl_Position.w;
    if (has_nan_or_inf(v2)) return;
    vec3 v3 = gl_in[2].gl_Position.xyz / gl_in[2].gl_Position.w;
    if (has_nan_or_inf(v3)) return;

#ifdef ENABLE_BACK_FACE_CULLING
    if (back_face_culling(v1, v2, v3))
        return;
#endif

    // fast bounding box based culling for [-1, 1] unit cube
    // this should filter out most primitives
    if (bounding_box_culling(v1, v2, v3))
        return;

    // accurate clipping with all clip planes

    int num_vert = 3;
    vec3 vert[MAX_VERTEX];
    vert[0] = v1;
    vert[1] = v2;
    vert[2] = v3;

    for (int i = 0; i < NUM_CLIP_PLANES; i++) {
        if (clip_with_plane(vert, num_vert, clip_planes[i]))
	    return;
    }

    float dmin = 1, dmax = 0;
    for (int i = 0; i < num_vert; i++) {
        // map [-1, 1] to [near, far] set by glDepthRange(near, far)
        float depth = depth_scale * vert[i].z + depth_transport;

        dmin = min(dmin, depth);
        dmax = max(dmax, depth);
    }

    // map [0, 1] to [0, 0xffffffff]
    uint idmin = uint(4294967295.0 * dmin);
    uint idmax = uint(4294967295.0 * dmax);

    uint i = select_result_index[0];
    // visible
    atomicExchange(select_result[i], 1);
    atomicMin(select_result[i + 1], idmin);
    atomicMax(select_result[i + 2], idmax);
}
