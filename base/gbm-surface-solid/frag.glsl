#version 330 compatibility
#define SHADER_VER330
#define SHADER_3DMODEL33
#define SYSTEM_DRAW_BUFFERS_BLEND
#define SHADER_QUAD
#define SHADER_FRINGE_CENTROID_TOP
#define SHADER_FRINGE_FILTERING_NEAREST
#define SHADER_FILL
#define SHADER_LIGHT
#define SHADER_STL_MATERIAL
#define SHADER_ALPHA_TEST_OPAQUE
#extension GL_ARB_gpu_shader5 : enable
#extension GL_ARB_shading_language_420pack : require
#extension GL_ARB_explicit_uniform_location : require
#extension GL_ARB_shading_language_packing : enable
#ifndef TYPEDEFS_GLSL_H
#define TYPEDEFS_GLSL_H

#define FLAT_ATTR flat

#define RED          vec3( 1.0, 0.0, 0.0 )
#define YELLOW       vec3( 1.0, 1.0, 0.0 )
#define GREEN        vec3( 0.0, 1.0, 0.0 )
#define CYAN         vec3( 0.0, 1.0, 1.0 )
#define BLUE         vec3( 0.0, 0.0, 1.0 )
#define MAGENTA      vec3( 1.0, 0.0, 1.0 )
#define WHITE        vec3( 1.0, 0.0, 0.0 )
#define BLACK        vec3( 0.0, 0.0, 0.0 )

// GLSL utility
#if (defined(GL_ARB_gpu_shader5) || __VERSION__ >= 400) && !defined(SYSTEM_DISABLE_FMA)
    #define beta_fma(a, b, c) fma(a, b, c)
#else 
  	#define beta_fma(a, b, c) (a * b + c) 
#endif

#if defined(SHADER_USE_SEC_COLOR)
	#define fSided vec2
#else //!SHADER_USE_SEC_COLOR
	#define fSided float
#endif //SHADER_USE_SEC_COLOR

#if defined(SHADER_3DMODEL) || defined(SHADER_3DMAPPING)
	uniform vec3 ax_p;
	uniform vec3 ax_s;
	uniform vec3 ax_t;
#elif defined(SHADER_3DMODEL33) || defined(SHADER_3DMAPPING33)
	#define ax_p vec3( 1., .0, .0)
	#define ax_s vec3( .0, 1., .0)
	#define ax_t vec3( .0, .0, 1.)
#endif

#define TwoTimes(_PROC_) {_PROC_}{_PROC_}

// GS Settings
#if defined(SHADER_QUAD) 
	#if defined(SHADER_SECOND_ORDER) 
		#define SHADER_QUAD8
	#else
		#define SHADER_QUAD4
	#endif
#elif !defined(SHADER_POLYGON)
	#if defined(SHADER_SECOND_ORDER) 
		#define SHADER_TRIA6
	#else
		#define SHADER_TRIA3
	#endif
#endif

#if defined(SHADER_3DMODEL33)
#define GS_TRIA3_MAXVERT 3
#define GS_QUAD4_MAXVERT 4
#define GS_TRIA6_MAXVERT 8
#define GS_QUAD8_MAXVERT 5
#define GS_POLYGON_PATCH_MAXVERT 4
#define TRIA3_TRUE_VERTICES 3
#define QUAD4_TRUE_VERTICES 4
#define TRIA6_TRUE_VERTICES 6
#define QUAD8_TRUE_VERTICES 8
#elif defined(SHADER_3DMAPPING33)
#define GS_TRIA3_MAXVERT 36
#define GS_QUAD4_MAXVERT 48
#define GS_TRIA6_MAXVERT 96
#define GS_QUAD8_MAXVERT 96
#define GS_POLYGON_PATCH_MAXVERT 96
#endif

#if defined(SHADER_TRIA3)
#define GS_MAXVERT GS_TRIA3_MAXVERT
#define TRUE_VERTICES TRIA3_TRUE_VERTICES
#elif defined(SHADER_QUAD4)
#define GS_MAXVERT GS_QUAD4_MAXVERT
#define TRUE_VERTICES QUAD4_TRUE_VERTICES
#elif defined(SHADER_TRIA6)
#define GS_MAXVERT GS_TRIA6_MAXVERT
#define TRUE_VERTICES TRIA6_TRUE_VERTICES
#elif defined(SHADER_SECOND_ORDER)
#define GS_MAXVERT GS_QUAD8_MAXVERT
#define TRUE_VERTICES QUAD8_TRUE_VERTICES
#elif defined(SHADER_POLYGON)
#define GS_MAXVERT GS_POLYGON_PATCH_MAXVERT
#endif

// Constants
const float PI = 3.14159265358979323846;

const vec2 VHALF =  vec2(0.5, 0.5);
const vec2 VONE  =  vec2(1.0, 1.0);
const vec2 VTWO  =  vec2(2.0, 2.0);
const vec3 V3HALF =  vec3(0.5, 0.5, 0.5);
const vec3 V3ONE  =  vec3(1.0, 1.0, 1.0);
const vec3 V3TWO  =  vec3(2.0, 2.0, 2.0);

const ivec2 IVZERO = ivec2(0, 0);
const ivec2 IVONE  = ivec2(1, 1);

const vec4 GRAY = vec4(0.5, 0.5, 0.5, 1.0);

const float FLT_MAX = 3.402823466e+38;

#endif /* TYPEDEFS_GLSL_H */



#ifndef MK_UNIFORMS_HPP
#define MK_UNIFORMS_HPP   

/*
 * This file is shared between C++ and GLSL.
 * Every change here will automatically be visible to shaders too!
 * Therefore, care should be taken to have code that is valid both in C++ and GLSL
 *
 */

#ifdef __cplusplus
#include "gm/gm_point.hpp"
#include "gm/gm_matrix.hpp"
#endif // __cplusplus

#ifdef __cplusplus
namespace mk 
{
#endif // __cplusplus

#ifdef __cplusplus
typedef gm::math::vec4f_t vec4;
typedef gm::math::int4_t ivec4;
typedef gm::math::uint4_t uvec4;
typedef gm::math::vec2f_t vec2;
typedef gm::math::int2_t ivec2;
typedef gm::math::uint2_t uvec2;
typedef gm::math::mat4f_t mat4; 
#endif //__cplusplus

#ifndef __cplusplus
#define static_assert(a, b)
#endif

#define MK_NUM_DIR_LIGHTS 4

// all lighting is done in view space so 
// direction, position of lights must be in view space

struct DirectionalLight
{
    vec4 direction; // 4N 
    int   status; // 1N
    float diffuse_intensity; // 1N
    float specular_intensity; // 1N
    int   casts_shadow; // 1N
};

struct PointLight
{
    vec4 position; // 4N
    int   status; // 1N
    float diffuse_intensity; // 1N
    float specular_intensity; // 1N

    float constant; // 1N
    float linear; // 1N
    float quadratic; // 1N
    vec2 pad0; // 2N
};

struct SpotLight
{
    vec4 position; // 4N
    vec4 direction; // 4N
    int     status; // 1N
    float   diffuse_intensity; // 1N
    float   specular_intensity; // 1N
    float   cutoff; // 1N
    float   outer_cutoff; // 1N

    float   constant; // 1N
    float   linear; // 1N
    float   quadratic; // 1N
};

struct Camera
{
    vec4   camera_position; // world space 4N
	float  tnear; // 1N
	float  tfar; // 1N
	vec2   pad0; // 2N
};

struct ShadowLightData
{
    mat4 dir_lights_view_matrix[MK_NUM_DIR_LIGHTS];
    mat4 dir_lights_projection_matrix[MK_NUM_DIR_LIGHTS];
    mat4 idir_lights_view_matrix[MK_NUM_DIR_LIGHTS];
};

struct UniformGlobals
{
    mat4  projection_matrix;
    mat4  view_matrix;
	mat4  view_projection_matrix;
    mat4  iprojection_matrix;
    mat4  iview_matrix;
	mat4  iview_projection_matrix;
	mat4  tr_iview_matrix;

	// These are the uniforms required for Single Pass Stereo.
	// TODO i.kapouranis: When all shaders move to GLSL 3.3, move all of them into a struct as commented.
	// This will help with logical grouping and code maintainability.
	// struct SinglePassStereo {
	mat4  right_view_matrix;
	mat4  right_projection_matrix;
	mat4  right_view_right_projection_matrix;
	mat4  iright_view_matrix;
	mat4  iright_projection_matrix;
	mat4  iright_view_right_projection_matrix;
	// } sps;

	ShadowLightData shadow_light_data;
	
    vec4  viewport; // zw 
	vec4  ambient_intensity;
	Camera camera;
	DirectionalLight   dir_lights[MK_NUM_DIR_LIGHTS]; // 8N * 4 = 32N
    PointLight         point_light; // 12N * 1 = 12N
    SpotLight          spot_light; // 16N * 1 = 16N
    vec4  contour_fringe_params;
    mat4  envmap_imv_matrix;
    mat4  envmap_sky_model_matrix;
    mat4  envmap_floor_model_matrix;
    vec4  envmap_yoffset; // x contains the skybox, y contains the floor
    vec4  wboit_constants;
    vec4  fringe_specular; // x = specular, y = noval blend factor
    vec4  scalar_fringe_paranom;
    vec4  scalar_fringe_limits;
    vec4  vector_fringe_paranom;
    vec4  vector_fringe_limits;
    vec4  clip_planes[8];
	vec4  background_color;
	vec4  novalue_color_mode;
	vec4  thick_shells_scale; // vec4 only for 1 value
	vec4  mesh_lines_color_width; // xyz = color, w = width
	vec4  contour_line_plot_width_factor; // vec4 only for r value
	vec4  ent_mode_top_color;
	vec4  ent_mode_bottom_color;
	vec4  inactive_color_baseline; // contains the rgba value that colors will be compared against for inactive state
	vec4  variable_light_color_baseline; // contains the rgb value that colors will be compared against for variable lighting, a stores the packed (r,g,b,0) value

	vec4 shadows_bias_intensity; // x contains the bias, y: contains the intensity

	// TODO MK KATRASD add uniforms from SSAO here
};

struct STLMaterialData // 3 vec4
{
    vec4 diffuse;
    vec4 ambient;
    vec4 specular;
    // specular.w stores the hardness
};
#ifdef __cplusplus
static_assert(sizeof(STLMaterialData) % sizeof(vec4) == 0, "");
#endif

struct PBRMaterialData // 3 vec4
{
    vec4 albedo;
    float   metallic;
    float   roughness;
    vec2 pad0; // by the driver
    vec4 pad1;
};
#ifdef __cplusplus
static_assert(sizeof(PBRMaterialData) % sizeof(vec4) == 0, "");
#endif

struct MaterialTextureData // 2 vec4
{
    vec2 tex_scale;
    vec2 tex_offset;
    float   tex_rotation;
    int map_type;
	int specular_texture_exists;
	int normal_texture_exists;
};
#ifdef __cplusplus
static_assert(sizeof(MaterialTextureData) % sizeof(vec4) == 0, "");
#endif

struct LICData
{
    float highPassBegin;
    float highPassEnd;
    float lowPassBegin;
    float lowPassEnd;
    vec4 origFact;
    float base_scale;
    float precOrderAdj;
    float baseCLvl;
    float bottomCLvl;
    float refPx;
    int qRes;
    vec2 wRes;
};
#ifdef __cplusplus
static_assert(sizeof(LICData) % sizeof(vec4) == 0, "");
#endif

// !!! this should be the same size as the PidUniformDataPBR
struct PidUniformDataSTL
{
    mat4 explode_matrix;
	STLMaterialData material_data; 
    MaterialTextureData material_texture_data; // dummy
    LICData lic_data;
	int clip; // 8 bit flag that says what clip planes can cut the pid
	int front_face; // 1 is ccw, -1 is cw
    float pad[10];
};

struct PidUniformDataPBR
{
    mat4 explode_matrix;
    PBRMaterialData material_data;
    MaterialTextureData material_texture_data;
    LICData lic_data;
	int clip; // 8 bit flag that says what clip planes can cut the pid
	int front_face; // 1 is ccw, -1 is cw
    float pad[10];
};

#ifdef __cplusplus
union PidUniformData
{
	PidUniformDataPBR p;
	PidUniformDataSTL s;
};
#endif

struct StreamlineUniformData
{
	mat4 explode;
	ivec4 steps;
	vec4 angle; // x: cosTheta, y: sinTheta
	vec4 radius; // x: slset_radius, y: slset_modul_radius
	vec4 width; // x: ribbon_width
	vec4 color;
	vec4 specular; // rgb: specular a: shininess
	vec4 object_min_vector;
	uvec4 clip;
	ivec4 explode_has_negative_determinant;
	vec4 locked_scalar_fringe_paranom;
	vec4 locked_scalar_fringe_limits;
	vec4 padding;
};

struct ModelUniformData
{
	vec4 clip_planes[8];
	vec4 blur_scale_factor;
	float pad[28];	
};


#ifdef __cplusplus
static_assert(sizeof(UniformGlobals) <= 16384, 
		"Uniform globals block must not exceed the minimum ubo block size of the spec");
static_assert(sizeof(STLMaterialData) == sizeof(PBRMaterialData), 
		"PBRMaterialData and STLMaterialData must be interchangeable and of the same size");
static_assert(sizeof(PidUniformDataSTL) == sizeof(PidUniformDataPBR),
		"PidUniformDataPBR and PidUniformDataSTL must be interchangeable and of the same size");
static_assert(sizeof(PidUniformDataSTL) == 256, "");
static_assert(sizeof(StreamlineUniformData) == 256, "");
static_assert(sizeof(ModelUniformData) == 256, "");
#endif

#ifdef __cplusplus
} // namespace mk
#endif // __cplusplus

#endif /* MK_UNIFORMS_HPP */


#ifndef MK_SHADER_LOCATIONS_GLSL_H
#define MK_SHADER_LOCATIONS_GLSL_H   

