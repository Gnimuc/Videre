#version 450 core
// 'in's
// attributes
layout (location = 0) in vec3 position;

// uniforms
uniform mat4 rotationMatrix;

void main(void)
{
    gl_Position = rotationMatrix * vec4(position, 1.0);
}
