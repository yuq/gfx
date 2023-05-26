#version 430

layout(location = 0) in vec4 color_fs;

layout(location = 0) out vec4 fragColor;

void main() {
     fragColor = color_fs;
}