/* Location defines for uniforms and attributes 
 * Grouped by shader 
 */

/******* GLOBAL **********/

// uniform buffers
#define SHADER_GLOBAL_BUFFER_BINDING 0
#define SHADER_MODEL_BUFFER_BINDING 1

// samplers
#define SHADER_TU_FRAG_EMPTY 0

/******* END GLOBAL ***********/


/******* 3DMODEL33 ************/

// input attributes
#define SHADER_3DMODEL33_POSITION_ATTRIB_LOC 0
#define SHADER_3DMODEL33_FRINGE_NODE_TOP_ATTRIB_LOC 1
#define SHADER_3DMODEL33_FRINGE_NODE_BOTTOM_ATTRIB_LOC 2
#define SHADER_3DMODEL33_VELOCITY_COLOR_ATTRIB_LOC 3
#define SHADER_3DMODEL33_LIC_VECTORS_ATTRIB_LOC 4
#define SHADER_3DMODEL33_TEX_COORDS_ATTRIB_LOC 5
#define SHADER_3DMODEL33_NODAL_NORMALS_ATTRIB_LOC 6
#define SHADER_3DMODEL33_NODAL_NORMALS_3F_ATTRIB_LOC 7
#define SHADER_3DMODEL33_NODAL_COLOR_ATTRIB_LOC 8
#define SHADER_3DMODEL33_EXTRA_THICKNESS_ATTRIB_LOC 9
#define SHADER_3DMODEL33_EXTRA_THICKNESS_INTERNAL_EDGE_MASK_ATTRIB_LOC 10
#define SHADER_3DMODEL33_NODAL_THICKNESS_ATTRIB_LOC 11
#define SHADER_3DMODEL33_EXTRA_VARIABLE_COLOR_ATTRIB_LOC 12
#define SHADER_3DMODEL33_PER_DRAW_DATA_ATTRIB_LOC 13

// uniforms
#define SHADER_3DMODEL33_ELEM_OFFSET_UNIFORM_LOC 0
#define SHADER_3DMODEL33_SELECTION_HIGHLIGHT_COLOR_UNIFORM_LOC 1
#define SHADER_3DMODEL33_SHADOW_DIR_LIGHT_LOC 2

// samplers
#define SHADER_3DMODEL33_TU_FRAG_BEGIN_FIXED SHADER_TU_FRAG_EMPTY
#define SHADER_3DMODEL33_TU_FRAG_FRINGE_BAR_BINDING 1
#define SHADER_3DMODEL33_TU_FRAG_IBL_IRRADIANCE_BINDING 2
#define SHADER_3DMODEL33_TU_FRAG_IBL_PREFILTER_BINDING 3
#define SHADER_3DMODEL33_TU_FRAG_IBL_BRDF_LUT_BINDING  4
#define SHADER_3DMODEL33_TU_FRAG_RENDER_TEXTURE_ALBEDO_BINDING 5
#define SHADER_3DMODEL33_TU_FRAG_RENDER_TEXTURE_SPECULAR_BINDING 6
#define SHADER_3DMODEL33_TU_FRAG_RENDER_TEXTURE_NORMAL_BINDING 7
#define SHADER_3DMODEL33_TU_FRAG_OIT_BINDING 8
#define SHADER_3DMODEL33_TU_FRAG_SSAO_BINDING 9
#define SHADER_3DMODEL33_TU_FRAG_MIRROR_BINDING 10
#define SHADER_3DMODEL33_TU_FRAG_SHADOW_DIR_MAP_BINDING 11
#define SHADER_3DMODEL33_TU_FRAG_END_FIXED 12

#define SHADER_3DMODEL33_TU_GEOM_BEGIN_FIXED SHADER_3DMODEL33_TU_GEOM_VISIBILITY_BINDING
#define SHADER_3DMODEL33_TU_GEOM_VISIBILITY_BINDING 16
#define SHADER_3DMODEL33_TU_GEOM_ELEM_FUNC_TOP_BINDING 17
#define SHADER_3DMODEL33_TU_GEOM_ELEM_FUNC_BOTTOM_BINDING 18
#define SHADER_3DMODEL33_TU_GEOM_NORMALS_BINDING 19
#define SHADER_3DMODEL33_TU_GEOM_COLOR_VARIANCE_BINDING 20
#define SHADER_3DMODEL33_TU_GEOM_QUAD8_MIDDLE_NODES_BINDING 21
#define SHADER_3DMODEL33_TU_GEOM_THICKNESS_BINDING 22
#define SHADER_3DMODEL33_TU_GEOM_THICKNESS_ONFEATURE_BINDING 23
#define SHADER_3DMODEL33_TU_GEOM_THICKNESS_Z_OFFSET_BINDING 24
#define SHADER_3DMODEL33_TU_GEOM_END_FIXED 25

// uniform buffers
#define SHADER_3DMODEL33_PER_PID_BUFFER_BINDING 2

/********* END 3DMODEL33 ******************/




/********* 3DMODEL33_FEATURELINES ****************/

// input attributes
#define SHADER_3DMODEL33_FEATURE_LINES_POSITION_ATTRIB_LOC 0
#define SHADER_3DMODEL33_FEATURE_LINES_FRINGE_NODE_TOP_ATTRIB_LOC 1
#define SHADER_3DMODEL33_FEATURE_LINES_PER_DRAW_DATA_ATTRIB_LOC 2
#define SHADER_3DMODEL33_FEATURE_LINES_NODAL_COLOR_ATTRIB_LOC 8

// uniforms
#define SHADER_3DMODEL33_FEATURE_LINES_SELECTION_HIGHLIGHT_COLOR_UNIFORM_LOC 1

// samplers
#define SHADER_3DMODEL33_FEATURE_LINES_TU_FRAG_FRINGE_BAR_BINDING 1

// uniform buffers
#define SHADER_3DMODEL33_FEATURE_LINES_PER_PID_BUFFER_BINDING 2

/********* 3DMODEL33_FEATURELINES ****************/


/******** STREAMLINES  ********************/

// input attributes
#define SHADER_STREAMLINE_POINT_ATTRIB_LOC 0
#define SHADER_STREAMLINE_FRINGE_ATTRIB_LOC 1
#define SHADER_STREAMLINE_RADIUS_OR_LENGTH_ATTRIB_LOC 2
#define SHADER_STREAMLINE_DIRECTION_ATTRIB_LOC 3
#define SHADER_STREAMLINE_COLOR_ATTRIB_LOC 4
#define SHADER_STREAMLINE_ORIENTATION_ATTRIB_LOC 5

// uniforms
#define SHADER_STREAMLINE_SLSET_COLOR_UNIFORM_LOC 0

// uniform buffers
#define SHADER_STREAMLINE_SLSET_BUFFER_BINDING 2

// samplers
#define SHADER_STREAMLINE_TU_FRAG_FRINGE_BAR_BINDING 1


/******** STREAMLINES  ********************/

/******** SPRITE_SPHERES  ********************/

// input attributes
#define SHADER_SPRITE_SPHERES_POSITION_ATTRIB_LOC 0
#define SHADER_SPRITE_SPHERES_FRINGE_CENTROID_TOP_ATTRIB_LOC 1
#define SHADER_SPRITE_SPHERES_VARIABLE_VISIBILITY_ATTRIB_LOC 2
#define SHADER_SPRITE_SPHERES_VARIABLE_COLOR_ATTRIB_LOC 3
#define SHADER_SPRITE_SPHERES_OLD_COLOR_ATTRIB_LOC 4
#define SHADER_SPRITE_SPHERES_OLD_COLOR_SEC_ATTRIB_LOC 5
#define SHADER_SPRITE_SPHERES_OLD_RADIUS_ATTRIB_LOC 6
#define SHADER_SPRITE_SPHERES_OLD_TEXTURE_COORD_ATTRIB_LOC 7

// uniforms
#define SHADER_SPRITE_SPHERES_MIN_MAX_VALUE_UNIFORM_LOC 0
#define SHADER_SPRITE_SPHERES_RADIUS_UNIFORM_LOC 1
#define SHADER_SPRITE_SPHERES_WIN_SCALE_UNIFORM_LOC 2
#define SHADER_SPRITE_SPHERES_WIN_WIDTH_UNIFORM_LOC 3

// samplers
#define SHADER_SPRITE_SPHERES_TU_FRAG_BEGIN_FIXED SHADER_TU_FRAG_EMPTY
#define SHADER_SPRITE_SPHERES_TU_FRAG_FRINGE_BAR_BINDING 1
#define SHADER_SPRITE_SPHERES_TU_FRAG_OIT_BINDING 2
#define SHADER_SPRITE_SPHERES_TU_FRAG_END_FIXED 3

// uniform buffers
#define SHADER_SPRITE_SPHERES_PER_PID_BUFFER_BINDING 2

/******** SPRITE_SPHERES ********************/

/******** WATERLIKE  ********************/

// input attributes
#define SHADER_WATERLIKE_POSITION_ATTRIB_LOC 0
#define SHADER_WATERLIKE_RADIUS_ATTRIB_LOC 1
#define SHADER_WATERLIKE_SCALAR_ATTRIB_LOC 2
#define SHADER_WATERLIKE_VISIBLE_ATTRIB_LOC 3

// uniforms
#define SHADER_WATERLIKE_EXPLODE_MODEL_MATRIX_LOC 0
#define SHADER_WATERLIKE_CLONE_MODEL_MATRIX_LOC 1
#define SHADER_WATERLIKE_FLIP_LOC 2
#define SHADER_WATERLIKE_THICK_TRANSPARENT_LOC 3
#define SHADER_WATERLIKE_SILHOUETTE_LOC 4
#define SHADER_WATERLIKE_VR_FACTOR_LOC 5
#define SHADER_WATERLIKE_CLIP_NUM_LOC 6

// samplers
#define SHADER_WATERLIKE_TU_FRAG_BEGIN_FIXED SHADER_TU_FRAG_EMPTY
#define SHADER_WATERLIKE_TU_FRAG_FRINGE_TEX 1
#define SHADER_WATERLIKE_TU_FRAG_IBL_IRRADIANCE_BINDING 2
#define SHADER_WATERLIKE_TU_FRAG_IBL_PREFILTER_BINDING 3
#define SHADER_WATERLIKE_TU_FRAG_IBL_BRDF_LUT_BINDING  4
#define SHADER_WATERLIKE_TU_FRAG_SCALAR_TEX 5
#define SHADER_WATERLIKE_TU_FRAG_NORMAL_TEX 6
#define SHADER_WATERLIKE_TU_FRAG_DEPTH_TEX 7
#define SHADER_WATERLIKE_TU_FRAG_OIT_BINDING 8
#define SHADER_WATERLIKE_TU_FRAG_SSAO_BINDING 9
#define SHADER_WATERLIKE_TU_FRAG_SCALAR_UPDATE_TEX 10
#define SHADER_WATERLIKE_TU_FRAG_ENV_TEX 11
#define SHADER_WATERLIKE_TU_FRAG_THICK_TEX 12
#define SHADER_WATERLIKE_TU_FRAG_UPDATE_TEX 13
#define SHADER_WATERLIKE_TU_FRAG_THICK_UPDATE_TEX 14

// uniform buffers
#define SHADER_WATERLIKE_PER_PID_BUFFER_BINDING 2

/******** WATERLIKE  ********************/

/******** GENERIC OBJECT ********************/

// input attributes
#define SHADER_GENERIC_OBJECT_POSITION_ATTRIB_LOC 0
#define SHADER_GENERIC_OBJECT_TEX_COORDS_ATTRIB_LOC 1
#define SHADER_GENERIC_OBJECT_NORMALS_ATTRIB_LOC 2

// uniforms
#define SHADER_GENERIC_OBJECT_SCALE_LOC 0
#define SHADER_GENERIC_OBJECT_TRANSFORM_LOC 1
#define SHADER_GENERIC_OBJECT_HAS_TEXTURE_LOC 2
#define SHADER_GENERIC_OBJECT_HAS_NORMALS_LOC 3
#define SHADER_GENERIC_OBJECT_COLOR_LOC 4
#define SHADER_GENERIC_OBJECT_LIGHTING_FACTOR_LOC 5
#define SHADER_GENERIC_OBJECT_ALPHA_TEST_THRESHOLD_LOC 6

// samplers
#define SHADER_GENERIC_OBJECT_TU_FRAG_BEGIN_FIXED SHADER_TU_FRAG_EMPTY
#define SHADER_GENERIC_OBJECT_TU_FRAG_COLOR_BINDING 1
#define SHADER_GENERIC_OBJECT_TU_FRAG_MASK_BINDING 2
#define SHADER_GENERIC_OBJECT_TU_FRAG_BAKED_AO_BINDING 3

/******** GENERIC OBJECT ********************/

/******** ANNOTATION ORIENTED QUAD ********************/

// input attributes

// uniforms
#define SHADER_ANNOTATION_ORIENTED_QUAD_LINE_WIDTH_LOC 0
#define SHADER_ANNOTATION_ORIENTED_QUAD_VIEWPORT_LOC 1

// samplers

/******** ANNOTATION ORIENTED QUAD ********************/

/******** FEATURE LINES HASH ********************/
// input attributes

// uniforms
#define SHADER_FEATURE_LINES_HASH_FACES_NUM_LOC 0
#define SHADER_FEATURE_LINES_HASH_BUCKETS_NUM_LOC 1
#define SHADER_FEATURE_LINES_HASH_TRIANGLES_NUM_LOC 2
#define SHADER_FEATURE_LINES_HASH_QUADS_NUM_LOC 3
#define SHADER_FEATURE_LINES_HASH_TRIA6_NUM_LOC 4
#define SHADER_FEATURE_LINES_HASH_QUAD8_NUM_LOC 5
#define SHADER_FEATURE_LINES_HASH_GLOBAL_INVOCATION_OFFSET_LOC 6

// shader storage buffers
#define SHADER_FEATURE_LINES_HASH_INDICES_BINDING 0
#define SHADER_FEATURE_LINES_HASH_FIRST_BINDING 1
#define SHADER_FEATURE_LINES_HASH_NEXT_BINDING 2
/******** FEATURE LINES HASH ********************/

