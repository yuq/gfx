#version 330 compatibility
#define SHADER_VER330
#define SYSTEM_DRAW_BUFFERS_BLEND
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



#if defined(SHADER_PBR_MATERIAL)
#define PidUniformData PidUniformDataPBR
#define MaterialData   PBRMaterialData 
#else
#define PidUniformData PidUniformDataSTL
#define MaterialData   STLMaterialData 
#endif

layout(std140, binding = SHADER_GLOBAL_BUFFER_BINDING) uniform global_buffer
{
	UniformGlobals globals;
};

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

layout(binding = SHADER_3DMODEL33_FEATURE_LINES_TU_FRAG_FRINGE_BAR_BINDING) uniform sampler2D texturef;
#if defined(SHADER_SELECTION_HIGHLIGHT)
layout(location = SHADER_3DMODEL33_FEATURE_LINES_SELECTION_HIGHLIGHT_COLOR_UNIFORM_LOC) uniform vec4 selection_color;
#endif

in VertexOut
{
	flat int not_used;
#if defined(SHADER_MULTI_DRAW_INDIRECT)
	flat int part_idx;
#endif
#if defined(SHADER_FRINGE_NODE)
    vec2 tex_top;
#endif
#if defined(SHADER_USE_NODAL_COLOR)
	vec4 nodal_color;
#endif
} fs_in;

layout(location = 0) out vec4 out_color;

void main()
{
#if defined(SHADER_DYNAMIC_LABELLING_RENDER_OCCUPANCY)
	out_color = vec4(1.0);
	return;
#endif
#if defined(SHADER_FRINGE_NODE) 
    vec2 ftex = fs_in.tex_top;
#if defined(SYSTEM_MESA_LLVM)
	// GL_NEAREST is a little buggy on mesa, when we have huge values below and above (0, 1) it is not working correctly
    // this change may not be needed here, but we need to be the same as with 3dmodel33 shader
    ftex = clamp(ftex, vec2(0.0), vec2(1.0));
#endif 
    out_color = texture(texturef, ftex);
#elif defined(SHADER_STL_MATERIAL) 
    out_color = vec4(pid_uniforms.material_data.diffuse.rgb, 1.0);
#elif defined(SHADER_USE_NODAL_COLOR) 
    out_color = fs_in.nodal_color;
#elif defined(SHADER_SELECTION_HIGHLIGHT)
    out_color = selection_color;
#else // global color
	out_color = vec4(globals.mesh_lines_color_width.xyz, 1.0);
#endif
}
