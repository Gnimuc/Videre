#version 410 core
// 'in's
// attributes
layout (location = 0) in vec3 offset;

void main(void)
{
    const vec4 vertices[3] = vec4[3](vec4( 0.5, -0.5, 0.0, 1.0),
                                     vec4( 0.0, 0.5, 0.0, 1.0),
                                     vec4( -0.5, -0.5, 0.0, 1.0));
    gl_Position = vertices[gl_VertexID] + vec4(offset, 0.0);
}