/******** FEATURE LINES CALC ********************/
// input attributes

// uniforms
#define SHADER_FEATURE_LINES_CALC_RAD_ANGLE_LOC 0
#define SHADER_FEATURE_LINES_CALC_BUCKETS_NUM_LOC 1
#define SHADER_FEATURE_LINES_CALC_TRIANGLES_NUM_LOC 2
#define SHADER_FEATURE_LINES_CALC_QUADS_NUM_LOC 3
#define SHADER_FEATURE_LINES_CALC_TRIA6_NUM_LOC 4
#define SHADER_FEATURE_LINES_CALC_QUAD8_NUM_LOC 5
#define SHADER_FEATURE_LINES_CALC_POLYGON_PATCHES_NUM_LOC 6
#define SHADER_FEATURE_LINES_CALC_PROPERTIES_COUNT_LOC 7
#define SHADER_FEATURE_LINES_CALC_FEATURE_LINES_AT_COUNTER_LOC 7
#define SHADER_FEATURE_LINES_CALC_GLOBAL_INVOCATION_OFFSET_LOC 8

// shader storage buffers
#define SHADER_FEATURE_LINES_CALC_FEATURE_LINES_BINDING 0
#define SHADER_FEATURE_LINES_CALC_POSITIONS_BINDING 1
#define SHADER_FEATURE_LINES_CALC_INDICES_BINDING 2
#define SHADER_FEATURE_LINES_CALC_FIRST_BINDING 3
#define SHADER_FEATURE_LINES_CALC_NEXT_BINDING 4
#define SHADER_FEATURE_LINES_CALC_PROP_RANGES_BINDING 5
#define SHADER_FEATURE_LINES_CALC_FL_RANGES_BINDING 6
/******** FEATURE LINES CALC ********************/

/******** VR RAY ********************************/

// input attributes
#define SHADER_VR_RAY_POSITION_ATTRIB_LOC 0
#define SHADER_VR_RAY_TEX_COORDS_ATTRIB_LOC 1

// uniforms
#define SHADER_VR_RAY_SCALE_LOC 0 
#define SHADER_VR_RAY_V_COORD_SCALE_LOC 1
#define SHADER_VR_RAY_TRANSFORM_LOC 2
#define SHADER_VR_RAY_COLOR_LOC 3
#define SHADER_VR_RAY_V_COORD_OFFSET_HIGHTLIGHT_LOC 4

// samplers
#define SHADER_VR_RAY_TU_FRAG_BEGIN_FIXED SHADER_TU_FRAG_EMPTY
#define SHADER_VR_RAY_TU_FRAG_HIGHLIGHT_BINDING 1

/******** VR RAY ********************************/

/******** OIT COMPOSE ********************************/

// samplers
#define SHADER_OIT_COMPOSE_TU_FRAG_PEEL_BINDING 0
#define SHADER_OIT_COMPOSE_TU_FRAG_WB_ACCUM_BINDING 0
#define SHADER_OIT_COMPOSE_TU_FRAG_WB_REVEAL_BINDING 1
// uniforms
#define SHADER_OIT_COMPOSE_SAMPLE_IDX_UNIFORM_LOC 0

/******** OIT COMPOSE ********************************/

/******** DYNAMIC LABELLING SAT **********************/

// uniforms
#define SHADER_DYNAMIC_LABELLING_SAT_SCREEN_SIZE_UNIFORM_LOC 0
#define SHADER_DYNAMIC_LABELLING_SAT_HORIZONTAL_UNIFORM_LOC 1
#define SHADER_DYNAMIC_LABELLING_SAT_STEP_UNIFORM_LOC 2
#define SHADER_DYNAMIC_LABELLING_SAT_LAST_STEP_UNIFORM_LOC 3

// samplers
#define SHADER_DYNAMIC_LABELLING_SAT_TU_FRAG_OCCUPANCY_BINDING SHADER_TU_FRAG_EMPTY

/******** DYNAMIC LABELLING SAT **********************/

/******** DYNAMIC LABELLING CONTRIB ******************/

// uniforms
#define SHADER_DYNAMIC_LABELLING_CONTRIB_SCREEN_SIZE_UNIFORM_LOC 0
#define SHADER_DYNAMIC_LABELLING_CONTRIB_ANCHOR_COORDS_UNIFORM_LOC 1
#define SHADER_DYNAMIC_LABELLING_CONTRIB_PREV_COORDS_UNIFORM_LOC 2
#define SHADER_DYNAMIC_LABELLING_CONTRIB_ANNOT_SIZE_UNIFORM_LOC 3
#define SHADER_DYNAMIC_LABELLING_CONTRIB_SENSITIVITY_LIMITS_UNIFORM_LOC 4
#define SHADER_DYNAMIC_LABELLING_CONTRIB_CHECK_DISTANCE_UNIFORM_LOC 5

// samplers
#define SHADER_DYNAMIC_LABELLING_CONTRIB_TU_FRAG_OCCUPANCY_BINDING SHADER_TU_FRAG_EMPTY
#define SHADER_DYNAMIC_LABELLING_CONTRIB_TU_FRAG_SAT_BINDING 1

/******** DYNAMIC LABELLING CONTRIB ******************/

/******** DYNAMIC LABELLING MATRIX REDUCTION  ********/

// uniforms
#define SHADER_DYNAMIC_LABELLING_MATRIX_REDUCTION_HORIZONTAL_UNIFORM_LOC 0
#define SHADER_DYNAMIC_LABELLING_MATRIX_REDUCTION_STEP_UNIFORM_LOC 1
#define SHADER_DYNAMIC_LABELLING_MATRIX_REDUCTION_FIRST_ITERATION_UNIFORM_LOC 2

// samplers
#define SHADER_DYNAMIC_LABELLING_MATRIX_REDUCTION_TU_FRAG_CONTRIB_BINDING SHADER_TU_FRAG_EMPTY

/******** DYNAMIC LABELLING MATRIX REDUCTION  ********/

#endif /* MK_SHADER_LOCATIONS_GLSL_H */


// 1. Provide software implementations for built-in functions of GL_ARB_shading_language_packing
// Our shaders enable this extension by default but some drivers might not support it
// 2. Provide normal spherical packing functions

#if !defined(GL_ARB_shading_language_packing)

int convert_uint8_to_int8(uint v)
{
	return (v <= 127u) ? int(v) : (int(v)-256);
}

uint convert_int8_to_uint8(int v)
{
	return (v >= 0) ? uint(v) : uint(v+256);
}

int convert_uint16_to_int16(uint v) 
{
	return (v <= 32767u) ? int(v) : (int(v)-65536);
}

uint pack_snorm_4x8(vec4 p)
{
    p = clamp(p, vec4(-1.0), vec4(1.0)) * 127.0;
	uvec4 uv;
	uv.x = convert_int8_to_uint8(int(p.x));
	uv.y = convert_int8_to_uint8(int(p.y));
	uv.z = convert_int8_to_uint8(int(p.z));
	uv.w = convert_int8_to_uint8(int(p.w));
    uint c = (uv.w << 24u) | (uv.z << 16u) | (uv.y << 8u) | (uv.x);
    return c;
}

vec4 unpack_snorm_4x8(uint p)
{
	ivec4 iv;
    iv.x = convert_uint8_to_int8((p >> 0u)  & 0xFFu);
    iv.y = convert_uint8_to_int8((p >> 8u)  & 0xFFu);
    iv.z = convert_uint8_to_int8((p >> 16u) & 0xFFu);
    iv.w = convert_uint8_to_int8((p >> 24u) & 0xFFu);
    return clamp(vec4(iv) / 127.0, vec4(-1.0), vec4(1.0));
}

uint pack_unorm_4x8(vec4 p)
{
    p = clamp(p, vec4(0.0), vec4(1.0)) * 255.0;
    uint ip = (uint(p.w) << 24u) | (uint(p.z) << 16u) | (uint(p.y) << 8u) | uint(p.x);
    return ip;
}

vec4 unpack_unorm_4x8(uint p)
{
    vec4 v;
    v.x = ((p >> 0u)  & 0xFFu);
    v.y = ((p >> 8u)  & 0xFFu);
    v.z = ((p >> 16u) & 0xFFu);
    v.w = ((p >> 24u) & 0xFFu);
    v = v / 255.0;
    return v;
}

vec2 unpack_snorm_2x16(uint p)
{
	uvec2 uv;
	uv.x = (p >> 0u)  & 0xFFFFu;
	uv.y = (p >> 16u) & 0xFFFFu;
	ivec2 iv;
	iv.x = convert_uint16_to_int16(uv.x);
	iv.y = convert_uint16_to_int16(uv.y);
	return clamp(vec2(iv) / 32767.0, vec2(-1.0), vec2(1.0));
}

vec2 unpack_unorm_2x16(uint p)
{
	vec2 v;
    v.x = ((p >> 0u)  & 0xFFFFu);
    v.y = ((p >> 16u) & 0xFFFFu);
    return v / 65535.0;
}

#else

#define pack_snorm_4x8 packSnorm4x8
#define unpack_snorm_4x8 unpackSnorm4x8
#define pack_unorm_4x8 packUnorm4x8
#define unpack_unorm_4x8 unpackUnorm4x8
#define unpack_snorm_2x16 unpackSnorm2x16
#define unpack_unorm_2x16 unpackUnorm2x16

#endif

vec3 uncompress_normal_spherical(uint cnorm)
{
	vec2 n = unpack_snorm_2x16(cnorm);
    n.x *= PI; // phi: -pi, pi
    n.y *= PI; // theta: -pi, pi
	n.y += PI; // theta: 0, 2pi
	n.y *= 0.5; // theta: 0, pi
    // convert to signed
    vec3 norm;
    float sin_phi = sin(n.x);
    float cos_phi = cos(n.x);
    float sin_theta = sin(n.y);
    float cos_theta = cos(n.y);
    norm.z = sin_theta * cos_phi;
    norm.x = sin_theta * sin_phi;
    norm.y = cos_theta;
	return norm;
}


#if defined(SHADER_LIGHT) && defined(SHADER_PBR_MATERIAL)
#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

float pbr_distr_GGX(float NdotH, float r)
{
    float a = r*r;
    float a2 = a * a;
    float NdotH2 = NdotH * NdotH;
    float nom = a2;
    float denom = (NdotH2 * (a2 - 1.0) + 1.0001);
    denom = M_PI * denom * denom;
    return nom / denom;
}
	
float pbr_geom_schlick_GGX(float NdotVL, float r)
{
    r += 1.0;
    float k = (r*r) * 0.125;
    float nom = NdotVL;
    float denom = NdotVL * (1.0 - k) + k;
    return nom / denom;
}

float pbr_geometry_smith(float NdotL, float NdotV, float r)
{
    float ggx2 = pbr_geom_schlick_GGX(NdotV, r);
    float ggx1 = pbr_geom_schlick_GGX(NdotL, r);
    return ggx1 * ggx2;
}

vec3 pbr_fresnel_schlick(float cos_theta, vec3 F0)
{
    return F0 + (1.0 - F0) * pow(1.0 - cos_theta, 5.0);
}

vec3 pbr_fresnel_schlick_roughness(float cos_theta, vec3 F0, float r)
{
    return F0 + (max(vec3(1.0 - r), F0) - F0) * pow(1.0 - cos_theta, 5.0);
}

float pbr_luminance(vec3 c)
{
	// mostly green due to human eye properties
    return dot(c, vec3(0.22, 0.707, 0.071));
}

// light_dir is the direction of the fragment TO the light, not from the light
// view normal must be normalized
// view_dir is (normalize(cam_view_pos - fragment_view_pos))
vec3 pbr_Lo_calc_common(PBRMaterialData pbr, vec3 view_normal, vec3 view_dir, 
		vec3 F0, vec3 light_dir, float light_specular_intensity, float radiance, float shadow)
{
	vec3 halfway_dir = normalize(light_dir + view_dir);
    float NdotL = max(dot(view_normal, light_dir), 0.0);
    float NdotV = max(dot(view_normal, view_dir), 0.0);
    float NdotH = max(dot(view_normal, halfway_dir), 0.0);
    float HdotV = clamp(dot(halfway_dir, view_dir), 0.0, 1.0);

    // Cook-Torrance BRDF
    float NDF = pbr_distr_GGX(NdotH, pbr.roughness);
    float G   = pbr_geometry_smith(NdotL, NdotV, pbr.roughness);
    vec3  F   = pbr_fresnel_schlick(HdotV, F0);

    vec3 nominator = NDF * G * F;
    float denominator = 4 * NdotV * NdotL + 0.001;
    vec3 specular = nominator / denominator;

    vec3 kS = F;
    vec3 kD = vec3(1.0) - kS;
    kD *= 1.0 - pbr.metallic;

    vec3 Lo = vec3(0.0);
    Lo = (shadow * kD * pbr.albedo.rgb / M_PI + shadow * specular * light_specular_intensity) * radiance * NdotL;
    return Lo;
}

// per-light

vec3 LoCalc_common(PBRMaterialData pbr, vec3 view_normal, vec3 view_dir, 
		vec3 F0, vec3 light_dir, float light_specular_intensity, float radiance)
{
	return pbr_Lo_calc_common(pbr, view_normal, view_dir, 
		F0, light_dir, light_specular_intensity, radiance, 1.0f);
}

vec3 pbr_calc_dir_light(DirectionalLight light, PBRMaterialData pbr, vec3 view_normal, vec3 view_dir, vec3 F0, float shadow)
{
	vec3 light_dir = normalize(-light.direction.xyz);
	float di = light.diffuse_intensity;
	float radiance = di * di * di * 10.0;
	vec3 Lo = pbr_Lo_calc_common(pbr, view_normal, view_dir, F0, light_dir, light.specular_intensity, radiance, shadow);
	return Lo;
}

