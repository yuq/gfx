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



/********** DERIVED DEFINITIONS ************/
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
#if defined(SHADER_FRINGE_NODE_TOP) || defined(SHADER_FRINGE_CORNER_TOP) || defined(SHADER_FRINGE_CENTROID_TOP)
#define SHADER_FRINGE_TOP
#endif
#if defined(SHADER_FRINGE_NODE_BOTTOM) || defined(SHADER_FRINGE_CORNER_BOTTOM) || defined(SHADER_FRINGE_CENTROID_BOTTOM) 
#define SHADER_FRINGE_BOTTOM
#endif

#if defined(SHADER_FRINGE_NODE) || defined(SHADER_FRINGE_ELEM)
#define SHADER_FRINGE
#endif

#if (defined(SHADER_FRINGE) && defined(SHADER_FRINGE_QUALITY) && (defined(SHADER_QUAD4) || defined(SHADER_TRIA3) || defined(SHADER_SECOND_ORDER)))
#define SHADER_FRINGE_EXACT
#endif

#if defined(SHADER_WIRE) && defined(SHADER_FILL) && !defined(SHADER_TRIA6)
#define SHADER_BARYCENTRICS
#endif

#if defined(SHADER_FRINGE_TOP) || defined(SHADER_FRINGE_BOTTOM) || defined(SHADER_LIC_LAY_COMPOSE) || defined(SHADER_LIC_SCREEN_SPACE) || defined(SHADER_SMOOTH_NORMALS)
#define SHADER_NEED_FOR_PRIMDATA
#endif

#if defined(SHADER_LIC_LAY_COMPOSE) || defined(SHADER_LIC_SCREEN_SPACE)
#define SHADER_NEED_FOR_MODNORMALS
#endif

#if !defined(SHADER_FILL) && defined(SHADER_WIRE) 
#define SHADER_ONLY_WIRE
#endif

#if defined(SHADER_OIT_WB_ACCUM) || defined(SHADER_OIT_DEPTH_PEEL)
#define SHADER_OIT
#endif
#if defined(SHADER_OIT_WB_ACCUM) && defined(SHADER_OIT_DEPTH_PEEL)
#define SHADER_OIT_SECOND_PASS
#endif
#if defined(SHADER_THICK_SHELLS_GET_FRINGE_TOP) || defined(SHADER_THICK_SHELLS_GET_FRINGE_BOTTOM)
#define SHADER_THICK_SHELLS_GET_FRINGE
#endif
#if defined(SHADER_THICK_SHELLS_GET_PART) || defined(SHADER_THICK_SHELLS_GET_OPTT) || defined(SHADER_THICK_SHELLS_GET_FRINGE) || defined(SHADER_THICK_SHELLS_GET_NODAL_THICKNESS) || defined(SHADER_THICK_SHELLS_GET_CORNER_THICKNESS)
#define SHADER_THICK_SHELLS
#endif


/******* End of DERIVED DEFINITIONS ********/

// set fringe interpolation qualifer
#if defined(SHADER_FRINGE_CENTROID)
    #define FRINGE_INTERP flat
#else 
    #define FRINGE_INTERP 
#endif

layout(std140, binding = SHADER_GLOBAL_BUFFER_BINDING) uniform global_buffer
{
	UniformGlobals globals;
};

layout(std140, binding = SHADER_MODEL_BUFFER_BINDING) uniform per_model_buffer
{
	ModelUniformData model_uniforms;
};

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
#define pid_uniforms pid_uniforms_multi[gs_in[0].part_idx]

#else 

layout(std140, binding = SHADER_3DMODEL33_PER_PID_BUFFER_BINDING) uniform per_pid_buffer
{
	PidUniformData pid_uniforms;
};

#endif

#if defined(SHADER_SHADOW_DIR_PASS)
layout(location = SHADER_3DMODEL33_SHADOW_DIR_LIGHT_LOC) uniform int current_dir_light;
#endif

#if defined(SHADER_FILL) 
 	#if defined(SHADER_THICK_SHELLS)
 		#if defined(SHADER_TWO_SIDE) || defined(SHADER_FRINGE_BOTTOM)
 			#if defined(SHADER_TRIA3)
 				layout(triangles) in;
 				layout(triangle_strip, max_vertices = 32) out; // 42 with trias
 			#elif defined(SHADER_QUAD4)
 				layout(lines_adjacency) in;
 				layout(triangle_strip, max_vertices = 40) out; // 60 with trias
 			#elif defined(SHADER_TRIA6)
 				layout(triangles_adjacency) in;
 				layout(triangle_strip, max_vertices = 52) out; // 96 with trias
 			#elif defined(SHADER_QUAD8)
 				layout(triangles_adjacency) in;
 				layout(triangle_strip, max_vertices = 38) out; // 66 with trias
 			#endif
 		#else
 			#if defined(SHADER_TRIA3)
 				layout(triangles) in;
 				layout(triangle_strip, max_vertices = 18) out; // 24 with trias
 			#elif defined(SHADER_QUAD4)
 				layout(lines_adjacency) in;
 				layout(triangle_strip, max_vertices = 24) out; // 36 with trias
 			#elif defined(SHADER_TRIA6)
 				layout(triangles_adjacency) in;
 				layout(triangle_strip, max_vertices = 34) out; // 60 with trias
 			#elif defined(SHADER_QUAD8)
 				layout(triangles_adjacency) in;
 				layout(triangle_strip, max_vertices = 24) out; // 42 with trias
 			#endif
 		#endif
 	#else
 		#if defined(SHADER_TRIA3)
 			layout(triangles) in;
 			layout(triangle_strip, max_vertices = GS_TRIA3_MAXVERT) out;
 		#elif defined(SHADER_QUAD4)
 			layout(lines_adjacency) in;
 			layout(triangle_strip, max_vertices = GS_QUAD4_MAXVERT) out;
 		#elif defined(SHADER_TRIA6)
 			layout(triangles_adjacency) in;
 			layout(triangle_strip, max_vertices = GS_TRIA6_MAXVERT) out;
 		#elif defined(SHADER_QUAD8)
 			layout(triangles_adjacency) in;
 			layout(triangle_strip, max_vertices = GS_QUAD8_MAXVERT) out;
		#elif defined(SHADER_POLYGON)
 			layout(triangles_adjacency) in;
 			layout(triangle_strip, max_vertices = GS_POLYGON_PATCH_MAXVERT) out;
 		#endif
	#endif		
#else  // WIRE ONLY
 	#if defined(SHADER_THICK_SHELLS)
		#if defined(SHADER_TRIA3)
		layout(triangles) in;
		layout(line_strip, max_vertices = 23) out;
		#elif defined(SHADER_QUAD4)
		layout(lines_adjacency) in;
		layout(line_strip, max_vertices = 30) out;
		#elif defined(SHADER_TRIA6)
		layout(triangles_adjacency) in;
		layout(line_strip, max_vertices = 35) out;
		#elif defined(SHADER_QUAD8)
		layout(triangles_adjacency) in;
		layout(line_strip, max_vertices = 17) out;
		#endif
	#else
		#if defined(SHADER_TRIA3)
		layout(triangles) in;
		layout(line_strip, max_vertices = 4) out;
		#elif defined(SHADER_QUAD4)
		layout(lines_adjacency) in;
		layout(line_strip, max_vertices = 5) out;
		#elif defined(SHADER_TRIA6)
		layout(triangles_adjacency) in;
		layout(line_strip, max_vertices = 7) out;
		#elif defined(SHADER_QUAD8)
		layout(triangles_adjacency) in;
		layout(line_strip, max_vertices = 5) out;
		#elif defined(SHADER_POLYGON)
		layout(triangles_adjacency) in;
		layout(line_strip, max_vertices = 3) out;
		#endif
	#endif
#endif

#if defined(SHADER_VISIBILITY_VARIANCE)
layout(binding = SHADER_3DMODEL33_TU_GEOM_VISIBILITY_BINDING) uniform usamplerBuffer elem_visibility;
#endif
#if defined(SHADER_FRINGE_ELEM) || (defined(SHADER_QUAD8) && defined(SHADER_FRINGE_EXACT) && defined(SHADER_FRINGE_NODE))
layout(binding = SHADER_3DMODEL33_TU_GEOM_ELEM_FUNC_TOP_BINDING) uniform samplerBuffer elem_func_top;
layout(binding = SHADER_3DMODEL33_TU_GEOM_ELEM_FUNC_BOTTOM_BINDING) uniform samplerBuffer elem_func_bottom;
#endif
#if defined(SHADER_SMOOTH_NORMALS) || defined(SHADER_LIC_OVERLAY) || defined(SHADER_LIC_SCREEN_SPACE)
layout(binding = SHADER_3DMODEL33_TU_GEOM_NORMALS_BINDING) uniform usamplerBuffer elem_smooth_normals;
#endif
#if defined(SHADER_COLOR_VARIANCE) && !defined(SHADER_EXTRA_ELEMENTS)
layout(binding = SHADER_3DMODEL33_TU_GEOM_COLOR_VARIANCE_BINDING) uniform samplerBuffer elem_var_color;
#endif
#if defined(SHADER_THICK_SHELLS)
layout(binding = SHADER_3DMODEL33_TU_GEOM_THICKNESS_BINDING) uniform samplerBuffer elem_thickness_values;
layout(binding = SHADER_3DMODEL33_TU_GEOM_THICKNESS_ONFEATURE_BINDING) uniform usamplerBuffer elem_thickness_onfeature;
#endif
#if defined(SHADER_THICK_SHELLS) && defined(SHADER_THICK_SHELLS_Z_OFFSET)
layout(binding = SHADER_3DMODEL33_TU_GEOM_THICKNESS_Z_OFFSET_BINDING) uniform samplerBuffer elem_thickness_z_offset;
#endif
#if defined(SHADER_FRINGE_EXACT) && defined(SHADER_QUAD8)
layout(binding = SHADER_3DMODEL33_TU_GEOM_QUAD8_MIDDLE_NODES_BINDING) uniform usamplerBuffer elem_middle_nodes;
#endif

#if defined(SHADER_LIC_OVERLAY)
	#if defined(SHADER_LIC_LAY_COMPOSE)
	uniform sampler2D texLIC0;
	uniform sampler2D texLIC1;
	uniform sampler2D texLIC2;
	uniform sampler2D texLIC3;
	#else //!SHADER_LIC_LAY_COMPOSE
	#endif //SHADER_LIC_LAY_COMPOSE
#endif //SHADER_LIC_OVERLAY

#define MAX_FRINGE_COLORS 256u
#if defined(SHADER_NON_LINEAR_FRINGE)
uniform float non_linear_fringe[MAX_FRINGE_COLORS];
#endif

#if defined(SHADER_LIC_OVERLAY) || defined(SHADER_LIC_SCREEN_SPACE)

vec3 p_axis() {
	return ax_p;
}

vec3 s_axis() {
	return ax_s;
}

vec3 t_axis() {
	return ax_t;
}

vec3 threeAxisDecomp(vec3 vector) {
	vec3 comp;
	comp.x = dot(ax_p, vector);
	comp.y = dot(ax_s, vector);
	comp.z = dot(ax_t, vector);
	return comp;
}

vec4 threeAxisDecomp(vec4 vector) {
	vec4 comp;
	comp.x = dot(ax_p, vector.xyz);
	comp.y = dot(ax_s, vector.xyz);
	comp.z = dot(ax_t, vector.xyz);
	comp.w = vector.w;
	return comp;
}

vec4 vect3ToBase(vec3 vector) {
	vec3 comp = threeAxisDecomp(vector);
	return vec4(comp, .0);
}

vec4 vect4ToBase(vec4 vector) {
	return vect3ToBase(vector.xyz);
}

vec3 transfToBase(vec3 rVec) {
	float xcomp = dot(ax_p, rVec);
	float ycomp = dot(ax_s, rVec);
	return vec3(xcomp, ycomp, .0);
}




float cascadeLevelFromRefSize(float l_feature, LICData lic_data) {
	return clamp(log2(lic_data.refPx / l_feature), lic_data.baseCLvl, lic_data.bottomCLvl);
}

float getPixelSizeOfFeature(vec4 modelViewPos, vec4 dirHScale, vec2 wRes, mat4 projection_matrix) {
	float feature_size;

	vec4 win_pos_f = projection_matrix * (modelViewPos + dirHScale);
	vec4 win_pos_n = projection_matrix * (modelViewPos - dirHScale);

	win_pos_f.xy *= wRes / vec2(win_pos_f.w * 2.);
	win_pos_n.xy *= wRes / vec2(win_pos_n.w * 2.);

	feature_size = distance(win_pos_f.xy, win_pos_n.xy);

	return feature_size;
}

vec2 modelToScreenVectorFwd(mat4 viewProjMat, LICData lic_data, vec4 position, vec4 vector)
{
	float rescaleMag = length(vector);
	vec4 scaledVec = rescaleMag > .0 ? vec4(lic_data.base_scale) * vector / vec4(rescaleMag) : vec4(.0);
	vec4 win_pos_f = viewProjMat * (position + scaledVec);
	vec4 win_pos_n = viewProjMat * position;

	win_pos_f.xy /= vec2(win_pos_f.w * 2.);
	win_pos_n.xy /= vec2(win_pos_n.w * 2.);

	return rescaleMag * normalize(lic_data.wRes * (win_pos_f.xy - win_pos_n.xy));
}

vec4 calcTangSign(vec3 vect, vec3 norm)
{
	vec3 normN = normalize(norm);
	vec3 ncomp = normN * dot(vect, normN);
	return vec4(vect - ncomp, sign(vect.x - vect.y));
}

float calcLICMaskLen(vec4 tangSign, vec3 vect)
{
	float maskLen = 1.;
#if defined(SHADER_DIR_INDIFFERENCE)
	maskLen = tangSign.w * length(tangSign.xyz);
#else //!SHADER_DIR_INDIFFERENCE
	maskLen = length(vect);
#endif //SHADER_DIR_INDIFFERENCE
	return maskLen;
}

float calcLICMasking(float maskLen, LICData lic_data) {
	float hp_mask = smoothstep(lic_data.highPassBegin, lic_data.highPassEnd, maskLen);
	float lp_mask = 1. - smoothstep(lic_data.lowPassBegin, lic_data.lowPassEnd, maskLen);
	float or_mask = max(hp_mask, lp_mask);
	float and_mask = hp_mask * lp_mask;
	return mix(
			and_mask,
			or_mask,
			float(
				(lic_data.highPassBegin + lic_data.highPassEnd) >=
				(lic_data.lowPassBegin + lic_data.lowPassEnd)
				)
			);
}




#define LAY_TOL (1.e-6)

#define TRSL_UL_UNIT vec4(-1.,  1., .0, .0)
#define TRSL_UR_UNIT vec4( 1.,  1., .0, .0)
#define TRSL_DL_UNIT vec4(-1., -1., .0, .0)
#define TRSL_DR_UNIT vec4( 1., -1., .0, .0)

#define TRSL_UL(_T_DIST_) ((_T_DIST_) * TRSL_UL_UNIT)
#define TRSL_UR(_T_DIST_) ((_T_DIST_) * TRSL_UR_UNIT)
#define TRSL_DL(_T_DIST_) ((_T_DIST_) * TRSL_DL_UNIT)
#define TRSL_DR(_T_DIST_) ((_T_DIST_) * TRSL_DR_UNIT)

float q_scale = .5;
float q_off = .5;
float texOff = .5;
vec4 oF = pid_uniforms.lic_data.origFact;
vec3 origin = oF.xyz;
float fact = oF.w;

vec4 toQ1(float off_q, float off_s, float scale, vec4 pos) {
	vec4 voff_q = TRSL_UL(off_q);
	vec4 voff_s = TRSL_UR(off_s);
	vec4 vscale = vec4(vec3(scale), 1.);
	return vscale * pos + voff_s + voff_q;
}

vec4 toQ2(float off_q, float off_s, float scale, vec4 pos) {
	vec4 voff_q = TRSL_UR(off_q);
	vec4 voff_s = TRSL_UR(off_s);
	vec4 vscale = vec4(vec3(scale), 1.);
	return vscale * pos + voff_s + voff_q;
}

vec4 toQ3(float off_q, float off_s, float scale, vec4 pos) {
	vec4 voff_q = TRSL_DR(off_q);
	vec4 voff_s = TRSL_UR(off_s);
	vec4 vscale = vec4(vec3(scale), 1.);
	return vscale * pos + voff_s + voff_q;
}

vec4 toQ4(float off_q, float off_s, float scale, vec4 pos) {
	vec4 voff_q = TRSL_DL(off_q);
	vec4 voff_s = TRSL_UR(off_s);
	vec4 vscale = vec4(vec3(scale), 1.);
	return vscale * pos + voff_s + voff_q;
}


// Functions taking model coordinates and returning [0, 1] tex coordinates

//Transformation procedure:
//vrtx: model vertices in model's units
//*= fact: model occupies [+-.5, +-.5]
//+= texOff: model occupies [.0, 1.]^2
//*= q_scale: model occupies [.0, .5]^2
//+= TRSL: model occupies a quadrant.

vec4 vertToTCOrient(vec3 vrtx) {
	vec3 rVec = vrtx - origin;
	vec3 comp = threeAxisDecomp(rVec);
	return vec4(2. * comp * fact, 1.);
}

vec2 vertToTCQ1(vec3 vrtx) {
	vec2 tc = vrtx.yz * fact + texOff; /*fact.yz*/
	return toQ1(q_off / 2., q_off / 2., q_scale, vec4(tc, .0, 1.)).xy;
}

vec2 vertToTCQ2(vec3 vrtx) {
	vec2 tc = vrtx.zx * fact + texOff; /*fact.zx*/
	return toQ2(q_off / 2., q_off / 2., q_scale, vec4(tc, .0, 1.)).xy;
}

vec2 vertToTCQ3(vec3 vrtx) {
	vec2 tc = vrtx.xy * fact + texOff; /*fact.xy*/
	return toQ3(q_off / 2., q_off / 2., q_scale, vec4(tc, .0, 1.)).xy;
}

float cascadeSizeFromLevel(float c_level) {
	return 1. / exp2(c_level);
}

vec4 qxToCascadeAtQ4(vec4 pos, float c_level) {
	float c_value = cascadeSizeFromLevel(c_level);
	return toQ4(1 - c_value, .0, c_value, pos);
}

vec2 sampleToCascadeAtQ4(vec2 tc, float c_level) {
	float c_value = cascadeSizeFromLevel(c_level);
	return vec2(c_value) * tc;
}

vec2 orientByPreferred(vec2 vector, vec2 prefVector) {
	return faceforward(vector, vector, prefVector);
}

float orientDepth3Q(sampler2D texSrc, vec3 src, vec3 vertex) {
	float p, s, t;
	vec3 proj_layer;

	vec2 coordQ1 = vertToTCQ1(vertex);
	vec2 coordQ2 = vertToTCQ2(vertex);
	vec2 coordQ3 = vertToTCQ3(vertex);

	proj_layer.x = texture(texSrc, coordQ1).t;
	proj_layer.y = texture(texSrc, coordQ2).t;
	proj_layer.z = texture(texSrc, coordQ3).t;

	return dot(src, proj_layer);
}

// End of tex coord functions


vec4 posToQ1(vec4 pos) {
	return toQ1(q_off, .0, q_scale, pos);
}

vec4 posToQ2(vec4 pos) {
	return toQ2(q_off, .0, q_scale, pos);
}

vec4 posToQ3(vec4 pos) {
	return toQ3(q_off, .0, q_scale, pos);
}

vec4 posToQ4(vec4 pos) {
	return toQ4(q_off, .0, q_scale, pos);
}

float calcLICOrientToDepth(vec3 srcWt, vec3 orient)
{
	vec3 orTc = 2. * orient * fact; //val range: [-1., 1.]
	return .5 * dot(srcWt, orTc) + .5;
}

vec4 getDirectionalScale(float scale, vec3 vector, vec3 normal) {
	return vec4(scale * normalize(cross(vector, normal)), .0);
}

vec3 getLICDirSrc(vec3 normal)
{
	vec3 absncomp = abs(threeAxisDecomp(normal));
	float dirDot = absncomp.x;
	float dirDotTmp = dirDot;
	float isDomDir;
	vec3 src = vec3(1., .0, .0);
	vec3 srcTmp = src;

	TwoTimes(
			srcTmp = srcTmp.zxy;
			absncomp = absncomp.yzx;
			dirDotTmp = absncomp.x;
			isDomDir = float(dirDotTmp >= dirDot);
			src = mix(src, srcTmp, isDomDir);
			dirDot = mix(dirDot, dirDotTmp, isDomDir);
			)

		return src;
}

vec4 getLICLaySrc(float vrtxDepth, vec4 layDepth)
{
	float distR = 1., dist, layMatch;
	vec4 layDepthDist = vec4(vrtxDepth) - layDepth;
	vec4 layer = vec4(1., .0, .0, .0);
	vec4 src = layer;

	TwoTimes(TwoTimes(
				dist = abs(dot(layer, layDepthDist));
				layMatch = dist - distR;
				src = float(abs(layMatch) < LAY_TOL) * layer + src;
				layMatch = float(layMatch < .0);
				src = mix(src, layer, layMatch);
				distR = mix(distR, dist, layMatch);
				layer = layer.wxyz;
				))

		return src;
}



#endif

in VertexOut 
{
	vec3 object_pos;
    vec3 view_pos;
#if defined(SHADER_FRINGE_NODE_TOP)
    float fringe_node_top;
#endif
#if defined(SHADER_FRINGE_NODE_BOTTOM) 
    float fringe_node_bottom;
#endif
#if defined(SHADER_USE_BLUR)
	vec3 velocity_color;
#endif
#if defined(SHADER_LIC_OVERLAY) || defined(SHADER_LIC_SCREEN_SPACE)
	vec3 vectors;
#if !defined(SHADER_LIC_SCREEN_SPACE)
	vec3 vr_Orient;
#endif
#endif
#if defined(SHADER_LIC_SCREEN_SPACE)
	vec2 vr_scrVect;
#endif
#if defined(SHADER_USE_TEX_COORDS)
	vec2 tex_coords;
#endif
#if defined(SHADER_USE_NODAL_NORMALS)
	uint nodal_normals;
#endif
#if defined(SHADER_USE_NODAL_NORMALS_3F)
	vec3 nodal_normals;
#endif
#if defined(SHADER_USE_NODAL_COLOR)
    vec4 nodal_color;
#endif
#if defined(SHADER_THICK_SHELLS) && defined(SHADER_EXTRA_ELEMENTS)
	vec2 thickness_values;
	uint thickness_internal_edge_mask;
#endif
#if defined(SHADER_THICK_SHELLS_GET_NODAL_THICKNESS)
	float nodal_thickness;
#endif
#if defined(SHADER_COLOR_VARIANCE) && defined(SHADER_EXTRA_ELEMENTS)
	vec4 variable_color;
#endif
#if defined(SHADER_MULTI_DRAW_INDIRECT)
	int part_idx;
#endif
    int elem_offset;
} gs_in[];

out GeometryOut
{
#if defined(SHADER_MULTI_DRAW_INDIRECT)
	flat int part_idx;
#endif
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
#endif // FRINGE_EXACT
#endif // SHADER_FRINGE_TOP
#if defined(SHADER_FRINGE_BOTTOM)
#if defined(SHADER_FRINGE_EXACT)
	flat vec2 tex_bottom[TRUE_VERTICES];
#else
    FRINGE_INTERP vec2 tex_bottom;
#endif // FRINGE_EXACT
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
} gs_out;

#if defined(SHADER_SINGLE_PASS_STEREO)
layout(secondary_view_offset = 1) out int gl_Layer;
#endif // SHADER_SINGLE_PASS_STEREO

#if defined(SHADER_TRIA3)
vec3 tria_normal(void)
{
    vec3 u = vec3(gs_in[1].object_pos - gs_in[0].object_pos);
    vec3 v = vec3(gs_in[2].object_pos - gs_in[0].object_pos);
    return normalize(cross(u, v));
}
#endif

#if defined(SHADER_POLYGON)
vec3 poly_normal(void)
{
    vec3 u = vec3(gs_in[4].object_pos - gs_in[3].object_pos);
    vec3 v = vec3(gs_in[5].object_pos - gs_in[3].object_pos);
    return normalize(cross(u, v));
}
#endif

#if defined(SHADER_QUAD4)
vec3 quad_normal(void)
{
    vec3 u = vec3(gs_in[2].object_pos - gs_in[0].object_pos);
    vec3 v = vec3(gs_in[3].object_pos - gs_in[1].object_pos);
    return normalize(cross(u, v));
}
#endif

#if defined(SHADER_TRIA6)
vec3 tria6_normal(void)
{
    vec3 u = vec3(gs_in[1].object_pos - gs_in[0].object_pos);
    vec3 v = vec3(gs_in[2].object_pos - gs_in[0].object_pos);
    return normalize(cross(u, v));
}
#endif

#if defined(SHADER_QUAD8)
vec3 quad8_normal(void)
{
    vec3 u = vec3(gs_in[1].object_pos - gs_in[3].object_pos); 
    vec3 v = vec3(gs_in[5].object_pos - gs_in[2].object_pos);
    return normalize(cross(u, v));
}
#endif

vec3 get_prim_flat_normal(void)
{
#if defined(SHADER_TRIA3)
    return tria_normal();
#elif defined(SHADER_QUAD4)
    return quad_normal();
#elif defined(SHADER_TRIA6)
    return tria6_normal();
#elif defined(SHADER_QUAD8)
    return quad8_normal();
#elif defined(SHADER_POLYGON)
    return poly_normal(); 
#endif
}

int get_prim_id()
{
#if !defined(SHADER_QUAD8)
    int prim_id = gl_PrimitiveIDIn + gs_in[0].elem_offset;
#elif defined(SHADER_QUAD8)
    int prim_id = (gl_PrimitiveIDIn / 2) + gs_in[0].elem_offset;
#endif
    return prim_id;
}

#define NO_VALUE_UINT 0x80000000u

bool isnoval(vec3 vals)
{
    uvec3 bits = floatBitsToUint(vals);
    return any(equal(bits, uvec3(NO_VALUE_UINT, NO_VALUE_UINT, NO_VALUE_UINT)));
}

bool isnoval(vec4 vals)
{
    uvec4 bits = floatBitsToUint(vals);
    return any(equal(bits, uvec4(NO_VALUE_UINT, NO_VALUE_UINT, NO_VALUE_UINT, NO_VALUE_UINT)));
}

bool isnoval(float val)
{
    uint bits = floatBitsToUint(val);
    return bits == NO_VALUE_UINT;
}

float lerpf(float value, float lower, float upper)
{
    return (value-lower)/(upper-lower);
}

#if defined(SHADER_NON_LINEAR_FRINGE)
float bsearch_nl_fringe(float value, uint count, bool reverse)
{
    uint left = 0u;
    uint right = count - 1u;
    uint mid;
    bool goleft = false;
    uint loop = 0u;
    const uint max_loop = uint(log(MAX_FRINGE_COLORS));
    while ((left+1u) < right && loop < max_loop) {
        mid = (left + right) / 2u;
        float mid_val = non_linear_fringe[mid];
        goleft = reverse ? value > mid_val : value < mid_val;
        left = goleft ? left : mid;
        right = goleft ? mid : right;
        loop++;
    }
/*	const bool same_max_min = ( globals.scalar_fringe_paranom.y == 0.0 );*/
    const bool same_max_min = (globals.scalar_fringe_limits.x == globals.scalar_fringe_limits.y);
	// Uniform branching
	if (same_max_min) {
		return 0.5;
	} else {
		float result = lerpf(value, non_linear_fringe[left], non_linear_fringe[right]);
		result += float(left);
		result /= float(count - 1u);
		return result;
	}
}

float nl_fringe(float value)
{
    uint count = uint(globals.scalar_fringe_paranom.x);
    if (count >= MAX_FRINGE_COLORS) return 0.0f;
    // the first level if is dynamically uniform
    bool reverse = non_linear_fringe[count] < non_linear_fringe[0];
    return bsearch_nl_fringe(value, count+1u, reverse);
}
#endif

#if !defined(SHADER_FRINGE_NODE_TOP_TEX)
vec2 compute_tex_coords(float val)
{
#if defined(SHADER_NON_LINEAR_FRINGE)
    float s = nl_fringe(val) * globals.scalar_fringe_paranom.z + globals.scalar_fringe_paranom.w;
#else

#if defined(SYSTEM_DISABLE_FMA)
    precise 
#endif
	float s = beta_fma(val, globals.scalar_fringe_paranom.x, globals.scalar_fringe_paranom.y);

#if defined(SHADER_FRINGE_CENTROID)
    // accuracy delta needed for values equal to the fringe limits (these accuracy problems do not appear on Quadro P5000)
    const float accd_sign = globals.scalar_fringe_limits.y > globals.scalar_fringe_limits.x ? 1.0 : -1.0;
    const float upper_lim = accd_sign > 0.0 ? globals.scalar_fringe_limits.y : globals.scalar_fringe_limits.x;
    const float lower_lim = accd_sign > 0.0 ? globals.scalar_fringe_limits.x : globals.scalar_fringe_limits.y;
    float accd  = (val < upper_lim) ? 0.0 : accd_sign;
          accd += (val > lower_lim) ? 0.0 : -accd_sign;
    s += accd;
#endif
    s = (globals.scalar_fringe_paranom.x == 0.0) ? (0.5 * globals.scalar_fringe_paranom.z + globals.scalar_fringe_paranom.w) : s;
#endif
    bool nv = (globals.novalue_color_mode.x > 0.0) && isnoval(val);
	
#if defined(SHADER_FRINGE_FILTERING_NEAREST)
    float t = nv ? globals.fringe_specular.y : 0.0;
#else 
	// we must not get beyond 75% of the no-value and result space
	// because no-value will blend with the color in that case
	float t = nv ? max(globals.fringe_specular.y, 0.75) : 0.0;
#endif
    return vec2(s, t);
}
#endif

