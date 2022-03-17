#version 460 compatibility

layout(location=0) in vec3 positionIn;
layout(location=1) in int indexIn;

out uint select_result_index;

void main()
{
    gl_Position = vec4(positionIn, 1);
    select_result_index = indexIn;
}