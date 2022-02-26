#version 460 compatibility

layout(location=0) in vec3 positionIn;
layout(location=1) in int indexIn;

out int objIndex;

void main()
{
    objIndex = indexIn;
    gl_Position = vec4(positionIn, 1);
}