#if defined(SHADER_FRINGE_NODE_TOP) && defined(SHADER_FRINGE_NODE_TOP_TEX)
vec2 compute_tex_coords(float val)
{
	return vec2(val, 0.0);
}
#endif

#if defined(SHADER_TRIA3) && defined(SHADER_FRINGE_TOP)
void get_fringe_tex_top(int prim_id, out vec2 tex[3])
{
#if defined(SHADER_FRINGE_CENTROID)
    float center = texelFetch(elem_func_top, prim_id).r;
    vec2 temp = compute_tex_coords(center);
    tex[0] = temp;
    tex[1] = temp;
    tex[2] = temp;
#elif defined(SHADER_FRINGE_NODE)
    tex[0] = compute_tex_coords(gs_in[0].fringe_node_top);
    tex[1] = compute_tex_coords(gs_in[1].fringe_node_top);
    tex[2] = compute_tex_coords(gs_in[2].fringe_node_top);
#elif defined(SHADER_FRINGE_CORNER)
    vec4 corner = texelFetch(elem_func_top, prim_id);
    tex[0] = compute_tex_coords(corner.r);
    tex[1] = compute_tex_coords(corner.g);
    tex[2] = compute_tex_coords(corner.b);
#endif
}
#endif

#if defined(SHADER_TRIA3) && defined(SHADER_FRINGE_BOTTOM)
void get_fringe_tex_bottom(int prim_id, out vec2 tex[3])
{
#if defined(SHADER_FRINGE_CENTROID)
    float center = texelFetch(elem_func_bottom, prim_id).r;
    vec2 temp = compute_tex_coords(center);
    tex[0] = temp;
    tex[1] = temp;
    tex[2] = temp;
#elif defined(SHADER_FRINGE_NODE)
    tex[0] = compute_tex_coords(gs_in[0].fringe_node_bottom);
    tex[1] = compute_tex_coords(gs_in[1].fringe_node_bottom);
    tex[2] = compute_tex_coords(gs_in[2].fringe_node_bottom);
#elif defined(SHADER_FRINGE_CORNER)
    vec4 corner = texelFetch(elem_func_bottom, prim_id);
    tex[0] = compute_tex_coords(corner.r);
    tex[1] = compute_tex_coords(corner.g);
    tex[2] = compute_tex_coords(corner.b);
#endif
}
#endif

#if defined(SHADER_QUAD4) && defined(SHADER_FRINGE_TOP)
void get_fringe_tex_top(int prim_id, out vec2 tex[4])
{
#if defined(SHADER_FRINGE_CENTROID)
    float center = texelFetch(elem_func_top, prim_id).r;
    vec2 temp = compute_tex_coords(center);
    tex[0] = temp;
    tex[1] = temp;
    tex[2] = temp;
    tex[3] = temp;
#elif defined(SHADER_FRINGE_NODE)
    tex[0] = compute_tex_coords(gs_in[0].fringe_node_top);
    tex[1] = compute_tex_coords(gs_in[1].fringe_node_top);
    tex[2] = compute_tex_coords(gs_in[2].fringe_node_top);
    tex[3] = compute_tex_coords(gs_in[3].fringe_node_top);
#elif defined(SHADER_FRINGE_CORNER)
    vec4 corner = texelFetch(elem_func_top, prim_id);
    tex[0] = compute_tex_coords(corner.r);
    tex[1] = compute_tex_coords(corner.g);
    tex[2] = compute_tex_coords(corner.b);
    tex[3] = compute_tex_coords(corner.a);
#endif
}
#endif

#if defined(SHADER_QUAD4) && defined(SHADER_FRINGE_BOTTOM)
void get_fringe_tex_bottom(int prim_id, out vec2 tex[4])
{
#if defined(SHADER_FRINGE_CENTROID)
    float center = texelFetch(elem_func_bottom, prim_id).r;
    vec2 temp = compute_tex_coords(center);
    tex[0] = temp;
    tex[1] = temp;
    tex[2] = temp;
    tex[3] = temp;
#elif defined(SHADER_FRINGE_NODE)
    tex[0] = compute_tex_coords(gs_in[0].fringe_node_bottom);
    tex[1] = compute_tex_coords(gs_in[1].fringe_node_bottom);
    tex[2] = compute_tex_coords(gs_in[2].fringe_node_bottom);
    tex[3] = compute_tex_coords(gs_in[3].fringe_node_bottom);
#elif defined(SHADER_FRINGE_CORNER)
    vec4 corner = texelFetch(elem_func_bottom, prim_id);
    tex[0] = compute_tex_coords(corner.r);
    tex[1] = compute_tex_coords(corner.g);
    tex[2] = compute_tex_coords(corner.b);
    tex[3] = compute_tex_coords(corner.a);
#endif
}
#endif

#if defined(SHADER_TRIA6) && defined(SHADER_FRINGE_TOP)
void get_fringe_tex_top(int prim_id, out vec2 tex[8])
{
#if defined(SHADER_FRINGE_CENTROID)
    float center = texelFetch(elem_func_top, prim_id).r;
    vec2 temp = compute_tex_coords(center);
    tex[0] = temp;
    tex[1] = temp;
    tex[2] = temp;
    tex[3] = temp;
    tex[4] = temp;
    tex[5] = temp;
#elif defined(SHADER_FRINGE_NODE)
    tex[0] = compute_tex_coords(gs_in[0].fringe_node_top);
    tex[1] = compute_tex_coords(gs_in[1].fringe_node_top);
    tex[2] = compute_tex_coords(gs_in[2].fringe_node_top);
    tex[3] = compute_tex_coords(gs_in[3].fringe_node_top);
    tex[4] = compute_tex_coords(gs_in[4].fringe_node_top);
    tex[5] = compute_tex_coords(gs_in[5].fringe_node_top);
#elif defined(SHADER_FRINGE_CORNER)
    vec4 c1 = texelFetch(elem_func_top, 2*prim_id);
    vec4 c2 = texelFetch(elem_func_top, 2*prim_id+1);
    float corner_vals[6] = float[](c1.r, c1.g, c1.b, c2.r, c2.g, c2.b);
    tex[0] = compute_tex_coords(corner_vals[0]);
    tex[1] = compute_tex_coords(corner_vals[1]);
    tex[2] = compute_tex_coords(corner_vals[2]);
    tex[3] = compute_tex_coords(corner_vals[3]);
    tex[4] = compute_tex_coords(corner_vals[4]);
    tex[5] = compute_tex_coords(corner_vals[5]);
#endif
}
#endif

#if defined(SHADER_TRIA6) && defined(SHADER_FRINGE_BOTTOM)
void get_fringe_tex_bottom(int prim_id, out vec2 tex[8])
{
#if defined(SHADER_FRINGE_CENTROID)
    float center = texelFetch(elem_func_bottom, prim_id).r;
    vec2 temp = compute_tex_coords(center);
    tex[0] = temp;
    tex[1] = temp;
    tex[2] = temp;
    tex[3] = temp;
    tex[4] = temp;
    tex[5] = temp;
#elif defined(SHADER_FRINGE_NODE)
    tex[0] = compute_tex_coords(gs_in[0].fringe_node_bottom);
    tex[1] = compute_tex_coords(gs_in[1].fringe_node_bottom);
    tex[2] = compute_tex_coords(gs_in[2].fringe_node_bottom);
    tex[3] = compute_tex_coords(gs_in[3].fringe_node_bottom);
    tex[4] = compute_tex_coords(gs_in[4].fringe_node_bottom);
    tex[5] = compute_tex_coords(gs_in[5].fringe_node_bottom);
#elif defined(SHADER_FRINGE_CORNER)
    vec4 c1 = texelFetch(elem_func_bottom, 2*prim_id);
    vec4 c2 = texelFetch(elem_func_bottom, 2*prim_id+1);
    float corner_vals[6] = float[](c1.r, c1.g, c1.b, c2.r, c2.g, c2.b);
    tex[0] = compute_tex_coords(corner_vals[0]);
    tex[1] = compute_tex_coords(corner_vals[1]);
    tex[2] = compute_tex_coords(corner_vals[2]);
    tex[3] = compute_tex_coords(corner_vals[3]);
    tex[4] = compute_tex_coords(corner_vals[4]);
    tex[5] = compute_tex_coords(corner_vals[5]);
#endif
}
#endif

#if defined(SHADER_QUAD8) && defined(SHADER_FRINGE_TOP) && !defined(SHADER_FRINGE_EXACT)
void get_fringe_tex_top(int prim_id, out vec2 tex[5])
{
#if defined(SHADER_FRINGE_CENTROID)
    float center = texelFetch(elem_func_top, prim_id).r;
    vec2 temp = compute_tex_coords(center);
    tex[0] = temp;
    tex[1] = temp;
    tex[2] = temp;
    tex[3] = temp;
    tex[4] = temp;
#elif defined(SHADER_FRINGE_NODE)
    tex[0] = compute_tex_coords(gs_in[0].fringe_node_top);
    tex[1] = compute_tex_coords(gs_in[1].fringe_node_top);
    tex[2] = compute_tex_coords(gs_in[2].fringe_node_top);
    tex[3] = compute_tex_coords(gs_in[3].fringe_node_top);
    tex[4] = compute_tex_coords(gs_in[4].fringe_node_top);
#elif defined(SHADER_FRINGE_CORNER)
    int chunk = gl_PrimitiveIDIn % 2;
    vec4 c1 = texelFetch(elem_func_top, 2*prim_id);
    vec4 c2 = texelFetch(elem_func_top, 2*prim_id+1);
    float corner_vals[8] = float[](c1.r, c1.g, c1.b, c1.a, c2.r, c2.g, c2.b, c2.a);
    if (chunk == 0) {
        tex[0] = compute_tex_coords(corner_vals[1]);
        tex[1] = compute_tex_coords(corner_vals[5]);
        tex[2] = compute_tex_coords(corner_vals[4]);
        tex[3] = compute_tex_coords(corner_vals[7]);
        tex[4] = compute_tex_coords(corner_vals[0]);
    } else {
        tex[0] = compute_tex_coords(corner_vals[3]);
        tex[1] = compute_tex_coords(corner_vals[7]);
        tex[2] = compute_tex_coords(corner_vals[6]);
        tex[3] = compute_tex_coords(corner_vals[5]);
        tex[4] = compute_tex_coords(corner_vals[2]);
    }
#endif
}
#endif

#if defined(SHADER_QUAD8) && defined(SHADER_FRINGE_TOP) && defined(SHADER_FRINGE_EXACT)
void get_fringe_tex_top(int prim_id, out vec2 tex[8])
{
#if defined(SHADER_FRINGE_CENTROID)
    float center = texelFetch(elem_func_top, prim_id).r;
    vec2 temp = compute_tex_coords(center);
    tex[0] = temp;
    tex[1] = temp;
    tex[2] = temp;
    tex[3] = temp;
    tex[4] = temp;
    tex[5] = temp;
    tex[6] = temp;
    tex[7] = temp;
#elif defined(SHADER_FRINGE_NODE) || defined(SHADER_FRINGE_CORNER)
	//use the elem_func_bottom texture buffer to get the whole Q8 fringe
    vec4 c1 = texelFetch(elem_func_top, 2*prim_id);
    vec4 c2 = texelFetch(elem_func_top, 2*prim_id+1);
    float vals[8] = float[](c1.r, c1.g, c1.b, c1.a, c2.r, c2.g, c2.b, c2.a);
	tex[0] = compute_tex_coords(vals[0]);
	tex[1] = compute_tex_coords(vals[1]);
	tex[2] = compute_tex_coords(vals[2]);
	tex[3] = compute_tex_coords(vals[3]);
	tex[4] = compute_tex_coords(vals[4]);
	tex[5] = compute_tex_coords(vals[5]);
	tex[6] = compute_tex_coords(vals[6]);
	tex[7] = compute_tex_coords(vals[7]);
#endif
}
#endif

#if defined(SHADER_QUAD8) && defined(SHADER_FRINGE_BOTTOM) && !defined(SHADER_FRINGE_EXACT)
void get_fringe_tex_bottom(int prim_id, out vec2 tex[5])
{
#if defined(SHADER_FRINGE_CENTROID)
    float center = texelFetch(elem_func_bottom, prim_id).r;
    vec2 temp = compute_tex_coords(center);
    tex[0] = temp;
    tex[1] = temp;
    tex[2] = temp;
    tex[3] = temp;
    tex[4] = temp;
#elif defined(SHADER_FRINGE_NODE)
    tex[0] = compute_tex_coords(gs_in[0].fringe_node_bottom);
    tex[1] = compute_tex_coords(gs_in[1].fringe_node_bottom);
    tex[2] = compute_tex_coords(gs_in[2].fringe_node_bottom);
    tex[3] = compute_tex_coords(gs_in[3].fringe_node_bottom);
    tex[4] = compute_tex_coords(gs_in[4].fringe_node_bottom);
#elif defined(SHADER_FRINGE_CORNER)
    int chunk = gl_PrimitiveIDIn % 2;
    vec4 c1 = texelFetch(elem_func_bottom, 2*prim_id);
    vec4 c2 = texelFetch(elem_func_bottom, 2*prim_id+1);
    float corner_vals[8] = float[](c1.r, c1.g, c1.b, c1.a, c2.r, c2.g, c2.b, c2.a);
    if (chunk == 0) {
        tex[0] = compute_tex_coords(corner_vals[1]);
        tex[1] = compute_tex_coords(corner_vals[5]);
        tex[2] = compute_tex_coords(corner_vals[4]);
        tex[3] = compute_tex_coords(corner_vals[7]);
        tex[4] = compute_tex_coords(corner_vals[0]);
    } else {
        tex[0] = compute_tex_coords(corner_vals[3]);
        tex[1] = compute_tex_coords(corner_vals[7]);
        tex[2] = compute_tex_coords(corner_vals[6]);
        tex[3] = compute_tex_coords(corner_vals[5]);
        tex[4] = compute_tex_coords(corner_vals[2]);
    }
#endif
}
#endif

#if defined(SHADER_QUAD8) && defined(SHADER_FRINGE_BOTTOM) && defined(SHADER_FRINGE_EXACT)
void get_fringe_tex_bottom(int prim_id, out vec2 tex[8])
{
#if defined(SHADER_FRINGE_CENTROID)
    float center = texelFetch(elem_func_bottom, prim_id).r;
    vec2 temp = compute_tex_coords(center);
    tex[0] = temp;
    tex[1] = temp;
    tex[2] = temp;
    tex[3] = temp;
    tex[4] = temp;
    tex[5] = temp;
    tex[6] = temp;
    tex[7] = temp;
#elif defined(SHADER_FRINGE_NODE) || defined(SHADER_FRINGE_CORNER)
	//use the elem_func_bottom texture buffer to get the whole Q8 fringe
    vec4 c1 = texelFetch(elem_func_bottom, 2*prim_id);
    vec4 c2 = texelFetch(elem_func_bottom, 2*prim_id+1);
    float vals[8] = float[](c1.r, c1.g, c1.b, c1.a, c2.r, c2.g, c2.b, c2.a);
	tex[0] = compute_tex_coords(vals[0]);
	tex[1] = compute_tex_coords(vals[1]);
	tex[2] = compute_tex_coords(vals[2]);
	tex[3] = compute_tex_coords(vals[3]);
	tex[4] = compute_tex_coords(vals[4]);
	tex[5] = compute_tex_coords(vals[5]);
	tex[6] = compute_tex_coords(vals[6]);
	tex[7] = compute_tex_coords(vals[7]);
#endif
}
#endif

#if defined(SHADER_POLYGON) && defined(SHADER_FRINGE_TOP)
void get_fringe_tex_top(int prim_id, out vec2 tex[4])
{
#if defined(SHADER_FRINGE_CENTROID)
    float center = texelFetch(elem_func_top, prim_id).r;
    vec2 temp = compute_tex_coords(center);
    tex[0] = temp;
    tex[1] = temp;
    tex[2] = temp;
    tex[3] = temp;
#elif defined(SHADER_FRINGE_NODE)
	vec2 tex3 = compute_tex_coords(gs_in[3].fringe_node_top);
	vec2 tex4 = compute_tex_coords(gs_in[4].fringe_node_top);
	vec2 tex5 = compute_tex_coords(gs_in[5].fringe_node_top);
	// center
    tex[3] = mix(mix(tex3, tex5, 0.5), tex4, 0.25);

    tex[0] = compute_tex_coords(gs_in[0].fringe_node_top);
    tex[1] = compute_tex_coords(gs_in[1].fringe_node_top);
    tex[2] = compute_tex_coords(gs_in[2].fringe_node_top);
#endif
}
#endif

#if defined(SHADER_POLYGON) && defined(SHADER_FRINGE_BOTTOM)
void get_fringe_tex_top(int prim_id, out vec2 tex[4])
{
#if defined(SHADER_FRINGE_CENTROID)
    float center = texelFetch(elem_func_bottom, prim_id).r;
    vec2 temp = compute_tex_coords(center);
    tex[0] = temp;
    tex[1] = temp;
    tex[2] = temp;
    tex[3] = temp;
#elif defined(SHADER_FRINGE_NODE)
	vec2 tex3 = compute_tex_coords(gs_in[3].fringe_node_bottom);
	vec2 tex4 = compute_tex_coords(gs_in[4].fringe_node_bottom);
	vec2 tex5 = compute_tex_coords(gs_in[5].fringe_node_bottom);
	// center
    tex[3] = mix(mix(tex3, tex5, 0.5), tex4, 0.25);

    tex[0] = compute_tex_coords(gs_in[0].fringe_node_bottom);
    tex[1] = compute_tex_coords(gs_in[1].fringe_node_bottom);
    tex[2] = compute_tex_coords(gs_in[2].fringe_node_bottom);
#endif
}
#endif

vec3 uncompress_normal(uint cnorm)
{
	vec3 n = uncompress_normal_spherical(cnorm);
#if defined(SHADER_SMOOTH_NORMALS)
	return -n;
#else
	return n;
#endif
}

#if defined(SHADER_USE_NODAL_NORMALS) || defined(SHADER_USE_NODAL_NORMALS_3F)
vec3 get_normal_uncompress_view_space(vec3 unormal)
{
	vec3 norm = normalize(globals.tr_iview_matrix * pid_uniforms.explode_matrix * vec4(unormal, .0)).xyz;
	return norm;
}

vec3 get_normal_uncompress_view_space(uint cnorm)
{
	vec3 unormal = uncompress_normal(cnorm);
	return get_normal_uncompress_view_space(unormal);
}
#endif

#if defined(SHADER_TRIA6) && (defined(SHADER_NEED_FOR_MODNORMALS) || defined(SHADER_SMOOTH_NORMALS))
void get_smooth_normals_tria6(int prim_id, out vec3 normals[8])
{
    uvec4 cnorms = texelFetch(elem_smooth_normals, prim_id).rgba;
    vec3 temp[6];
    temp[0] = uncompress_normal(cnorms.r),
    temp[1] = uncompress_normal(cnorms.g),
    temp[2] = uncompress_normal(cnorms.b),
    temp[3] = normalize(temp[0] + temp[1]);
    temp[4] = normalize(temp[1] + temp[2]); 
    temp[5] = normalize(temp[2] + temp[0]); 
    
    normals[0] = temp[0];
    normals[1] = temp[1];
    normals[2] = temp[2];
    normals[3] = temp[3];
    normals[4] = temp[4];
    normals[5] = temp[5];
    // this is because GS_TRIA6_MAXVERT output and input are different (8 != 6)
    normals[6] = vec3(0.0);
    normals[7] = vec3(0.0);
}
#endif

#if defined(SHADER_QUAD8) && (defined(SHADER_NEED_FOR_MODNORMALS) || defined(SHADER_SMOOTH_NORMALS))
void get_smooth_normals_quad8_chunk(int prim_id, out vec3 normals[5])
{
    int chunk = gl_PrimitiveIDIn % 2;
    uvec4 cnorms = texelFetch(elem_smooth_normals, prim_id).rgba;
    vec3 temp[8];
    temp[0] = uncompress_normal(cnorms.r),
    temp[1] = uncompress_normal(cnorms.g),
    temp[2] = uncompress_normal(cnorms.b),
    temp[3] = uncompress_normal(cnorms.a),
    temp[4] = normalize(temp[0] + temp[1]);
    temp[5] = normalize(temp[1] + temp[2]); 
    temp[6] = normalize(temp[2] + temp[3]); 
    temp[7] = normalize(temp[3] + temp[0]); 
    
    if (chunk == 0) {
        normals[0] = temp[1];
        normals[1] = temp[5];
        normals[2] = temp[4];
        normals[3] = temp[7];
        normals[4] = temp[0];
    } else {
        normals[0] = temp[3];
        normals[1] = temp[7];
        normals[2] = temp[6];
        normals[3] = temp[5];
        normals[4] = temp[2];
    }
}
#endif

#if defined(SHADER_POLYGON) && (defined(SHADER_NEED_FOR_MODNORMALS) || defined(SHADER_SMOOTH_NORMALS))
void get_smooth_normals_polygon_patch(int prim_id, out vec3 normals[4])
{
	uvec4 cnorms = texelFetch(elem_smooth_normals, prim_id);
    normals[0] = uncompress_normal(cnorms.r);
    normals[1] = uncompress_normal(cnorms.g);
    normals[2] = uncompress_normal(cnorms.b);
    normals[3] = uncompress_normal(cnorms.a); // center
}
#endif

#if defined(SHADER_CLIP)
bool can_be_clipped(int clip_bitfield, int clip_idx) 
{
    return (((clip_bitfield >> clip_idx) & 1) > 0)  ? true : false;
}

void output_clip_vertex(vec4 _view_pos, int _clip) 
{
#if defined(SHADER_CLIP_DISTANCES)
	// _clip is a bitfield with 1s in the position of the clip plane that can cut
	gl_ClipDistance[0] = can_be_clipped(_clip, 0) ? dot(_view_pos, model_uniforms.clip_planes[0]) : 1.0;
	gl_ClipDistance[1] = can_be_clipped(_clip, 1) ? dot(_view_pos, model_uniforms.clip_planes[1]) : 1.0;
	gl_ClipDistance[2] = can_be_clipped(_clip, 2) ? dot(_view_pos, model_uniforms.clip_planes[2]) : 1.0;
	gl_ClipDistance[3] = can_be_clipped(_clip, 3) ? dot(_view_pos, model_uniforms.clip_planes[3]) : 1.0;
	gl_ClipDistance[4] = can_be_clipped(_clip, 4) ? dot(_view_pos, model_uniforms.clip_planes[4]) : 1.0;
	gl_ClipDistance[5] = can_be_clipped(_clip, 5) ? dot(_view_pos, model_uniforms.clip_planes[5]) : 1.0;
	gl_ClipDistance[6] = can_be_clipped(_clip, 6) ? dot(_view_pos, model_uniforms.clip_planes[6]) : 1.0;
	gl_ClipDistance[7] = dot(_view_pos, model_uniforms.clip_planes[7]); // mirror
#else 
	// this should go but we do not use per-model unifs in view-smart and flowpath
	gl_ClipDistance[0] = can_be_clipped(_clip, 0) ? dot(_view_pos, globals.clip_planes[0]) : 1.0;
	gl_ClipDistance[1] = can_be_clipped(_clip, 1) ? dot(_view_pos, globals.clip_planes[1]) : 1.0;
	gl_ClipDistance[2] = can_be_clipped(_clip, 2) ? dot(_view_pos, globals.clip_planes[2]) : 1.0;
	gl_ClipDistance[3] = can_be_clipped(_clip, 3) ? dot(_view_pos, globals.clip_planes[3]) : 1.0;
	gl_ClipDistance[4] = can_be_clipped(_clip, 4) ? dot(_view_pos, globals.clip_planes[4]) : 1.0;
	gl_ClipDistance[5] = can_be_clipped(_clip, 5) ? dot(_view_pos, globals.clip_planes[5]) : 1.0;
	gl_ClipDistance[6] = can_be_clipped(_clip, 6) ? dot(_view_pos, globals.clip_planes[6]) : 1.0;
	gl_ClipDistance[7] = can_be_clipped(_clip, 7) ? dot(_view_pos, globals.clip_planes[7]) : 1.0;
#endif
}
#endif

#if defined(SHADER_FRINGE_TOP) && !defined(SHADER_FRINGE_EXACT)
#define OUTPUT_TEX_TOP(_idx)\
    gs_out.tex_top = primDat.tex_top[_idx];
#else
#define OUTPUT_TEX_TOP(_idx)
#endif
#if defined(SHADER_FRINGE_BOTTOM) && !defined(SHADER_FRINGE_EXACT)
#define OUTPUT_TEX_BOTTOM(_idx)\
    gs_out.tex_bottom = primDat.tex_bottom[_idx];
#else
#define OUTPUT_TEX_BOTTOM(_idx)
#endif
#if defined(SHADER_FRINGE_TOP) && defined(SHADER_FRINGE_EXACT)
#if defined(SHADER_QUAD4)
#define OUTPUT_TEX_TOP_FRINGE_QUALITY()\
    gs_out.tex_top[0] = primDat.tex_top[0];\
    gs_out.tex_top[1] = primDat.tex_top[1];\
    gs_out.tex_top[2] = primDat.tex_top[2];\
    gs_out.tex_top[3] = primDat.tex_top[3];
#elif defined(SHADER_QUAD8)
#define OUTPUT_TEX_TOP_FRINGE_QUALITY(_middle_nodes)\
    gs_out.tex_top[0] = primDat.tex_top[0];\
    gs_out.tex_top[1] = primDat.tex_top[1];\
    gs_out.tex_top[2] = primDat.tex_top[2];\
    gs_out.tex_top[3] = primDat.tex_top[3];\
	gs_out.tex_top[4] = ((_middle_nodes >> 4) & 1u) == 1u ? primDat.tex_top[4] : (primDat.tex_top[0] + primDat.tex_top[1])*0.5f;\
    gs_out.tex_top[5] = ((_middle_nodes >> 5) & 1u) == 1u ? primDat.tex_top[5] : (primDat.tex_top[1] + primDat.tex_top[2])*0.5f;\
    gs_out.tex_top[6] = ((_middle_nodes >> 6) & 1u) == 1u ? primDat.tex_top[6] : (primDat.tex_top[2] + primDat.tex_top[3])*0.5f;\
    gs_out.tex_top[7] = ((_middle_nodes >> 7) & 1u) == 1u ? primDat.tex_top[7] : (primDat.tex_top[0] + primDat.tex_top[3])*0.5f;
#elif defined(SHADER_TRIA3)
#define OUTPUT_TEX_TOP_FRINGE_QUALITY()\
    gs_out.tex_top[0] = primDat.tex_top[0];\
    gs_out.tex_top[1] = primDat.tex_top[1];\
    gs_out.tex_top[2] = primDat.tex_top[2];
#elif defined(SHADER_TRIA6)
#define OUTPUT_TEX_TOP_FRINGE_QUALITY()\
    gs_out.tex_top[0] = primDat.tex_top[0];\
    gs_out.tex_top[1] = primDat.tex_top[1];\
    gs_out.tex_top[2] = primDat.tex_top[2];\
    gs_out.tex_top[3] = all(equal(gl_in[3].gl_Position, gl_in[0].gl_Position)) ? (primDat.tex_top[0] + primDat.tex_top[1]) * 0.5f : primDat.tex_top[3];\
    gs_out.tex_top[4] = all(equal(gl_in[4].gl_Position, gl_in[1].gl_Position)) ? (primDat.tex_top[1] + primDat.tex_top[2]) * 0.5f : primDat.tex_top[4];\
    gs_out.tex_top[5] = all(equal(gl_in[5].gl_Position, gl_in[2].gl_Position)) ? (primDat.tex_top[2] + primDat.tex_top[0]) * 0.5f : primDat.tex_top[5];
#endif
#else
#if defined(SHADER_QUAD4) || defined(SHADER_TRIA3) || defined(SHADER_TRIA6)
#define OUTPUT_TEX_TOP_FRINGE_QUALITY()
#elif defined(SHADER_QUAD8)
#define OUTPUT_TEX_TOP_FRINGE_QUALITY(_middle_nodes)
#endif
#endif
#if defined(SHADER_FRINGE_BOTTOM) && defined(SHADER_FRINGE_EXACT)
#if defined(SHADER_QUAD4)
#define OUTPUT_TEX_BOTTOM_FRINGE_QUALITY()\
    gs_out.tex_bottom[0] = primDat.tex_bottom[0];\
    gs_out.tex_bottom[1] = primDat.tex_bottom[1];\
    gs_out.tex_bottom[2] = primDat.tex_bottom[2];\
    gs_out.tex_bottom[3] = primDat.tex_bottom[3];
