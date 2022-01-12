#version 430 compatibility

layout(location = 0) in vec3 positionIn;

out vec3 position;

void main()
{
    position = positionIn;
}
