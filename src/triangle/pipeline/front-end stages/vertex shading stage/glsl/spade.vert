#version 410 core
// 'in's
// attributes
layout (location = 0) in vec4 offset;
layout (location = 1) in vec4 color;

// 'out's
// interface blocks
out TriangleColor
{
    vec4 color;
} trianglecolor;

void main(void)
{
    const vec4 vertices[3] = vec4[3](vec4( 0.5, -0.5, 0.0, 1.0),
                                     vec4( 0.0, 0.5, 0.0, 1.0),
                                     vec4( -0.5, -0.5, 0.0, 1.0)
                                     );
    gl_Position = vertices[gl_VertexID] + offset;
    trianglecolor.color = color;
}