#elif defined(SHADER_QUAD8)
#define OUTPUT_TEX_BOTTOM_FRINGE_QUALITY(_middle_nodes)\
    gs_out.tex_bottom[0] = primDat.tex_bottom[0];\
    gs_out.tex_bottom[1] = primDat.tex_bottom[1];\
    gs_out.tex_bottom[2] = primDat.tex_bottom[2];\
    gs_out.tex_bottom[3] = primDat.tex_bottom[3];\
    gs_out.tex_bottom[4] = ((_middle_nodes >> 4) & 1u) == 1u ? primDat.tex_bottom[4] : (primDat.tex_bottom[0] + primDat.tex_bottom[1])*0.5f;\
    gs_out.tex_bottom[5] = ((_middle_nodes >> 5) & 1u) == 1u ? primDat.tex_bottom[5] : (primDat.tex_bottom[1] + primDat.tex_bottom[2])*0.5f;\
    gs_out.tex_bottom[6] = ((_middle_nodes >> 6) & 1u) == 1u ? primDat.tex_bottom[6] : (primDat.tex_bottom[2] + primDat.tex_bottom[3])*0.5f;\
    gs_out.tex_bottom[7] = ((_middle_nodes >> 7) & 1u) == 1u ? primDat.tex_bottom[7] : (primDat.tex_bottom[0] + primDat.tex_bottom[3])*0.5f;
#elif defined(SHADER_TRIA3)
#define OUTPUT_TEX_BOTTOM_FRINGE_QUALITY()\
    gs_out.tex_bottom[0] = primDat.tex_bottom[0];\
    gs_out.tex_bottom[1] = primDat.tex_bottom[1];\
    gs_out.tex_bottom[2] = primDat.tex_bottom[2];
#elif defined(SHADER_TRIA6)
#define OUTPUT_TEX_BOTTOM_FRINGE_QUALITY()\
    gs_out.tex_bottom[0] = primDat.tex_bottom[0];\
    gs_out.tex_bottom[1] = primDat.tex_bottom[1];\
    gs_out.tex_bottom[2] = primDat.tex_bottom[2];\
    gs_out.tex_bottom[3] = all(equal(gl_in[3].gl_Position, gl_in[0].gl_Position)) ? (primDat.tex_bottom[0] + primDat.tex_bottom[1]) * 0.5f : primDat.tex_bottom[3];\
    gs_out.tex_bottom[4] = all(equal(gl_in[4].gl_Position, gl_in[1].gl_Position)) ? (primDat.tex_bottom[1] + primDat.tex_bottom[2]) * 0.5f : primDat.tex_bottom[4];\
    gs_out.tex_bottom[5] = all(equal(gl_in[5].gl_Position, gl_in[2].gl_Position)) ? (primDat.tex_bottom[2] + primDat.tex_bottom[0]) * 0.5f : primDat.tex_bottom[5];
#endif
#else
#if defined(SHADER_QUAD4) || defined(SHADER_TRIA3) || defined(SHADER_TRIA6)
#define OUTPUT_TEX_BOTTOM_FRINGE_QUALITY()
#elif defined(SHADER_QUAD8)
#define OUTPUT_TEX_BOTTOM_FRINGE_QUALITY(_middle_nodes)
#endif
#endif
#if defined(SHADER_FRINGE_EXACT)
#if defined(SHADER_QUAD4)
#define OUTPUT_FRINGE_BARYCENTRIC(_b0, _b1)\
    gs_out.fringe_barycentric = vec2(_b0, _b1);
#elif defined(SHADER_QUAD8)
#define OUTPUT_FRINGE_BARYCENTRIC(_b0, _b1)\
    gs_out.fringe_barycentric = vec2(_b0, _b1);
#define OUTPUT_MIDDLE_NODE_FRINGE_BARYCENTRIC(_middle_nodes, _middle, _middle_barycentric, _main_barycentric)\
	gs_out.fringe_barycentric = ((_middle_nodes >> _middle) & 1u) == 1u ? _middle_barycentric : _main_barycentric;
#elif defined(SHADER_TRIA3)
#define OUTPUT_FRINGE_BARYCENTRIC(_b0, _b1, _b2)\
    gs_out.fringe_barycentric = vec3(_b0, _b1, _b2);
#elif defined(SHADER_TRIA6)
#define OUTPUT_MIDDLE_NODE_FRINGE_BARYCENTRIC(_middle, _main, _middle_barycentric, _main_barycentric)\
	gs_out.fringe_barycentric = all(equal(gl_in[_middle].gl_Position, gl_in[_main].gl_Position)) ? _main_barycentric : _middle_barycentric;
#define OUTPUT_FRINGE_BARYCENTRIC(_b0, _b1, _b2)\
    gs_out.fringe_barycentric = vec3(_b0, _b1, _b2);
#endif
#else
#if defined(SHADER_QUAD4)
#define OUTPUT_FRINGE_BARYCENTRIC(_b0, _b1)
#elif defined(SHADER_QUAD8)
#define OUTPUT_FRINGE_BARYCENTRIC(_b0, _b1)
#define OUTPUT_MIDDLE_NODE_FRINGE_BARYCENTRIC(_middle_nodes, _middle, _middle_barycentric, _main_barycentric)
#elif defined(SHADER_TRIA3)
#define OUTPUT_FRINGE_BARYCENTRIC(_b0, _b1, _b2)
#elif defined(SHADER_TRIA6)
#define OUTPUT_FRINGE_BARYCENTRIC(_b0, _b1, _b2)
#define OUTPUT_MIDDLE_NODE_FRINGE_BARYCENTRIC(_middle, _main, _middle_barycentric, _main_barycentric)
#endif
#endif // SHADER_FRINGE_EXACT

#if defined(SHADER_ONLY_WIRE) && defined(SHADER_TWO_SIDE)
float calc_area(vec4 pos0, vec4 pos1, vec4 pos2)
{
	vec3 ndc0 = pos0.xyz / pos0.w;
	vec3 ndc1 = pos1.xyz / pos1.w;
	vec3 ndc2 = pos2.xyz / pos2.w;

	vec2 view_coord0 = ndc0.xy * 0.5 + 0.5;
	vec2 view_coord1 = ndc1.xy * 0.5 + 0.5;
	vec2 view_coord2 = ndc2.xy * 0.5 + 0.5;

	vec2 view_pixel_coord0 = view_coord0 * globals.viewport.zw;
	vec2 view_pixel_coord1 = view_coord1 * globals.viewport.zw;
	vec2 view_pixel_coord2 = view_coord2 * globals.viewport.zw;

	float sum1 = view_pixel_coord0.x * view_pixel_coord1.y - view_pixel_coord1.x * view_pixel_coord0.y;
	float sum2 = view_pixel_coord1.x * view_pixel_coord2.y - view_pixel_coord2.x * view_pixel_coord1.y;
	float sum3 = view_pixel_coord2.x * view_pixel_coord0.y - view_pixel_coord0.x * view_pixel_coord2.y;

	return 0.5 * ( sum1 + sum2 + sum3 );	
}

#define OUTPUT_AREA(_idx)\
	gs_out.area = area;
#else
#define OUTPUT_AREA(_idx)
#endif


#if defined(SHADER_USE_BLUR)
#define OUTPUT_BLUR_VELOCITY(_idx)\
	gs_out.velocity_color = gs_in[_idx].velocity_color;
#else
#define OUTPUT_BLUR_VELOCITY(_idx)
#endif
#if defined(SHADER_USE_TEX_COORDS)
#define OUTPUT_TEX_COORDS(_idx)\
	gs_out.tex_coords = gs_in[_idx].tex_coords;
#else
#define OUTPUT_TEX_COORDS(_idx)
#endif
#if defined(SHADER_USE_NODAL_NORMALS) || defined(SHADER_USE_NODAL_NORMALS_3F)
#define OUTPUT_NODAL_NORMALS(_idx)\
	gs_out.nodal_normals = get_normal_uncompress_view_space(gs_in[_idx].nodal_normals);
#else
#define OUTPUT_NODAL_NORMALS(_idx)
#endif
#if defined(SHADER_USE_NODAL_COLOR)
#define OUTPUT_NODAL_COLOR(_idx)\
	gs_out.nodal_color = gs_in[_idx].nodal_color;
#else
#define OUTPUT_NODAL_COLOR(_idx)
#endif

#if defined(SHADER_NEED_FOR_PRIMDATA)
struct PrimData {
#if defined(SHADER_FRINGE_TOP)
#if defined(SHADER_FRINGE_EXACT) && defined(SHADER_QUAD8)
    vec2 tex_top[8];
#else
    vec2 tex_top[GS_MAXVERT];
#endif
#endif
#if defined(SHADER_FRINGE_BOTTOM)
#if defined(SHADER_FRINGE_EXACT) && defined(SHADER_QUAD8)
    vec2 tex_bottom[8];
#else
    vec2 tex_bottom[GS_MAXVERT];
#endif
#endif
#if defined(SHADER_SMOOTH_NORMALS) || defined(SHADER_NEED_FOR_MODNORMALS)
	vec3 smooth_normals[GS_MAXVERT];
	vec3 modNormal[GS_MAXVERT];
#endif
#if defined(SHADER_LIC_LAY_COMPOSE)
	float nrLvl;
	vec4 lvl_uni;
	vec4 vr_mul_layWt[GS_MAXVERT];
	vec3 vr_srcWt[GS_MAXVERT];
	vec4 tangVec[GS_MAXVERT];
#endif
#if defined(SHADER_LIC_SCREEN_SPACE)
	vec2 scrVec[GS_MAXVERT];
	vec4 tangVec[GS_MAXVERT];
#endif
};

PrimData get_prim_data(int prim_id)
{
	PrimData prim_data;
#if defined(SHADER_LIC_LAY_COMPOSE)
	prim_data.lvl_uni = vec4(1.0);
#endif

#if (defined(SHADER_NEED_FOR_MODNORMALS) || defined(SHADER_SMOOTH_NORMALS))
#if defined (SHADER_TRIA3) 
	uvec4 cnorms = texelFetch(elem_smooth_normals, prim_id);
	prim_data.modNormal[0] = uncompress_normal(cnorms.r);
	prim_data.modNormal[1] = uncompress_normal(cnorms.g);
	prim_data.modNormal[2] = uncompress_normal(cnorms.b);
#elif defined(SHADER_QUAD4)
	uvec4 cnorms = texelFetch(elem_smooth_normals, prim_id);
	prim_data.modNormal[0] = uncompress_normal(cnorms.r);
	prim_data.modNormal[1] = uncompress_normal(cnorms.g);
	prim_data.modNormal[2] = uncompress_normal(cnorms.b);
	prim_data.modNormal[3] = uncompress_normal(cnorms.a);
#elif defined(SHADER_QUAD8)
	get_smooth_normals_quad8_chunk(prim_id, prim_data.modNormal);
#elif defined(SHADER_TRIA6)
	get_smooth_normals_tria6(prim_id, prim_data.modNormal);
#elif defined(SHADER_POLYGON)
	get_smooth_normals_polygon_patch(prim_id, prim_data.modNormal);
#endif
#endif

#if defined(SHADER_FRINGE_TOP)
    get_fringe_tex_top(prim_id, prim_data.tex_top);
#endif
#if defined(SHADER_FRINGE_BOTTOM)
    get_fringe_tex_bottom(prim_id, prim_data.tex_bottom);
#endif

#if defined(SHADER_NEED_FOR_MODNORMALS) || defined(SHADER_SMOOTH_NORMALS)
	mat4 expl_mat = globals.tr_iview_matrix * pid_uniforms.explode_matrix;
	for(int iVert = 0; iVert < GS_MAXVERT && iVert < 6; iVert++) {
		vec3 mn = prim_data.modNormal[iVert];
	#if defined(SHADER_SMOOTH_NORMALS)
		prim_data.smooth_normals[iVert] = normalize(expl_mat * vec4(mn, 0.0)).xyz;
	#endif
	#if defined(SHADER_LIC_LAY_COMPOSE) || defined(SHADER_LIC_SCREEN_SPACE)
		prim_data.tangVec[iVert] = /*pid_uniforms.lic_data.precOrderAdj **/ calcTangSign(gs_in[iVert].vectors, mn);
	#if defined(SHADER_LIC_LAY_COMPOSE)
		prim_data.vr_srcWt[iVert] = getLICDirSrc(mn);
		vec4 depth_layer;
		depth_layer.x = orientDepth3Q(texLIC0, prim_data.vr_srcWt[iVert], gs_in[iVert].vr_Orient);
		depth_layer.y = orientDepth3Q(texLIC1, prim_data.vr_srcWt[iVert], gs_in[iVert].vr_Orient);
		depth_layer.z = orientDepth3Q(texLIC2, prim_data.vr_srcWt[iVert], gs_in[iVert].vr_Orient);
		depth_layer.w = orientDepth3Q(texLIC3, prim_data.vr_srcWt[iVert], gs_in[iVert].vr_Orient);
		float curr_depth = calcLICOrientToDepth(prim_data.vr_srcWt[iVert], gs_in[iVert].vr_Orient);
		prim_data.vr_mul_layWt[iVert] = getLICLaySrc(curr_depth, depth_layer);
		prim_data.lvl_uni *= prim_data.vr_mul_layWt[iVert];
	#endif
	#if defined(SHADER_LIC_SCREEN_SPACE)
		prim_data.scrVec[iVert] = modelToScreenVectorFwd(globals.view_projection_matrix * pid_uniforms.explode_matrix, pid_uniforms.lic_data, vec4(gs_in[iVert].object_pos, 1.), vec4(prim_data.tangVec[iVert].xyz, .0));
	#endif
	#endif
	}
#endif

#if defined(SHADER_LIC_LAY_COMPOSE)
	prim_data.nrLvl = dot(prim_data.lvl_uni, vec4(1.0));
	prim_data.lvl_uni /= vec4(mix(1.0, prim_data.nrLvl, float(prim_data.nrLvl > 1.0)));
#endif
	return prim_data;
}
#endif

#if defined(SHADER_LIC_OVERLAY) && defined(SHADER_LIC_LAY_COMPOSE)
#define OUTPUT_LICDATA_EXT(_TVEC_, _VEC_, _SRCWT_, _VRORIENT_, _LAYWT_, _VIEWPOS_, _MODNORM_)\
{\
	float maskLen = calcLICMaskLen(_TVEC_, _VEC_);\
	gs_out.vr_mask = calcLICMasking(maskLen, pid_uniforms.lic_data);\
	gs_out.vr_srcWt = _SRCWT_;\
	gs_out.vr_licCoords_p = vertToTCQ1(_VRORIENT_);\
	gs_out.vr_licCoords_s = vertToTCQ2(_VRORIENT_);\
	gs_out.vr_licCoords_t = vertToTCQ3(_VRORIENT_);\
	float nrVLvl = dot(_LAYWT_, vec4(1.));\
	vec4 vr_layWtHom = mix(vec4(1., .0, .0, .0), _LAYWT_, float(nrVLvl > .0));\
	vr_layWtHom /= vec4(mix(1., nrVLvl, float(nrVLvl > 1.)));\
	gs_out.vr_layWt = mix(vr_layWtHom, primDat.lvl_uni, float(primDat.nrLvl > .0));\
	vec4 dirScale = globals.view_matrix * .5 * getDirectionalScale(pid_uniforms.lic_data.base_scale, _TVEC_.xyz, _MODNORM_);\
	float vrtxScalePx = getPixelSizeOfFeature(vec4(_VIEWPOS_, 1.), dirScale, pid_uniforms.lic_data.wRes, globals.projection_matrix);\
	gs_out.vr_cLevel = cascadeLevelFromRefSize(vrtxScalePx, pid_uniforms.lic_data);\
}
#define OUTPUT_LICDATA(_idx)\
{\
	OUTPUT_LICDATA_EXT(primDat.tangVec[_idx], gs_in[_idx].vectors, primDat.vr_srcWt[_idx], gs_in[_idx].vr_Orient, primDat.vr_mul_layWt[_idx], gs_in[_idx].view_pos, primDat.modNormal[_idx])\
}
#elif defined(SHADER_LIC_SCREEN_SPACE)
#define OUTPUT_LICDATA_EXT(_TVEC_, _VEC_, _SRCVEC_)\
{\
	float maskLen = calcLICMaskLen(_TVEC_, _VEC_);\
	gs_out.vr_mask = calcLICMasking(maskLen, pid_uniforms.lic_data);\
	gs_out.vr_scrVect = orientByPreferred(_SRCVEC_, primDat.scrVec[0]);\
}
#define OUTPUT_LICDATA(_idx)\
{\
	OUTPUT_LICDATA_EXT(primDat.tangVec[_idx], gs_in[_idx].vectors, primDat.scrVec[_idx])\
}
#else
#define OUTPUT_LICDATA(_idx)
#endif

#if defined(SHADER_CLIP)
#if defined(SHADER_SHADOW_DIR_PASS)
#define OUTPUT_CLIP_VERTEX(_idx)\
{\
	vec4 _view_pos = globals.view_matrix * globals.shadow_light_data.idir_lights_view_matrix[current_dir_light] * vec4(gs_in[_idx].view_pos, 1.0f);\
	output_clip_vertex(_view_pos, pid_uniforms.clip);\
}
#else
#define OUTPUT_CLIP_VERTEX(_idx)\
{\
	vec4 _view_pos = vec4(gs_in[_idx].view_pos, 1.0);\
	output_clip_vertex(_view_pos, pid_uniforms.clip);\
}
#endif
#else
#define OUTPUT_CLIP_VERTEX(_idx)
#endif

#if defined(SHADER_SMOOTH_NORMALS)
#define OUTPUT_SMOOTH_NORMALS(_idx)\
    gs_out.normal = primDat.smooth_normals[_idx];
#else
#define OUTPUT_SMOOTH_NORMALS(_idx)
#endif

#if defined(SHADER_BARYCENTRICS)
#define OUTPUT_BARYCENTRIC(_compX, _compY)\
    gs_out.barycentric = vec2(_compX, _compY);
#else
#define OUTPUT_BARYCENTRIC(_compX, _compY)
#endif

#if defined(SHADER_SINGLE_PASS_STEREO)
	#define OUTPUT_POSITION(_idx)\
		gl_Position = gl_in[_idx].gl_Position;\
		gl_SecondaryPositionNV = gl_in[_idx].gl_SecondaryPositionNV;\
		gl_Layer = 0;
#else
	#define OUTPUT_POSITION(_idx)\
		gl_Position = gl_in[_idx].gl_Position;
#endif // SHADER_SINGLE_PASS_STEREO

#if defined(SHADER_THICK_SHELLS)

#if defined(SHADER_THICK_SHELLS)
#if !defined(SHADER_EXTRA_ELEMENTS)
vec2 get_thickness_factors(int prim_id)
{
	#if defined(SHADER_THICK_SHELLS_GET_FRINGE)
		vec2 ret;
		float top = texelFetch(elem_thickness_values, prim_id).r;
		bool isnoval_top = isnoval(top);
		top = (isnoval_top) ? 0.0 : top * globals.thick_shells_scale.r * 0.5;
		ret = vec2( top, -top );
		#if defined(SHADER_THICK_SHELLS_GET_FRINGE_BOTTOM)
			float bottom = texelFetch(elem_thickness_values, prim_id).g;
			bool isnoval_bottom = isnoval(bottom);
			bottom = (isnoval_bottom) ? 0.0 : bottom * globals.thick_shells_scale.r * 0.5;
			if ( !isnoval_top && !isnoval_bottom ) {
				float avg = (top + bottom) * 0.5;
				ret = vec2( avg, -avg );
			} else {
				ret = vec2( 0.0 );
			} 
		#endif
		return ret;
	#else
		return texelFetch(elem_thickness_values, prim_id).rg;
	#endif
}
#else
vec2 get_thickness_factors(int prim_id)
{
	// here calculations are done in update jobs
	return gs_in[0].thickness_values;
}
#endif

#if !defined(SHADER_EXTRA_ELEMENTS)
uint get_thickness_onfeature(int prim_id)
{
	return texelFetch(elem_thickness_onfeature, prim_id).r;
}
#else
uint get_thickness_onfeature(int prim_id)
{
	uint x = 0u;
	return ~(x & 0u);
}
#endif

vec4 explode(vec3 object_pos, vec3 object_normal, float value)
{
	vec3 direction = object_normal * value;
	vec3 world_position = object_pos + direction;

	return (globals.view_matrix * pid_uniforms.explode_matrix * vec4( world_position, 1.0 ));
}

vec3 orient_view_normal(vec3 view_normal)
{
	return ( dot( view_normal, vec3( 0.0, 0.0, 1.0 ) ) < 0 ) ? -view_normal :  view_normal;
}

vec3 calc_normal_thick_tria3(vec4 view_pos_0, vec4 view_pos_1, vec4 view_pos_2)
{
    vec3 u = vec3(view_pos_1 - view_pos_0);
    vec3 v = vec3(view_pos_2 - view_pos_0);
	vec3 norm = normalize(cross(u, v));
	
	return orient_view_normal( norm );
}

vec3 calc_normal_thick_quad4(vec4 view_pos_0, vec4 view_pos_1, vec4 view_pos_2, vec4 view_pos_3)
{
    vec3 u = vec3(view_pos_2 - view_pos_0);
    vec3 v = vec3(view_pos_3 - view_pos_1);
	vec3 norm = normalize(cross(u, v));
	
	return orient_view_normal( norm );
}

vec3 calc_normal_thick_quad6(vec4 view_pos_0, vec4 view_pos_1, vec4 view_pos_2, vec4 view_pos_3)
{
    vec3 u = vec3(view_pos_3 - view_pos_0);
    vec3 v = vec3(view_pos_2 - view_pos_1);
	vec3 norm = normalize(cross(u, v));
	
	return orient_view_normal( norm );
}

vec3 calc_normal_thick_quad8(vec4 view_pos_1, vec4 view_pos_3, vec4 view_pos_5, vec4 view_pos_2)
{
    vec3 u = vec3(view_pos_1 - view_pos_3);
    vec3 v = vec3(view_pos_5 - view_pos_2);
	vec3 norm = normalize(cross(u, v));
	
	return orient_view_normal( norm );
}

#if defined(SHADER_CLIP)
#define OUTPUT_CLIP_VERTEX_THICK(_view_pos)\
{\
	output_clip_vertex(_view_pos, pid_uniforms.clip);\
}
#else
#define OUTPUT_CLIP_VERTEX_THICK(__view_pos)
#endif

void output_params(vec2 brcs, int i)
{
	int prim_id = get_prim_id();

#if defined(SHADER_NEED_FOR_PRIMDATA)
	PrimData primDat = get_prim_data(prim_id);
#endif
	OUTPUT_BARYCENTRIC(brcs.x, brcs.y);
	OUTPUT_SMOOTH_NORMALS(i);
	OUTPUT_TEX_TOP(i);
	OUTPUT_TEX_BOTTOM(i);
	// OUTPUT_BLUR_VELOCITY(i);
	OUTPUT_TEX_COORDS(i);
	OUTPUT_NODAL_NORMALS(i);
	// OUTPUT_CLIP_VERTEX(i);
	OUTPUT_LICDATA(i);
}

#if (defined(SHADER_FRINGE_NODE) || defined(SHADER_FRINGE_CORNER)) && defined(SHADER_FRINGE_BOTTOM)
void output_params_top_bottom_node(vec2 brcs, int i, bool middle_value)
{
	int prim_id = get_prim_id();

#if defined(SHADER_NEED_FOR_PRIMDATA)
	PrimData primDat = get_prim_data(prim_id);
#endif
	OUTPUT_BARYCENTRIC(brcs.x, brcs.y);
	// OUTPUT_SMOOTH_NORMALS(i);
	if ( !middle_value ) {
		OUTPUT_TEX_TOP(i);
		OUTPUT_TEX_BOTTOM(i);
	} else {
		vec2 avg = vec2( ( primDat.tex_top[i] + primDat.tex_bottom[i] ) / 2.0 );
		gs_out.tex_top = avg;
		gs_out.tex_bottom = avg;
	}
	// OUTPUT_BLUR_VELOCITY(i);
	OUTPUT_TEX_COORDS(i);
	OUTPUT_NODAL_NORMALS(i);
	OUTPUT_CLIP_VERTEX(i);
	OUTPUT_LICDATA(i);
}
#endif

void output_params_wire(int i)
{
#if defined(SHADER_FRINGE_NODE)
    gs_out.tex_top = compute_tex_coords(gs_in[i].fringe_node_top);
#endif
	OUTPUT_CLIP_VERTEX(i);
}

void make_face_tria_3(vec4 view_pos_0, vec4 view_pos_1, vec4 view_pos_2, ivec3 ids)
{
	vec3 view_normal_new = calc_normal_thick_tria3( view_pos_0, view_pos_1, view_pos_2 );

#if defined(SHADER_BARYCENTRICS)
	gs_out.edges = (1u << 2u) | (1u << 1u) | (1u << 0u);
#endif

#if !defined(SHADER_SMOOTH_NORMALS)
	gs_out.flat_normal = pack_snorm_4x8(vec4(view_normal_new, 0.0));
#endif
	
	output_params(vec2(0.0, 0.0), ids.x);
	OUTPUT_CLIP_VERTEX_THICK(view_pos_0);
	gl_Position = globals.projection_matrix * view_pos_0;
	EmitVertex();
	output_params(vec2(0.0, 1.0), ids.y);
	OUTPUT_CLIP_VERTEX_THICK(view_pos_1);
	gl_Position = globals.projection_matrix * view_pos_1;
	EmitVertex();
	output_params(vec2(1.0, 0.0), ids.z);
	OUTPUT_CLIP_VERTEX_THICK(view_pos_2);
	gl_Position = globals.projection_matrix * view_pos_2;
	EmitVertex();
	EndPrimitive();
}

void make_face_tria_6(vec4 view_pos_0, vec4 view_pos_1, vec4 view_pos_2,
				 vec4 view_pos_3, vec4 view_pos_4, vec4 view_pos_5,
				 int ids[6])
{
	vec3 view_normal_new = calc_normal_thick_tria3( view_pos_0, view_pos_1, view_pos_2 );

#if defined(SHADER_BARYCENTRICS)
	gs_out.edges = (1u << 2u) | (1u << 1u) | (1u << 0u);
#endif

#if !defined(SHADER_SMOOTH_NORMALS)
	gs_out.flat_normal = pack_snorm_4x8(vec4(view_normal_new, 0.0));
#endif
	
	output_params(vec2(0.0, 0.0), ids[1]);
	OUTPUT_CLIP_VERTEX_THICK(view_pos_1);
	gl_Position = globals.projection_matrix * view_pos_1;
	EmitVertex();
	output_params(vec2(0.0, 0.0), ids[4]);
	OUTPUT_CLIP_VERTEX_THICK(view_pos_4);
	gl_Position = globals.projection_matrix * view_pos_4;
	EmitVertex();
	output_params(vec2(0.0, 0.0), ids[3]);
	OUTPUT_CLIP_VERTEX_THICK(view_pos_3);
	gl_Position = globals.projection_matrix * view_pos_3;
	EmitVertex();
	output_params(vec2(0.0, 0.0), ids[5]);
	OUTPUT_CLIP_VERTEX_THICK(view_pos_5);
	gl_Position = globals.projection_matrix * view_pos_5;
	EmitVertex();
	output_params(vec2(0.0, 0.0), ids[0]);
	OUTPUT_CLIP_VERTEX_THICK(view_pos_0);
	gl_Position = globals.projection_matrix * view_pos_0;
	EmitVertex();
	EndPrimitive();

	output_params(vec2(0.0, 0.0), ids[4]);
	OUTPUT_CLIP_VERTEX_THICK(view_pos_4);
	gl_Position = globals.projection_matrix * view_pos_4;
	EmitVertex();
	output_params(vec2(0.0, 0.0), ids[2]);
	OUTPUT_CLIP_VERTEX_THICK(view_pos_2);
	gl_Position = globals.projection_matrix * view_pos_2;
	EmitVertex();
	output_params(vec2(0.0, 0.0), ids[5]);
	OUTPUT_CLIP_VERTEX_THICK(view_pos_5);
	gl_Position = globals.projection_matrix * view_pos_5;
	EmitVertex();
	EndPrimitive();
}

void make_face_quad_4(vec4 view_pos_0, vec4 view_pos_1, vec4 view_pos_2, vec4 view_pos_3,
						ivec4 ids, bool thick_skip_wire_barycentrics)
{
	vec3 view_normal_new = calc_normal_thick_quad4( view_pos_0, view_pos_1, view_pos_2, view_pos_3);

#if defined(SHADER_BARYCENTRICS)
	gs_out.edges = (1u << 1u) | (1u << 0u);
#endif

#if !defined(SHADER_SMOOTH_NORMALS)
	gs_out.flat_normal = pack_snorm_4x8(vec4(view_normal_new, 0.0));
#endif

	output_params(vec2(0.0, 0.0), ids.x);
	OUTPUT_CLIP_VERTEX_THICK(view_pos_0);
	gl_Position = globals.projection_matrix * view_pos_0;
	EmitVertex();
	output_params(vec2(0.0, 1.0), ids.y);
	OUTPUT_CLIP_VERTEX_THICK(view_pos_1);
	gl_Position = globals.projection_matrix * view_pos_1;
	EmitVertex();
	output_params(vec2(1.0, 0.0), ids.w);
	OUTPUT_CLIP_VERTEX_THICK(view_pos_3);
	gl_Position = globals.projection_matrix * view_pos_3;
	EmitVertex();
#if defined(SHADER_BARYCENTRICS)
	gs_out.edges = (thick_skip_wire_barycentrics) ? (1u << 1u) : gs_out.edges;
#endif
	output_params(vec2(0.0, 0.0), ids.z);
	OUTPUT_CLIP_VERTEX_THICK(view_pos_2);
	gl_Position = globals.projection_matrix * view_pos_2;
	EmitVertex();
	EndPrimitive();
}

