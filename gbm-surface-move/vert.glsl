attribute vec3 positionIn;

uniform float scale;

void main()
{
    gl_Position = vec4(positionIn * scale, 1);
}