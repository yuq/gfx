#version 330

in vec3 positionIn;

void main()
{
    gl_Position = vec4(positionIn, 1);
}
