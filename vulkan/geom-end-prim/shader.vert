#version 430

layout(location = 0) out int end_prim_offset;

void main()
{
    end_prim_offset = gl_VertexIndex;
}
