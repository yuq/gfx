attribute vec3 positionIn;
attribute vec2 texIn;

varying vec2 texv;

void main()
{
    texv = texIn;
    gl_Position = vec4(positionIn, 1);
}