vec3 pbr_calc_point_light(PointLight light, PBRMaterialData pbr, vec3 view_normal, vec3 view_dir, vec3 F0, vec3 view_pos)
{
    vec3 light_dir = normalize(light.position.xyz - view_pos);
	float distance = length(light_dir);
    float attenuation = 1.0 / (( distance * distance ) + 0.001);
	float di = light.diffuse_intensity;
	float exp = di * di * di * 10.0;
    float radiance = exp * attenuation;
	vec3 Lo = pbr_Lo_calc_common(pbr, view_normal, view_dir, F0, light_dir,  light.specular_intensity, radiance, 1.0f);
	return Lo;
}

vec3 pbr_calc_spot_light(SpotLight light, PBRMaterialData pbr, vec3 view_normal, vec3 view_dir, vec3 F0, vec3 view_pos)
{
    vec3 light_dir = normalize(light.position.xyz - view_pos);
	float distance = length(light_dir);
    float attenuation = 1.0 / ((light.constant + light.linear * distance + light.quadratic * ( distance * distance )) + 0.001);
    float theta = dot(light_dir, normalize(-light.direction.xyz));
    float epsilon = light.cutoff - light.outer_cutoff;
    float intensity = clamp((theta - light.outer_cutoff) / (epsilon + 0.001), 0.0, 1.0);
	float di = light.diffuse_intensity;
	float exp = di * di * di * 10.0;
    float radiance = exp * attenuation * intensity;
	vec3 Lo = pbr_Lo_calc_common(pbr, view_normal, view_dir, F0, light_dir,  light.specular_intensity, radiance, 1.0f);
	return Lo;
}

vec3 pbr_ibl_ambient_calc(PBRMaterialData pbr, vec3 view_normal, vec3 view_dir, vec3 F0, float shadow, float shadow_intensity,
		mat4 envmap_imv_matrix, float envmap_yoffset, 
		samplerCube irradiance_tex, samplerCube prefilter_tex, sampler2D brdf_lut_tex)
{
	const float MAX_REFLECTION_LOD = 4.0;
    float NdotV = max(dot(view_normal, view_dir), 0.0);
    vec3 F = pbr_fresnel_schlick_roughness(NdotV, F0, pbr.roughness);
    vec3 kS = F;
    vec3 kD = 1.0 - kS;
    kD *= 1.0 - pbr.metallic;

	// get normal in envmap space
    vec4 wn = normalize(envmap_imv_matrix * vec4(view_normal, 0.0));
    vec3 irradiance = texture(irradiance_tex, wn.xyz).rgb;
    vec3 diffuse = irradiance * pbr.albedo.rgb;

    vec3 r = reflect(-view_dir, view_normal);
    r = (envmap_imv_matrix * vec4(r, 0.0)).xyz + vec3(envmap_yoffset);
    vec3 pfColor = textureLod(prefilter_tex, r, pbr.roughness * MAX_REFLECTION_LOD).rgb;
    vec2 envBRDF = texture(brdf_lut_tex, vec2(NdotV, pbr.roughness)).rg;
    vec3 specular = pfColor * (F * envBRDF.x + envBRDF.y);

    float shi = 1.0-shadow;
    shi *= shadow_intensity;
    return mix(kD * diffuse + specular, diffuse * 0.3 * (1.0-shi), shi);
}




#endif
#if defined(SHADER_USE_SHADOW_DIR_MAP) || defined(SHADER_SHADOW_DIR_PASS)
vec2 computeShadowMoments(float depth)
{
	vec2 moments;

	moments.x = depth;

	float dx = dFdx(depth);
	float dy = dFdy(depth);

	moments.y = depth * depth + 0.25f * (dx*dx + dy*dy);

	/*moments.x = depth;
	moments.y = depth * depth;*/

	return moments;
}

float reduceLightBleeding(float pmax, float amount)
{
	return smoothstep(amount, 1.0f, pmax);
}

float ChebyshevUpperBound(vec2 moments, float t, float bias)
{
	float mean = moments.x;
	float p = 0.0f;
	if (t <= mean){
		p = 1.0f;
	}

	float variance = moments.y - moments.x * moments.x;
	variance = max(variance, 0.00005f);

	float d = t - mean;

	float pmax = variance / (variance + d * d);

	if (bias == 0.0f)
		return max(p, pmax);
	else
		return reduceLightBleeding(max(p, pmax), bias);
}



#endif
#if defined(SHADER_PBR_TEXTURE)
// procedural texture functions

mat2 proctex_calc_mat2_from_angle_deg(float angle)
{
    float rot = radians(angle);
    mat2 m = mat2(cos(rot), -sin(rot), sin(rot), cos(rot));
    return m;
}

vec2 proctex_project(vec3 pos, vec3 n)
{
    if(abs(n.x) > abs(n.y)) {
        if(abs(n.x) > abs(n.z)) { //x is the max
            return vec2(pos.y, pos.z);
        } else { //z is the max
            return vec2(pos.x, pos.y);
        }
    } else if(abs(n.y) > abs(n.z)) {  //y is the max
        return vec2(pos.x, pos.z);
    } else { //z is the max
        return vec2(pos.x, pos.y);
    }
}

vec4 proctex_eye_generate(vec4 screen_pos, MaterialTextureData mtd, sampler2D tex)
{
    vec2 coords;
    coords.x = dot(screen_pos, vec4(mtd.tex_scale.x, 0.0, 0.0, 0.0));
    coords.y = dot(screen_pos, vec4(0.0, mtd.tex_scale.y, 0.0, 0.0 ));
    coords.xy *= proctex_calc_mat2_from_angle_deg(mtd.tex_rotation);
	coords.xy = (coords.xy + vec2(1.0)) * vec2(0.5);
    coords.xy += mtd.tex_offset;
    return texture(tex, coords);
}

vec4 proctex_normal_generate(vec3 view_normal, sampler2D tex)
{
    return texture(tex, view_normal.xy);
}

// normal must be normalized
vec4 proctex_box_generate(vec3 local_normal, vec4 local_pos, 
		MaterialTextureData mtd, sampler2D tex)
{
	vec2 coords;
	coords.xy = proctex_project(local_pos.xyz, local_normal);
	coords.xy *= mtd.tex_scale;
	coords.xy *= proctex_calc_mat2_from_angle_deg(mtd.tex_rotation);
	coords.xy += mtd.tex_offset;
	return texture(tex, coords);
}

// normal must be normalized
vec4 proctex_triplanar_generate(vec3 local_normal, vec4 local_pos,
		MaterialTextureData mtd, sampler2D tex)
{
	vec4 coords = vec4(local_pos.xyz, 0.0);
	vec3 blending = abs(local_normal);
	blending = normalize(max(blending, 0.00001)); // Force weights to sum to 1.0
	float b = (blending.x + blending.y + blending.z);
	blending /= vec3(b, b, b);
	vec2 uv1 = coords.yz;
	vec2 uv2 = coords.xz;
	vec2 uv3 = coords.xy;
	uv1 *= mtd.tex_scale;
	uv1 *= proctex_calc_mat2_from_angle_deg(mtd.tex_rotation);
	uv1 += mtd.tex_offset;
	uv2 *= mtd.tex_scale;
	uv2 *= proctex_calc_mat2_from_angle_deg(mtd.tex_rotation);
	uv2 += mtd.tex_offset;
	uv3 *= mtd.tex_scale;
	uv3 *= proctex_calc_mat2_from_angle_deg(mtd.tex_rotation);
	uv3 += mtd.tex_offset;
	vec4 xaxis = texture(tex, uv1);
	vec4 yaxis = texture(tex, uv2);
	vec4 zaxis = texture(tex, uv3);
	// blend the results of the 3 planar projections
	vec4 res = xaxis * blending.x + yaxis * blending.y + zaxis * blending.z;
	return res;
}

vec4 proctex_planar_x_generate(vec4 local_pos, MaterialTextureData mtd, sampler2D tex)
{
	vec4 coords = vec4(local_pos.xyz, 0.0);
	vec2 uv = coords.yz;
	uv *= mtd.tex_scale;
	uv *= proctex_calc_mat2_from_angle_deg(mtd.tex_rotation);
	uv += mtd.tex_offset;
	return texture(tex, uv);
}

vec4 proctex_planar_y_generate(vec4 local_pos, MaterialTextureData mtd, sampler2D tex)
{
	vec4 coords = vec4(local_pos.xyz, 0.0 );
	vec2 uv = coords.xz;
	uv *= mtd.tex_scale;
	uv *= proctex_calc_mat2_from_angle_deg(mtd.tex_rotation);
	uv += mtd.tex_offset;
	return texture(tex, uv);
}

vec4 proctex_planar_z_generate(vec4 local_pos, MaterialTextureData mtd, sampler2D tex)
{
	vec4 coords = vec4(local_pos.xyz, 0.0 );
	vec2 uv = coords.xy;
	uv *= mtd.tex_scale;
	uv *= proctex_calc_mat2_from_angle_deg(mtd.tex_rotation);
	uv += mtd.tex_offset;
	return texture(tex, uv);
}



#endif

#if defined(SHADER_FRINGE_CENTROID_TOP) || defined(SHADER_FRINGE_CENTROID_BOTTOM)
#define SHADER_FRINGE_CENTROID
#endif
#if defined(SHADER_FRINGE_CORNER_TOP) || defined(SHADER_FRINGE_CORNER_BOTTOM)
#define SHADER_FRINGE_CORNER
#endif
#if defined(SHADER_FRINGE_CENTROID) || defined(SHADER_FRINGE_CORNER)
#define SHADER_FRINGE_ELEM
#endif
#if defined(SHADER_FRINGE_NODE_TOP) || defined(SHADER_FRINGE_NODE_BOTTOM) 
#define SHADER_FRINGE_NODE
#endif
#if defined(SHADER_FRINGE_NODE) || defined(SHADER_FRINGE_ELEM)
#define SHADER_FRINGE
#endif
#if defined(SHADER_FRINGE_NODE_TOP) || defined(SHADER_FRINGE_CORNER_TOP) || defined(SHADER_FRINGE_CENTROID_TOP)
#define SHADER_FRINGE_TOP
#endif
#if defined(SHADER_FRINGE_NODE_BOTTOM) || defined(SHADER_FRINGE_CORNER_BOTTOM) || defined(SHADER_FRINGE_CENTROID_BOTTOM) 
#define SHADER_FRINGE_BOTTOM
#endif

#if (defined(SHADER_FRINGE) && defined(SHADER_FRINGE_QUALITY) && (defined(SHADER_QUAD4) || defined(SHADER_TRIA3) || defined(SHADER_SECOND_ORDER)))
#define SHADER_FRINGE_EXACT
#endif
#if defined(SHADER_THICK_SHELLS_GET_FRINGE_TOP) || defined(SHADER_THICK_SHELLS_GET_FRINGE_BOTTOM)
#define SHADER_THICK_SHELLS_GET_FRINGE
#endif
#if defined(SHADER_THICK_SHELLS_GET_PART) || defined(SHADER_THICK_SHELLS_GET_OPTT) || defined(SHADER_THICK_SHELLS_GET_FRINGE) || defined(SHADER_THICK_SHELLS_GET_NODAL_THICKNESS) || defined(SHADER_THICK_SHELLS_GET_CORNER_THICKNESS)
#define SHADER_THICK_SHELLS
#endif

#if defined(SHADER_IBL) && !defined(SHADER_PBR_MATERIAL) 
#error "FEATURE ERROR: IBL without PBR_MATERIAL"
#endif

#if defined(SHADER_WIRE) && defined(SHADER_FILL) && !defined(SHADER_TRIA6)
#define SHADER_BARYCENTRICS
#endif

#if defined(SHADER_OIT_WB_ACCUM) || defined(SHADER_OIT_DEPTH_PEEL)
#define SHADER_OIT
#endif
#if defined(SHADER_OIT_WB_ACCUM) && defined(SHADER_OIT_DEPTH_PEEL)
#define SHADER_OIT_SECOND_PASS
#endif

// set fringe interpolation qualifer
#if defined(SHADER_FRINGE_CENTROID)
    #define FRINGE_INTERP flat
#else 
    #define FRINGE_INTERP 
#endif

#if !defined(SHADER_FILL) && defined(SHADER_WIRE) 
#define SHADER_ONLY_WIRE
#endif

layout(std140, binding = SHADER_GLOBAL_BUFFER_BINDING) uniform global_buffer
{
	UniformGlobals globals;
};

layout(std140, binding = SHADER_MODEL_BUFFER_BINDING) uniform per_model_buffer
{
	ModelUniformData model_uniforms;
};

// TODO do not have globals in this file...
#if defined(SHADER_LIGHT) && !defined(SHADER_PBR_MATERIAL)

// ao is ambient occlusion [0, 1]

vec3 blinn_calc_dir_light(DirectionalLight light, vec3 normal, vec3 view_dir, STLMaterialData stl_material, float ao, float shadow)
{
    vec3 light_dir = normalize(-light.direction.xyz);
	float diff = max(dot(normal, light_dir), 0.0);
	vec3 halfway_dir = normalize(light_dir + view_dir);
    float spec = pow(max(dot(halfway_dir, normal), 0.0), stl_material.specular.w);

    vec3 ambient = globals.ambient_intensity.r * stl_material.ambient.rgb;
    vec3 diffuse = light.diffuse_intensity * diff * stl_material.diffuse.rgb;
	vec3 specular = (light.specular_intensity * spec * stl_material.specular.rgb);
	vec3 res = (ambient*ao + diffuse*ao*shadow + specular*shadow);
    return res;
}

vec3 blinn_calc_point_light(PointLight light, vec3 normal, vec3 view_pos, vec3 view_dir, STLMaterialData stl_material, float ao)
{
    vec3 light_dir = normalize(light.position.xyz - view_pos);
    float diff = max(dot(normal, light_dir), 0.0);
	vec3 halfway_dir = normalize(light_dir + view_dir);
    float spec = pow(max(dot(halfway_dir, normal), 0.0), stl_material.specular.w);

    // attenuation
    float distance = length( light_dir );
    float attenuation = 1.0 / (light.constant + light.linear * distance + light.quadratic * (distance * distance));    

    vec3 ambient = globals.ambient_intensity.r * stl_material.ambient.rgb;
    vec3 diffuse = light.diffuse_intensity * diff * stl_material.diffuse.rgb;
	vec3 specular = (light.specular_intensity * spec * stl_material.specular.rgb);
	vec3 res = (ambient*ao + diffuse*ao + specular) * vec3(attenuation);
    return res;
}

