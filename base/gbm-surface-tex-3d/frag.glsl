#version 130

uniform sampler3D tex;
out vec4 fragColor;

void main()
{
    ivec2 pos = ivec2(floor(gl_FragCoord.xy));
    fragColor = texelFetch(tex, ivec3(pos, 0), 1);
}
