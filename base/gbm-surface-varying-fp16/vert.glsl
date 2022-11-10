attribute vec3 positionIn;
attribute vec4 colorIn;

varying mediump vec4 color;
varying mediump vec4 color2;

void main()
{
    gl_Position = vec4(positionIn, 1);
    color = colorIn / 2.0;
    color2 = colorIn / 4.0;
}