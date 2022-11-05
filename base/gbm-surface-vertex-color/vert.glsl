attribute vec3 positionIn;
attribute vec3 colorIn;

void main()
{
    gl_FrontColor = vec4(colorIn, 1);
    gl_Position = vec4(positionIn, 1);
}