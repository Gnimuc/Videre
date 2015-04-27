#version 450 core
// 'in's
// attributes
layout (location = 0) in vec3 position;

void main(void)
{
    gl_Position = vec4(position, 1.0);
}
