#version 450 core
// 'in's
// interface block
in TriangleColor
{
    vec4 color;
}trianglecolor;

// 'out's
out vec4 color;

void main(void)
{
    color = trianglecolor.color;
}
