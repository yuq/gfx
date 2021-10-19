#version 120

uniform vec3 color_v;

attribute vec3 positionIn;

varying vec3 color;

void main()
{
    gl_Position = vec4(positionIn, 1);
    color = gl_LightSource[0].ambient.rgb;
}