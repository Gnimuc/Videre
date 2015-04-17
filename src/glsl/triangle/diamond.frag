#version 450 core
// uniforms
// Default Block Uniform
uniform vec4 ucolor;

// 'out's
out vec4 color;

void main(void)
{
    color = ucolor;
}
