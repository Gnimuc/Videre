#version 450 core
// uniform blocks
layout (binding = 0) uniform FuzzyTriangle
{
    vec4 InnerColor;
    vec4 OuterColor;
    float RadiusInner;
    float RadiusOuter;
};

// 'out's
out vec4 color;

void main(void)
{
    float dx = gl_FragCoord.x/800 - 0.5;
    float dy = gl_FragCoord.y/600 - 0.5;
    float dist = sqrt(dx*dx + dy*dy);
    color = mix( InnerColor, OuterColor, smoothstep( RadiusInner, RadiusOuter, dist));
}
