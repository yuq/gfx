attribute vec3 positionIn;
attribute vec3 p2In;

void main()
{
    gl_Position = vec4(positionIn + p2In, 1);
}