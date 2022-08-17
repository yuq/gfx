#version 450 compatibility
in vec3 positionIn;
flat out dvec3 hhh;

void main()
{
    hhh = positionIn + 0.5;
    gl_Position = vec4(positionIn, 1);
}