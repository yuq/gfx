#version 430

#extension GL_ARB_sample_shading : enable

layout (location = 0) out vec4 out_color;
layout (rg32f, binding = 0) uniform writeonly mediump image2D img_out0;
layout (rg32f, binding = 1) uniform writeonly mediump image2D img_out1;

void main() {
     ivec2 pos = ivec2(floor(gl_FragCoord.xy));
     vec4 data = vec4(gl_SamplePosition, 0, 0);

     if (gl_SampleID == 0)
     	imageStore(img_out0, pos, data);
     else if (gl_SampleID == 1)
        imageStore(img_out1, pos, data);

     out_color = vec4(0.0, 0.0, 0.0, 0.0);
}