void make_face_quad_4_side(vec4 view_pos_0, vec4 view_pos_1, vec4 view_pos_2, vec4 view_pos_3,
							ivec4 ids, bool thick_skip_wire_barycentrics, vec3 view_normal_orig, bool on_feature,
							vec2 brcs[4])
{
#if defined(SHADER_THICK_SHELLS_GET_NODAL_THICKNESS)
	// if ( !on_feature ) return; // TODO KATRASD THICK -> this has problem with nodal thickness on features, leaves holes! Later do an optimization to skip these.
#endif
#if defined(SHADER_THICK_SHELLS_ONFEATURE_ALWAYS_ON)
	vec3 view_normal_new = calc_normal_thick_quad4( view_pos_0, view_pos_1, view_pos_2, view_pos_3);
#else
	vec3 view_normal_new = (on_feature) ? calc_normal_thick_quad4( view_pos_0, view_pos_1, view_pos_2, view_pos_3) : orient_view_normal( view_normal_orig );
#endif

#if defined(SHADER_BARYCENTRICS) && !defined(SHADER_QUAD8)
	gs_out.edges = (1u << 1u) | (1u << 0u);
#endif

#if !defined(SHADER_SMOOTH_NORMALS)
	gs_out.flat_normal = pack_snorm_4x8(vec4(view_normal_new, 0.0));
#endif

	output_params(brcs[0], ids.x);
	OUTPUT_CLIP_VERTEX_THICK(view_pos_0);
	gl_Position = globals.projection_matrix * view_pos_0;
	EmitVertex();
	output_params(brcs[1], ids.y);
	OUTPUT_CLIP_VERTEX_THICK(view_pos_1);
	gl_Position = globals.projection_matrix * view_pos_1;
	EmitVertex();
	output_params(brcs[3], ids.w);
	OUTPUT_CLIP_VERTEX_THICK(view_pos_3);
	gl_Position = globals.projection_matrix * view_pos_3;
	EmitVertex();
#if defined(SHADER_BARYCENTRICS) && !defined(SHADER_QUAD8)
	gs_out.edges = (thick_skip_wire_barycentrics) ? (1u << 1u) : gs_out.edges;
#endif
	output_params(brcs[2], ids.z);
	OUTPUT_CLIP_VERTEX_THICK(view_pos_2);
	gl_Position = globals.projection_matrix * view_pos_2;
	EmitVertex();
	EndPrimitive();
}

#if (defined(SHADER_FRINGE_NODE) || defined(SHADER_FRINGE_CORNER)) && defined(SHADER_FRINGE_BOTTOM)
void make_face_quad_4_side_top_bottom_node(vec4 view_pos_0, vec4 view_pos_1, vec4 view_pos_2, vec4 view_pos_3,
							ivec4 ids, bvec4 middle_values, bool thick_skip_wire_barycentrics, vec3 view_normal_orig,
							bool on_feature, vec2 brcs[4])
{
#if defined(SHADER_THICK_SHELLS_ONFEATURE_ALWAYS_ON)
	vec3 view_normal_new = calc_normal_thick_quad4( view_pos_0, view_pos_1, view_pos_2, view_pos_3 );
#else
	vec3 view_normal_new = (on_feature) ? calc_normal_thick_quad4( view_pos_0, view_pos_1, view_pos_2, view_pos_3 ) : orient_view_normal( view_normal_orig );
#endif

#if defined(SHADER_BARYCENTRICS) && !defined(SHADER_QUAD8)
	gs_out.edges = (1u << 1u) | (1u << 0u);
#endif

#if !defined(SHADER_SMOOTH_NORMALS)
	gs_out.flat_normal = pack_snorm_4x8(vec4(view_normal_new, 0.0));
#endif

	output_params_top_bottom_node(brcs[0], ids.x, middle_values.x);
	gl_Position = globals.projection_matrix * view_pos_0;
	EmitVertex();
	output_params_top_bottom_node(brcs[1], ids.y, middle_values.y);
	gl_Position = globals.projection_matrix * view_pos_1;
	EmitVertex();
	output_params_top_bottom_node(brcs[3], ids.w, middle_values.w);
	gl_Position = globals.projection_matrix * view_pos_3;
	EmitVertex();
#if defined(SHADER_BARYCENTRICS) && !defined(SHADER_QUAD8)
	gs_out.edges = (thick_skip_wire_barycentrics) ? (1u << 1u) : gs_out.edges;
#endif
	output_params_top_bottom_node(brcs[2], ids.z, middle_values.z);
	gl_Position = globals.projection_matrix * view_pos_2;
	EmitVertex();
	EndPrimitive();
}
#endif

void make_face_quad_6_side(vec4 view_pos_0, vec4 view_pos_1, vec4 view_pos_2,
				 	  vec4 view_pos_3, vec4 view_pos_4, vec4 view_pos_5,
				 	  int ids[6], vec3 view_normal_orig, bool on_feature)
{
#if defined(SHADER_THICK_SHELLS_ONFEATURE_ALWAYS_ON)
	vec3 view_normal_new = calc_normal_thick_quad6( view_pos_0, view_pos_1, view_pos_4, view_pos_5 );
#else
	vec3 view_normal_new = (on_feature) ? calc_normal_thick_quad6( view_pos_0, view_pos_1, view_pos_4, view_pos_5 ) : orient_view_normal( view_normal_orig );
#endif

#if defined(SHADER_BARYCENTRICS)
	gs_out.edges = (1u << 2u) | (1u << 1u) | (1u << 0u);
#endif

#if !defined(SHADER_SMOOTH_NORMALS)
	gs_out.flat_normal = pack_snorm_4x8(vec4(view_normal_new, 0.0));
#endif
	
	output_params(vec2(0.0, 0.0), ids[0]);
	OUTPUT_CLIP_VERTEX_THICK(view_pos_0);
	gl_Position = globals.projection_matrix * view_pos_0;
	EmitVertex();
	output_params(vec2(0.0, 0.0), ids[1]);
	OUTPUT_CLIP_VERTEX_THICK(view_pos_1);
	gl_Position = globals.projection_matrix * view_pos_1;
	EmitVertex();
	output_params(vec2(0.0, 0.0), ids[2]);
	OUTPUT_CLIP_VERTEX_THICK(view_pos_2);
	gl_Position = globals.projection_matrix * view_pos_2;
	EmitVertex();
	output_params(vec2(0.0, 0.0), ids[3]);
	OUTPUT_CLIP_VERTEX_THICK(view_pos_3);
	gl_Position = globals.projection_matrix * view_pos_3;
	EmitVertex();
	output_params(vec2(0.0, 0.0), ids[4]);
	OUTPUT_CLIP_VERTEX_THICK(view_pos_4);
	gl_Position = globals.projection_matrix * view_pos_4;
	EmitVertex();
	output_params(vec2(0.0, 0.0), ids[5]);
	OUTPUT_CLIP_VERTEX_THICK(view_pos_5);
	gl_Position = globals.projection_matrix * view_pos_5;
	EmitVertex();
	EndPrimitive();
}

#if (defined(SHADER_FRINGE_NODE) || defined(SHADER_FRINGE_CORNER)) && defined(SHADER_FRINGE_BOTTOM)
void make_face_quad_6_side_top_bottom_node(vec4 view_pos_0, vec4 view_pos_1, vec4 view_pos_2,
				 	  vec4 view_pos_3, vec4 view_pos_4, vec4 view_pos_5,
				 	  int ids[6], bool middle_values[6], vec3 view_normal_orig, bool on_feature)
{
#if defined(SHADER_THICK_SHELLS_ONFEATURE_ALWAYS_ON)
	vec3 view_normal_new = calc_normal_thick_quad6( view_pos_0, view_pos_1, view_pos_4, view_pos_5 );
#else
	vec3 view_normal_new = (on_feature) ? calc_normal_thick_quad6( view_pos_0, view_pos_1, view_pos_4, view_pos_5 ) : orient_view_normal( view_normal_orig );
#endif

#if defined(SHADER_BARYCENTRICS)
	gs_out.edges = (1u << 2u) | (1u << 1u) | (1u << 0u);
#endif

#if !defined(SHADER_SMOOTH_NORMALS)
	gs_out.flat_normal = pack_snorm_4x8(vec4(view_normal_new, 0.0));
#endif
	
	output_params_top_bottom_node(vec2(0.0, 0.0), ids[0], middle_values[0]);
	gl_Position = globals.projection_matrix * view_pos_0;
	EmitVertex();
	output_params_top_bottom_node(vec2(0.0, 0.0), ids[1], middle_values[1]);
	gl_Position = globals.projection_matrix * view_pos_1;
	EmitVertex();
	output_params_top_bottom_node(vec2(0.0, 0.0), ids[2], middle_values[2]);
	gl_Position = globals.projection_matrix * view_pos_2;
	EmitVertex();
	output_params_top_bottom_node(vec2(0.0, 0.0), ids[3], middle_values[3]);
	gl_Position = globals.projection_matrix * view_pos_3;
	EmitVertex();
	output_params_top_bottom_node(vec2(0.0, 0.0), ids[4], middle_values[4]);
	gl_Position = globals.projection_matrix * view_pos_4;
	EmitVertex();
	output_params_top_bottom_node(vec2(0.0, 0.0), ids[5], middle_values[5]);
	gl_Position = globals.projection_matrix * view_pos_5;
	EmitVertex();
	EndPrimitive();
}
#endif

void make_face_quad_8_half_top_or_bottom(vec4 view_pos_0, vec4 view_pos_1, vec4 view_pos_2,
				 vec4 view_pos_3, vec4 view_pos_4, vec4 view_pos_5,
				 int ids[5], vec2 brcs[5])
{
	vec3 view_normal_new = calc_normal_thick_quad8( view_pos_1, view_pos_3, view_pos_5, view_pos_2 );

#if !defined(SHADER_SMOOTH_NORMALS)
	gs_out.flat_normal = pack_snorm_4x8(vec4(view_normal_new, 0.0));
#endif
	
	output_params(brcs[0], ids[0]);
	OUTPUT_CLIP_VERTEX_THICK(view_pos_0);
	gl_Position = globals.projection_matrix * view_pos_0;
	EmitVertex();
	output_params(brcs[1], ids[1]);
	OUTPUT_CLIP_VERTEX_THICK(view_pos_1);
	gl_Position = globals.projection_matrix * view_pos_1;
	EmitVertex();
	output_params(brcs[2], ids[2]);
	OUTPUT_CLIP_VERTEX_THICK(view_pos_2);
	gl_Position = globals.projection_matrix * view_pos_2;
	EmitVertex();
	output_params(brcs[3], ids[3]);
	OUTPUT_CLIP_VERTEX_THICK(view_pos_3);
	gl_Position = globals.projection_matrix * view_pos_3;
	EmitVertex();
	output_params(brcs[4], ids[4]);
	OUTPUT_CLIP_VERTEX_THICK(view_pos_4);
	gl_Position = globals.projection_matrix * view_pos_4;
	EmitVertex();
	EndPrimitive();
}

void make_face_quad_8_front_side(vec4 view_pos_0, vec4 view_pos_1, vec4 view_pos_2,
								 vec4 view_pos_3, vec4 view_pos_4, vec4 view_pos_5,
								 int ids[6], vec3 view_normal_orig, bool on_feature, vec2 brcs[6])
{
#if defined(SHADER_THICK_SHELLS_ONFEATURE_ALWAYS_ON)
	vec3 view_normal_new = calc_normal_thick_quad6(view_pos_0, view_pos_1, view_pos_4, view_pos_5);
#else
	vec3 view_normal_new = (on_feature) ? calc_normal_thick_quad6(view_pos_0, view_pos_1, view_pos_4, view_pos_5) : orient_view_normal( view_normal_orig );
#endif

#if !defined(SHADER_SMOOTH_NORMALS)
	gs_out.flat_normal = pack_snorm_4x8(vec4(view_normal_new, 0.0));
#endif
	
	output_params(brcs[0], ids[0]);
	OUTPUT_CLIP_VERTEX_THICK(view_pos_0);
	gl_Position = globals.projection_matrix * view_pos_0;
	EmitVertex();
	output_params(brcs[1], ids[1]);
	OUTPUT_CLIP_VERTEX_THICK(view_pos_1);
	gl_Position = globals.projection_matrix * view_pos_1;
	EmitVertex();
	output_params(brcs[2], ids[2]);
	OUTPUT_CLIP_VERTEX_THICK(view_pos_2);
	gl_Position = globals.projection_matrix * view_pos_2;
	EmitVertex();
	output_params(brcs[3], ids[3]);
	OUTPUT_CLIP_VERTEX_THICK(view_pos_3);
	gl_Position = globals.projection_matrix * view_pos_3;
	EmitVertex();
	output_params(brcs[4], ids[4]);
	OUTPUT_CLIP_VERTEX_THICK(view_pos_4);
	gl_Position = globals.projection_matrix * view_pos_4;
	EmitVertex();
	output_params(brcs[5], ids[5]);
	OUTPUT_CLIP_VERTEX_THICK(view_pos_5);
	gl_Position = globals.projection_matrix * view_pos_5;
	EmitVertex();
	EndPrimitive();
}

#if (defined(SHADER_FRINGE_NODE) || defined(SHADER_FRINGE_CORNER)) && defined(SHADER_FRINGE_BOTTOM)
void make_face_quad_8_front_side_top_bottom_node(vec4 view_pos_0, vec4 view_pos_1, vec4 view_pos_2,
								 vec4 view_pos_3, vec4 view_pos_4, vec4 view_pos_5,
								 int ids[6], bool middle_values[6], vec3 view_normal_orig, bool on_feature,
								 vec2 brcs[6])
{
#if defined(SHADER_THICK_SHELLS_ONFEATURE_ALWAYS_ON)
	vec3 view_normal_new = calc_normal_thick_quad6(view_pos_0, view_pos_1, view_pos_4, view_pos_5);
#else
	vec3 view_normal_new = (on_feature) ? calc_normal_thick_quad6(view_pos_0, view_pos_1, view_pos_4, view_pos_5) : orient_view_normal( view_normal_orig );
#endif

#if !defined(SHADER_SMOOTH_NORMALS)
	gs_out.flat_normal = pack_snorm_4x8(vec4(view_normal_new, 0.0));
#endif
	
	output_params_top_bottom_node(brcs[0], ids[0], middle_values[0]);
	gl_Position = globals.projection_matrix * view_pos_0;
	EmitVertex();
	output_params_top_bottom_node(brcs[1], ids[1], middle_values[1]);
	gl_Position = globals.projection_matrix * view_pos_1;
	EmitVertex();
	output_params_top_bottom_node(brcs[2], ids[2], middle_values[2]);
	gl_Position = globals.projection_matrix * view_pos_2;
	EmitVertex();
	output_params_top_bottom_node(brcs[3], ids[3], middle_values[3]);
	gl_Position = globals.projection_matrix * view_pos_3;
	EmitVertex();
	output_params_top_bottom_node(brcs[4], ids[4], middle_values[4]);
	gl_Position = globals.projection_matrix * view_pos_4;
	EmitVertex();
	output_params_top_bottom_node(brcs[5], ids[5], middle_values[5]);
	gl_Position = globals.projection_matrix * view_pos_5;
	EmitVertex();
	EndPrimitive();
}
#endif

#if defined(SHADER_TRIA3) && !defined(SHADER_TWO_SIDE)
void output_tria3_thick(vec3 view_normal)
{
	vec4 u0, u1, u2, d0, d1, d2; // view pos

	int prim_id = get_prim_id();
	uint bits_onfeat = get_thickness_onfeature(prim_id);
	
#if !defined(SHADER_SMOOTH_NORMALS)
#if defined(SHADER_THICK_SHELLS_GET_NODAL_THICKNESS)
	float f0, f1, f2;
	vec3 n0, n1, n2;

	vec3 object_normal = get_prim_flat_normal();

	#if defined(SHADER_USE_NODAL_NORMALS)
		n0 = uncompress_normal( gs_in[0].nodal_normals );
		n1 = uncompress_normal( gs_in[1].nodal_normals );
		n2 = uncompress_normal( gs_in[2].nodal_normals );
	#else // SHADER_USE_NODAL_NORMALS_3F
		n0 = gs_in[0].nodal_normals;
		n1 = gs_in[1].nodal_normals;
		n2 = gs_in[2].nodal_normals;
	#endif

	n0 = ( ((bits_onfeat >> 4u) & 1u) == 1u ) ? object_normal : n0;
	n1 = ( ((bits_onfeat >> 5u) & 1u) == 1u ) ? object_normal : n1;
	n2 = ( ((bits_onfeat >> 6u) & 1u) == 1u ) ? object_normal : n2;

#if !defined(SHADER_EXTRA_ELEMENTS)
	f0 = gs_in[0].nodal_thickness * globals.thick_shells_scale.r * 0.5;
	f1 = gs_in[1].nodal_thickness * globals.thick_shells_scale.r * 0.5;
	f2 = gs_in[2].nodal_thickness * globals.thick_shells_scale.r * 0.5;
	
	u0 = explode( gs_in[0].object_pos, n0,  f0 ); 
	u1 = explode( gs_in[1].object_pos, n1,  f1 ); 
	u2 = explode( gs_in[2].object_pos, n2,  f2 ); 

	d0 = explode( gs_in[0].object_pos, n0, -f0 ); 
	d1 = explode( gs_in[1].object_pos, n1, -f1 ); 
	d2 = explode( gs_in[2].object_pos, n2, -f2 );
#else // defined(SHADER_EXTRA_ELEMENTS)
	u0 = explode( gs_in[0].object_pos, n0, gs_in[0].thickness_values.x ); 
	u1 = explode( gs_in[1].object_pos, n1, gs_in[1].thickness_values.x ); 
	u2 = explode( gs_in[2].object_pos, n2, gs_in[2].thickness_values.x ); 

	d0 = explode( gs_in[0].object_pos, n0, gs_in[0].thickness_values.y ); 
	d1 = explode( gs_in[1].object_pos, n1, gs_in[1].thickness_values.y ); 
	d2 = explode( gs_in[2].object_pos, n2, gs_in[2].thickness_values.y );
#endif // end !defined(SHADER_EXTRA_ELEMENTS)
#elif defined(SHADER_THICK_SHELLS_GET_CORNER_THICKNESS)
	vec3 object_normal = get_prim_flat_normal();
#if !defined(SHADER_EXTRA_ELEMENTS)
	float f0, f1, f2;

	vec4 corner_values = texelFetch(elem_thickness_values, prim_id);
	#if defined(SHADER_THICK_SHELLS_Z_OFFSET)
	float zoffset = texelFetch(elem_thickness_z_offset, prim_id).r;
	#else
	float zoffset = 0.0;
	#endif

	f0 = corner_values.r * globals.thick_shells_scale.r * 0.5;
	f1 = corner_values.g * globals.thick_shells_scale.r * 0.5;
	f2 = corner_values.b * globals.thick_shells_scale.r * 0.5;

	u0 = explode( gs_in[0].object_pos, object_normal, zoffset+f0 );
	u1 = explode( gs_in[1].object_pos, object_normal, zoffset+f1 );
	u2 = explode( gs_in[2].object_pos, object_normal, zoffset+f2 );

	d0 = explode( gs_in[0].object_pos, object_normal, zoffset-f0 );
	d1 = explode( gs_in[1].object_pos, object_normal, zoffset-f1 );
	d2 = explode( gs_in[2].object_pos, object_normal, zoffset-f2 );
#else // defined(SHADER_EXTRA_ELEMENTS)
	u0 = explode( gs_in[0].object_pos, object_normal, gs_in[0].thickness_values.x );
	u1 = explode( gs_in[1].object_pos, object_normal, gs_in[1].thickness_values.x );
	u2 = explode( gs_in[2].object_pos, object_normal, gs_in[2].thickness_values.x );

	d0 = explode( gs_in[0].object_pos, object_normal, gs_in[0].thickness_values.y );
	d1 = explode( gs_in[1].object_pos, object_normal, gs_in[1].thickness_values.y );
	d2 = explode( gs_in[2].object_pos, object_normal, gs_in[2].thickness_values.y );
#endif // end !defined(SHADER_EXTRA_ELEMENTS)
#else // CENTROID THICKNESS
	vec3 object_normal = get_prim_flat_normal();
	vec2 thickness_factors = get_thickness_factors( prim_id );

	u0 = explode( gs_in[0].object_pos, object_normal, thickness_factors.x );
	u1 = explode( gs_in[1].object_pos, object_normal, thickness_factors.x );
	u2 = explode( gs_in[2].object_pos, object_normal, thickness_factors.x );

	d0 = explode( gs_in[0].object_pos, object_normal, thickness_factors.y );
	d1 = explode( gs_in[1].object_pos, object_normal, thickness_factors.y );
	d2 = explode( gs_in[2].object_pos, object_normal, thickness_factors.y );
#endif
#else // SHADER_SMOOTH_NORMALS
#if defined(SHADER_THICK_SHELLS_GET_NODAL_THICKNESS)
	#if defined(SHADER_NEED_FOR_PRIMDATA)
		PrimData primDat = get_prim_data(prim_id);
	#endif
	u0 = explode( gs_in[0].object_pos, normalize( (globals.iview_matrix * vec4( orient_view_normal( primDat.smooth_normals[0]), 0.0 )).xyz ), gs_in[0].nodal_thickness * globals.thick_shells_scale.r * 0.5 );
	u1 = explode( gs_in[1].object_pos, normalize( (globals.iview_matrix * vec4( orient_view_normal( primDat.smooth_normals[1]), 0.0 )).xyz ), gs_in[1].nodal_thickness * globals.thick_shells_scale.r * 0.5 );
	u2 = explode( gs_in[2].object_pos, normalize( (globals.iview_matrix * vec4( orient_view_normal( primDat.smooth_normals[2]), 0.0 )).xyz ), gs_in[2].nodal_thickness * globals.thick_shells_scale.r * 0.5 );

	d0 = explode( gs_in[0].object_pos, normalize( (globals.iview_matrix * vec4( orient_view_normal( primDat.smooth_normals[0]), 0.0 )).xyz ), -gs_in[0].nodal_thickness * globals.thick_shells_scale.r * 0.5 );
	d1 = explode( gs_in[1].object_pos, normalize( (globals.iview_matrix * vec4( orient_view_normal( primDat.smooth_normals[1]), 0.0 )).xyz ), -gs_in[1].nodal_thickness * globals.thick_shells_scale.r * 0.5 );
	d2 = explode( gs_in[2].object_pos, normalize( (globals.iview_matrix * vec4( orient_view_normal( primDat.smooth_normals[2]), 0.0 )).xyz ), -gs_in[2].nodal_thickness * globals.thick_shells_scale.r * 0.5 );
#else
	vec3 object_normal = get_prim_flat_normal();
	vec2 thickness_factors = get_thickness_factors( prim_id );

	u0 = explode( gs_in[0].object_pos, object_normal, thickness_factors.x );
	u1 = explode( gs_in[1].object_pos, object_normal, thickness_factors.x );
	u2 = explode( gs_in[2].object_pos, object_normal, thickness_factors.x );

	d0 = explode( gs_in[0].object_pos, object_normal, thickness_factors.y );
	d1 = explode( gs_in[1].object_pos, object_normal, thickness_factors.y );
	d2 = explode( gs_in[2].object_pos, object_normal, thickness_factors.y );
#endif
#endif // END SHADER_SMOOTH_NORMALS

	make_face_tria_3( u0, u1, u2, ivec3( 0, 1, 2 ) ); // top
	make_face_tria_3( d0, d1, d2, ivec3( 0, 1, 2 ) ); // bottom

	vec2 brcs_def[4] = { vec2( 0.0, 0.0 ), vec2( 0.0, 1.0 ), vec2( 0.0, 0.0 ), vec2( 1.0, 0.0 ) };

#if defined(SHADER_EXTRA_ELEMENTS)
	if ( (( gs_in[0].thickness_internal_edge_mask >> 0u ) & 1u ) != 1u ) {
#endif
		make_face_quad_4_side( u0, d0, d1, u1, ivec4( 0, 0, 1, 1 ), false, view_normal, (((bits_onfeat >> 0u) & 1u) == 1u), brcs_def ); // side
#if defined(SHADER_EXTRA_ELEMENTS)
	}
#endif
#if defined(SHADER_EXTRA_ELEMENTS)
	if ( (( gs_in[0].thickness_internal_edge_mask >> 1u ) & 1u ) != 1u ) {
#endif
		make_face_quad_4_side( u1, d1, d2, u2, ivec4( 1, 1, 2, 2 ), false, view_normal, (((bits_onfeat >> 1u) & 1u) == 1u), brcs_def ); // side
#if defined(SHADER_EXTRA_ELEMENTS)
	}
#endif
#if defined(SHADER_EXTRA_ELEMENTS)
	if ( (( gs_in[0].thickness_internal_edge_mask >> 2u ) & 1u ) != 1u ) {
#endif
		make_face_quad_4_side( u2, d2, d0, u0, ivec4( 2, 2, 0, 0 ), false, view_normal, (((bits_onfeat >> 2u) & 1u) == 1u), brcs_def ); // side
#if defined(SHADER_EXTRA_ELEMENTS)
	}
#endif
}
#endif

