attribute vec3 positionIn;
attribute vec2 uvIn;

varying vec2 texUV;

void main()
{
    gl_Position = vec4(positionIn, 1);
    texUV = uvIn;
}