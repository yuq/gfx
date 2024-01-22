#version 150
#extension GL_ARB_compute_shader: require
#extension GL_ARB_shader_atomic_counters: require
#extension GL_ARB_explicit_uniform_location: require

layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;
layout(binding = 0) uniform atomic_uint differences;
uniform sampler2D source;

void main() {
   ivec2 coord = ivec2(gl_GlobalInvocationID.xy);
   if (abs(texelFetch(source, coord, 0).r - 0.5) > 0.001f)
      atomicCounterIncrement(differences);
}