#if defined(SHADER_TRIA3) && (defined(SHADER_TWO_SIDE) || defined(SHADER_FRINGE_BOTTOM))
void output_tria3_thick_two_side(vec3 view_normal)
{
	vec4 u0, u1, u2; // view pos
	vec4 m0, m1, m2; // view pos
	vec4 d0, d1, d2; // view pos

	int prim_id = get_prim_id();
	uint bits_onfeat = get_thickness_onfeature(prim_id);

#if !defined(SHADER_SMOOTH_NORMALS)
	#if defined(SHADER_THICK_SHELLS_GET_NODAL_THICKNESS)
		#if defined(SHADER_USE_NODAL_NORMALS)
		#else // SHADER_USE_NODAL_NORMALS_3F
		#endif
		#if !defined(SHADER_EXTRA_ELEMENTS)
		#else // defined(SHADER_EXTRA_ELEMENTS)
		#endif // end !defined(SHADER_EXTRA_ELEMENTS)
	#elif defined(SHADER_THICK_SHELLS_GET_CORNER_THICKNESS)
		#if !defined(SHADER_EXTRA_ELEMENTS)
			float f0, f1, f2;

			vec3 object_normal = get_prim_flat_normal();
			vec4 corner_values = texelFetch(elem_thickness_values, prim_id);
			#if defined(SHADER_THICK_SHELLS_Z_OFFSET)
			float zoffset = texelFetch(elem_thickness_z_offset, prim_id).r;
			#else
			float zoffset = 0.0;
			#endif
			
			f0 = corner_values.r * globals.thick_shells_scale.r * 0.5;
			f1 = corner_values.g * globals.thick_shells_scale.r * 0.5;
			f2 = corner_values.b * globals.thick_shells_scale.r * 0.5;

			u0 = explode( gs_in[0].object_pos, object_normal, zoffset+f0 );
			u1 = explode( gs_in[1].object_pos, object_normal, zoffset+f1 );
			u2 = explode( gs_in[2].object_pos, object_normal, zoffset+f2 );
			m0 = explode( gs_in[0].object_pos, object_normal, zoffset );
			m1 = explode( gs_in[1].object_pos, object_normal, zoffset );
			m2 = explode( gs_in[2].object_pos, object_normal, zoffset );
			d0 = explode( gs_in[0].object_pos, object_normal, zoffset-f0 );
			d1 = explode( gs_in[1].object_pos, object_normal, zoffset-f1 );
			d2 = explode( gs_in[2].object_pos, object_normal, zoffset-f2 );
		#else // defined(SHADER_EXTRA_ELEMENTS)
		#endif // end !defined(SHADER_EXTRA_ELEMENTS)
	#else // CENTROID THICKNESS
		vec3 object_normal = get_prim_flat_normal();

		vec2 thickness_factors = get_thickness_factors( prim_id );
		
		u0 = explode( gs_in[0].object_pos, object_normal, thickness_factors.x );
		u1 = explode( gs_in[1].object_pos, object_normal, thickness_factors.x );
		u2 = explode( gs_in[2].object_pos, object_normal, thickness_factors.x );
		float mid_fact = (thickness_factors.x + thickness_factors.y ) * 0.5;
		m0 = explode( gs_in[0].object_pos, object_normal, mid_fact );
		m1 = explode( gs_in[1].object_pos, object_normal, mid_fact );
		m2 = explode( gs_in[2].object_pos, object_normal, mid_fact );
		d0 = explode( gs_in[0].object_pos, object_normal, thickness_factors.y );
		d1 = explode( gs_in[1].object_pos, object_normal, thickness_factors.y );
		d2 = explode( gs_in[2].object_pos, object_normal, thickness_factors.y );
	#endif
#else // SHADER_SMOOTH_NORMALS
	#if defined(SHADER_THICK_SHELLS_GET_NODAL_THICKNESS)
		#if defined(SHADER_NEED_FOR_PRIMDATA)
		#endif
	#else
	#endif
#endif // END SHADER_SMOOTH_NORMALS

	make_face_tria_3( u0, u1, u2, ivec3( 0, 1, 2 ) ); // top
	make_face_tria_3( d0, d1, d2, ivec3( 0, 1, 2 ) ); // bottom
	
	vec2 brcs_def[4] = { vec2( 0.0, 0.0 ), vec2( 0.0, 1.0 ), vec2( 0.0, 0.0 ), vec2( 1.0, 0.0 ) };

#if !(defined(SHADER_FRINGE_NODE) || defined(SHADER_FRINGE_CORNER))
	make_face_quad_4_side( u0, m0, m1, u1, ivec4( 0, 0, 1, 1 ), true, view_normal, (((bits_onfeat >> 0u) & 1u) == 1u), brcs_def ); // side
	make_face_quad_4_side( u1, m1, m2, u2, ivec4( 1, 1, 2, 2 ), true, view_normal, (((bits_onfeat >> 1u) & 1u) == 1u), brcs_def ); // side
	make_face_quad_4_side( u2, m2, m0, u0, ivec4( 2, 2, 0, 0 ), true, view_normal, (((bits_onfeat >> 2u) & 1u) == 1u), brcs_def ); // side

	make_face_quad_4_side( d0, m0, m1, d1, ivec4( 0, 0, 1, 1 ), true, view_normal, (((bits_onfeat >> 0u) & 1u) == 1u), brcs_def ); // side
	make_face_quad_4_side( d1, m1, m2, d2, ivec4( 1, 1, 2, 2 ), true, view_normal, (((bits_onfeat >> 1u) & 1u) == 1u), brcs_def ); // side
	make_face_quad_4_side( d2, m2, m0, d0, ivec4( 2, 2, 0, 0 ), true, view_normal, (((bits_onfeat >> 2u) & 1u) == 1u), brcs_def ); // side
#else
	make_face_quad_4_side_top_bottom_node( u0, m0, m1, u1, ivec4( 0, 0, 1, 1 ), bvec4( false, true, true, false ), true, view_normal, (((bits_onfeat >> 0u) & 1u) == 1u), brcs_def ); // side
	make_face_quad_4_side_top_bottom_node( u1, m1, m2, u2, ivec4( 1, 1, 2, 2 ), bvec4( false, true, true, false ), true, view_normal, (((bits_onfeat >> 1u) & 1u) == 1u), brcs_def ); // side
	make_face_quad_4_side_top_bottom_node( u2, m2, m0, u0, ivec4( 2, 2, 0, 0 ), bvec4( false, true, true, false ), true, view_normal, (((bits_onfeat >> 2u) & 1u) == 1u), brcs_def ); // side

	make_face_quad_4_side_top_bottom_node( d0, m0, m1, d1, ivec4( 0, 0, 1, 1 ), bvec4( false, true, true, false ), true, view_normal, (((bits_onfeat >> 0u) & 1u) == 1u), brcs_def ); // side
	make_face_quad_4_side_top_bottom_node( d1, m1, m2, d2, ivec4( 1, 1, 2, 2 ), bvec4( false, true, true, false ), true, view_normal, (((bits_onfeat >> 1u) & 1u) == 1u), brcs_def ); // side
	make_face_quad_4_side_top_bottom_node( d2, m2, m0, d0, ivec4( 2, 2, 0, 0 ), bvec4( false, true, true, false ), true, view_normal, (((bits_onfeat >> 2u) & 1u) == 1u), brcs_def ); // side
#endif
}
#endif

#if defined(SHADER_TRIA6) && !defined(SHADER_TWO_SIDE)
void output_tria6_thick(vec3 view_normal)
{
	vec4 u0, u1, u2, u3, u4, u5;
	vec4 d0, d1, d2, d3, d4, d5;

	int prim_id = get_prim_id();
	uint bits_onfeat = get_thickness_onfeature(prim_id);

#if !defined(SHADER_SMOOTH_NORMALS)
	#if defined(SHADER_THICK_SHELLS_GET_NODAL_THICKNESS)
		#if defined(SHADER_USE_NODAL_NORMALS)
		#else // SHADER_USE_NODAL_NORMALS_3F
		#endif
		#if !defined(SHADER_EXTRA_ELEMENTS)
		#else // defined(SHADER_EXTRA_ELEMENTS)
		#endif // end !defined(SHADER_EXTRA_ELEMENTS)
	#elif defined(SHADER_THICK_SHELLS_GET_CORNER_THICKNESS)
		#if !defined(SHADER_EXTRA_ELEMENTS)
			float f0, f1, f2;

			vec3 object_normal = get_prim_flat_normal();
			vec4 corner_values = texelFetch(elem_thickness_values, prim_id);
			#if defined(SHADER_THICK_SHELLS_Z_OFFSET)
			float zoffset = texelFetch(elem_thickness_z_offset, prim_id).r;
			#else
			float zoffset = 0.0;
			#endif
		
			f0 = corner_values.r * globals.thick_shells_scale.r * 0.5;
			f1 = corner_values.g * globals.thick_shells_scale.r * 0.5;
			f2 = corner_values.b * globals.thick_shells_scale.r * 0.5;

			u0 = explode( gs_in[0].object_pos, object_normal, zoffset+f0          );
			u1 = explode( gs_in[1].object_pos, object_normal, zoffset+f1          );
			u2 = explode( gs_in[2].object_pos, object_normal, zoffset+f2          );
			u3 = explode( gs_in[3].object_pos, object_normal, zoffset+(f0+f1)*0.5 );
			u4 = explode( gs_in[4].object_pos, object_normal, zoffset+(f1+f2)*0.5 );
			u5 = explode( gs_in[5].object_pos, object_normal, zoffset+(f0+f2)*0.5 );

			d0 = explode( gs_in[0].object_pos, object_normal, zoffset-f0          );
			d1 = explode( gs_in[1].object_pos, object_normal, zoffset-f1          );
			d2 = explode( gs_in[2].object_pos, object_normal, zoffset-f2          );
			d3 = explode( gs_in[3].object_pos, object_normal, zoffset-(f0+f1)*0.5 );
			d4 = explode( gs_in[4].object_pos, object_normal, zoffset-(f1+f2)*0.5 );
			d5 = explode( gs_in[5].object_pos, object_normal, zoffset-(f0+f2)*0.5 );
		#else // defined(SHADER_EXTRA_ELEMENTS)
		#endif // end !defined(SHADER_EXTRA_ELEMENTS)
	#else // CENTROID THICKNESS
		vec3 object_normal = get_prim_flat_normal();

		vec2 thickness_factors = get_thickness_factors( prim_id );

		u0 = explode( gs_in[0].object_pos, object_normal, thickness_factors.x );
		u1 = explode( gs_in[1].object_pos, object_normal, thickness_factors.x );
		u2 = explode( gs_in[2].object_pos, object_normal, thickness_factors.x );
		u3 = explode( gs_in[3].object_pos, object_normal, thickness_factors.x );
		u4 = explode( gs_in[4].object_pos, object_normal, thickness_factors.x );
		u5 = explode( gs_in[5].object_pos, object_normal, thickness_factors.x );

		d0 = explode( gs_in[0].object_pos, object_normal, thickness_factors.y );
		d1 = explode( gs_in[1].object_pos, object_normal, thickness_factors.y );
		d2 = explode( gs_in[2].object_pos, object_normal, thickness_factors.y );
		d3 = explode( gs_in[3].object_pos, object_normal, thickness_factors.y );
		d4 = explode( gs_in[4].object_pos, object_normal, thickness_factors.y );
		d5 = explode( gs_in[5].object_pos, object_normal, thickness_factors.y );
	#endif
#else // SHADER_SMOOTH_NORMALS
	#if defined(SHADER_THICK_SHELLS_GET_NODAL_THICKNESS)
		#if defined(SHADER_NEED_FOR_PRIMDATA)
		#endif
	#else
	#endif
#endif // END SHADER_SMOOTH_NORMALS

	int ids[6] = { 0, 1, 2, 3, 4, 5 };
	make_face_tria_6( u0, u1, u2, u3, u4, u5, ids ); // top
	make_face_tria_6( d0, d1, d2, d3, d4, d5, ids ); // bottom
	
	int ids_side_01[6] = { 0, 0, 3, 3, 1, 1 };
	make_face_quad_6_side( u0, d0, u3, d3, u1, d1, ids_side_01, view_normal, (((bits_onfeat >> 0u) & 1u) == 1u) ); // side
	int ids_side_02[6] = { 1, 1, 4, 4, 2, 2 };
	make_face_quad_6_side( u1, d1, u4, d4, u2, d2, ids_side_02, view_normal, (((bits_onfeat >> 1u) & 1u) == 1u) ); // side
	int ids_side_03[6] = { 2, 2, 5, 5, 0, 0 };
	make_face_quad_6_side( u2, d2, u5, d5, u0, d0, ids_side_03, view_normal, (((bits_onfeat >> 2u) & 1u) == 1u) ); // side
}
#endif

#if defined(SHADER_TRIA6) && (defined(SHADER_TWO_SIDE) || defined(SHADER_FRINGE_BOTTOM))
void output_tria6_thick_two_side(vec3 view_normal)
{
	vec4 u0, u1, u2, u3, u4, u5;
	vec4 m0, m1, m2, m3, m4, m5;
	vec4 d0, d1, d2, d3, d4, d5;

	int prim_id = get_prim_id();
	uint bits_onfeat = get_thickness_onfeature(prim_id);

#if !defined(SHADER_SMOOTH_NORMALS)
	#if defined(SHADER_THICK_SHELLS_GET_NODAL_THICKNESS)
		#if defined(SHADER_USE_NODAL_NORMALS)
		#else // SHADER_USE_NODAL_NORMALS_3F
		#endif
		#if !defined(SHADER_EXTRA_ELEMENTS)
		#else // defined(SHADER_EXTRA_ELEMENTS)
		#endif // end !defined(SHADER_EXTRA_ELEMENTS)
	#elif defined(SHADER_THICK_SHELLS_GET_CORNER_THICKNESS)
		#if !defined(SHADER_EXTRA_ELEMENTS)
			float f0, f1, f2;

			vec3 object_normal = get_prim_flat_normal();
			vec4 corner_values = texelFetch(elem_thickness_values, prim_id);
			#if defined(SHADER_THICK_SHELLS_Z_OFFSET)
			float zoffset = texelFetch(elem_thickness_z_offset, prim_id).r;
			#else
			float zoffset = 0.0;
			#endif
			
			f0 = corner_values.r * globals.thick_shells_scale.r * 0.5;
			f1 = corner_values.g * globals.thick_shells_scale.r * 0.5;
			f2 = corner_values.b * globals.thick_shells_scale.r * 0.5;

			u0 = explode( gs_in[0].object_pos, object_normal, zoffset+f0          );
			u1 = explode( gs_in[1].object_pos, object_normal, zoffset+f1          );
			u2 = explode( gs_in[2].object_pos, object_normal, zoffset+f2          );
			u3 = explode( gs_in[3].object_pos, object_normal, zoffset+(f0+f1)*0.5 );
			u4 = explode( gs_in[4].object_pos, object_normal, zoffset+(f1+f2)*0.5 );
			u5 = explode( gs_in[5].object_pos, object_normal, zoffset+(f0+f2)*0.5 );
			m0 = explode( gs_in[0].object_pos, object_normal, zoffset );
			m1 = explode( gs_in[1].object_pos, object_normal, zoffset );
			m2 = explode( gs_in[2].object_pos, object_normal, zoffset );
			m3 = explode( gs_in[3].object_pos, object_normal, zoffset );
			m4 = explode( gs_in[4].object_pos, object_normal, zoffset );
			m5 = explode( gs_in[5].object_pos, object_normal, zoffset );
			d0 = explode( gs_in[0].object_pos, object_normal, zoffset-f0          );
			d1 = explode( gs_in[1].object_pos, object_normal, zoffset-f1          );
			d2 = explode( gs_in[2].object_pos, object_normal, zoffset-f2          );
			d3 = explode( gs_in[3].object_pos, object_normal, zoffset-(f0+f1)*0.5 );
			d4 = explode( gs_in[4].object_pos, object_normal, zoffset-(f1+f2)*0.5 );
			d5 = explode( gs_in[5].object_pos, object_normal, zoffset-(f0+f2)*0.5 );
		#else // defined(SHADER_EXTRA_ELEMENTS)
		#endif // end !defined(SHADER_EXTRA_ELEMENTS)
	#else // CENTROID THICKNESS
		vec3 object_normal = get_prim_flat_normal();

		vec2 thickness_factors = get_thickness_factors( prim_id );
		
		u0 = explode( gs_in[0].object_pos, object_normal, thickness_factors.x );
		u1 = explode( gs_in[1].object_pos, object_normal, thickness_factors.x );
		u2 = explode( gs_in[2].object_pos, object_normal, thickness_factors.x );
		u3 = explode( gs_in[3].object_pos, object_normal, thickness_factors.x );
		u4 = explode( gs_in[4].object_pos, object_normal, thickness_factors.x );
		u5 = explode( gs_in[5].object_pos, object_normal, thickness_factors.x );
		float mid_fact = (thickness_factors.x + thickness_factors.y ) * 0.5;
		m0 = explode( gs_in[0].object_pos, object_normal, mid_fact );
		m1 = explode( gs_in[1].object_pos, object_normal, mid_fact );
		m2 = explode( gs_in[2].object_pos, object_normal, mid_fact );
		m3 = explode( gs_in[3].object_pos, object_normal, mid_fact );
		m4 = explode( gs_in[4].object_pos, object_normal, mid_fact );
		m5 = explode( gs_in[5].object_pos, object_normal, mid_fact );
		d0 = explode( gs_in[0].object_pos, object_normal, thickness_factors.y );
		d1 = explode( gs_in[1].object_pos, object_normal, thickness_factors.y );
		d2 = explode( gs_in[2].object_pos, object_normal, thickness_factors.y );
		d3 = explode( gs_in[3].object_pos, object_normal, thickness_factors.y );
		d4 = explode( gs_in[4].object_pos, object_normal, thickness_factors.y );
		d5 = explode( gs_in[5].object_pos, object_normal, thickness_factors.y );
	#endif
#else // SHADER_SMOOTH_NORMALS
	#if defined(SHADER_THICK_SHELLS_GET_NODAL_THICKNESS)
		#if defined(SHADER_NEED_FOR_PRIMDATA)
		#endif
	#else
	#endif
#endif // END SHADER_SMOOTH_NORMALS

	int ids[6] = { 0, 1, 2, 3, 4, 5 };
	make_face_tria_6( u0, u1, u2, u3, u4, u5, ids ); // top
	make_face_tria_6( d0, d1, d2, d3, d4, d5, ids ); // bottom

#if !(defined(SHADER_FRINGE_NODE) || defined(SHADER_FRINGE_CORNER))
	int ids_side_01[6] = { 0, 0, 3, 3, 1, 1 };
	make_face_quad_6_side( u0, m0, u3, m3, u1, m1, ids_side_01, view_normal, (((bits_onfeat >> 0u) & 1u) == 1u) ); // side
	int ids_side_02[6] = { 1, 1, 4, 4, 2, 2 };
	make_face_quad_6_side( u1, m1, u4, m4, u2, m2, ids_side_02, view_normal, (((bits_onfeat >> 1u) & 1u) == 1u) ); // side
	int ids_side_03[6] = { 2, 2, 5, 5, 0, 0 };
	make_face_quad_6_side( u2, m2, u5, m5, u0, m0, ids_side_03, view_normal, (((bits_onfeat >> 2u) & 1u) == 1u) ); // side

	int ids_side_04[6] = { 0, 0, 3, 3, 1, 1 };
	make_face_quad_6_side( d0, m0, d3, m3, d1, m1, ids_side_04, view_normal, (((bits_onfeat >> 0u) & 1u) == 1u) ); // side
	int ids_side_05[6] = { 1, 1, 4, 4, 2, 2 };
	make_face_quad_6_side( d1, m1, d4, m4, d2, m2, ids_side_05, view_normal, (((bits_onfeat >> 1u) & 1u) == 1u) ); // side
	int ids_side_06[6] = { 2, 2, 5, 5, 0, 0 };
	make_face_quad_6_side( d2, m2, d5, m5, d0, m0, ids_side_06, view_normal, (((bits_onfeat >> 2u) & 1u) == 1u) ); // side
#else
	int ids_side_01[6] = { 0, 0, 3, 3, 1, 1 };
	bool middle_values_01[6] = { false, true, false, true, false, true };
	make_face_quad_6_side_top_bottom_node( u0, m0, u3, m3, u1, m1, ids_side_01, middle_values_01, view_normal, (((bits_onfeat >> 0u) & 1u) == 1u) ); // side
	int ids_side_02[6] = { 1, 1, 4, 4, 2, 2 };
	make_face_quad_6_side_top_bottom_node( u1, m1, u4, m4, u2, m2, ids_side_02, middle_values_01, view_normal, (((bits_onfeat >> 1u) & 1u) == 1u) ); // side
	int ids_side_03[6] = { 2, 2, 5, 5, 0, 0 };
	make_face_quad_6_side_top_bottom_node( u2, m2, u5, m5, u0, m0, ids_side_03, middle_values_01, view_normal, (((bits_onfeat >> 2u) & 1u) == 1u) ); // side

	int ids_side_04[6] = { 0, 0, 3, 3, 1, 1 };
	make_face_quad_6_side_top_bottom_node( d0, m0, d3, m3, d1, m1, ids_side_04, middle_values_01, view_normal, (((bits_onfeat >> 0u) & 1u) == 1u) ); // side
	int ids_side_05[6] = { 1, 1, 4, 4, 2, 2 };
	make_face_quad_6_side_top_bottom_node( d1, m1, d4, m4, d2, m2, ids_side_05, middle_values_01, view_normal, (((bits_onfeat >> 1u) & 1u) == 1u) ); // side
	int ids_side_06[6] = { 2, 2, 5, 5, 0, 0 };
	make_face_quad_6_side_top_bottom_node( d2, m2, d5, m5, d0, m0, ids_side_06, middle_values_01, view_normal, (((bits_onfeat >> 2u) & 1u) == 1u) ); // side
#endif
}
#endif

#if defined(SHADER_QUAD4) && !defined(SHADER_TWO_SIDE)
void output_quad4_thick(vec3 view_normal)
{
	vec4 u0, u1, u2, u3, d0, d1, d2, d3;

	int prim_id = get_prim_id();
	uint bits_onfeat = get_thickness_onfeature(prim_id);

#if !defined(SHADER_SMOOTH_NORMALS)
#if defined(SHADER_THICK_SHELLS_GET_NODAL_THICKNESS)
	float f0, f1, f2, f3;
	vec3 n0, n1, n2, n3;

	vec3 object_normal = get_prim_flat_normal();

	#if defined(SHADER_USE_NODAL_NORMALS)
		n0 = uncompress_normal( gs_in[0].nodal_normals );
		n1 = uncompress_normal( gs_in[1].nodal_normals );
		n2 = uncompress_normal( gs_in[2].nodal_normals );
		n3 = uncompress_normal( gs_in[3].nodal_normals );
	#else // SHADER_USE_NODAL_NORMALS_3F
		n0 = gs_in[0].nodal_normals;
		n1 = gs_in[1].nodal_normals;
		n2 = gs_in[2].nodal_normals;
		n3 = gs_in[3].nodal_normals;
	#endif

	n0 = ( ((bits_onfeat >> 4u) & 1u) == 1u ) ? object_normal : n0;
	n1 = ( ((bits_onfeat >> 5u) & 1u) == 1u ) ? object_normal : n1;
	n2 = ( ((bits_onfeat >> 6u) & 1u) == 1u ) ? object_normal : n2;
	n3 = ( ((bits_onfeat >> 7u) & 1u) == 1u ) ? object_normal : n3;

	f0 = gs_in[0].nodal_thickness * globals.thick_shells_scale.r * 0.5;
	f1 = gs_in[1].nodal_thickness * globals.thick_shells_scale.r * 0.5;
	f3 = gs_in[3].nodal_thickness * globals.thick_shells_scale.r * 0.5;
	f2 = gs_in[2].nodal_thickness * globals.thick_shells_scale.r * 0.5;

	u0 = explode( gs_in[0].object_pos, n0,  f0 );
	u1 = explode( gs_in[1].object_pos, n1,  f1 );
	u3 = explode( gs_in[3].object_pos, n3,  f3 );
	u2 = explode( gs_in[2].object_pos, n2,  f2 );

	d0 = explode( gs_in[0].object_pos, n0, -f0 );
	d1 = explode( gs_in[1].object_pos, n1, -f1 );
	d3 = explode( gs_in[3].object_pos, n3, -f3 );
	d2 = explode( gs_in[2].object_pos, n2, -f2 );
#elif defined(SHADER_THICK_SHELLS_GET_CORNER_THICKNESS)
	float f0, f1, f2, f3;

	vec3 object_normal = get_prim_flat_normal();
	vec4 corner_values = texelFetch(elem_thickness_values, prim_id);
	#if defined(SHADER_THICK_SHELLS_Z_OFFSET)
	float zoffset = texelFetch(elem_thickness_z_offset, prim_id).r;
	#else
	float zoffset = 0.0;
	#endif

	f0 = corner_values.r * globals.thick_shells_scale.r * 0.5;
	f1 = corner_values.g * globals.thick_shells_scale.r * 0.5;
	f3 = corner_values.a * globals.thick_shells_scale.r * 0.5;
	f2 = corner_values.b * globals.thick_shells_scale.r * 0.5;

	u0 = explode( gs_in[0].object_pos, object_normal, zoffset+f0 );
	u1 = explode( gs_in[1].object_pos, object_normal, zoffset+f1 );
	u3 = explode( gs_in[3].object_pos, object_normal, zoffset+f3 );
	u2 = explode( gs_in[2].object_pos, object_normal, zoffset+f2 );

	d0 = explode( gs_in[0].object_pos, object_normal, zoffset-f0 );
	d1 = explode( gs_in[1].object_pos, object_normal, zoffset-f1 );
	d3 = explode( gs_in[3].object_pos, object_normal, zoffset-f3 );
	d2 = explode( gs_in[2].object_pos, object_normal, zoffset-f2 );
#else // CENTROID THICKNESS
	vec3 object_normal = get_prim_flat_normal();
	vec2 thickness_factors = get_thickness_factors( prim_id );
	u0 = explode( gs_in[0].object_pos, object_normal, thickness_factors.x );
	u1 = explode( gs_in[1].object_pos, object_normal, thickness_factors.x );
	u3 = explode( gs_in[3].object_pos, object_normal, thickness_factors.x );
	u2 = explode( gs_in[2].object_pos, object_normal, thickness_factors.x );

	d0 = explode( gs_in[0].object_pos, object_normal, thickness_factors.y );
	d1 = explode( gs_in[1].object_pos, object_normal, thickness_factors.y );
	d3 = explode( gs_in[3].object_pos, object_normal, thickness_factors.y );
	d2 = explode( gs_in[2].object_pos, object_normal, thickness_factors.y );
#endif
#else // SHADER_SMOOTH_NORMALS
#if defined(SHADER_THICK_SHELLS_GET_NODAL_THICKNESS)
	#if defined(SHADER_NEED_FOR_PRIMDATA)
		PrimData primDat = get_prim_data(prim_id);
	#endif
	u0 = explode( gs_in[0].object_pos, normalize( (globals.iview_matrix * vec4( orient_view_normal( primDat.smooth_normals[0]), 0.0 )).xyz ), gs_in[0].nodal_thickness * globals.thick_shells_scale.r * 0.5 );
	u1 = explode( gs_in[1].object_pos, normalize( (globals.iview_matrix * vec4( orient_view_normal( primDat.smooth_normals[1]), 0.0 )).xyz ), gs_in[1].nodal_thickness * globals.thick_shells_scale.r * 0.5 );
	u3 = explode( gs_in[3].object_pos, normalize( (globals.iview_matrix * vec4( orient_view_normal( primDat.smooth_normals[3]), 0.0 )).xyz ), gs_in[3].nodal_thickness * globals.thick_shells_scale.r * 0.5 );
	u2 = explode( gs_in[2].object_pos, normalize( (globals.iview_matrix * vec4( orient_view_normal( primDat.smooth_normals[2]), 0.0 )).xyz ), gs_in[2].nodal_thickness * globals.thick_shells_scale.r * 0.5 );

	d0 = explode( gs_in[0].object_pos, normalize( (globals.iview_matrix * vec4( orient_view_normal( primDat.smooth_normals[0]), 0.0 )).xyz ), -gs_in[0].nodal_thickness * globals.thick_shells_scale.r * 0.5 );
	d1 = explode( gs_in[1].object_pos, normalize( (globals.iview_matrix * vec4( orient_view_normal( primDat.smooth_normals[1]), 0.0 )).xyz ), -gs_in[1].nodal_thickness * globals.thick_shells_scale.r * 0.5 );
	d3 = explode( gs_in[3].object_pos, normalize( (globals.iview_matrix * vec4( orient_view_normal( primDat.smooth_normals[3]), 0.0 )).xyz ), -gs_in[3].nodal_thickness * globals.thick_shells_scale.r * 0.5 );
	d2 = explode( gs_in[2].object_pos, normalize( (globals.iview_matrix * vec4( orient_view_normal( primDat.smooth_normals[2]), 0.0 )).xyz ), -gs_in[2].nodal_thickness * globals.thick_shells_scale.r * 0.5 );
#else
	vec3 object_normal = get_prim_flat_normal();
	vec2 thickness_factors = get_thickness_factors( prim_id );
	u0 = explode( gs_in[0].object_pos, object_normal, thickness_factors.x );
	u1 = explode( gs_in[1].object_pos, object_normal, thickness_factors.x );
	u3 = explode( gs_in[3].object_pos, object_normal, thickness_factors.x );
	u2 = explode( gs_in[2].object_pos, object_normal, thickness_factors.x );

	d0 = explode( gs_in[0].object_pos, object_normal, thickness_factors.y );
	d1 = explode( gs_in[1].object_pos, object_normal, thickness_factors.y );
	d3 = explode( gs_in[3].object_pos, object_normal, thickness_factors.y );
	d2 = explode( gs_in[2].object_pos, object_normal, thickness_factors.y );
#endif
#endif // END SHADER_SMOOTH_NORMALS

	make_face_quad_4( u0, u1, u2, u3, ivec4( 0, 1, 2, 3 ), false ); // top
	make_face_quad_4( d0, d1, d2, d3, ivec4( 0, 1, 2, 3 ), false ); // bottom
	
	vec2 brcs_def[4] = { vec2( 0.0, 0.0 ), vec2( 0.0, 1.0 ), vec2( 0.0, 0.0 ), vec2( 1.0, 0.0 ) };

	make_face_quad_4_side( u0, d0, d1, u1, ivec4( 0, 0, 1, 1 ), false, view_normal, (((bits_onfeat >> 0u) & 1u) == 1u ), brcs_def ); // side
	make_face_quad_4_side( u1, d1, d2, u2, ivec4( 1, 1, 2, 2 ), false, view_normal, (((bits_onfeat >> 1u) & 1u) == 1u ), brcs_def ); // side
	make_face_quad_4_side( u2, d2, d3, u3, ivec4( 2, 2, 3, 3 ), false, view_normal, (((bits_onfeat >> 2u) & 1u) == 1u ), brcs_def ); // side
	make_face_quad_4_side( u3, d3, d0, u0, ivec4( 3, 3, 0, 0 ), false, view_normal, (((bits_onfeat >> 3u) & 1u) == 1u ), brcs_def ); // side
}
#endif