vec3 blinn_calc_spot_light(SpotLight light, vec3 normal, vec3 view_pos, vec3 view_dir, STLMaterialData stl_material, float ao)
{
    vec3 light_dir = normalize(light.position.xyz - view_pos);
    float diff = max(dot(normal, light_dir), 0.0);
	vec3 halfway_dir = normalize(light_dir + view_dir);
    float spec = pow(max(dot(halfway_dir, normal), 0.0), stl_material.specular.w);

    // attenuation
	float distance = length(light_dir);
    float attenuation = 1.0 / (light.constant + light.linear * distance + light.quadratic * (distance * distance));    
	// spotlight intensity
	float theta = dot(light_dir, normalize(-light.direction.xyz)); 
	float epsilon = light.cutoff - light.outer_cutoff;
    float intensity = clamp((theta - light.outer_cutoff) / epsilon, 0.0, 1.0);

    vec3 ambient = globals.ambient_intensity.r * stl_material.ambient.rgb;
    vec3 diffuse = light.diffuse_intensity * diff * stl_material.diffuse.rgb;
	vec3 specular = (light.specular_intensity * spec * stl_material.specular.rgb);
	vec3 res = (ambient*ao + diffuse*ao + specular) * vec3(attenuation) * vec3(intensity);
    return res;
}

vec4 blinn_calc(vec4 pre_color, vec3 specular, float shininess, vec3 view_pos, vec3 view_normal)
{
	//All relevant variables should be initialized here, otherwise it has undefined behavor
	STLMaterialData stl_material;
    stl_material.diffuse = pre_color;
    stl_material.ambient = pre_color;
	stl_material.specular.w = shininess;
	stl_material.specular.rgb = specular;

    vec3 view_dir = vec3(0.0, 0.0, 1.0);
	vec3 lighted_color = vec3(0.0);
	// uniform branching
	for (int i = 0; i < MK_NUM_DIR_LIGHTS; i++) {
		if (globals.dir_lights[i].status == 1) {
			lighted_color += blinn_calc_dir_light(globals.dir_lights[i], view_normal, view_dir, stl_material, 1.0, 1.0f);
		}
	}
	if (globals.point_light.status == 1) {
		lighted_color += blinn_calc_point_light(globals.point_light, view_normal, view_pos, view_dir, stl_material, 1.0);
	}
	if (globals.spot_light.status == 1) {
		lighted_color += blinn_calc_spot_light(globals.spot_light, view_normal, view_pos, view_dir, stl_material, 1.0);
	}
    return vec4(lighted_color, stl_material.diffuse.a);
}

//Blinn calculation only for directional lights
vec4 blinn_calc(vec4 pre_color, vec3 specular, float shininess, vec3 view_normal)
{		
	//All relevant variables should be initialized here, otherwise it has undefined behavor
	STLMaterialData stl_material;
    stl_material.diffuse = pre_color;
    stl_material.ambient = pre_color;
	stl_material.specular.w = shininess;
	stl_material.specular.rgb = specular;

    vec3 view_dir = vec3(0.0, 0.0, 1.0);
	vec3 lighted_color = vec3( 0.0 );
	for (int i = 0; i < MK_NUM_DIR_LIGHTS; i++) {
		lighted_color += globals.dir_lights[i].status == 1 ? blinn_calc_dir_light(globals.dir_lights[i], view_normal, view_dir, stl_material, 1.0, 1.0f) : vec3( 0.0 );	
	}
    return vec4(lighted_color, stl_material.diffuse.a);
}


 
#endif

#if defined(SHADER_PBR_MATERIAL)
#define PidUniformData PidUniformDataPBR
#define MaterialData   PBRMaterialData 
#else
#define PidUniformData PidUniformDataSTL
#define MaterialData   STLMaterialData 
#endif

#if defined(SHADER_MULTI_DRAW_INDIRECT)

layout(std430, binding = SHADER_3DMODEL33_PER_PID_BUFFER_BINDING) buffer per_pid_buffer
{
	PidUniformData pid_uniforms_multi[];
};
#define pid_uniforms pid_uniforms_multi[fs_in.part_idx]

#else 

layout(std140, binding = SHADER_3DMODEL33_PER_PID_BUFFER_BINDING) uniform per_pid_buffer
{
	PidUniformData pid_uniforms;
};

#endif

in GeometryOut 
{
#if defined(SHADER_MULTI_DRAW_INDIRECT) 
	flat int part_idx;
#endif
/*    f16vec2 packed_normal;*/
#if defined(SHADER_SMOOTH_NORMALS)
    vec3 normal;
#else 
    flat uint flat_normal;
#endif
#if defined(SHADER_COLOR_VARIANCE)
    flat uint var_color;
#endif

#if defined(SHADER_FRINGE_TOP)
#if defined(SHADER_FRINGE_EXACT)
	flat vec2 tex_top[TRUE_VERTICES];
#else
    FRINGE_INTERP vec2 tex_top;
#endif // SHADER_EXACT
#endif // SHADER_FRINGE_TOP
#if defined(SHADER_FRINGE_BOTTOM)
#if defined(SHADER_FRINGE_EXACT)
	flat vec2 tex_bottom[TRUE_VERTICES];
#else
    FRINGE_INTERP vec2 tex_bottom;
#endif
#endif // SHADER_FRINGE_BOTTOM
#if defined(SHADER_FRINGE_EXACT)
#if defined(SHADER_QUAD4) || defined(SHADER_QUAD8)
	vec2 fringe_barycentric;
#elif defined(SHADER_TRIA3) || defined(SHADER_TRIA6)
	vec3 fringe_barycentric;
#endif
#endif // SHADER_FRINGE_EXACT

#if defined(SHADER_USE_BLUR)
	vec3 velocity_color;
#endif
#if defined(SHADER_LIC_OVERLAY) || defined(SHADER_LIC_SCREEN_SPACE)
	float vr_mask;
#if defined(SHADER_LIC_LAY_COMPOSE)
	vec2 vr_licCoords_p;
	vec2 vr_licCoords_s;
	vec2 vr_licCoords_t;

	vec4 vr_layWt;
	vec3 vr_srcWt;
	float vr_cLevel;
#else //!SHADER_LIC_LAY_COMPOSE
	vec2 vr_licCoords;
#endif //SHADER_LIC_LAY_COMPOSE
#endif
#if defined(SHADER_LIC_SCREEN_SPACE)
	vec2 vr_scrVect;
#endif
#if defined(SHADER_WIRE)
    flat uint edges;
#endif
#if defined(SHADER_BARYCENTRICS)
    vec2 barycentric;
#endif
#if defined(SHADER_USE_TEX_COORDS)
	vec2 tex_coords;
#endif
#if defined(SHADER_USE_NODAL_NORMALS) || defined(SHADER_USE_NODAL_NORMALS_3F)
	vec3 nodal_normals;
#endif
#if defined(SHADER_USE_NODAL_COLOR)
    vec4 nodal_color;
#endif
#if defined(SHADER_ONLY_WIRE) && defined(SHADER_TWO_SIDE)
	flat float area;
#endif
} fs_in;

#if defined(SHADER_SSAO_DEPTH_PRE_PASS)
// NO OUTPUT
layout(location = 0) out vec3 out_depth_prepass_normal;
#elif defined(SHADER_SHADOW_DIR_PASS)
layout(location = 0) out vec2 variance_depth;
#else
layout(location = 0) out vec4 out_color;
#endif
#if defined(SHADER_USE_BLUR)
layout(location = 1) out vec4 out_velocity;
#endif
#if defined(SHADER_OIT_WB_ACCUM)
layout(location = 1) out float out_wboit_reveal;
#endif
#if defined(SHADER_LIC_SCREEN_SPACE)
layout(location = 1) out vec3 out_vectors;
#endif

// samplers
#if defined(SHADER_FRINGE_NODE_TOP) && defined(SHADER_FRINGE_NODE_TOP_TEX)
layout(binding = SHADER_3DMODEL33_TU_FRAG_FRINGE_BAR_BINDING) uniform sampler1D texturef;
#else 
layout(binding = SHADER_3DMODEL33_TU_FRAG_FRINGE_BAR_BINDING) uniform sampler2D texturef;
#endif
#if defined(SHADER_IBL)
layout(binding = SHADER_3DMODEL33_TU_FRAG_IBL_IRRADIANCE_BINDING) uniform samplerCube irradianceTex;
layout(binding = SHADER_3DMODEL33_TU_FRAG_IBL_PREFILTER_BINDING) uniform samplerCube prefilterTex;
layout(binding = SHADER_3DMODEL33_TU_FRAG_IBL_BRDF_LUT_BINDING) uniform sampler2D brdfLutTex;
#endif
#if defined(SHADER_PBR_TEXTURE)
layout(binding = SHADER_3DMODEL33_TU_FRAG_RENDER_TEXTURE_ALBEDO_BINDING) uniform sampler2D albedo_texture;
layout(binding = SHADER_3DMODEL33_TU_FRAG_RENDER_TEXTURE_SPECULAR_BINDING) uniform sampler2D specular_texture;
layout(binding = SHADER_3DMODEL33_TU_FRAG_RENDER_TEXTURE_NORMAL_BINDING) uniform sampler2D normal_texture;
#endif
#if defined(SHADER_OIT_DEPTH_PEEL)
#if !defined(SHADER_MSAA)
layout(binding = SHADER_3DMODEL33_TU_FRAG_OIT_BINDING) uniform sampler2D front_depth_tex;
#else 
layout(binding = SHADER_3DMODEL33_TU_FRAG_OIT_BINDING) uniform sampler2DMS front_depth_tex;
#endif
#endif
#if defined(SHADER_USE_SSAO)
	#if defined(SHADER_SINGLE_PASS_STEREO)
	layout(binding = SHADER_3DMODEL33_TU_FRAG_SSAO_BINDING) uniform sampler2DArray ssao_tex;
	#else
	layout(binding = SHADER_3DMODEL33_TU_FRAG_SSAO_BINDING) uniform sampler2D ssao_tex;
	#endif // SHADER_SINGLE_PASS_STEREO
#endif
#if defined(SHADER_USE_SHADOW_DIR_MAP)
	layout(binding = SHADER_3DMODEL33_TU_FRAG_SHADOW_DIR_MAP_BINDING) uniform sampler2DArray shadow_dir_map_tex;
#endif
#if defined(SHADER_MIRROR_2ND_PASS_DRAW)
layout(binding =  SHADER_3DMODEL33_TU_FRAG_MIRROR_BINDING) uniform sampler2D mirror_tex;
#endif

#if defined(SHADER_SELECTION_HIGHLIGHT)
layout(location = SHADER_3DMODEL33_SELECTION_HIGHLIGHT_COLOR_UNIFORM_LOC) uniform vec4 selection_highlight_color;
#endif

vec4 get_projection_space_position();
vec4 get_view_space_position();
vec4 get_world_space_position();
vec4 get_local_space_position();
vec4 get_view_space_normal();
// vec4 get_world_space_normal();
vec4 get_local_space_normal();

vec2 write_bias_scale(vec2 v)
{
    return (v + VONE) * VHALF;
}

#if defined(SHADER_PBR_TEXTURE)
/* branches here are dynamically uniform */
vec3 get_pbr_texture_color(vec3 pre_color, vec3 view_normal)
{
	MaterialTextureData mtd = pid_uniforms.material_texture_data;
	vec3 color = vec3(1.0);
#if defined(SHADER_USE_TEX_COORDS)
	if (mtd.map_type == -1) {
		color = vec3(1.0, 1.0, 1.0);
	} else {
		color = texture(albedo_texture, fs_in.tex_coords).rgb;
	}
#elif defined(SHADER_MIRROR_2ND_PASS_DRAW)
	const mat4 proj_scale_trans = mat4(
		0.5, 0.0, 0.0, 0.0,
		0.0, 0.5, 0.0, 0.0,
		0.0, 0.0, 0.5, 0.0,
		0.5, 0.5, 0.5, 1.0
	);
	vec4 projection_tex_coords = proj_scale_trans * get_projection_space_position();
	vec2 texCoord = projection_tex_coords.st / projection_tex_coords.q;
	color = texture(mirror_tex, texCoord).rgb;
#else
	if (mtd.map_type == 0) { // TRIPLANAR
		vec4 local_pos = get_local_space_position();
		vec4 local_normal = get_local_space_normal();
		color = proctex_triplanar_generate(local_normal.xyz, local_pos, 
				mtd, albedo_texture).rgb;
	} else if (mtd.map_type == 1) { // BOX
		vec4 local_pos = get_local_space_position();
		vec4 local_normal = get_local_space_normal();
		color = proctex_box_generate(local_normal.xyz, local_pos, 
				mtd, albedo_texture).rgb;
	} else if (mtd.map_type == 2) { // PLANAR X
		vec4 local_pos = get_local_space_position();
		color = proctex_planar_x_generate(local_pos, mtd, albedo_texture).rgb;
	} else if (mtd.map_type == 3) { // PLANAR Y
		vec4 local_pos = get_local_space_position();
		color = proctex_planar_y_generate(local_pos, mtd, albedo_texture).rgb;
	} else if (mtd.map_type == 4) { // PLANAR Z
		vec4 local_pos = get_local_space_position();
		color = proctex_planar_z_generate(local_pos, mtd, albedo_texture).rgb;
	} else if (mtd.map_type == 5) { // CAMERA/EYE
		vec4 screen_pos = get_projection_space_position();
		color = proctex_eye_generate(screen_pos, mtd, albedo_texture).rgb;
	} else if (mtd.map_type == 6) { // NORMAL
		color = proctex_normal_generate(view_normal, albedo_texture).rgb;
	} else if (mtd.map_type == -1) { // NO MAP
		color = vec3(1.0, 1.0, 1.0);
	} else {
		color = vec3(1.0, 0.0, 0.6);
	}
    color = color * pre_color;
#endif
	return color;
}
#endif

