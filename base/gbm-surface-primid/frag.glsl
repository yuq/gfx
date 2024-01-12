#version 330

out vec4 fragColor;

void main()
{
    float color = float(gl_PrimitiveID + 1) / 2.0;
    fragColor = vec4(color, 0, 0, 1);
}