#if defined(SHADER_QUAD4) && (defined(SHADER_TWO_SIDE) || defined(SHADER_FRINGE_BOTTOM))
void output_quad4_thick_two_side(vec3 view_normal)
{
	vec4 u0, u1, u2, u3;
	vec4 m0, m1, m2, m3;
	vec4 d0, d1, d2, d3;

	int prim_id = get_prim_id();
	uint bits_onfeat = get_thickness_onfeature(prim_id);

#if !defined(SHADER_SMOOTH_NORMALS)
	#if defined(SHADER_THICK_SHELLS_GET_NODAL_THICKNESS)
		#if defined(SHADER_USE_NODAL_NORMALS)
		#else // SHADER_USE_NODAL_NORMALS_3F
		#endif
		#if !defined(SHADER_EXTRA_ELEMENTS)
		#else // defined(SHADER_EXTRA_ELEMENTS)
		#endif // end !defined(SHADER_EXTRA_ELEMENTS)
	#elif defined(SHADER_THICK_SHELLS_GET_CORNER_THICKNESS)
		#if !defined(SHADER_EXTRA_ELEMENTS)
			float f0, f1, f2, f3;

			vec3 object_normal = get_prim_flat_normal();

			vec4 corner_values = texelFetch(elem_thickness_values, prim_id);
			#if defined(SHADER_THICK_SHELLS_Z_OFFSET)
			float zoffset = texelFetch(elem_thickness_z_offset, prim_id).r;
			#else
			float zoffset = 0.0;
			#endif

			f0 = corner_values.r * globals.thick_shells_scale.r * 0.5;
			f1 = corner_values.g * globals.thick_shells_scale.r * 0.5;
			f3 = corner_values.a * globals.thick_shells_scale.r * 0.5;
			f2 = corner_values.b * globals.thick_shells_scale.r * 0.5;

			u0 = explode( gs_in[0].object_pos, object_normal, zoffset+f0 );
			u1 = explode( gs_in[1].object_pos, object_normal, zoffset+f1 );
			u3 = explode( gs_in[3].object_pos, object_normal, zoffset+f3 );
			u2 = explode( gs_in[2].object_pos, object_normal, zoffset+f2 );
			m0 = explode( gs_in[0].object_pos, object_normal, zoffset );
			m1 = explode( gs_in[1].object_pos, object_normal, zoffset );
			m2 = explode( gs_in[2].object_pos, object_normal, zoffset );
			m3 = explode( gs_in[3].object_pos, object_normal, zoffset );
			d0 = explode( gs_in[0].object_pos, object_normal, zoffset-f0 );
			d1 = explode( gs_in[1].object_pos, object_normal, zoffset-f1 );
			d3 = explode( gs_in[3].object_pos, object_normal, zoffset-f3 );
			d2 = explode( gs_in[2].object_pos, object_normal, zoffset-f2 );
		#else // defined(SHADER_EXTRA_ELEMENTS)
		#endif // end !defined(SHADER_EXTRA_ELEMENTS)
	#else // CENTROID THICKNESS
		vec3 object_normal = get_prim_flat_normal();

		vec2 thickness_factors = get_thickness_factors( prim_id );
		
		u0 = explode( gs_in[0].object_pos, object_normal, thickness_factors.x );
		u1 = explode( gs_in[1].object_pos, object_normal, thickness_factors.x );
		u3 = explode( gs_in[3].object_pos, object_normal, thickness_factors.x );
		u2 = explode( gs_in[2].object_pos, object_normal, thickness_factors.x );
		float mid_fact = (thickness_factors.x + thickness_factors.y ) * 0.5;
		m0 = explode( gs_in[0].object_pos, object_normal, mid_fact );
		m1 = explode( gs_in[1].object_pos, object_normal, mid_fact );
		m2 = explode( gs_in[2].object_pos, object_normal, mid_fact );
		m3 = explode( gs_in[3].object_pos, object_normal, mid_fact );
		d0 = explode( gs_in[0].object_pos, object_normal, thickness_factors.y );
		d1 = explode( gs_in[1].object_pos, object_normal, thickness_factors.y );
		d3 = explode( gs_in[3].object_pos, object_normal, thickness_factors.y );
		d2 = explode( gs_in[2].object_pos, object_normal, thickness_factors.y );
	#endif
#else // SHADER_SMOOTH_NORMALS
	#if defined(SHADER_THICK_SHELLS_GET_NODAL_THICKNESS)
		#if defined(SHADER_NEED_FOR_PRIMDATA)
		#endif
	#else
	#endif
#endif // END SHADER_SMOOTH_NORMALS

	make_face_quad_4( u0, u1, u2, u3, ivec4( 0, 1, 2, 3 ), false ); // top
	make_face_quad_4( d0, d1, d2, d3, ivec4( 0, 1, 2, 3 ), false ); // bottom
	
	vec2 brcs_def[4] = { vec2( 0.0, 0.0 ), vec2( 0.0, 1.0 ), vec2( 0.0, 0.0 ), vec2( 1.0, 0.0 ) };
	
#if !(defined(SHADER_FRINGE_NODE) || defined(SHADER_FRINGE_CORNER))
	make_face_quad_4_side( u0, m0, m1, u1, ivec4( 0, 0, 1, 1 ), true, view_normal, (((bits_onfeat >> 0u) & 1u) == 1u ), brcs_def ); // side
	make_face_quad_4_side( u1, m1, m2, u2, ivec4( 1, 1, 2, 2 ), true, view_normal, (((bits_onfeat >> 1u) & 1u) == 1u ), brcs_def ); // side
	make_face_quad_4_side( u2, m2, m3, u3, ivec4( 2, 2, 3, 3 ), true, view_normal, (((bits_onfeat >> 2u) & 1u) == 1u ), brcs_def ); // side
	make_face_quad_4_side( u3, m3, m0, u0, ivec4( 3, 3, 0, 0 ), true, view_normal, (((bits_onfeat >> 3u) & 1u) == 1u ), brcs_def ); // side	

	make_face_quad_4_side( d0, m0, m1, d1, ivec4( 0, 0, 1, 1 ), true, view_normal, (((bits_onfeat >> 0u) & 1u) == 1u ), brcs_def ); // side
	make_face_quad_4_side( d1, m1, m2, d2, ivec4( 1, 1, 2, 2 ), true, view_normal, (((bits_onfeat >> 1u) & 1u) == 1u ), brcs_def ); // side
	make_face_quad_4_side( d2, m2, m3, d3, ivec4( 2, 2, 3, 3 ), true, view_normal, (((bits_onfeat >> 2u) & 1u) == 1u ), brcs_def ); // side
	make_face_quad_4_side( d3, m3, m0, d0, ivec4( 3, 3, 0, 0 ), true, view_normal, (((bits_onfeat >> 3u) & 1u) == 1u ), brcs_def ); // side
#else
	make_face_quad_4_side_top_bottom_node( u0, m0, m1, u1, ivec4( 0, 0, 1, 1 ), bvec4( false, true, true, false ), true, view_normal, (((bits_onfeat >> 0u) & 1u) == 1u ), brcs_def ); // side
	make_face_quad_4_side_top_bottom_node( u1, m1, m2, u2, ivec4( 1, 1, 2, 2 ), bvec4( false, true, true, false ), true, view_normal, (((bits_onfeat >> 1u) & 1u) == 1u ), brcs_def ); // side
	make_face_quad_4_side_top_bottom_node( u2, m2, m3, u3, ivec4( 2, 2, 3, 3 ), bvec4( false, true, true, false ), true, view_normal, (((bits_onfeat >> 2u) & 1u) == 1u ), brcs_def ); // side
	make_face_quad_4_side_top_bottom_node( u3, m3, m0, u0, ivec4( 3, 3, 0, 0 ), bvec4( false, true, true, false ), true, view_normal, (((bits_onfeat >> 3u) & 1u) == 1u ), brcs_def ); // side	

	make_face_quad_4_side_top_bottom_node( d0, m0, m1, d1, ivec4( 0, 0, 1, 1 ), bvec4( false, true, true, false ), true, view_normal, (((bits_onfeat >> 0u) & 1u) == 1u ), brcs_def ); // side
	make_face_quad_4_side_top_bottom_node( d1, m1, m2, d2, ivec4( 1, 1, 2, 2 ), bvec4( false, true, true, false ), true, view_normal, (((bits_onfeat >> 1u) & 1u) == 1u ), brcs_def ); // side
	make_face_quad_4_side_top_bottom_node( d2, m2, m3, d3, ivec4( 2, 2, 3, 3 ), bvec4( false, true, true, false ), true, view_normal, (((bits_onfeat >> 2u) & 1u) == 1u ), brcs_def ); // side
	make_face_quad_4_side_top_bottom_node( d3, m3, m0, d0, ivec4( 3, 3, 0, 0 ), bvec4( false, true, true, false ), true, view_normal, (((bits_onfeat >> 3u) & 1u) == 1u ), brcs_def ); // side
#endif
}
#endif

#if defined(SHADER_QUAD8) && !defined(SHADER_TWO_SIDE)
void output_quad8_thick(vec3 view_normal)
{
	vec4 u7, u0, u4, u1, u5, u6; 
	vec4 d7, d0, d4, d1, d5, d6;

	int prim_id = get_prim_id();
	uint bits_onfeat = get_thickness_onfeature(prim_id);

#if !defined(SHADER_SMOOTH_NORMALS)
	#if defined(SHADER_THICK_SHELLS_GET_NODAL_THICKNESS)
		#if defined(SHADER_USE_NODAL_NORMALS)
		#else // SHADER_USE_NODAL_NORMALS_3F
		#endif
	#elif defined(SHADER_THICK_SHELLS_GET_CORNER_THICKNESS)
		#if !defined(SHADER_EXTRA_ELEMENTS)
			float f0, f1, f2, f3;
			// 1 -> 5 -> 4 -> 7 -> 0 -> 6

			// 1 -> 0
			// 5 -> 1
			// 4 -> 2
			// 7 -> 3
			// 0 -> 4
			// 6 -> 5

			vec3 object_normal = get_prim_flat_normal();
			vec4 corner_values = texelFetch(elem_thickness_values, prim_id);
			#if defined(SHADER_THICK_SHELLS_Z_OFFSET)
			float zoffset = texelFetch(elem_thickness_z_offset, prim_id).r;
			#else
			float zoffset = 0.0;
			#endif

			f0 = corner_values.r * globals.thick_shells_scale.r * 0.5;
			f1 = corner_values.g * globals.thick_shells_scale.r * 0.5;
			f3 = corner_values.a * globals.thick_shells_scale.r * 0.5;
			f2 = corner_values.b * globals.thick_shells_scale.r * 0.5;

			int chunk = gl_PrimitiveIDIn % 2;
			float corner_vals[8] = float[](f0, f1, f2, f3, (f0+f1)*0.5, (f1+f2)*0.5, (f2+f3)*0.5, (f3+f0)*0.5);
			float strip_corner_factors[6];
			if (chunk == 0) {
				strip_corner_factors[0] = corner_vals[1];
				strip_corner_factors[1] = corner_vals[5];
				strip_corner_factors[2] = corner_vals[4];
				strip_corner_factors[3] = corner_vals[7];
				strip_corner_factors[4] = corner_vals[0];
				strip_corner_factors[5] = corner_vals[2];
			} else {
				strip_corner_factors[0] = corner_vals[3];
				strip_corner_factors[1] = corner_vals[7];
				strip_corner_factors[2] = corner_vals[6];
				strip_corner_factors[3] = corner_vals[5];
				strip_corner_factors[4] = corner_vals[2];
				strip_corner_factors[5] = corner_vals[0];
			}

			u1 = explode( gs_in[0].object_pos, object_normal, zoffset+strip_corner_factors[0]); 
			u5 = explode( gs_in[1].object_pos, object_normal, zoffset+strip_corner_factors[1]); 
			u4 = explode( gs_in[2].object_pos, object_normal, zoffset+strip_corner_factors[2]); 
			u7 = explode( gs_in[3].object_pos, object_normal, zoffset+strip_corner_factors[3]); 
			u0 = explode( gs_in[4].object_pos, object_normal, zoffset+strip_corner_factors[4]); 
			u6 = explode( gs_in[5].object_pos, object_normal, zoffset+strip_corner_factors[5]); 

			d1 = explode( gs_in[0].object_pos, object_normal, zoffset-strip_corner_factors[0]);
			d5 = explode( gs_in[1].object_pos, object_normal, zoffset-strip_corner_factors[1]);
			d4 = explode( gs_in[2].object_pos, object_normal, zoffset-strip_corner_factors[2]);
			d7 = explode( gs_in[3].object_pos, object_normal, zoffset-strip_corner_factors[3]);
			d0 = explode( gs_in[4].object_pos, object_normal, zoffset-strip_corner_factors[4]);
			d6 = explode( gs_in[5].object_pos, object_normal, zoffset-strip_corner_factors[5]);
		#else // defined(SHADER_EXTRA_ELEMENTS)
		#endif // end !defined(SHADER_EXTRA_ELEMENTS)
	#else // CENTROID THICKNESS
		vec3 object_normal = get_prim_flat_normal();

		// 1 -> 5 -> 4 -> 7 -> 0 -> 6

		// 1 -> 0
		// 5 -> 1
		// 4 -> 2
		// 7 -> 3
		// 0 -> 4
		// 6 -> 5

		vec2 thickness_factors = get_thickness_factors( prim_id );

		u1 = explode( gs_in[0].object_pos, object_normal, thickness_factors.x );
		u5 = explode( gs_in[1].object_pos, object_normal, thickness_factors.x );
		u4 = explode( gs_in[2].object_pos, object_normal, thickness_factors.x );
		u7 = explode( gs_in[3].object_pos, object_normal, thickness_factors.x );
		u0 = explode( gs_in[4].object_pos, object_normal, thickness_factors.x );
		u6 = explode( gs_in[5].object_pos, object_normal, thickness_factors.x );

		d1 = explode( gs_in[0].object_pos, object_normal, thickness_factors.y );
		d5 = explode( gs_in[1].object_pos, object_normal, thickness_factors.y );
		d4 = explode( gs_in[2].object_pos, object_normal, thickness_factors.y );
		d7 = explode( gs_in[3].object_pos, object_normal, thickness_factors.y );
		d0 = explode( gs_in[4].object_pos, object_normal, thickness_factors.y );
		d6 = explode( gs_in[5].object_pos, object_normal, thickness_factors.y );
	#endif
#else // SHADER_SMOOTH_NORMALS
	#if defined(SHADER_THICK_SHELLS_GET_NODAL_THICKNESS)
		#if defined(SHADER_NEED_FOR_PRIMDATA)
		#endif
	#else
	#endif
#endif // END SHADER_SMOOTH_NORMALS

	int ids[5] = { 0, 1, 2, 3, 4 };
	vec2 brcs1[5] = { vec2( 0.0, 0.0 ), vec2( 0.0, 0.5 ), vec2( 0.5, 0.0 ), vec2( 1.0, 0.5 ), vec2( 1.0, 0.0 ) };
	make_face_quad_8_half_top_or_bottom( u1, u5, u4, u7, u0, u6, ids, brcs1 ); // top half
	make_face_quad_8_half_top_or_bottom( d1, d5, d4, d7, d0, d6, ids, brcs1 ); // bottom half

	uint side1, side2;
	side1 = ( gl_PrimitiveIDIn % 2 == 0 ) ? 1u : 3u;
	side2 = ( gl_PrimitiveIDIn % 2 == 0 ) ? 3u : 1u;
	uint front_side = ( gl_PrimitiveIDIn % 2 == 0 ) ? 0u : 2u;

	vec2 brcs2[4] = { vec2( 0.0, 0.0 ), vec2( 1.0, 0.0 ), vec2( 1.0, 0.5 ), vec2( 0.0, 0.5 ) };
	make_face_quad_4_side( u1, d1, d5, u5, ivec4( 0, 0, 1, 1 ), false, view_normal, (((bits_onfeat >> side1) & 1u) == 1u ), brcs2 ); // side half
	make_face_quad_4_side( d0, u0, u7, d7, ivec4( 4, 4, 3, 3 ), false, view_normal, (((bits_onfeat >> side2) & 1u) == 1u ), brcs2 ); // side half
	int ids_side_01[6] = { 4, 4, 2, 2, 0, 0 };
	vec2 brcs3[6] = { vec2( 1.0, 1.0 ), vec2( 1.0, 0.0 ), vec2( 0.5, 1.0 ), vec2( 0.5, 0.0 ), vec2( 0.0, 1.0 ), vec2( 0.0, 0.0 ) };
	make_face_quad_8_front_side( u0, d0, u4, d4, u1, d1, ids_side_01, view_normal, (((bits_onfeat >> front_side) & 1u) == 1u ), brcs3 ); // side front
}
#endif

#if defined(SHADER_QUAD8) && (defined(SHADER_TWO_SIDE) || defined(SHADER_FRINGE_BOTTOM))
void output_quad8_thick_two_side(vec3 view_normal)
{
	vec4 u7, u0, u4, u1, u5, u6;
	vec4 m7, m0, m4, m1, m5, m6;
	vec4 d7, d0, d4, d1, d5, d6;

	int prim_id = get_prim_id();
	uint bits_onfeat = get_thickness_onfeature(prim_id);

#if !defined(SHADER_SMOOTH_NORMALS)
	#if defined(SHADER_THICK_SHELLS_GET_NODAL_THICKNESS)
		#if defined(SHADER_USE_NODAL_NORMALS)
		#else // SHADER_USE_NODAL_NORMALS_3F
		#endif
		#if !defined(SHADER_EXTRA_ELEMENTS)
		#else // defined(SHADER_EXTRA_ELEMENTS)
		#endif // end !defined(SHADER_EXTRA_ELEMENTS)
	#elif defined(SHADER_THICK_SHELLS_GET_CORNER_THICKNESS)
		#if !defined(SHADER_EXTRA_ELEMENTS)
			float f0, f1, f2, f3;

			vec3 object_normal = get_prim_flat_normal();
			vec4 corner_values = texelFetch(elem_thickness_values, prim_id);
			#if defined(SHADER_THICK_SHELLS_Z_OFFSET)
			float zoffset = texelFetch(elem_thickness_z_offset, prim_id).r;
			#else
			float zoffset = 0.0;
			#endif
		
			f0 = corner_values.r * globals.thick_shells_scale.r * 0.5;
			f1 = corner_values.g * globals.thick_shells_scale.r * 0.5;
			f3 = corner_values.a * globals.thick_shells_scale.r * 0.5;
			f2 = corner_values.b * globals.thick_shells_scale.r * 0.5;

			int chunk = gl_PrimitiveIDIn % 2;
			float corner_vals[8] = float[](f0, f1, f2, f3, (f0+f1)*0.5, (f1+f2)*0.5, (f2+f3)*0.5, (f3+f0)*0.5);
			float strip_corner_factors[6];
			if (chunk == 0) {
				strip_corner_factors[0] = corner_vals[1];
				strip_corner_factors[1] = corner_vals[5];
				strip_corner_factors[2] = corner_vals[4];
				strip_corner_factors[3] = corner_vals[7];
				strip_corner_factors[4] = corner_vals[0];
				strip_corner_factors[5] = corner_vals[2];
			} else {
				strip_corner_factors[0] = corner_vals[3];
				strip_corner_factors[1] = corner_vals[7];
				strip_corner_factors[2] = corner_vals[6];
				strip_corner_factors[3] = corner_vals[5];
				strip_corner_factors[4] = corner_vals[2];
				strip_corner_factors[5] = corner_vals[0];
			}

			u1 = explode( gs_in[0].object_pos, object_normal, zoffset+strip_corner_factors[0] );
			u5 = explode( gs_in[1].object_pos, object_normal, zoffset+strip_corner_factors[1] );
			u4 = explode( gs_in[2].object_pos, object_normal, zoffset+strip_corner_factors[2] );
			u7 = explode( gs_in[3].object_pos, object_normal, zoffset+strip_corner_factors[3] );
			u0 = explode( gs_in[4].object_pos, object_normal, zoffset+strip_corner_factors[4] );
			u6 = explode( gs_in[5].object_pos, object_normal, zoffset+strip_corner_factors[5] );
			m1 = explode( gs_in[0].object_pos, object_normal, zoffset );
			m5 = explode( gs_in[1].object_pos, object_normal, zoffset );
			m4 = explode( gs_in[2].object_pos, object_normal, zoffset );
			m7 = explode( gs_in[3].object_pos, object_normal, zoffset );
			m0 = explode( gs_in[4].object_pos, object_normal, zoffset );
			m6 = explode( gs_in[5].object_pos, object_normal, zoffset );
			d1 = explode( gs_in[0].object_pos, object_normal, zoffset-strip_corner_factors[0] );
			d5 = explode( gs_in[1].object_pos, object_normal, zoffset-strip_corner_factors[1] );
			d4 = explode( gs_in[2].object_pos, object_normal, zoffset-strip_corner_factors[2] );
			d7 = explode( gs_in[3].object_pos, object_normal, zoffset-strip_corner_factors[3] );
			d0 = explode( gs_in[4].object_pos, object_normal, zoffset-strip_corner_factors[4] );
			d6 = explode( gs_in[5].object_pos, object_normal, zoffset-strip_corner_factors[5] );
		#else // defined(SHADER_EXTRA_ELEMENTS)
		#endif // end !defined(SHADER_EXTRA_ELEMENTS)
	#else // CENTROID THICKNESS
		vec3 object_normal = get_prim_flat_normal();
		
		// 1 -> 5 -> 4 -> 7 -> 0 -> 6

		// 1 -> 0
		// 5 -> 1
		// 4 -> 2
		// 7 -> 3
		// 0 -> 4
		// 6 -> 5

		vec2 thickness_factors = get_thickness_factors( prim_id );
		
		u1 = explode( gs_in[0].object_pos, object_normal, thickness_factors.x );
		u5 = explode( gs_in[1].object_pos, object_normal, thickness_factors.x );
		u4 = explode( gs_in[2].object_pos, object_normal, thickness_factors.x );
		u7 = explode( gs_in[3].object_pos, object_normal, thickness_factors.x );
		u0 = explode( gs_in[4].object_pos, object_normal, thickness_factors.x );
		u6 = explode( gs_in[5].object_pos, object_normal, thickness_factors.x );
		float mid_fact = (thickness_factors.x + thickness_factors.y ) * 0.5;
		m1 = explode( gs_in[0].object_pos, object_normal, mid_fact );
		m5 = explode( gs_in[1].object_pos, object_normal, mid_fact );
		m4 = explode( gs_in[2].object_pos, object_normal, mid_fact );
		m7 = explode( gs_in[3].object_pos, object_normal, mid_fact );
		m0 = explode( gs_in[4].object_pos, object_normal, mid_fact );
		m6 = explode( gs_in[5].object_pos, object_normal, mid_fact );
		d1 = explode( gs_in[0].object_pos, object_normal, thickness_factors.y );
		d5 = explode( gs_in[1].object_pos, object_normal, thickness_factors.y );
		d4 = explode( gs_in[2].object_pos, object_normal, thickness_factors.y );
		d7 = explode( gs_in[3].object_pos, object_normal, thickness_factors.y );
		d0 = explode( gs_in[4].object_pos, object_normal, thickness_factors.y );
		d6 = explode( gs_in[5].object_pos, object_normal, thickness_factors.y );
	#endif
#else // SHADER_SMOOTH_NORMALS
	#if defined(SHADER_THICK_SHELLS_GET_NODAL_THICKNESS)
		#if defined(SHADER_NEED_FOR_PRIMDATA)
		#endif
	#else
	#endif
#endif // END SHADER_SMOOTH_NORMALS

	int ids[5] = { 0, 1, 2, 3, 4 };
	vec2 brcs1[5] = { vec2( 0.0, 0.0 ), vec2( 0.0, 0.5 ), vec2( 0.5, 0.0 ), vec2( 1.0, 0.5 ), vec2( 1.0, 0.0 ) };
	make_face_quad_8_half_top_or_bottom( u1, u5, u4, u7, u0, u6, ids, brcs1 ); // top half
	make_face_quad_8_half_top_or_bottom( d1, d5, d4, d7, d0, d6, ids, brcs1 ); // bottom half

	uint side1, side2;
	side1 = ( gl_PrimitiveIDIn % 2 == 0 ) ? 1u : 3u;
	side2 = ( gl_PrimitiveIDIn % 2 == 0 ) ? 3u : 1u;
	uint front_side = ( gl_PrimitiveIDIn % 2 == 0 ) ? 0u : 2u;
#if !(defined(SHADER_FRINGE_NODE) || defined(SHADER_FRINGE_CORNER))
	// in tria6, quad8 the wire is done in separate step so barycentric is false
	vec2 brcs2[4] = { vec2( 0.0, 0.0 ), vec2( 1.0, 0.0 ), vec2( 0.5, 0.5 ), vec2( 0.0, 0.5 ) };
	make_face_quad_4_side( u1, m1, m5, u5, ivec4( 0, 0, 1, 1 ), false, view_normal, (((bits_onfeat >> side1) & 1u) == 1u ), brcs2 ); // side half 
	vec2 brcs3[4] = { vec2( 0.0, 0.0 ), vec2( 1.0, 0.0 ), vec2( 1.0, 0.5 ), vec2( 0.5, 0.5 ) };
	make_face_quad_4_side( m0, u0, u7, m7, ivec4( 4, 4, 3, 3 ), false, view_normal, (((bits_onfeat >> side2) & 1u) == 1u ), brcs3 ); // side half
	int ids_side_01[6] = { 4, 4, 2, 2, 0, 0 };
	vec2 brcs4[6] = { vec2( 1.0, 1.0 ), vec2( 1.0, 0.0 ), vec2( 0.5, 1.0 ), vec2( 0.5, 0.5 ), vec2( 0.0, 1.0 ), vec2( 0.0, 0.0 ) };
	make_face_quad_8_front_side( u0, m0, u4, m4, u1, m1, ids_side_01, view_normal, (((bits_onfeat >> front_side) & 1u) == 1u ), brcs4 ); // side front
	// in tria6, quad8 the wire is done in separate step so barycentric is false
	vec2 brcs5[4] = { vec2( 0.0, 0.0 ), vec2( 1.0, 0.0 ), vec2( 0.5, 0.5 ), vec2( 0.0, 0.5 ) };
	make_face_quad_4_side( d1, m1, m5, d5, ivec4( 0, 0, 1, 1 ), false, view_normal, (((bits_onfeat >> side1) & 1u) == 1u ), brcs5 ); // side half
	vec2 brcs6[4] = { vec2( 0.0, 0.0 ), vec2( 1.0, 0.0 ), vec2( 1.0, 0.5 ), vec2( 0.5, 0.5 ) };
	make_face_quad_4_side( m0, d0, d7, m7, ivec4( 4, 4, 3, 3 ), false, view_normal, (((bits_onfeat >> side2) & 1u) == 1u ), brcs6 ); // side half
	vec2 brcs7[6] = { vec2( 1.0, 1.0 ), vec2( 1.0, 0.0 ), vec2( 0.5, 1.0 ), vec2( 0.5, 0.5 ), vec2( 0.0, 1.0 ), vec2( 0.0, 0.0 ) };
	make_face_quad_8_front_side( d0, m0, d4, m4, d1, m1, ids_side_01, view_normal, (((bits_onfeat >> front_side) & 1u) == 1u ), brcs7 ); // side front
#else
	// in tria6 the wire is done in separate step so barycentric is false
	vec2 brcs2[4] = { vec2( 0.0, 0.0 ), vec2( 1.0, 0.0 ), vec2( 0.5, 0.5 ), vec2( 0.0, 0.5 ) };
	make_face_quad_4_side_top_bottom_node( u1, m1, m5, u5, ivec4( 0, 0, 1, 1 ), bvec4( false, true, true, false ), false, view_normal, (((bits_onfeat >> side1) & 1u) == 1u ), brcs2 ); // side half 
	vec2 brcs3[4] = { vec2( 0.0, 0.0 ), vec2( 1.0, 0.0 ), vec2( 1.0, 0.5 ), vec2( 0.5, 0.5 ) };
	make_face_quad_4_side_top_bottom_node( m0, u0, u7, m7, ivec4( 4, 4, 3, 3 ), bvec4( true, false, false, true ), false, view_normal, (((bits_onfeat >> side2) & 1u) == 1u ), brcs3 ); // side half
	int ids_side_01[6] = { 4, 4, 2, 2, 0, 0 };
	bool middle_values_front_01[6] = { false, true, false, true, false, true };
	vec2 brcs4[6] = { vec2( 1.0, 1.0 ), vec2( 1.0, 0.0 ), vec2( 0.5, 1.0 ), vec2( 0.5, 0.5 ), vec2( 0.0, 1.0 ), vec2( 0.0, 0.0 ) };
	make_face_quad_8_front_side_top_bottom_node( u0, m0, u4, m4, u1, m1, ids_side_01, middle_values_front_01, view_normal, (((bits_onfeat >> front_side) & 1u) == 1u ), brcs4 ); // side front
	// in tria6 the wire is done in separate step so barycentric is false
	vec2 brcs5[4] = { vec2( 0.0, 0.0 ), vec2( 1.0, 0.0 ), vec2( 0.5, 0.5 ), vec2( 0.0, 0.5 ) };
	make_face_quad_4_side_top_bottom_node( d1, m1, m5, d5, ivec4( 0, 0, 1, 1 ), bvec4( false, true, true, false ), false, view_normal, (((bits_onfeat >> side1) & 1u) == 1u ), brcs5 ); // side half
	vec2 brcs6[4] = { vec2( 0.0, 0.0 ), vec2( 1.0, 0.0 ), vec2( 1.0, 0.5 ), vec2( 0.5, 0.5 ) };
	make_face_quad_4_side_top_bottom_node( m0, d0, d7, m7, ivec4( 4, 4, 3, 3 ), bvec4( true, false, false, true ), false, view_normal, (((bits_onfeat >> side2) & 1u) == 1u ), brcs6 ); // side half 
	vec2 brcs7[6] = { vec2( 1.0, 1.0 ), vec2( 1.0, 0.0 ), vec2( 0.5, 1.0 ), vec2( 0.5, 0.5 ), vec2( 0.0, 1.0 ), vec2( 0.0, 0.0 ) };
	make_face_quad_8_front_side_top_bottom_node( d0, m0, d4, m4, d1, m1, ids_side_01, middle_values_front_01, view_normal, (((bits_onfeat >> front_side) & 1u) == 1u ), brcs7 ); // side front
#endif
}
#endif