#if defined(SHADER_USE_SSAO)
float calc_ssao()
{
	vec2 coords = vec2(gl_FragCoord.x / globals.viewport.z, gl_FragCoord.y / globals.viewport.w);
#if defined(SHADER_SINGLE_PASS_STEREO)
	float ao = texture(ssao_tex, vec3(coords, gl_Layer)).r;
#else
	float ao = texture(ssao_tex, coords).r;
#endif // SHADER_SINGLE_PASS_STEREO
	ao *= ao;
	return ao;
}
#endif

#if defined(SHADER_USE_SHADOW_DIR_MAP)
float calc_shadow(int shadow_map_index, int light_index)
{
	vec4 lightSpacePos = globals.shadow_light_data.dir_lights_projection_matrix[light_index] * globals.shadow_light_data.dir_lights_view_matrix[light_index] * get_world_space_position();
	//vec3 projCoords = lightSpacePos.xyz / lightSpacePos.w;
	vec3 projCoords = lightSpacePos.xyz;
	projCoords = projCoords * 0.5f + 0.5f;
	float currentDepth = projCoords.z;

	vec2 moments = texture(shadow_dir_map_tex, vec3(projCoords.xy, float(shadow_map_index))).rg;

	return ChebyshevUpperBound(moments, currentDepth, globals.shadows_bias_intensity.x);
}
#endif

#if defined (SHADER_LIGHT) && defined(SHADER_PBR_MATERIAL)
vec4 PBRCalc(vec3 view_normal, vec3 view_pos)
{
    float gamma = 2.2;
	PBRMaterialData pbr = pid_uniforms.material_data;	
    float alpha = pbr.albedo.a;

#if defined(SHADER_PBR_TEXTURE)
	pbr.albedo.rgb = pow( get_pbr_texture_color(pbr.albedo.rgb, view_normal), vec3( gamma ) );
#else
    pbr.albedo.rgb = pow( pbr.albedo.rgb, vec3( gamma ) );
#endif

#if defined(SHADER_MIRROR_2ND_PASS_DRAW)
	// This is duplicated with lines at the end of this function
	// but it is only a rare case with return. 
	vec3 color_ = pbr.albedo.rgb;

    // reinhardt tonemapping
    float lum_ = pbr_luminance( color_ );
    float scale_ = lum_ / (1.0 + lum_);
    color_ *= scale_ / lum_;

    // gamma correction
    color_ = pow(color_, vec3(1.0/gamma));

    return vec4(color_, alpha);
#endif

#if defined(SHADER_PERSPECTIVE_PROJECTION)
    vec3 view_dir = normalize(-view_pos); // normalize(cam_world_pos - world_pos) but in view space
#else
    vec3 view_dir = vec3(0.0, 0.0, 1.0);
#endif

    vec3 F0 = vec3( 0.04 );
    F0 = mix(F0, pbr.albedo.rgb, pbr.metallic);

    float r = clamp(pbr.roughness, 0.025, 1.0);

    vec3 Lo = vec3( 0.0 );
    float shadow = 1.0f;
    float min_shadow = 1.0f;
#if defined(SHADER_USE_SHADOW_DIR_MAP)
    int shadow_map_index = 0;
#endif
	// uniform branching for lights
	for (int i = 0; i < MK_NUM_DIR_LIGHTS; i++) {
		if (globals.dir_lights[i].status == 1) {
			shadow = 1.0f;
#if defined(SHADER_USE_SHADOW_DIR_MAP)
			if (globals.dir_lights[i].casts_shadow == 1){
				shadow = calc_shadow(shadow_map_index, i);
				min_shadow = min(shadow, min_shadow);
				vec3 light_dir = normalize(-globals.dir_lights[i].direction.xyz);
				min_shadow *= (dot(view_normal, light_dir) > 0.0) ? 1.0 : 0.0;
				shadow = mix(1.0f, shadow, globals.shadows_bias_intensity.y);
			}
			shadow_map_index = shadow_map_index + 1;
#endif
			Lo += pbr_calc_dir_light(globals.dir_lights[i], pbr, view_normal, view_dir, F0, shadow);
		}
	}
	if (globals.point_light.status == 1) {
		Lo += pbr_calc_point_light(globals.point_light, pbr, view_normal, view_dir, F0, view_pos);
	}
	if (globals.spot_light.status == 1) {
		Lo += pbr_calc_spot_light(globals.spot_light, pbr, view_normal, view_dir, F0, view_pos);
	}

#if defined(SHADER_IBL)
    vec3 ambient = pbr_ibl_ambient_calc(pbr, view_normal, view_dir, F0, min_shadow, globals.shadows_bias_intensity.y,
			globals.envmap_imv_matrix, globals.envmap_yoffset.x, 
			irradianceTex, prefilterTex, brdfLutTex);
#else
    vec3 ambient = clamp(globals.ambient_intensity.r, 0.03, 1.0) * pbr.albedo.rgb; // * ao; currently ao = 1
#endif
	
	vec3 color = vec3( 0.0 );
	color = ambient + Lo;

    // reinhardt tonemapping
    float lum = pbr_luminance(color);
    float scale = lum / (1.0 + lum);
    color *= scale / lum;

    // gamma correction
    color = pow(color, vec3(1.0/gamma));

#if defined(SHADER_USE_SSAO)
	float ao = calc_ssao();
	color *= ao;
#endif

	return vec4(color, alpha);
}
#endif // SHADER_PBR_MATERIAL

#if defined(SHADER_LIGHT) && !defined(SHADER_PBR_MATERIAL)
vec4 blinn_calc_33(vec4 pre_color, vec3 view_normal, vec3 view_pos)
{	
	STLMaterialData stl_material = pid_uniforms.material_data;
#if (defined(SHADER_FRINGE) || defined(SHADER_TWO_SIDE)) && !defined(SHADER_COLOR_VARIANCE)
    // if we have a transparent pid and we have fringe we need the transparent color to show
    pre_color = (stl_material.diffuse.a < 1.0) ? stl_material.diffuse : pre_color;
#endif
#if defined(SHADER_COLOR_VARIANCE) || defined(SHADER_FRINGE) || defined(SHADER_TWO_SIDE) || defined(SHADER_USE_NODAL_COLOR)
    // if we have per-element coloring or fringe or two sided -> change material properties
    stl_material.diffuse = pre_color;
    stl_material.ambient = pre_color;
#endif
#if defined(SHADER_PBR_TEXTURE) && defined(SHADER_USE_TEX_COORDS)
	MaterialTextureData mtd = pid_uniforms.material_texture_data;
	if (mtd.map_type != -1) {
		stl_material.diffuse.rgb = texture(albedo_texture, fs_in.tex_coords).rgb;
		if (mtd.specular_texture_exists == 1) {
			stl_material.specular.rgb = texture(specular_texture, fs_in.tex_coords).rgb;
		}
	}
#endif
#if defined(SHADER_FRINGE)
	// apply fringe specular dampening if it exists
	stl_material.specular.rgb *= globals.fringe_specular.r;
#endif

	vec3 view_dir;
#if defined(SHADER_PERSPECTIVE_PROJECTION)
    view_dir = normalize(-view_pos);
#else
    // here fs_in.view_pos is optimized out
    view_dir = vec3(0.0, 0.0, 1.0);
#endif

#if defined(SHADER_USE_SSAO)
	float ao = calc_ssao();
#else 
	const float ao = 1.0;
#endif
	// branching is uniform here
	vec3 lighted_color = vec3(0.0);
	float shadow = 1.0f;
#if defined(SHADER_USE_SHADOW_DIR_MAP)
	int shadow_map_index = 0;
#endif
	for (int i = 0; i < MK_NUM_DIR_LIGHTS; i++) {
		if (globals.dir_lights[i].status == 1) {
			shadow = 1.0f;
#if defined(SHADER_USE_SHADOW_DIR_MAP)
			if (globals.dir_lights[i].casts_shadow == 1){
				shadow = calc_shadow(shadow_map_index, i);
				shadow = mix(1.0f, shadow, globals.shadows_bias_intensity.y);
			}
			shadow_map_index = shadow_map_index + 1;
#endif
			lighted_color += blinn_calc_dir_light(globals.dir_lights[i], view_normal, view_dir, stl_material, ao, shadow);
		}
	}
	if (globals.point_light.status == 1) {
		lighted_color += blinn_calc_point_light(globals.point_light, view_normal, view_pos, view_dir, stl_material, ao);
	}
	if (globals.spot_light.status == 1) {
		lighted_color += blinn_calc_spot_light(globals.spot_light, view_normal, view_pos, view_dir, stl_material, ao);
	}

    return vec4(lighted_color, stl_material.diffuse.a);
}
#endif

#if defined(SHADER_LIGHT)
/*********** Colour source summation *************
 - colour is a precomputed color for cases of fringe, lic etc..., it is not needed when using materials
 - normal is the vertex/fragment normal in view space (!!! DANGER !!! META needs inverse normals)
 - view_pos is the vertex/fragment position in view space
*/
vec4 applyLighting(vec4 pre_color, vec3 view_normal, vec3 view_pos) 
{
#if defined (SHADER_PBR_MATERIAL) && !defined(SHADER_FRINGE)
	return PBRCalc(view_normal, view_pos);
#else
	return blinn_calc_33(pre_color, view_normal, view_pos);
#endif
}
/**************************************************/
#endif // SHADER_LIGHT


#if defined(SHADER_WIRE)

#if defined(SHADER_QUAD8)
float edge_factor(vec2 cb)
{
    vec2 bary = vec2(cb.x, cb.y);
    float width =  globals.mesh_lines_color_width.w;
    vec2 bias = vec2(width);
    vec2 d = bias * max(abs(dFdx(bary)), abs(dFdy(bary)));
	vec2 a3 = smoothstep(vec2(0.0), d, bary);
	vec2 b3 = vec2(1.0) - smoothstep(vec2(1.0)-d, vec2(1.0), bary);
	float a = min(min(a3.x, a3.y), min(b3.x, b3.y));
#if defined(SHADER_MSAA)
	return a;
#else
    // we check here for the degenerate case of both edges not being wired
    // just add a double-pixel-width line with less color tone so that it seems like its one line
    float res;
    res = (a < 0.4999) ? 0.0 : 1.0;
    res = (a >= 0.4999 && a < 0.5001) ? 0.6 : res;
    return res;
#endif
}

#else 

float edge_factor(vec2 cb)
{
    vec3 bary = vec3(cb.x, cb.y, 1.0-cb.x-cb.y);
    float width = globals.mesh_lines_color_width.w;
    vec3 bias = vec3(width);
    vec3 d = bias * max(abs(dFdx(bary)), abs(dFdy(bary)));
	vec3 a3 = smoothstep(vec3(0.0), d, bary);
    uvec3 edges;
    edges.x = (fs_in.edges & (1u << 0u)) >> 0u;
    edges.y = (fs_in.edges & (1u << 1u)) >> 1u;
	edges.z = (fs_in.edges & (1u << 2u)) >> 2u;
	a3.x = edges.x == 0u ? 1.0 : a3.x;
	a3.y = edges.y == 0u ? 1.0 : a3.y;
	a3.z = edges.z == 0u ? 1.0 : a3.z;
#if defined(SHADER_MSAA)
    return min(min(a3.x, a3.y), a3.z);
#else
    float a = min(min(a3.x, a3.y), a3.z);
    float res;
    // we check here for the degenerate case of both edges not being wired
    // just add a double-pixel-width line with less color tone so that it seems like its one line
    res = (a < 0.4999) ? 0.0 : 1.0;
    res = (a >= 0.4999 && a < 0.5001) ? 0.6 : res;
    return res;
#endif
}

#endif

#endif

bool is_front_facing()
{
	bool ff;
#if defined(SHADER_ONLY_WIRE) && defined(SHADER_TWO_SIDE)
	ff = (fs_in.area > 0.0);
#else 
	// pid: ccw, model: ccw -> ccw
	// pid: cw, model: ccw -> cw
	// pid: ccw, model: cw -> cw
	// pid: cw, model: cw -> ccw
	ff = pid_uniforms.front_face > 0; 
	ff = !(gl_FrontFacing ^^ ff);  
#endif
	return ff;
}

#if defined(SHADER_FRINGE_EXACT)
#if defined(SHADER_QUAD4)
vec2 get_fringe_exact_tex(vec2 fringe_uv, vec2 tex[4])
{
	if (all(equal(tex[0], tex[1])) == true && all(equal(tex[1], tex[2])) == true && all(equal(tex[2], tex[3])) == true) return tex[0];

	vec2 uv = fringe_uv * vec2(2.0f) - vec2(1.0f);
	float u = uv.x;
	float v = uv.y;

	float n[4];
	n[0] = 0.25f * (1.0f - u) * (1.0f - v);
	n[1] = 0.25f * (1.0f + u) * (1.0f - v);
	n[2] = 0.25f * (1.0f + u) * (1.0f + v);
	n[3] = 0.25f * (1.0f - u) * (1.0f + v);

	vec2 p = n[0] * tex[0] + n[1] * tex[1] + n[2] * tex[2] + n[3] * tex[3];
	return p;
}

#elif defined(SHADER_TRIA3)
vec2 get_fringe_exact_tex(vec3 fringe_uv, vec2 tex[3])
{
	if (all(equal(tex[0], tex[1])) == true && all(equal(tex[1], tex[2])) == true) return tex[0];

	float u = fringe_uv.x;
	float v = fringe_uv.y;
	float w = fringe_uv.z;

	float n[3];
	n[0] = w; /* ( 0, 0) */
	n[1] = u; /* ( 1, 0) */
	n[2] = v; /* ( 0, 1) */

	vec2 p = n[1] * tex[0] + n[2] * tex[1] + n[0] * tex[2];
	return p;
}

