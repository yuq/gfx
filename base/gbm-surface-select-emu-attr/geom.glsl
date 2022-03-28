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

vec4 get_intersection(vec4 v1, vec4 v2, float d1, float d2)
{
    float factor = d1 / (d1 - d2);
    return (1 - factor) * v1 + factor * v2;
}

bool clip_with_plane(inout vec4 vert[MAX_VERTEX], inout int num_vert, vec4 plane)
{
    float dist[MAX_VERTEX];
    for (int i = 0; i < num_vert; i++)
        dist[i] = dot(vert[i], plane);

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
    vec4 saved;

    int index = 0;
    for (int i = 0; i < num_vert; i++) {
        if (dist[i] >= 0) {
	    // +/0 case, just keep the vert

	    if (index > i) {
	        // array grew case, vert[i] is inserted vertex or prev +/0 vertex
		vec4 tmp = vert[index];
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
	        vec4 v;
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
    return num_vert == 0;
}

bool fast_frustum_culling(vec4 v0, vec4 v1, vec4 v2)
{
    return (v0.x + v0.w < 0 && v1.x + v1.w < 0 && v2.x + v2.w < 0) ||
           (v0.x - v0.w > 0 && v1.x - v1.w > 0 && v2.x - v2.w > 0) ||
	   (v0.y + v0.w < 0 && v1.y + v1.w < 0 && v2.y + v2.w < 0) ||
           (v0.y - v0.w > 0 && v1.y - v1.w > 0 && v2.y - v2.w > 0) ||
	   (v0.z + v0.w < 0 && v1.z + v1.w < 0 && v2.z + v2.w < 0) ||
           (v0.z - v0.w > 0 && v1.z - v1.w > 0 && v2.z - v2.w > 0);
}

#ifdef ENABLE_BACK_FACE_CULLING
bool back_face_culling(vec4 v0, vec4 v1, vec4 v2)
{
    float det = v0.x * (v1.y * v2.w - v2.y * v1.w) +
                v1.x * (v2.y * v0.w - v0.y * v2.w) +
                v2.x * (v0.y * v1.w - v1.y * v0.w);

    // invert det once any vertex w < 0
    if (v0.w < 0 ^^ v1.w < 0 ^^ v2.w < 0)
        det = -det;

    // det < 0 then z points to camera
    return det == 0 || (det < 0 ^^ CULLING_CONFIG);
}
#endif

bool has_nan_or_inf(vec4 v)
{
    return any(isnan(v)) || any(isinf(v));
}

void main(void)
{
    vec4 v1 = gl_in[0].gl_Position;
    vec4 v2 = gl_in[1].gl_Position;
    vec4 v3 = gl_in[2].gl_Position;
    if (has_nan_or_inf(v1) || has_nan_or_inf(v2) || has_nan_or_inf(v3))
        return;

#ifdef ENABLE_BACK_FACE_CULLING
    if (back_face_culling(v1, v2, v3))
        return;
#endif

    // fast frustum culling, this should filter out most primitives
    if (fast_frustum_culling(v1, v2, v3))
        return;

    // accurate clipping with all clip planes

    int num_vert = 3;
    vec4 vert[MAX_VERTEX];
    vert[0] = v1;
    vert[1] = v2;
    vert[2] = v3;

    vec4 clip_planes[NUM_CLIP_PLANES];
    clip_planes[0] = vec4(1, 0, 0, 1);
    clip_planes[1] = vec4(-1, 0, 0, 1);
    clip_planes[2] = vec4(0, 1, 0, 1);
    clip_planes[3] = vec4(0, -1, 0, 1);
    clip_planes[4] = vec4(0, 0, 1, 1);
    clip_planes[5] = vec4(0, 0, -1, 1);
    //clip_planes[6] = gl_ClipPlane[0];

    for (int i = 0; i < NUM_CLIP_PLANES; i++) {
        if (clip_with_plane(vert, num_vert, clip_planes[i]))
	    return;
    }

    float depth_scale = (gl_DepthRange.far - gl_DepthRange.near) / 2;
    float depth_transport = (gl_DepthRange.far + gl_DepthRange.near) / 2;

    float dmin = 1, dmax = 0;
    for (int i = 0; i < num_vert; i++) {
        // do perspective division, if w==0, xyz must be 0 too (otherwise can't pass
	// the clip test), 0/0=NaN, but we want it to be the nearest point
        float depth =  vert[i].w == 0 ? -1 : vert[i].z / vert[i].w;

        // map [-1, 1] to [near, far] set by glDepthRange(near, far)
        depth = depth_scale * depth + depth_transport;

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