// TODO KATRASD THICK add defines where missing to compile correctly
void make_wire_tria_3(vec4 view_pos_0, vec4 view_pos_1, vec4 view_pos_2, ivec3 ids, float area)
{
	output_params_wire(ids.x);
	gl_Position = globals.projection_matrix * view_pos_0;
	OUTPUT_AREA(0);
	EmitVertex();

	output_params_wire(ids.y);
	gl_Position = globals.projection_matrix * view_pos_1;
	OUTPUT_AREA(1);
	EmitVertex();

	output_params_wire(ids.z);
	gl_Position = globals.projection_matrix * view_pos_2;
	OUTPUT_AREA(2);
	EmitVertex();

	output_params_wire(ids.x);
	gl_Position = globals.projection_matrix * view_pos_0;
	EmitVertex();
	OUTPUT_AREA(0);
	EndPrimitive();
}

void make_wire_tria_6(vec4 view_pos_0, vec4 view_pos_1, vec4 view_pos_2,
					  vec4 view_pos_3, vec4 view_pos_4, vec4 view_pos_5,
					  int ids[6], float area)
{
	output_params_wire(ids[0]);
	gl_Position = globals.projection_matrix * view_pos_0;
	OUTPUT_AREA(0);
	EmitVertex();

	output_params_wire(ids[1]);
	gl_Position = globals.projection_matrix * view_pos_1;
	OUTPUT_AREA(1);
	EmitVertex();

	output_params_wire(ids[2]);
	gl_Position = globals.projection_matrix * view_pos_2;
	OUTPUT_AREA(2);
	EmitVertex();

	output_params_wire(ids[3]);
	gl_Position = globals.projection_matrix * view_pos_3;
	OUTPUT_AREA(3);
	EmitVertex();

	output_params_wire(ids[4]);
	gl_Position = globals.projection_matrix * view_pos_4;
	OUTPUT_AREA(4);
	EmitVertex();

	output_params_wire(ids[5]);
	gl_Position = globals.projection_matrix * view_pos_5;
	OUTPUT_AREA(5);
	EmitVertex();

	output_params_wire(ids[0]);
	gl_Position = globals.projection_matrix * view_pos_0;
	OUTPUT_AREA(0);
	EmitVertex();
	EndPrimitive();
}

void make_wire_quad_4(vec4 view_pos_0, vec4 view_pos_1, vec4 view_pos_2, vec4 view_pos_3,
					  ivec4 ids, float area)
{
	output_params_wire(ids.x);
	gl_Position = globals.projection_matrix * view_pos_0;
	OUTPUT_AREA(0);
	EmitVertex();

	output_params_wire(ids.y);
	gl_Position = globals.projection_matrix * view_pos_1;
	OUTPUT_AREA(1);
	EmitVertex();

	output_params_wire(ids.z);
	gl_Position = globals.projection_matrix * view_pos_2;
	OUTPUT_AREA(2);
	EmitVertex();

	output_params_wire(ids.w);
	gl_Position = globals.projection_matrix * view_pos_3;
	OUTPUT_AREA(3);
	EmitVertex();

	output_params_wire(ids.x);
	gl_Position = globals.projection_matrix * view_pos_0;
	OUTPUT_AREA(0);
	EmitVertex();
	EndPrimitive();
}

void make_wire_quad_4_open(vec4 view_pos_0, vec4 view_pos_1, vec4 view_pos_2, vec4 view_pos_3,
					  ivec4 ids, float area)
{
	output_params_wire(ids.x);
	gl_Position = globals.projection_matrix * view_pos_0;
	OUTPUT_AREA(0);
	EmitVertex();

	output_params_wire(ids.y);
	gl_Position = globals.projection_matrix * view_pos_1;
	OUTPUT_AREA(1);
	EmitVertex();

	output_params_wire(ids.z);
	gl_Position = globals.projection_matrix * view_pos_2;
	OUTPUT_AREA(2);
	EmitVertex();

	output_params_wire(ids.w);
	gl_Position = globals.projection_matrix * view_pos_3;
	OUTPUT_AREA(3);
	EmitVertex();
	EndPrimitive();
}

void make_wire_quad_6(vec4 view_pos_0, vec4 view_pos_1, vec4 view_pos_2,
					  vec4 view_pos_3, vec4 view_pos_4, vec4 view_pos_5,
					  int ids[6], float area)
{
	output_params_wire(ids[0]);
	gl_Position = globals.projection_matrix * view_pos_0;
	OUTPUT_AREA(0);
	EmitVertex();

	output_params_wire(ids[1]);
	gl_Position = globals.projection_matrix * view_pos_1;
	OUTPUT_AREA(1);
	EmitVertex();

	output_params_wire(ids[2]);
	gl_Position = globals.projection_matrix * view_pos_2;
	OUTPUT_AREA(2);
	EmitVertex();

	output_params_wire(ids[3]);
	gl_Position = globals.projection_matrix * view_pos_3;
	OUTPUT_AREA(3);
	EmitVertex();

	output_params_wire(ids[4]);
	gl_Position = globals.projection_matrix * view_pos_4;
	OUTPUT_AREA(4);
	EmitVertex();

	output_params_wire(ids[5]);
	gl_Position = globals.projection_matrix * view_pos_5;
	OUTPUT_AREA(5);
	EmitVertex();

	output_params_wire(ids[0]);
	gl_Position = globals.projection_matrix * view_pos_0;
	OUTPUT_AREA(0);
	EmitVertex();
	EndPrimitive();
}
	
void make_wire_quad_8_half_top_or_bottom( vec4 view_pos_0, vec4 view_pos_1, vec4 view_pos_2,
					 					  vec4 view_pos_3, vec4 view_pos_4,
					 					  int ids[5], float area)
{
	output_params_wire(ids[0]);
	gl_Position = globals.projection_matrix * view_pos_0;
	OUTPUT_AREA(0);
	EmitVertex();

	output_params_wire(ids[1]);
	gl_Position = globals.projection_matrix * view_pos_1;
	OUTPUT_AREA(1);
	EmitVertex();

	output_params_wire(ids[2]);
	gl_Position = globals.projection_matrix * view_pos_2;
	OUTPUT_AREA(2);
	EmitVertex();

	output_params_wire(ids[3]);
	gl_Position = globals.projection_matrix * view_pos_3;
	OUTPUT_AREA(3);
	EmitVertex();

	output_params_wire(ids[4]);
	gl_Position = globals.projection_matrix * view_pos_4;
	OUTPUT_AREA(4);
	EmitVertex();
	EndPrimitive();
}

#if defined(SHADER_TRIA3) && !defined(SHADER_POLYGON) && defined(SHADER_ONLY_WIRE)
void output_wire_tria3_thick()
{
	vec4 u0, u1, u2, d0, d1, d2; // view pos

	int prim_id = get_prim_id();

#if defined(SHADER_THICK_SHELLS_GET_NODAL_THICKNESS)
#elif defined(SHADER_THICK_SHELLS_GET_CORNER_THICKNESS)
	vec3 object_normal = get_prim_flat_normal();
	float f0, f1, f2;

	vec4 corner_values = texelFetch(elem_thickness_values, prim_id);
	#if defined(SHADER_THICK_SHELLS_Z_OFFSET)
	float zoffset = texelFetch(elem_thickness_z_offset, prim_id).r;
	#else
	float zoffset = 0.0;
	#endif

	f0 = corner_values.r * globals.thick_shells_scale.r * 0.5;
	f1 = corner_values.g * globals.thick_shells_scale.r * 0.5;
	f2 = corner_values.b * globals.thick_shells_scale.r * 0.5;

	u0 = explode( gs_in[0].object_pos, object_normal, zoffset+f0 );
	u1 = explode( gs_in[1].object_pos, object_normal, zoffset+f1 );
	u2 = explode( gs_in[2].object_pos, object_normal, zoffset+f2 );

	d0 = explode( gs_in[0].object_pos, object_normal, zoffset-f0 );
	d1 = explode( gs_in[1].object_pos, object_normal, zoffset-f1 );
	d2 = explode( gs_in[2].object_pos, object_normal, zoffset-f2 );
#else // CENTROID THICKNESS
	vec3 object_normal = get_prim_flat_normal();

	vec2 thickness_factors = get_thickness_factors( prim_id );
	
	u0 = explode( gs_in[0].object_pos, object_normal, thickness_factors.x );
	u1 = explode( gs_in[1].object_pos, object_normal, thickness_factors.x );
	u2 = explode( gs_in[2].object_pos, object_normal, thickness_factors.x );

	d0 = explode( gs_in[0].object_pos, object_normal, thickness_factors.y );
	d1 = explode( gs_in[1].object_pos, object_normal, thickness_factors.y );
	d2 = explode( gs_in[2].object_pos, object_normal, thickness_factors.y );
#endif
#if defined(SHADER_TWO_SIDE)
	float area = calc_area(gl_in[0].gl_Position, gl_in[1].gl_Position, gl_in[2].gl_Position);
#else
	float area = 0.0;
#endif
	make_wire_tria_3( u0, u1, u2, ivec3( 0, 1, 2 ), area );
	make_wire_tria_3( d0, d1, d2, ivec3( 0, 1, 2 ), area );

	make_wire_quad_4( u0, d0, d1, u1, ivec4( 0, 0, 1, 1 ), area ); // side
	make_wire_quad_4( u1, d1, d2, u2, ivec4( 1, 1, 2, 2 ), area ); // side
	make_wire_quad_4( u2, d2, d0, u0, ivec4( 2, 2, 0, 0 ), area ); // side
}
#endif

#if defined(SHADER_TRIA6) && defined(SHADER_ONLY_WIRE)
void output_wire_tria6_thick()
{
	vec4 u0, u1, u2, u3, u4, u5;
	vec4 d0, d1, d2, d3, d4, d5;

	int prim_id = get_prim_id();

#if defined(SHADER_THICK_SHELLS_GET_NODAL_THICKNESS)
#elif defined(SHADER_THICK_SHELLS_GET_CORNER_THICKNESS)
	float f0, f1, f2;

	vec3 object_normal = get_prim_flat_normal();
	vec4 corner_values = texelFetch(elem_thickness_values, prim_id);
	#if defined(SHADER_THICK_SHELLS_Z_OFFSET)
	float zoffset = texelFetch(elem_thickness_z_offset, prim_id).r;
	#else
	float zoffset = 0.0;
	#endif
	
	f0 = corner_values.r * globals.thick_shells_scale.r * 0.5;
	f1 = corner_values.g * globals.thick_shells_scale.r * 0.5;
	f2 = corner_values.b * globals.thick_shells_scale.r * 0.5;

	u0 = explode( gs_in[0].object_pos, object_normal, zoffset+f0          );
	u1 = explode( gs_in[1].object_pos, object_normal, zoffset+f1          );
	u2 = explode( gs_in[2].object_pos, object_normal, zoffset+f2          );
	u3 = explode( gs_in[3].object_pos, object_normal, zoffset+(f0+f1)*0.5 );
	u4 = explode( gs_in[4].object_pos, object_normal, zoffset+(f1+f2)*0.5 );
	u5 = explode( gs_in[5].object_pos, object_normal, zoffset+(f0+f2)*0.5 );

	d0 = explode( gs_in[0].object_pos, object_normal, zoffset-f0          );
	d1 = explode( gs_in[1].object_pos, object_normal, zoffset-f1          );
	d2 = explode( gs_in[2].object_pos, object_normal, zoffset-f2          );
	d3 = explode( gs_in[3].object_pos, object_normal, zoffset-(f0+f1)*0.5 );
	d4 = explode( gs_in[4].object_pos, object_normal, zoffset-(f1+f2)*0.5 );
	d5 = explode( gs_in[5].object_pos, object_normal, zoffset-(f0+f2)*0.5 );
#else // CENTROID THICKNESS
	vec3 object_normal = get_prim_flat_normal();
	vec2 thickness_factors = get_thickness_factors( prim_id );
	
	u0 = explode( gs_in[0].object_pos, object_normal, thickness_factors.x );
	u1 = explode( gs_in[1].object_pos, object_normal, thickness_factors.x );
	u2 = explode( gs_in[2].object_pos, object_normal, thickness_factors.x );
	u3 = explode( gs_in[3].object_pos, object_normal, thickness_factors.x );
	u4 = explode( gs_in[4].object_pos, object_normal, thickness_factors.x );
	u5 = explode( gs_in[5].object_pos, object_normal, thickness_factors.x );

	d0 = explode( gs_in[0].object_pos, object_normal, thickness_factors.y );
	d1 = explode( gs_in[1].object_pos, object_normal, thickness_factors.y );
	d2 = explode( gs_in[2].object_pos, object_normal, thickness_factors.y );
	d3 = explode( gs_in[3].object_pos, object_normal, thickness_factors.y );
	d4 = explode( gs_in[4].object_pos, object_normal, thickness_factors.y );
	d5 = explode( gs_in[5].object_pos, object_normal, thickness_factors.y );
#endif

#if defined(SHADER_TWO_SIDE)
	float area = calc_area(gl_in[0].gl_Position, gl_in[1].gl_Position, gl_in[2].gl_Position);
#else
	float area = 0.0;
#endif
	int ids[6] = { 0, 3, 1, 4, 2, 5 };
	make_wire_tria_6( u0, u3, u1, u4, u2, u5, ids, area );
	make_wire_tria_6( d0, d3, d1, d4, d2, d5, ids, area );
	
	int ids_side_01[6] = { 0, 0, 3, 1, 1, 3 };
	make_wire_quad_6( u0, d0, d3, d1, u1, u3, ids_side_01, area );
	int ids_side_02[6] = { 1, 1, 4, 2, 2, 4 };
	make_wire_quad_6( u1, d1, d4, d2, u2, u4, ids_side_02, area );
	int ids_side_03[6] = { 2, 2, 5, 0, 0, 5 };
	make_wire_quad_6( u2, d2, d5, d0, u0, u5, ids_side_03, area );
}
#endif

#if defined(SHADER_QUAD4) && defined(SHADER_ONLY_WIRE)
void output_wire_quad4_thick()
{
	vec4 u0, u1, u2, u3, d0, d1, d2, d3; // view pos

	int prim_id = get_prim_id();

#if defined(SHADER_THICK_SHELLS_GET_NODAL_THICKNESS)
#elif defined(SHADER_THICK_SHELLS_GET_CORNER_THICKNESS)
	float f0, f1, f2, f3;

	vec3 object_normal = get_prim_flat_normal();
	vec4 corner_values = texelFetch(elem_thickness_values, prim_id);
	#if defined(SHADER_THICK_SHELLS_Z_OFFSET)
	float zoffset = texelFetch(elem_thickness_z_offset, prim_id).r;
	#else
	float zoffset = 0.0;
	#endif

	f0 = corner_values.r * globals.thick_shells_scale.r * 0.5;
	f1 = corner_values.g * globals.thick_shells_scale.r * 0.5;
	f3 = corner_values.a * globals.thick_shells_scale.r * 0.5;
	f2 = corner_values.b * globals.thick_shells_scale.r * 0.5;

	u0 = explode( gs_in[0].object_pos, object_normal, zoffset+f0 );
	u1 = explode( gs_in[1].object_pos, object_normal, zoffset+f1 );
	u3 = explode( gs_in[3].object_pos, object_normal, zoffset+f3 );
	u2 = explode( gs_in[2].object_pos, object_normal, zoffset+f2 );

	d0 = explode( gs_in[0].object_pos, object_normal, zoffset-f0 );
	d1 = explode( gs_in[1].object_pos, object_normal, zoffset-f1 );
	d3 = explode( gs_in[3].object_pos, object_normal, zoffset-f3 );
	d2 = explode( gs_in[2].object_pos, object_normal, zoffset-f2 );
#else // CENTROID THICKNESS
	vec3 object_normal = get_prim_flat_normal();
	vec2 thickness_factors = get_thickness_factors( prim_id );
	
	u0 = explode( gs_in[0].object_pos, object_normal, thickness_factors.x );
	u1 = explode( gs_in[1].object_pos, object_normal, thickness_factors.x );
	u2 = explode( gs_in[2].object_pos, object_normal, thickness_factors.x );
	u3 = explode( gs_in[3].object_pos, object_normal, thickness_factors.x );

	d0 = explode( gs_in[0].object_pos, object_normal, thickness_factors.y );
	d1 = explode( gs_in[1].object_pos, object_normal, thickness_factors.y );
	d2 = explode( gs_in[2].object_pos, object_normal, thickness_factors.y );
	d3 = explode( gs_in[3].object_pos, object_normal, thickness_factors.y );
#endif
#if defined(SHADER_TWO_SIDE)
	float area = calc_area(gl_in[0].gl_Position, gl_in[1].gl_Position, gl_in[3].gl_Position);
#else
	float area = 0.0;
#endif
	make_wire_quad_4( u0, u1, u2, u3, ivec4( 0, 1, 2, 3 ), area );
	make_wire_quad_4( d0, d1, d2, d3, ivec4( 0, 1, 2, 3 ), area );

	make_wire_quad_4( u0, d0, d1, u1, ivec4( 0, 0, 1, 1 ), area );
	make_wire_quad_4( u1, d1, d2, u2, ivec4( 1, 1, 2, 2 ), area );
	make_wire_quad_4( u2, d2, d3, u3, ivec4( 2, 2, 3, 3 ), area );
	make_wire_quad_4( u3, d3, d0, u0, ivec4( 3, 3, 0, 0 ), area );
}
#endif

#if defined(SHADER_QUAD8) && defined(SHADER_ONLY_WIRE)
void output_wire_quad8_thick()
{
	vec4 u7, u0, u4, u1, u5; 
	vec4 d7, d0, d4, d1, d5;

	int prim_id = get_prim_id();

#if defined(SHADER_THICK_SHELLS_GET_NODAL_THICKNESS)
#elif defined(SHADER_THICK_SHELLS_GET_CORNER_THICKNESS)
	float f0, f1, f2, f3;
	// 1 -> 5 -> 4 -> 7 -> 0 -> 6

	// 1 -> 0
	// 5 -> 1
	// 4 -> 2
	// 7 -> 3
	// 0 -> 4
	// 6 -> 5

	vec3 object_normal = get_prim_flat_normal();
	vec4 corner_values = texelFetch(elem_thickness_values, prim_id);
	#if defined(SHADER_THICK_SHELLS_Z_OFFSET)
	float zoffset = texelFetch(elem_thickness_z_offset, prim_id).r;
	#else
	float zoffset = 0.0;
	#endif

	f0 = corner_values.r * globals.thick_shells_scale.r * 0.5;
	f1 = corner_values.g * globals.thick_shells_scale.r * 0.5;
	f3 = corner_values.a * globals.thick_shells_scale.r * 0.5;
	f2 = corner_values.b * globals.thick_shells_scale.r * 0.5;

	int chunk = gl_PrimitiveIDIn % 2;
	float corner_vals[8] = float[](f0, f1, f2, f3, (f0+f1)*0.5, (f1+f2)*0.5, (f2+f3)*0.5, (f3+f0)*0.5);
	float strip_corner_factors[6];
	if (chunk == 0) {
		strip_corner_factors[0] = corner_vals[1];
		strip_corner_factors[1] = corner_vals[5];
		strip_corner_factors[2] = corner_vals[4];
		strip_corner_factors[3] = corner_vals[7];
		strip_corner_factors[4] = corner_vals[0];
	} else {
		strip_corner_factors[0] = corner_vals[3];
		strip_corner_factors[1] = corner_vals[7];
		strip_corner_factors[2] = corner_vals[6];
		strip_corner_factors[3] = corner_vals[5];
		strip_corner_factors[4] = corner_vals[2];
	}

	u1 = explode( gs_in[0].object_pos, object_normal, zoffset+strip_corner_factors[0]); 
	u5 = explode( gs_in[1].object_pos, object_normal, zoffset+strip_corner_factors[1]); 
	u4 = explode( gs_in[2].object_pos, object_normal, zoffset+strip_corner_factors[2]); 
	u7 = explode( gs_in[3].object_pos, object_normal, zoffset+strip_corner_factors[3]); 
	u0 = explode( gs_in[4].object_pos, object_normal, zoffset+strip_corner_factors[4]); 

	d1 = explode( gs_in[0].object_pos, object_normal, zoffset-strip_corner_factors[0]);
	d5 = explode( gs_in[1].object_pos, object_normal, zoffset-strip_corner_factors[1]);
	d4 = explode( gs_in[2].object_pos, object_normal, zoffset-strip_corner_factors[2]);
	d7 = explode( gs_in[3].object_pos, object_normal, zoffset-strip_corner_factors[3]);
	d0 = explode( gs_in[4].object_pos, object_normal, zoffset-strip_corner_factors[4]);
#else // CENTROID THICKNESS
	vec3 object_normal = get_prim_flat_normal();
	
	// 1 -> 5 -> 4 -> 7 -> 0 -> 6

	// 1 -> 0
	// 5 -> 1
	// 4 -> 2
	// 7 -> 3
	// 0 -> 4
	// 6 -> 5

	vec2 thickness_factors = get_thickness_factors( prim_id );
	
	u1 = explode( gs_in[0].object_pos, object_normal, thickness_factors.x );
	u5 = explode( gs_in[1].object_pos, object_normal, thickness_factors.x );
	u4 = explode( gs_in[2].object_pos, object_normal, thickness_factors.x );
	u7 = explode( gs_in[3].object_pos, object_normal, thickness_factors.x );
	u0 = explode( gs_in[4].object_pos, object_normal, thickness_factors.x );

	d1 = explode( gs_in[0].object_pos, object_normal, thickness_factors.y );
	d5 = explode( gs_in[1].object_pos, object_normal, thickness_factors.y );
	d4 = explode( gs_in[2].object_pos, object_normal, thickness_factors.y );
	d7 = explode( gs_in[3].object_pos, object_normal, thickness_factors.y );
	d0 = explode( gs_in[4].object_pos, object_normal, thickness_factors.y );
#endif
#if defined(SHADER_TWO_SIDE)
	float area = calc_area(gl_in[0].gl_Position, gl_in[1].gl_Position, gl_in[2].gl_Position);
#else
	float area = 0.0;
#endif
	int ids[5] = { 1, 0, 2, 4, 3 };
	make_wire_quad_8_half_top_or_bottom( u5, u1, u4, u0, u7, ids, area );
	make_wire_quad_8_half_top_or_bottom( d5, d1, d4, d0, d7, ids, area );

	make_wire_quad_4_open( u5, u1, d1, d5, ivec4( 1, 0, 0, 1 ), area );
	make_wire_quad_4_open( d7, d0, u0, u7, ivec4( 3, 4, 4, 3 ), area );

	int ids_side_01[6] = { 4, 4, 2, 0, 0, 2 };
	make_wire_quad_6( u0, d0, d4, d1, u1, u4, ids_side_01, area );
}
#endif
#endif // SHADER_THICK_SHELLS


#endif

#if defined(SHADER_TRIA3)
void output_tria3()
{
	int prim_id = get_prim_id();
#if defined(SHADER_NEED_FOR_PRIMDATA)
	PrimData primDat = get_prim_data(prim_id);
#endif

#if defined(SHADER_BARYCENTRICS)
	gs_out.edges = (1u << 2u) | (1u << 1u) | (1u << 0u);
#endif
	OUTPUT_TEX_TOP_FRINGE_QUALITY();
	OUTPUT_TEX_BOTTOM_FRINGE_QUALITY();

	OUTPUT_FRINGE_BARYCENTRIC(1.0f, 0.0f, 0.0f);
	OUTPUT_BARYCENTRIC(0.0, 0.0);
	OUTPUT_SMOOTH_NORMALS(0);
	OUTPUT_TEX_TOP(0);
	OUTPUT_TEX_BOTTOM(0);
	OUTPUT_BLUR_VELOCITY(0);
	OUTPUT_TEX_COORDS(0);
	OUTPUT_NODAL_NORMALS(0);
	OUTPUT_NODAL_COLOR(0);
	OUTPUT_CLIP_VERTEX(0);
	OUTPUT_LICDATA(0);
	OUTPUT_POSITION(0);
	EmitVertex();

	OUTPUT_FRINGE_BARYCENTRIC(0.0f, 1.0f, 0.0f);
	OUTPUT_BARYCENTRIC(0.0, 1.0);
	OUTPUT_SMOOTH_NORMALS(1);
	OUTPUT_TEX_TOP(1);
	OUTPUT_TEX_BOTTOM(1);
	OUTPUT_BLUR_VELOCITY(1);
	OUTPUT_TEX_COORDS(1);
	OUTPUT_NODAL_NORMALS(1);
	OUTPUT_NODAL_COLOR(1);
	OUTPUT_CLIP_VERTEX(1);
	OUTPUT_LICDATA(1);
	OUTPUT_POSITION(1);
	EmitVertex();

	OUTPUT_FRINGE_BARYCENTRIC(0.0f, 0.0f, 1.0f);
	OUTPUT_BARYCENTRIC(1.0, 0.0);
	OUTPUT_SMOOTH_NORMALS(2);
	OUTPUT_TEX_TOP(2);
	OUTPUT_TEX_BOTTOM(2);
	OUTPUT_BLUR_VELOCITY(2);
	OUTPUT_TEX_COORDS(2);
	OUTPUT_NODAL_NORMALS(2);
	OUTPUT_NODAL_COLOR(2);
	OUTPUT_CLIP_VERTEX(2);
	OUTPUT_LICDATA(2);
	OUTPUT_POSITION(2);
	EmitVertex();
}
#endif

#if defined(SHADER_QUAD4)
void output_quad4()
{
	int prim_id = get_prim_id();
#if defined(SHADER_NEED_FOR_PRIMDATA)
	PrimData primDat = get_prim_data(prim_id);
#endif

#if defined(SHADER_BARYCENTRICS)
	gs_out.edges = (1u << 1u) | (1u << 0u);
#endif

	OUTPUT_TEX_TOP_FRINGE_QUALITY();
	OUTPUT_TEX_BOTTOM_FRINGE_QUALITY();

	OUTPUT_FRINGE_BARYCENTRIC(0.0f, 0.0f);
	OUTPUT_BARYCENTRIC(0.0, 0.0);
	OUTPUT_SMOOTH_NORMALS(0);
	OUTPUT_TEX_TOP(0);
	OUTPUT_TEX_BOTTOM(0);
	OUTPUT_BLUR_VELOCITY(0);
	OUTPUT_TEX_COORDS(0);
	OUTPUT_NODAL_NORMALS(0);
	OUTPUT_NODAL_COLOR(0);
	OUTPUT_CLIP_VERTEX(0);
	OUTPUT_LICDATA(0);
	OUTPUT_POSITION(0);
	EmitVertex();

	OUTPUT_FRINGE_BARYCENTRIC(1.0f, 0.0f);
	OUTPUT_BARYCENTRIC(0.0, 1.0);
	OUTPUT_SMOOTH_NORMALS(1);
	OUTPUT_TEX_TOP(1);
	OUTPUT_TEX_BOTTOM(1);
	OUTPUT_BLUR_VELOCITY(1);
	OUTPUT_TEX_COORDS(1);
	OUTPUT_NODAL_NORMALS(1);
	OUTPUT_NODAL_COLOR(1);
	OUTPUT_CLIP_VERTEX(1);
	OUTPUT_LICDATA(1);
	OUTPUT_POSITION(1);
	EmitVertex();

	OUTPUT_FRINGE_BARYCENTRIC(0.0f, 1.0f);
	OUTPUT_BARYCENTRIC(1.0, 0.0);
	OUTPUT_SMOOTH_NORMALS(3);
	OUTPUT_TEX_TOP(3);
	OUTPUT_TEX_BOTTOM(3);
	OUTPUT_BLUR_VELOCITY(3);
	OUTPUT_TEX_COORDS(3);
	OUTPUT_NODAL_NORMALS(3);
	OUTPUT_NODAL_COLOR(3);
	OUTPUT_CLIP_VERTEX(3);
	OUTPUT_LICDATA(3);
	OUTPUT_POSITION(3);
	EmitVertex();

	OUTPUT_FRINGE_BARYCENTRIC(1.0f, 1.0f);
	OUTPUT_BARYCENTRIC(0.0, 0.0);
	OUTPUT_SMOOTH_NORMALS(2);
	OUTPUT_TEX_TOP(2);
	OUTPUT_TEX_BOTTOM(2);
	OUTPUT_BLUR_VELOCITY(2);
	OUTPUT_TEX_COORDS(2);
	OUTPUT_NODAL_NORMALS(2);
	OUTPUT_NODAL_COLOR(2);
	OUTPUT_CLIP_VERTEX(2);
	OUTPUT_LICDATA(2);
	OUTPUT_POSITION(2);
	EmitVertex();
}
#endif