#elif defined(SHADER_TRIA6)
vec2 get_fringe_exact_tex(vec3 fringe_uv, vec2 tex[6])
{
	if (all(equal(tex[0],tex[1])) == true && all(equal(tex[1],tex[2])) == true && all(equal(tex[2],tex[3])) == true && 
			all(equal(tex[3],tex[4])) == true && all(equal(tex[4],tex[5])) == true) return tex[0];

	float u = fringe_uv.x;
	float v = fringe_uv.y;
	float w = fringe_uv.z;

	float n[6];
	n[0] = -w * (1.0f - 2.0f * w); 	/* (0, 0) */
	n[1] = 4.0f * u * w;			/* (0.5, 0) */
	n[2] = -u * (1.0f - 2.0f * u);	/* (1.0, 0) */
	n[3] = 4.0f * u * v;			/* (0.5, 0.5) */
	n[4] = -v * (1.0f - 2.0f * v);	/* (0.0, 1.0) */
	n[5] = 4.0f * v * w;			/* (0, 0.5) */

	vec2 p = n[2] * tex[0] + n[0] * tex[1] + n[4] * tex[2] +
			n[1] * tex[3] + n[5] * tex[4] + n[3] * tex[5];
	return p;
}

#elif defined(SHADER_QUAD8)
vec2 get_fringe_exact_tex(vec2 fringe_uv, vec2 tex[8])
{
	if (all(equal(tex[0],tex[1])) == true && all(equal(tex[1],tex[2])) == true &&
		all(equal(tex[2],tex[3])) == true && all(equal(tex[3],tex[4])) == true && 
		all(equal(tex[4],tex[5])) == true && all(equal(tex[5],tex[6])) == true && 
		all(equal(tex[6],tex[7])) == true) return tex[0];

	vec2 uv = fringe_uv * vec2(2.0f) - vec2(1.0f);
	float u = uv.x;
	float v = uv.y;
	
	float n[8];
	n[0] = -0.25 * (1.0-u) * (1.0-v) * (1.0+u+v); /* (-1,-1) */
	n[1] =  0.50 * (1.0-u*u) * (1.0-v);			  /* ( 0,-1) */
	n[2] = -0.25 * (1.0+u) * (1.0-v) * (1.0-u+v); /* ( 1,-1) */
	n[3] =  0.50 * (1.0+u) * (1.0-v*v);			  /* ( 1, 0) */
	n[4] = -0.25 * (1.0+u) * (1.0+v) * (1.0-u-v); /* ( 1, 1) */
	n[5] =  0.50 * (1.0-u*u) * (1.0+v);			  /* ( 0, 1) */
	n[6] = -0.25 * (1.0-u) * (1.0+v) * (1.0+u-v); /* (-1, 1) */
	n[7] =  0.50 * (1.0-u) * (1.0-v*v);			  /* (-1, 0) */

	vec2 p = n[2] * tex[0] + n[0] * tex[1] + n[6] * tex[2] + n[4] * tex[3] + n[1] * tex[4] +
			n[7] * tex[5] + n[5] * tex[6] + n[3] * tex[7];
	return p;
}

#endif
#endif

#if defined(SHADER_CONTOUR_FRAG_FILL) || defined(SHADER_CONTOUR_FRAG_LINE)
struct ContourFragSettings
{
    float frag_color_factor;
    vec4  texContour;
};

ContourFragSettings calc_fragcolor_factor()
{
	ContourFragSettings settings;
#if defined(SHADER_FRINGE_BOTTOM)
    // meta has reversed top and bottom
#if defined(SHADER_FRINGE_EXACT)
	vec2 temp_tex = get_fringe_exact_tex(fs_in.fringe_barycentric, is_front_facing() ? fs_in.tex_bottom : fs_in.tex_top);
#else
	vec2 temp_tex = is_front_facing() ? fs_in.tex_bottom : fs_in.tex_top;
#endif// SHADER_FRINGE_EXACT
#elif defined(SHADER_FRINGE) 
#if defined(SHADER_FRINGE_EXACT)
    vec2 temp_tex = get_fringe_exact_tex(fs_in.fringe_barycentric, fs_in.tex_top);
#else
    vec2 temp_tex = fs_in.tex_top;
#endif // SHADER_FRINGE_EXACT
#endif
	float fringeCoordLocal = temp_tex.s;
	float factor = 1.0f;
	float cou_size  = globals.contour_fringe_params.x;
	float cou_tex_val = fringeCoordLocal*cou_size;
	float cou_dsize;
	cou_dsize = globals.contour_line_plot_width_factor.r * cou_size*max( abs(dFdx(fringeCoordLocal)), abs(dFdy(fringeCoordLocal)) );
	float cou_zzz = abs( cou_tex_val - sign(cou_tex_val)*floor(abs(cou_tex_val)+0.5) );

	if( cou_zzz>0 && cou_tex_val<=globals.contour_fringe_params.y && cou_tex_val>=globals.contour_fringe_params.z ){
		factor = smoothstep(-cou_dsize, cou_dsize, cou_zzz);
		if (factor > 1.5f) {
			factor = pow(factor, globals.contour_line_plot_width_factor.r);
		}
	}
#if defined(SHADER_CONTOUR_FRAG_LINE)
    factor = 1.0 - pow(max(0.0, abs(factor) * 2.0 - 1.0 ), 0.7 );
#endif

#if !defined(SHADER_CONTOUR_FRAG_LINE)
	settings.frag_color_factor = (temp_tex.t > 0.5) ? 1.0 : factor;
#else 
	settings.frag_color_factor = factor;
#endif
	settings.texContour = texture(texturef, vec2(fringeCoordLocal - 0.5 / cou_size, 0.0f));
	
	return settings;
}
#endif

vec3 unpack_normal()
{
/*    f16vec2 pn = fs_in.packed_normal;*/
/*    float pnz = sqrt(1.0 - pn.x * pn.x - pn.y * pn.y);*/
/*    vec3 normal = normalize(vec3(pn.x, pn.y, pnz));*/
#if defined(SHADER_SMOOTH_NORMALS)
    return normalize(fs_in.normal);
#else 
    return normalize(unpack_snorm_4x8(fs_in.flat_normal).xyz);
#endif
}

vec4 get_projection_space_position()
{
    vec4 ndc_pos;
    ndc_pos.xy = ((2.0 * gl_FragCoord.xy) - (2.0 * globals.viewport.xy)) / (globals.viewport.zw) - 1.0;

	float depth = gl_FragCoord.z;
    ndc_pos.z  = (2.0 * depth - gl_DepthRange.near - gl_DepthRange.far) / 
                 (gl_DepthRange.far - gl_DepthRange.near);
    ndc_pos.w  = 1.0;

    vec4 clip_pos = ndc_pos / gl_FragCoord.w;
	return clip_pos;
}

vec4 get_view_space_position()
{
#if defined(SHADER_SINGLE_PASS_STEREO)
	vec4 view_pos;
	if (gl_Layer == 0) {
		view_pos = globals.iprojection_matrix * get_projection_space_position();
	} else if (gl_Layer == 1) {
		view_pos = globals.iright_projection_matrix * get_projection_space_position();		
	}
#else
    vec4 view_pos = globals.iprojection_matrix * get_projection_space_position();
#endif // SHADER_SINGLE_PASS_STEREO

    return view_pos;
}

vec4 get_world_space_position()
{
#if defined(SHADER_SINGLE_PASS_STEREO)
	vec4 world_pos;
	if (gl_Layer == 0) {
		world_pos = globals.iview_matrix * get_view_space_position();
	} else if (gl_Layer == 1) {
		world_pos = globals.iright_view_matrix * get_view_space_position();
	}
#else
	vec4 world_pos = globals.iview_matrix * get_view_space_position();
#endif // SHADER_SINGLE_PASS_STEREO

	return world_pos;
}

vec4 get_local_space_position()
{
#if defined(SHADER_SINGLE_PASS_STEREO)
	vec4 local_pos;
	if (gl_Layer == 0) {
		local_pos = globals.iview_matrix * get_view_space_position();
	} else if (gl_Layer == 1) {
		local_pos = globals.iright_view_matrix * get_view_space_position();
	}
#else
	vec4 local_pos = inverse(pid_uniforms.explode_matrix) * globals.iview_matrix * get_view_space_position();
#endif // SHADER_SINGLE_PASS_STEREO

	return local_pos;
}

vec4 get_view_space_normal()
{
// TODO KATRASD BMW_ENV
// #if defined(SHADER_PBR_TEXTURE) && defined(SHADER_USE_TEX_COORDS)
// 	if (normal_texture_exists == 1) {
// 		return texture(normal_texture, fs_in.tex_coords);
// 	}
// #endif
#if (defined(SHADER_USE_NODAL_NORMALS) || defined(SHADER_USE_NODAL_NORMALS_3F)) && !defined(SHADER_THICK_SHELLS)
	#if defined(SHADER_REVERSE_NORMALS)
		#if defined(SHADER_USE_NODAL_NORMALS_3F)
			return is_front_facing() ? -vec4(fs_in.nodal_normals, 0.0) : vec4(fs_in.nodal_normals, 0.0);
		#else
		    // obj && fbx
			return vec4(fs_in.nodal_normals, 0.0);
		#endif
	#else
	    // extra (failed solids and lagrange clipped elements)
		return is_front_facing() ? vec4(fs_in.nodal_normals, 0.0) : -vec4(fs_in.nodal_normals, 0.0);
	#endif
#elif defined(SHADER_THICK_SHELLS)
	vec4 view_normal = vec4(unpack_normal(), 0.0);
	#if defined(SHADER_SMOOTH_NORMALS)
		view_normal = is_front_facing() ? view_normal : -view_normal;
	#endif
	return view_normal;
#else
	vec4 view_normal = vec4(unpack_normal(), 0.0);
	view_normal = is_front_facing() ? view_normal : -view_normal;
	return view_normal;
#endif
}

vec4 get_local_space_normal()
{
	vec4 local_normal = globals.iview_matrix * get_view_space_normal();
	return normalize(local_normal);
}

// vec4 get_world_space_normal()
// {
// 	vec4 world_normal = globals.iview_matrix * get_view_space_normal();
// 	
// 	return world_normal;
// }

/****************** LIC FUNCTIONS ******************/
#if defined(SHADER_LIC_OVERLAY)
	uniform sampler2D texLIC0;

  #if defined(SHADER_LIC_LAY_COMPOSE)
		uniform sampler2D texLIC1;
		uniform sampler2D texLIC2;
		uniform sampler2D texLIC3;

		float cascadeSizeFromLevel(float c_level) {
			return 1. / exp2(c_level);
		}

		vec2 sampleToCascadeAtQ4(vec2 tc, float c_level) {
			float c_value = cascadeSizeFromLevel(c_level);
			return vec2(c_value) * tc;
		}

		float interLevelSigmoidTransf(float cLevel_interp, float steepness) {
			float rejection = .1;
			return clamp((1. + 2. * rejection) / (1. + exp(-6 * steepness * (cLevel_interp - .5))) - rejection, .0, 1.);
		}

        vec2 orientMixing3Q(sampler2D texSrc) {
        	vec2 layMix, p, s, t;
        	vec3 src, mask, lay;
			vec3 srcWt = fs_in.vr_srcWt;
			float cLevel = fs_in.vr_cLevel;

			float cLevel_up = floor(cLevel);
			float cLevel_down = ceil(cLevel);
			float cLevel_interp = cLevel - cLevel_up;

			cLevel_interp = interLevelSigmoidTransf(cLevel_interp, 2.);

			vec2 tc_u_p = sampleToCascadeAtQ4(fs_in.vr_licCoords_p, cLevel_up);
			vec2 tc_u_s = sampleToCascadeAtQ4(fs_in.vr_licCoords_s, cLevel_up);
			vec2 tc_u_t = sampleToCascadeAtQ4(fs_in.vr_licCoords_t, cLevel_up);

			vec2 tc_d_p = sampleToCascadeAtQ4(fs_in.vr_licCoords_p, cLevel_down);
			vec2 tc_d_s = sampleToCascadeAtQ4(fs_in.vr_licCoords_s, cLevel_down);
			vec2 tc_d_t = sampleToCascadeAtQ4(fs_in.vr_licCoords_t, cLevel_down);
        
        	p = mix(texture(texSrc, tc_u_p).st, texture(texSrc, tc_d_p).st, vec2(cLevel_interp));
        	s = mix(texture(texSrc, tc_u_s).st, texture(texSrc, tc_d_s).st, vec2(cLevel_interp));
        	t = mix(texture(texSrc, tc_u_t).st, texture(texSrc, tc_d_t).st, vec2(cLevel_interp));
        
        	src.x = p.s;
        	src.y = s.s;
        	src.z = t.s;
        
        	mask.x = p.t;
        	mask.y = s.t;
        	mask.z = t.t;
        
        	layMix.s = dot(srcWt, src);
        	layMix.t = dot(srcWt, mask);
        
        	return layMix;
        }
	#else //!SHADER_LIC_LAY_COMPOSE
		//varying vec2 vr_licCoords;
    #endif //SHADER_LIC_LAY_COMPOSE

    vec4 applyLIC(vec4 ext_colour) {
    	float licComp;
		vec4 resCol;

        #if defined(SHADER_LIC_LAY_COMPOSE)
        	vec4 lic;
        
        	lic.s = orientMixing3Q(texLIC0).s;
        	lic.t = orientMixing3Q(texLIC1).s;
        	lic.p = orientMixing3Q(texLIC2).s;
        	lic.q = orientMixing3Q(texLIC3).s;
        
        	licComp = dot(fs_in.vr_layWt, lic);
        #else //!SHADER_LIC_LAY_COMPOSE
        	licComp = texture(texLIC0, fs_in.vr_licCoords).s;
        #endif //SHADER_LIC_LAY_COMPOSE

		resCol = vec4(ext_colour.rgb * mix(1., licComp, fs_in.vr_mask), ext_colour.a);
		return resCol;
    }
