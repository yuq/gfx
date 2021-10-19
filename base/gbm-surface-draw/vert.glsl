attribute vec3 positionIn;
attribute vec4 colorIn;

varying vec4 color;

void main()
{
    color = colorIn;
    gl_Position = vec4(positionIn, 1);
}