#if defined(SHADER_TRIA6)
void output_tria6()
{
	int prim_id = get_prim_id();
#if defined(SHADER_NEED_FOR_PRIMDATA)
	PrimData primDat = get_prim_data(prim_id);
#endif
	OUTPUT_TEX_TOP_FRINGE_QUALITY();
	OUTPUT_TEX_BOTTOM_FRINGE_QUALITY();

	OUTPUT_FRINGE_BARYCENTRIC(0.0f, 0.0f, 1.0f);
	OUTPUT_SMOOTH_NORMALS(1);
	OUTPUT_TEX_TOP(1);
	OUTPUT_TEX_BOTTOM(1);
	OUTPUT_BLUR_VELOCITY(1);
	OUTPUT_TEX_COORDS(1);
	OUTPUT_NODAL_NORMALS(1);
	OUTPUT_NODAL_COLOR(1);
	OUTPUT_CLIP_VERTEX(1);
	OUTPUT_LICDATA(1);
	OUTPUT_POSITION(1);
	EmitVertex();

	OUTPUT_MIDDLE_NODE_FRINGE_BARYCENTRIC(4, 1, vec3(0.0f, 0.5f, 0.5f), vec3(0.0f, 0.0f, 1.0f))
	OUTPUT_SMOOTH_NORMALS(4);
	OUTPUT_TEX_TOP(4);
	OUTPUT_TEX_BOTTOM(4);
	OUTPUT_BLUR_VELOCITY(4);
	OUTPUT_TEX_COORDS(4);
	OUTPUT_NODAL_NORMALS(4);
	OUTPUT_NODAL_COLOR(4);
	OUTPUT_CLIP_VERTEX(4);
	OUTPUT_LICDATA(4);
	OUTPUT_POSITION(4);
	EmitVertex();

	OUTPUT_MIDDLE_NODE_FRINGE_BARYCENTRIC(3, 0, vec3(0.5f, 0.0f, 0.5f), vec3(1.0f, 0.0f, 0.0f))
	OUTPUT_SMOOTH_NORMALS(3);
	OUTPUT_TEX_TOP(3);
	OUTPUT_TEX_BOTTOM(3);
	OUTPUT_BLUR_VELOCITY(3);
	OUTPUT_TEX_COORDS(3);
	OUTPUT_NODAL_NORMALS(3);
	OUTPUT_NODAL_COLOR(3);
	OUTPUT_CLIP_VERTEX(3);
	OUTPUT_LICDATA(3);
	OUTPUT_POSITION(3);
	EmitVertex();

	OUTPUT_MIDDLE_NODE_FRINGE_BARYCENTRIC(5, 2, vec3(0.5f, 0.5f, 0.0f), vec3(0.0f, 1.0f, 0.0f))
	OUTPUT_SMOOTH_NORMALS(5);
	OUTPUT_TEX_TOP(5);
	OUTPUT_TEX_BOTTOM(5);
	OUTPUT_BLUR_VELOCITY(5);
	OUTPUT_TEX_COORDS(5);
	OUTPUT_NODAL_NORMALS(5);
	OUTPUT_NODAL_COLOR(5);
	OUTPUT_CLIP_VERTEX(5);
	OUTPUT_LICDATA(5);
	OUTPUT_POSITION(5);
	EmitVertex();

	OUTPUT_FRINGE_BARYCENTRIC(1.0f, 0.0f, 0.0f);
	OUTPUT_SMOOTH_NORMALS(0);
	OUTPUT_TEX_TOP(0);
	OUTPUT_TEX_BOTTOM(0);
	OUTPUT_BLUR_VELOCITY(0);
	OUTPUT_TEX_COORDS(0);
	OUTPUT_NODAL_NORMALS(0);
	OUTPUT_NODAL_COLOR(0);
	OUTPUT_CLIP_VERTEX(0);
	OUTPUT_LICDATA(0);
	OUTPUT_POSITION(0);
	EmitVertex();

	EndPrimitive();

	OUTPUT_MIDDLE_NODE_FRINGE_BARYCENTRIC(4, 1, vec3(0.0f, 0.5f, 0.5f), vec3(0.0f, 0.0f, 1.0f))
    OUTPUT_SMOOTH_NORMALS(4);
	OUTPUT_TEX_TOP(4);
	OUTPUT_TEX_BOTTOM(4);
	OUTPUT_BLUR_VELOCITY(4);
	OUTPUT_TEX_COORDS(4);
	OUTPUT_NODAL_NORMALS(4);
	OUTPUT_NODAL_COLOR(4);
	OUTPUT_CLIP_VERTEX(4);
	OUTPUT_LICDATA(4);
	OUTPUT_POSITION(4);
	EmitVertex();

	OUTPUT_FRINGE_BARYCENTRIC(0.0f, 1.0f, 0.0f);
	OUTPUT_SMOOTH_NORMALS(2);
	OUTPUT_TEX_TOP(2);
	OUTPUT_TEX_BOTTOM(2);
	OUTPUT_BLUR_VELOCITY(2);
	OUTPUT_TEX_COORDS(2);
	OUTPUT_NODAL_NORMALS(2);
	OUTPUT_NODAL_COLOR(2);
	OUTPUT_CLIP_VERTEX(2);
	OUTPUT_LICDATA(2);
	OUTPUT_POSITION(2);
	EmitVertex();

	OUTPUT_MIDDLE_NODE_FRINGE_BARYCENTRIC(5, 2, vec3(0.5f, 0.5f, 0.0f), vec3(0.0f, 1.0f, 0.0f))
	OUTPUT_SMOOTH_NORMALS(5);
	OUTPUT_TEX_TOP(5);
	OUTPUT_TEX_BOTTOM(5);
	OUTPUT_BLUR_VELOCITY(5);
	OUTPUT_TEX_COORDS(5);
	OUTPUT_NODAL_NORMALS(5);
	OUTPUT_NODAL_COLOR(5);
	OUTPUT_CLIP_VERTEX(5);
	OUTPUT_LICDATA(5);
	OUTPUT_POSITION(5);
	EmitVertex();
    EndPrimitive();
}
#endif

#if defined(SHADER_QUAD8)
void output_quad8()
{
	int prim_id = get_prim_id();
    int chunk = gl_PrimitiveIDIn % 2;
#if defined(SHADER_NEED_FOR_PRIMDATA)
	PrimData primDat = get_prim_data(prim_id);
#endif
#if defined(SHADER_FRINGE_EXACT)
    uint middle_nodes = texelFetch(elem_middle_nodes, prim_id).r;
#endif
	OUTPUT_TEX_TOP_FRINGE_QUALITY(middle_nodes);
	OUTPUT_TEX_BOTTOM_FRINGE_QUALITY(middle_nodes);

	bool invalid_y1mid = all(equal(gl_in[0].gl_Position, gl_in[1].gl_Position));
	bool invalid_xmid = all(equal(gl_in[2].gl_Position, gl_in[4].gl_Position));

	float y1mid_bar = invalid_y1mid ? 0.0  : 0.5;
	float xmid_bar = invalid_xmid ? 0.0  : 0.5;

	OUTPUT_FRINGE_BARYCENTRIC(float(chunk) + 0.0f, float(chunk) + 0.0f);
	OUTPUT_BARYCENTRIC(1.0, 0.0);
	OUTPUT_SMOOTH_NORMALS(0);
	OUTPUT_TEX_TOP(0);
	OUTPUT_TEX_BOTTOM(0);
	OUTPUT_BLUR_VELOCITY(0);
	OUTPUT_TEX_COORDS(0);
	OUTPUT_NODAL_NORMALS(0);
	OUTPUT_NODAL_COLOR(0);
	OUTPUT_CLIP_VERTEX(0);
	OUTPUT_LICDATA(0);
	OUTPUT_POSITION(0);
	EmitVertex();

	OUTPUT_MIDDLE_NODE_FRINGE_BARYCENTRIC(middle_nodes, 5 + 2 * chunk, vec2(float(chunk) + 0.0f, 0.5f), vec2(float(chunk) + 0.0f, float(chunk) + 0.0f))
	OUTPUT_BARYCENTRIC(1.0, y1mid_bar);
	OUTPUT_SMOOTH_NORMALS(1);
	OUTPUT_TEX_TOP(1);
	OUTPUT_TEX_BOTTOM(1);
	OUTPUT_BLUR_VELOCITY(1);
	OUTPUT_TEX_COORDS(1);
	OUTPUT_NODAL_NORMALS(1);
	OUTPUT_NODAL_COLOR(1);
	OUTPUT_CLIP_VERTEX(1);
	OUTPUT_LICDATA(1);
	OUTPUT_POSITION(1);
	EmitVertex();

	OUTPUT_MIDDLE_NODE_FRINGE_BARYCENTRIC(middle_nodes, 4 + 2 * chunk, vec2(0.5f, float(chunk) + 0.0f), vec2(1.0f - float(chunk), float(chunk)))
	OUTPUT_BARYCENTRIC(xmid_bar, 0.0);
	OUTPUT_SMOOTH_NORMALS(2);
	OUTPUT_TEX_TOP(2);
	OUTPUT_TEX_BOTTOM(2);
	OUTPUT_BLUR_VELOCITY(2);
	OUTPUT_TEX_COORDS(2);
	OUTPUT_NODAL_NORMALS(2);
	OUTPUT_NODAL_COLOR(2);
	OUTPUT_CLIP_VERTEX(2);
	OUTPUT_LICDATA(2);
	OUTPUT_POSITION(2);
	EmitVertex();

	OUTPUT_MIDDLE_NODE_FRINGE_BARYCENTRIC(middle_nodes, 7 - 2 * chunk, vec2(1.0f - float(chunk), 0.5f), vec2(1.0f - float(chunk), 1.0f - float(chunk)))
	OUTPUT_BARYCENTRIC(0.0, 0.5);
	OUTPUT_SMOOTH_NORMALS(3);
	OUTPUT_TEX_TOP(3);
	OUTPUT_TEX_BOTTOM(3);
	OUTPUT_BLUR_VELOCITY(3);
	OUTPUT_TEX_COORDS(3);
	OUTPUT_NODAL_NORMALS(3);
	OUTPUT_NODAL_COLOR(3);
	OUTPUT_CLIP_VERTEX(3);
	OUTPUT_LICDATA(3);
	OUTPUT_POSITION(3);
	EmitVertex();

	OUTPUT_FRINGE_BARYCENTRIC(1.0f - float(chunk), float(chunk) + 0.0f);
	OUTPUT_BARYCENTRIC(0.0, 0.0);
	OUTPUT_SMOOTH_NORMALS(4);
	OUTPUT_TEX_TOP(4);
	OUTPUT_TEX_BOTTOM(4);
	OUTPUT_BLUR_VELOCITY(4);
	OUTPUT_TEX_COORDS(4);
	OUTPUT_NODAL_NORMALS(4);
	OUTPUT_NODAL_COLOR(4);
	OUTPUT_CLIP_VERTEX(4);
	OUTPUT_LICDATA(4);
	OUTPUT_POSITION(4);
	EmitVertex();

	EndPrimitive();
}
#endif

#define CENT_AVG(_TYPE_, _PREIDX_, _POSTIDX_, _CNTOUT_)\
_TYPE_ _CNTOUT_;\
{\
	_TYPE_ v3 = _PREIDX_[3]_POSTIDX_;\
	_TYPE_ v4 = _PREIDX_[4]_POSTIDX_;\
	_TYPE_ v5 = _PREIDX_[5]_POSTIDX_;\
	_CNTOUT_ = mix(mix(v3, v5, 0.5), v4, 0.25);\
}
#if defined(SHADER_POLYGON)
void output_polygon_patch()
{
	int prim_id = get_prim_id();
#if defined(SHADER_NEED_FOR_PRIMDATA)
	PrimData primDat = get_prim_data(prim_id);
#endif

#if defined(SHADER_BARYCENTRICS)
	gs_out.edges = /*(1u << 2u) | (1u << 1u) |*/ (1u << 0u);
#endif

	OUTPUT_BARYCENTRIC(0.0, 0.0);
	OUTPUT_SMOOTH_NORMALS(0);
	OUTPUT_TEX_TOP(0);
	OUTPUT_TEX_BOTTOM(0);
	OUTPUT_BLUR_VELOCITY(0);
	OUTPUT_TEX_COORDS(0);
	OUTPUT_NODAL_NORMALS(0);
	OUTPUT_NODAL_COLOR(0);
	OUTPUT_CLIP_VERTEX(0);
	OUTPUT_LICDATA(0);
	OUTPUT_POSITION(0);
	EmitVertex();

	OUTPUT_BARYCENTRIC(0.0, 1.0);
	OUTPUT_SMOOTH_NORMALS(1);
	OUTPUT_TEX_TOP(1);
	OUTPUT_TEX_BOTTOM(1);
	OUTPUT_BLUR_VELOCITY(1);
	OUTPUT_TEX_COORDS(1);
	OUTPUT_NODAL_NORMALS(1);
	OUTPUT_NODAL_COLOR(1);
	OUTPUT_CLIP_VERTEX(1);
	OUTPUT_LICDATA(1);
	OUTPUT_POSITION(1);
	EmitVertex();
	
	OUTPUT_BARYCENTRIC(1.0, 0.0);
	OUTPUT_SMOOTH_NORMALS(3);
	OUTPUT_TEX_TOP(3);
	OUTPUT_TEX_BOTTOM(3);
#if defined(SHADER_USE_BLUR)
	{
		CENT_AVG(vec3, gs_in, .velocity_color, center);
		gs_out.velocity_color = center;
	}
#endif
#if defined(SHADER_USE_TEX_COORDS)
	{
		CENT_AVG(vec2, gs_in, .tex_coords, center);
		gs_out.tex_coords = center;
	}
#endif
#if defined(SHADER_USE_NODAL_NORMALS)
	{
		vec3 v3 = get_normal_uncompress_view_space(gs_in[3].nodal_normals); 
		vec3 v4 = get_normal_uncompress_view_space(gs_in[4].nodal_normals); 
		vec3 v5 = get_normal_uncompress_view_space(gs_in[5].nodal_normals); 
		vec3 center = mix(mix(v3, v5, 0.5), v4, 0.25);
		//CENT_AVG(vec3, get_normal_uncompress_view_space(gs_in, .nodal_normals), center);
		gs_out.nodal_normals = normalize(center);
	}
#endif
#if defined(SHADER_USE_NODAL_COLOR) 
	{
		// is this really needed?
		CENT_AVG(vec4, gs_in, .nodal_color, center);
		gs_out.nodal_color = center;
	}
#endif
#if defined(SHADER_CLIP)
	{
		CENT_AVG(vec3, gs_in, .view_pos, center);
		output_clip_vertex(vec4(center, 1.0), pid_uniforms.clip);
	}
#endif

#if defined(SHADER_LIC_OVERLAY) && defined(SHADER_LIC_LAY_COMPOSE)
	CENT_AVG(vec3, gs_in, .vectors, vectors);
	CENT_AVG(vec3, gs_in, .vr_Orient, vr_Orient);
	CENT_AVG(vec3, gs_in, .view_pos, view_pos);
	OUTPUT_LICDATA_EXT(primDat.tangVec[3], vectors, primDat.vr_srcWt[3], vr_Orient, primDat.vr_mul_layWt[3], view_pos, primDat.modNormal[3]);
#elif defined(SHADER_LIC_SCREEN_SPACE)
	CENT_AVG(vec3, gs_in, .vectors, vectors);
	OUTPUT_LICDATA_EXT(primDat.tangVec[3], vectors, primDat.scrVec[3]);
#endif

	vec4 cpos = mix(gl_in[3].gl_Position, gl_in[5].gl_Position, 0.5);
	cpos = mix(cpos, gl_in[4].gl_Position, 0.25);
	gl_Position = cpos;
#if defined(SHADER_SINGLE_PASS_STEREO) 
	vec4 sec_cpos = mix(gl_in[3].gl_SecondaryPositionNV, gl_in[5].gl_SecondaryPositionNV, 0.5);
	sec_cpos = mix(sec_cpos, gl_in[4].gl_SecondaryPositionNV, 0.25);
	gl_SecondaryPositionNV = sec_cpos;
	gl_Layer = 0;
#endif
	EmitVertex();

	OUTPUT_BARYCENTRIC(0.0, 0.0);
	OUTPUT_SMOOTH_NORMALS(2);
	OUTPUT_TEX_TOP(2);
	OUTPUT_TEX_BOTTOM(2);
	OUTPUT_BLUR_VELOCITY(2);
	OUTPUT_TEX_COORDS(2);
	OUTPUT_NODAL_NORMALS(2);
	OUTPUT_NODAL_COLOR(2);
	OUTPUT_CLIP_VERTEX(2);
	OUTPUT_LICDATA(2);
	OUTPUT_POSITION(2);
	EmitVertex();
}
#endif


#if defined(SHADER_TRIA3) && defined(SHADER_ONLY_WIRE)
void output_wire_tria3()
{
#if defined(SHADER_ONLY_WIRE) && defined(SHADER_TWO_SIDE)
	float area = calc_area( gl_in[0].gl_Position, gl_in[1].gl_Position, gl_in[2].gl_Position );
#endif
#if defined(SHADER_FRINGE_NODE)
    gs_out.tex_top = compute_tex_coords(gs_in[0].fringe_node_top);
#endif
	OUTPUT_CLIP_VERTEX(0);
	OUTPUT_POSITION(0); 
	OUTPUT_AREA(0);
	EmitVertex();

#if defined(SHADER_FRINGE_NODE)
    gs_out.tex_top = compute_tex_coords(gs_in[1].fringe_node_top);
#endif
	OUTPUT_CLIP_VERTEX(1);
	OUTPUT_POSITION(1);
	OUTPUT_AREA(1);
	EmitVertex();

#if defined(SHADER_FRINGE_NODE)
    gs_out.tex_top = compute_tex_coords(gs_in[2].fringe_node_top);
#endif
	OUTPUT_CLIP_VERTEX(2);
	OUTPUT_POSITION(2);
	OUTPUT_AREA(2);
	EmitVertex();

#if defined(SHADER_FRINGE_NODE)
    gs_out.tex_top = compute_tex_coords(gs_in[0].fringe_node_top);
#endif
    OUTPUT_CLIP_VERTEX(0);
	OUTPUT_POSITION(0);
	OUTPUT_AREA(0);
	EmitVertex();
}
#endif

#if defined(SHADER_QUAD4) && defined(SHADER_ONLY_WIRE)
void output_wire_quad4()
{
#if defined(SHADER_ONLY_WIRE) && defined(SHADER_TWO_SIDE)
	float area = calc_area( gl_in[0].gl_Position, gl_in[1].gl_Position, gl_in[2].gl_Position );
#endif
#if defined(SHADER_FRINGE_NODE)
    gs_out.tex_top = compute_tex_coords(gs_in[0].fringe_node_top);
#endif
	OUTPUT_CLIP_VERTEX(0);
	OUTPUT_POSITION(0);
	OUTPUT_AREA(0);
	EmitVertex();

#if defined(SHADER_FRINGE_NODE)
    gs_out.tex_top = compute_tex_coords(gs_in[1].fringe_node_top);
#endif
	OUTPUT_CLIP_VERTEX(1);
	OUTPUT_POSITION(1);
	OUTPUT_AREA(1);
	EmitVertex();

#if defined(SHADER_FRINGE_NODE)
    gs_out.tex_top = compute_tex_coords(gs_in[2].fringe_node_top);
#endif
    OUTPUT_CLIP_VERTEX(2);
	OUTPUT_POSITION(2);
	OUTPUT_AREA(2);
	EmitVertex();

#if defined(SHADER_FRINGE_NODE)
    gs_out.tex_top = compute_tex_coords(gs_in[3].fringe_node_top);
#endif
	OUTPUT_CLIP_VERTEX(3);
	OUTPUT_POSITION(3);
	OUTPUT_AREA(3);
	EmitVertex();

#if defined(SHADER_FRINGE_NODE)
    gs_out.tex_top = compute_tex_coords(gs_in[0].fringe_node_top);
#endif
	OUTPUT_CLIP_VERTEX(0);
	OUTPUT_POSITION(0);
	OUTPUT_AREA(0);
	EmitVertex();
}
#endif

#if defined(SHADER_TRIA6) && defined(SHADER_ONLY_WIRE)
void output_wire_tria6()
{
#if defined(SHADER_ONLY_WIRE) && defined(SHADER_TWO_SIDE)
	float area = calc_area( gl_in[0].gl_Position, gl_in[1].gl_Position, gl_in[2].gl_Position );
#endif
#if defined(SHADER_FRINGE_NODE)
    gs_out.tex_top = compute_tex_coords(gs_in[0].fringe_node_top);
#endif
	OUTPUT_CLIP_VERTEX(0);
	OUTPUT_POSITION(0);
	OUTPUT_AREA(0);
	EmitVertex();

#if defined(SHADER_FRINGE_NODE)
    gs_out.tex_top = compute_tex_coords(gs_in[3].fringe_node_top);
#endif
	OUTPUT_CLIP_VERTEX(3);
	OUTPUT_POSITION(3);
	OUTPUT_AREA(3);
	EmitVertex();

#if defined(SHADER_FRINGE_NODE)
    gs_out.tex_top = compute_tex_coords(gs_in[1].fringe_node_top);
#endif
	OUTPUT_CLIP_VERTEX(1);
	OUTPUT_POSITION(1);
	OUTPUT_AREA(1);
	EmitVertex();

#if defined(SHADER_FRINGE_NODE)
    gs_out.tex_top = compute_tex_coords(gs_in[4].fringe_node_top);
#endif
	OUTPUT_CLIP_VERTEX(4);
	OUTPUT_POSITION(4);
	OUTPUT_AREA(4);
	EmitVertex();

#if defined(SHADER_FRINGE_NODE)
    gs_out.tex_top = compute_tex_coords(gs_in[2].fringe_node_top);
#endif
	OUTPUT_CLIP_VERTEX(2);
	OUTPUT_POSITION(2);
	OUTPUT_AREA(2);
	EmitVertex();

#if defined(SHADER_FRINGE_NODE)
    gs_out.tex_top = compute_tex_coords(gs_in[5].fringe_node_top);
#endif
	OUTPUT_CLIP_VERTEX(5);
	OUTPUT_POSITION(5);
	OUTPUT_AREA(5);
	EmitVertex();

#if defined(SHADER_FRINGE_NODE)
    gs_out.tex_top = compute_tex_coords(gs_in[0].fringe_node_top);
#endif
	OUTPUT_CLIP_VERTEX(0);
	OUTPUT_POSITION(0);
	OUTPUT_AREA(0);
	EmitVertex();

	EndPrimitive();
}
#endif

#if defined(SHADER_QUAD8) && defined(SHADER_ONLY_WIRE)
void output_wire_quad8()
{
#if defined(SHADER_ONLY_WIRE) && defined(SHADER_TWO_SIDE)
	float area = calc_area( gl_in[0].gl_Position, gl_in[1].gl_Position, gl_in[2].gl_Position );
#endif
#if defined(SHADER_FRINGE_NODE)
    gs_out.tex_top = compute_tex_coords(gs_in[1].fringe_node_top);
#endif
	OUTPUT_CLIP_VERTEX(1);
	OUTPUT_POSITION(1);
	OUTPUT_AREA(1);
	EmitVertex();

#if defined(SHADER_FRINGE_NODE)
    gs_out.tex_top = compute_tex_coords(gs_in[0].fringe_node_top);
#endif
	OUTPUT_CLIP_VERTEX(0);
	OUTPUT_POSITION(0);
	OUTPUT_AREA(0);
	EmitVertex();

#if defined(SHADER_FRINGE_NODE)
    gs_out.tex_top = compute_tex_coords(gs_in[2].fringe_node_top);
#endif
	OUTPUT_CLIP_VERTEX(2);
	OUTPUT_POSITION(2);
	OUTPUT_AREA(2);
	EmitVertex();

#if defined(SHADER_FRINGE_NODE)
    gs_out.tex_top = compute_tex_coords(gs_in[4].fringe_node_top);
#endif
	OUTPUT_CLIP_VERTEX(4);
	OUTPUT_POSITION(4);
	OUTPUT_AREA(4);
	EmitVertex();

#if defined(SHADER_FRINGE_NODE)
    gs_out.tex_top = compute_tex_coords(gs_in[3].fringe_node_top);
#endif
	OUTPUT_CLIP_VERTEX(3);
	OUTPUT_POSITION(3);
	OUTPUT_AREA(3);
	EmitVertex();

	EndPrimitive();
}
#endif

#if defined(SHADER_POLYGON) && defined(SHADER_ONLY_WIRE)
void output_wire_polygon_patch()
{
#if defined(SHADER_ONLY_WIRE) && defined(SHADER_TWO_SIDE)
	float area = calc_area( gl_in[3].gl_Position, gl_in[4].gl_Position, gl_in[5].gl_Position );
#endif
#if defined(SHADER_FRINGE_NODE)
    gs_out.tex_top = compute_tex_coords(gs_in[0].fringe_node_top);
#endif
	OUTPUT_CLIP_VERTEX(0);
	OUTPUT_POSITION(0);
	OUTPUT_AREA(0);
	EmitVertex();

#if defined(SHADER_FRINGE_NODE)
    gs_out.tex_top = compute_tex_coords(gs_in[1].fringe_node_top);
#endif
	OUTPUT_CLIP_VERTEX(1);
	OUTPUT_POSITION(1);
	OUTPUT_AREA(1);
	EmitVertex();

#if defined(SHADER_FRINGE_NODE)
    gs_out.tex_top = compute_tex_coords(gs_in[2].fringe_node_top);
#endif
	OUTPUT_CLIP_VERTEX(2);
	OUTPUT_POSITION(2);
	OUTPUT_AREA(2);
	EmitVertex();
}
#endif


void main(void)
{
    int prim_id = get_prim_id();
#if defined(SHADER_VISIBILITY_VARIANCE)
    uint vis = texelFetch(elem_visibility, prim_id).r;
    if (vis == 0u) return;
#endif

#if !defined(SHADER_SMOOTH_NORMALS)
	vec3 normal = get_prim_flat_normal();
	mat4 exp = globals.tr_iview_matrix * pid_uniforms.explode_matrix;
    normal = normalize(exp * vec4(normal, 0.0)).xyz;
	gs_out.flat_normal = pack_snorm_4x8(vec4(normal, 0.0));
#else // SHADER_SMOOTH_NORMALS
	vec3 normal = vec3( 0.0, 0.0, 1.0 );
#endif // END SHADER_SMOOTH_NORMALS

#if defined(SHADER_COLOR_VARIANCE) && !defined(SHADER_COLOR_VARIANCE_2_SIDE)
#if !defined(SHADER_EXTRA_ELEMENTS)
    vec4 variable_color = texelFetch(elem_var_color, prim_id);
#else
	vec4 variable_color = gs_in[0].variable_color;
#endif
    variable_color = all(equal(variable_color, vec4(0.0))) ? pid_uniforms.material_data.diffuse : variable_color;

#if defined(SHADER_OIT) 
    if (variable_color.a == 1.0) return;
#else
    if (variable_color.a != 1.0) return;
#endif
    gs_out.var_color = pack_unorm_4x8(variable_color);
#endif

#if defined(SHADER_COLOR_VARIANCE) && defined(SHADER_COLOR_VARIANCE_2_SIDE)
#if defined(SHADER_OIT)
	bool transp_pass = true;
#else 
	bool transp_pass = false;
#endif
    vec4 variable_color = texelFetch(elem_var_color, prim_id);
	uint packed_var_color = pack_unorm_4x8(variable_color);
	if ((packed_var_color & 0x0000ffffu) > 0u) { // not inactive part, not transparent
		if (transp_pass) return;
	} else if (packed_var_color > 0u) { // not inactive part but transparent 
		if (!transp_pass) return;
	} else {
		if (!transp_pass) return;
	}
    gs_out.var_color = packed_var_color;
#endif

#if defined(SHADER_MULTI_DRAW_INDIRECT)
	gs_out.part_idx = gs_in[0].part_idx;
#endif

#if defined(SHADER_FILL) 
	#if defined(SHADER_THICK_SHELLS)
		#if defined(SHADER_TWO_SIDE) || defined(SHADER_FRINGE_BOTTOM)
			#if defined(SHADER_TRIA3)
			    output_tria3_thick_two_side(normal);
			#elif defined(SHADER_QUAD4)
			    output_quad4_thick_two_side(normal);
			#elif defined(SHADER_TRIA6)
			    output_tria6_thick_two_side(normal);
			#elif defined(SHADER_QUAD8)
			    output_quad8_thick_two_side(normal);
			#endif
		#else
			#if defined(SHADER_TRIA3)
			    output_tria3_thick(normal);
			#elif defined(SHADER_QUAD4)
			    output_quad4_thick(normal);
			#elif defined(SHADER_TRIA6)
			    output_tria6_thick(normal);
			#elif defined(SHADER_QUAD8)
			    output_quad8_thick(normal);
			#endif
		#endif
	#else
		#if defined(SHADER_TRIA3)
		    output_tria3();
		#elif defined(SHADER_QUAD4)
		    output_quad4();
		#elif defined(SHADER_TRIA6)
		    output_tria6();
		#elif defined(SHADER_QUAD8)
		    output_quad8();
		#elif defined(SHADER_POLYGON)
			output_polygon_patch();
		#endif
	#endif
#elif defined(SHADER_WIRE)	
	#if defined(SHADER_THICK_SHELLS)
		#if defined(SHADER_TRIA3) && !defined(SHADER_POLYGON)
		    output_wire_tria3_thick();
		#elif defined(SHADER_QUAD4)
		    output_wire_quad4_thick();
		#elif defined(SHADER_TRIA6)
		    output_wire_tria6_thick();
		#elif defined(SHADER_QUAD8)
		    output_wire_quad8_thick();
		#endif
	#else
		#if defined(SHADER_TRIA3)
		    output_wire_tria3();
		#elif defined(SHADER_POLYGON)
		    output_wire_polygon_patch();
		#elif defined(SHADER_QUAD4)
		    output_wire_quad4();
		#elif defined(SHADER_TRIA6)
		    output_wire_tria6();
		#elif defined(SHADER_QUAD8)
		    output_wire_quad8();
		#elif defined(SHADER_POLYGON)
			output_wire_polygon_patch();
		#endif
	#endif
#endif
}