#endif
/***************************************************/

/********* WEIGHTED BLENDED TRANSPARENCY ACCUMULATION FUNCTION ****************/
#if defined(SHADER_OIT_WB_ACCUM)
void wb_transparency_accumulation(vec4 color, out vec4 accum, out float reveal)
{
    const float epsilon = 1e-5;
    float linear_depth = get_view_space_position().z + globals.wboit_constants.x;

    float scale = 1.0 / (2.0 * globals.wboit_constants.y);
    vec4 premult = vec4(color.rgb * color.a, color.a);

    // function (9) in paper
    float weight = pow(color.a, 3) *
        clamp(0.03 / (epsilon + pow(abs(linear_depth) * scale, 4)), 1e-2, 3e3);

#if defined(SYSTEM_DRAW_BUFFERS_BLEND)
    accum = premult * weight;
    reveal = color.a;
#else
    // here we do not use per render target blend functions (pre OpenGL 4.0)
    // we instead store the revealage in the accum.a and the weighted alpha in reveal
    accum = vec4(premult.rgb * weight, color.a);
    reveal = color.a * weight;
#endif
}
#endif
/******************************************************************************/

/********* DEPTH PEELING FUNCTION ****************/
#if defined (SHADER_OIT_DEPTH_PEEL)
bool depth_peel_check(ivec2 frag_coord)
{
    const float front_depth_bias = 0.0000001;
    float fd0 = texelFetch(front_depth_tex, frag_coord, 0).r;
#if defined(SHADER_MSAA)
    // depth peeling needs per sample evaluation to be 100 percent correct
    // but just comparing with all the depth samples does the job 
    // default samples is at least 2 (check bwgl/post_aa.c)
    float fd1 = texelFetch(front_depth_tex, frag_coord, 1).r;
#if (SYSTEM_MSAA_SAMPLES >= 4)
    float fd2 = texelFetch(front_depth_tex, frag_coord, 2).r;
    float fd3 = texelFetch(front_depth_tex, frag_coord, 3).r;
#endif
#if (SYSTEM_MSAA_SAMPLES >= 8) 
    float fd4 = texelFetch(front_depth_tex, frag_coord, 4).r;
    float fd5 = texelFetch(front_depth_tex, frag_coord, 5).r;
    float fd6 = texelFetch(front_depth_tex, frag_coord, 6).r;
    float fd7 = texelFetch(front_depth_tex, frag_coord, 7).r;
#endif

    fd0 = max(fd0, fd1);
#if (SYSTEM_MSAA_SAMPLES >= 4)
    fd2 = max(fd2, fd3);
    fd0 = max(fd0, fd2);
#endif
#if (SYSTEM_MSAA_SAMPLES >= 8)
    fd4 = max(fd4, fd5);
    fd6 = max(fd6, fd7);
    fd4 = max(fd4, fd6);
    fd0 = max(fd0, fd4);
#endif
#endif

	float depth = gl_FragCoord.z;

    return (depth <= fd0 + front_depth_bias);
}
#endif
/*************************************************/

#if defined(SHADER_COLOR_VARIANCE) && defined(SHADER_COLOR_VARIANCE_2_SIDE)
void uncompress_2_side_color(uint color_front_back, out vec4 color_f, out vec4 color_b)
{
	uint front_rgb[3], back_rgb[3];

	front_rgb[2] = (color_front_back >> 27) & 0x1fu;
	front_rgb[1] = (color_front_back >> 21) & 0x3fu;
	front_rgb[0] = (color_front_back >> 16) & 0x1fu;

	back_rgb[2] = (color_front_back >> 11) & 0x1fu;
	back_rgb[1] = (color_front_back >>  5) & 0x3fu;
	back_rgb[0] = color_front_back         & 0x1fu;


	float b = front_rgb[2] / 31.f;
	float g = front_rgb[1] / 63.f;
	float r = front_rgb[0] / 31.f;

	color_f = vec4(r, g, b, 1.);

	b = back_rgb[2] / 31.f;
	g = back_rgb[1] / 63.f;
	r = back_rgb[0] / 31.f;

	color_b = vec4(r, g, b, 1.);
}
#endif

#if defined(SHADER_SSAO_DEPTH_PRE_PASS)
void write_depth_prepass()
{
    vec3 view_pos = get_view_space_position().xyz;
    vec3 view_normal = normalize(cross(dFdx(view_pos), dFdy(view_pos)));
	out_depth_prepass_normal = view_normal;
}
#endif

#if defined(SHADER_DEPTH_AS_COLOR)
float linearize_depth(float depth) // depth is [0,1]
{
	float ndc_z = depth * 2.0 - 1.0; // back to NDC [-1,1]
	float tnear = globals.camera.tnear;
	float tfar  = globals.camera.tfar;
	float linear_depth = (2.0 * tnear * tfar) / (ndc_z * (tfar - tnear) - (tfar + tnear));
	float gray_val = (tnear + linear_depth) / (tnear - tfar);
	return gray_val;
}
#endif

void main(void)
{
#if defined(SHADER_SSAO_DEPTH_PRE_PASS)
    write_depth_prepass();
#elif defined(SHADER_SHADOW_DIR_PASS)
    variance_depth = computeShadowMoments(gl_FragCoord.z);
#else // !SHADER_SSAO_DEPTH_PRE_PASS && !SHADER_SHADOW_DIR_PASS
#if defined(SHADER_DYNAMIC_LABELLING_RENDER_OCCUPANCY)
	out_color = vec4(1.0);
	return;
#endif

#if defined(SHADER_OIT_SECOND_PASS)
    // enable this only in the 2nd oit pass
    if (depth_peel_check(ivec2(gl_FragCoord.xy))) { discard; }
#endif

    vec3 view_normal = get_view_space_normal().xyz;
    vec3 view_pos = get_view_space_position().xyz;
	vec4 color = vec4(0.0, 0.0, 0.0, 1.0);

#if defined(SHADER_FRINGE)
#if defined(SHADER_FRINGE_BOTTOM)
    // meta has reversed top and bottom
#if defined(SHADER_FRINGE_EXACT)
    vec2 ftex = get_fringe_exact_tex(fs_in.fringe_barycentric, is_front_facing() ? fs_in.tex_bottom : fs_in.tex_top);
#else
	vec2 ftex = is_front_facing() ? fs_in.tex_bottom : fs_in.tex_top;
#endif // SHADER_FRINGE_EXACT
#else
#if defined(SHADER_FRINGE_EXACT)
    vec2 ftex = get_fringe_exact_tex(fs_in.fringe_barycentric, fs_in.tex_top);
#else
	vec2 ftex = fs_in.tex_top;
#endif // SHADER_FRINGE_EXACT
#endif // SHADER_FRINGE_BOTTOM

#if defined(SYSTEM_MESA_LLVM) && !defined(SHADER_FRINGE_NODE_TOP_TEX)
	// TODO GOUZ check when unification of fringes is done on ANSA/META
	// GL_NEAREST is a little buggy on mesa, when we have huge values below and above (0, 1) it is not working correctly
    ftex = clamp(ftex, vec2(0.0), vec2(1.0));
#endif 

#if defined(SHADER_FRINGE_NODE_TOP) && defined(SHADER_FRINGE_NODE_TOP_TEX)
	color = texture(texturef, ftex.x);
#else 
    color = texture(texturef, ftex);
#endif

#elif defined(SHADER_USE_NODAL_COLOR)
	color = fs_in.nodal_color;
#endif // SHADER_FRINGE

#if (defined(SHADER_FRINGE) && (defined(SHADER_CONTOUR_FRAG_FILL) || defined(SHADER_CONTOUR_FRAG_LINE)))
	ContourFragSettings contourSettings = calc_fragcolor_factor();
	#if defined(SHADER_CONTOUR_FRAG_FILL)
		color.rgb = contourSettings.frag_color_factor * color.rgb;
	#elif defined(SHADER_CONTOUR_FRAG_LINE)
		color.rgb = mix(pid_uniforms.material_data.diffuse.rgb, contourSettings.texContour.rgb, contourSettings.frag_color_factor);
	#endif
#endif

#if defined(SHADER_COLOR_VARIANCE) && !defined(SHADER_COLOR_VARIANCE_2_SIDE)
    vec4 var_color = unpack_unorm_4x8(fs_in.var_color);
#if defined(SHADER_FRINGE)
    color = (var_color.a < 1.0) ? var_color : color;
#else 
    color = var_color;
#endif
#endif

#if defined(SHADER_COLOR_VARIANCE) && defined(SHADER_COLOR_VARIANCE_2_SIDE)
    uint packed_var_color = fs_in.var_color;
	vec4 var_color_top;
	vec4 var_color_bot;
	if ((packed_var_color & 0x0000ffffu) > 0u) { // not inactive part, not transparent
		uncompress_2_side_color(packed_var_color, var_color_top, var_color_bot);
	} else if (packed_var_color > 0u) { // not inactive part but transparent 
		uncompress_2_side_color(packed_var_color, var_color_top, var_color_bot);
		var_color_top.a = 0.4;
		var_color_bot = var_color_top;
	} else {
		var_color_top = globals.inactive_color_baseline;
		var_color_bot = var_color_top;
	}
	color = is_front_facing() ? var_color_top : var_color_bot;
#endif

#if defined(SHADER_TWO_SIDE) && !defined(SHADER_COLOR_VARIANCE)
	color = is_front_facing() ? globals.ent_mode_top_color : globals.ent_mode_bottom_color;
#endif 
#if defined(SHADER_TWO_SIDE) && defined(SHADER_COLOR_VARIANCE)
	color = is_front_facing() ? vec4(globals.ent_mode_top_color.rgb, color.a) : vec4(globals.ent_mode_bottom_color.rgb, color.a);
#endif 


#if defined(SHADER_LIGHT)
	vec4 lighted_color = applyLighting(color, view_normal, get_view_space_position().xyz);
	#if defined(SHADER_LIGHT_VARIANCE) && defined(SHADER_COLOR_VARIANCE)
		bool apply_light = (fs_in.var_color & 0xFFFFFFu) == (floatBitsToUint(globals.variable_light_color_baseline.w) & 0xFFFFFFu);
		lighted_color = apply_light ? lighted_color : color;
	#endif
	#if defined(SHADER_CONTOUR_FRAG_LINE)
		color = mix(lighted_color, color, contourSettings.frag_color_factor);
	#else 
		color = lighted_color;
	#endif
#else // No light
	#if defined(SHADER_STL_MATERIAL)
		#if defined(SHADER_COLOR_VARIANCE) || defined(SHADER_COLOR_VARIANCE_EXTRA) || defined(SHADER_FRINGE) || defined(SHADER_TWO_SIDE)
			color = color;
		#else
			color = pid_uniforms.material_data.diffuse;
		#endif
	#elif defined(SHADER_PBR_MATERIAL)
		color = GRAY;
	#endif
#endif

#if defined(SHADER_SELECTION_HIGHLIGHT)
	color = selection_highlight_color;
#endif

#if defined(SHADER_FILL) && defined(SHADER_HIDDEN)
	color = globals.background_color;
#endif

#if !defined(SHADER_USE_BLUR) && defined(SHADER_BARYCENTRICS)
    float edge_factor = edge_factor(fs_in.barycentric);
#else 
    float edge_factor = 1.0;
#endif
#if defined(SHADER_USE_BLUR)
	vec4 velocity_color = GRAY;
	vec3 vectBlur = fs_in.velocity_color;
	vec3 blur_factor = model_uniforms.blur_scale_factor.xyz;
#if defined(SHADER_SINGLE_PASS_STEREO)
	vec2 scrVect;
	if (gl_Layer == 0) {
		scrVect = (globals.projection_matrix * globals.view_matrix * vec4(vectBlur * blur_factor, 0.0)).xy * globals.viewport.zw; // TODO KATRASD BLUR Check if model matrix is also needed (explode, etc)
	} else {
		scrVect = (globals.right_projection_matrix * globals.right_view_matrix * vec4(vectBlur * blur_factor, 0.0)).xy * globals.viewport.zw; // TODO KATRASD BLUR Check if model matrix is also needed (explode, etc)
	}
#else
	vec2 scrVect = (globals.projection_matrix * globals.view_matrix * vec4(vectBlur * blur_factor, 0.0)).xy * globals.viewport.zw; // TODO KATRASD BLUR Check if model matrix is also needed (explode, etc)
#endif // SHADER_SINGLE_PASS_STEREO
	scrVect *= vec2(gl_FragCoord.w);
	velocity_color = vec4(write_bias_scale(scrVect), 0.5, 1.0);

	out_velocity = velocity_color;
	out_color = color;
#else

#if defined(SHADER_ALPHA_TEST_OPAQUE)
    if (color.a <  0.999) discard;
#elif defined(SHADER_ALPHA_TEST_TRANSPARENT)
    if (color.a >= 0.999) discard;
#endif

	vec4 wire_color = vec4(globals.mesh_lines_color_width.xyz, 1.0);
#if defined(SHADER_OIT_WB_ACCUM) // DEFAULT CASE WITH OIT
    vec4 accum;
    float reveal;
    color = mix(wire_color, color, edge_factor);
    wb_transparency_accumulation(color, accum, reveal);
    out_color = accum;
    out_wboit_reveal = reveal;
#else // DEFAULT CASE WITHOUT OIT
    out_color = mix(wire_color, color, edge_factor);
#endif
#endif

#if defined(SHADER_LIC_OVERLAY)
	out_color = applyLIC(out_color);
#endif
#if defined(SHADER_LIC_SCREEN_SPACE)
	out_vectors = vec3(fs_in.vr_scrVect, fs_in.vr_mask);
#endif
#if defined(SHADER_DEPTH_AS_COLOR)
	float depth = linearize_depth(gl_FragCoord.z);
	out_color = vec4(vec3(depth), 1.0);
#endif
#endif // END SHADER_SSAO_DEPTH_PRE_PASS
}

