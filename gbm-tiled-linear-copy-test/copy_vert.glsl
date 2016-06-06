attribute vec3 positionIn;
attribute vec2 texcoordIn;
varying vec2 texcoord;

void main()
{
    texcoord = texcoordIn;
    gl_Position = vec4(positionIn, 1);
}