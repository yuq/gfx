#version 430

uniform vec3 color_v[100];

in vec3 positionIn;

out vec3 color;

void main()
{
    int i;
    gl_Position = vec4(positionIn, 1);
    color = color_v[3];
    //color = vec3(0.1, 0.1, 0.1);
}