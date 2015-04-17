## Vertex Shading Stage ##
#=
:: mandatory
>> raw vertex data
   execute for each vertex
<< processed vertex data
=#

# Note that you may need to modify the version number(e.g. 410 here) to fit your specific case.

triangle♡v = """#version 410 core
                void main(void)
                {
                    const vec4 vertices[3] = vec4[3](vec4( 0.5, -0.5, 0.0, 1.0),
                                                     vec4( 0.0, 0.5, 0.0, 1.0),
                                                     vec4( -0.5, -0.5, 0.0, 1.0));
                    gl_Position = vertices[gl_VertexID];
                }"""

triangle♠v = """#version 410 core
                // 'in's
                // attributes
                layout (location = 0) in vec3 offset;
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
                                                      vec4( -0.5, -0.5, 0.0, 1.0));
                     gl_Position = vertices[gl_VertexID] + vec4(offset, 0.0);
                     trianglecolor.color = color;
                }"""

triangle♢v = """#version 410 core
                // 'in's
                // attributes
                layout (location = 0) in vec3 position;

                // uniforms
                uniform mat4 rotationMatrix;

                void main(void)
                {
                     gl_Position = rotationMatrix * vec4(position, 1.0);
                }"""
