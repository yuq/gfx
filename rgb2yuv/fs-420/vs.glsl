#version 430
#extension GL_ARB_shader_viewport_layer_array : enable

in vec3 positionIn;
in vec2 texcoordIn;

out vec2 texcoord;

void main()
{
    gl_Position = vec4(positionIn, 1);
    texcoord = texcoordIn;
    gl_ViewportIndex = gl_InstanceID;
}
