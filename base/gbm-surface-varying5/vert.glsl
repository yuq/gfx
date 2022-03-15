uniform float color_v;

attribute vec3 positionIn;

varying float color;

void main()
{
    gl_Position = vec4(positionIn, 1);
    color = color_v;
}
