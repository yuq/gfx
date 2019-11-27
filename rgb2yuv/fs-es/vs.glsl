#version 300 es

in vec3 positionIn;
in vec2 texcoordIn;

out vec2 texcoord;

void main()
{
    gl_Position = vec4(positionIn, 1);
    texcoord = texcoordIn;
}
