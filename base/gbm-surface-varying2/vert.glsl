#version 430

in vec3 positionIn;
in vec3 colorIn;

out vec3 color;
out vec3 color2;

void main()
{
    gl_Position = vec4(positionIn, 1);
    color = colorIn;
    color2 = colorIn * 0.5;
}