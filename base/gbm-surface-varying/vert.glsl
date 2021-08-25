#version 430

in vec3 positionIn;
in vec3 colorIn;

centroid out vec2 color_rg;
out float color_b;

void main()
{
    gl_Position = vec4(positionIn, 1);
    color_rg = colorIn.rg;
    color_b = colorIn.b;
}