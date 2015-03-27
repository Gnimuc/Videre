## Vertex Shader ##
# In the pipeline, vertex shader is the second stage and the first programmable stage. #
# The first stage of the pipeline is vertex fetching/pulling which generates inputs to the vertex shader. #
# Vertex shader is the only mandatory in the pipeline, but in many cases, you have to write a fragment shader #

# Note that you may need to modify the version number(ex. 330 here) to fit your specific case.

# GLSL Strings #
vertexΔ =    """#version 330 core
                void main(void)
                {
                     const vec4 vertices[3] = vec4[3](vec4( 0.5, -0.5, 0, 1.0),
                                                      vec4(-0.5, 0.5, 0, 1.0),
                                                      vec4( 0.5, 0.5, 0, 1.0));
                     gl_Position = vertices[gl_VertexID];
                 }"""


vertexΔ2 =    """#version 330 core
                 // "offset" and "color" are two input vertex attributes
                 layout (location = 0) in vec4 offset;
                 layout (location = 1) in vec4 color;

                 // "vs_color" is an output that will be sent to the next shader stage
                 out vec4 vs_color;

                 void main(void)
                 {
                      const vec4 vertices[3] = vec4[3](vec4( 0.25, -0.25, 0.5, 1.0),
                                                       vec4(-0.25, -0.25, 0.5, 1.0),
                                                       vec4( 0.25, 0.25, 0.5, 1.0));
                      // Add "offset" to our hard-coded vertex position
                      gl_Position = vertices[gl_VertexID] + offset;
                      // Output a fixed value for vs_color
                      vs_color = color;
                 }"""

vertexΔ3 =    """#version 330 core
                 layout (location = 0) in vec4 offset;
                 layout (location = 1) in vec4 color;
                 // Declare VS_OUT as an output interface block out VS_OUT
                 out VS_OUT
                 {
                     vec4 color;    // Send color to the next stage
                 } Δ3out;

                 void main(void)
                 {
                      const vec4 vertices[3] = vec4[3](vec4( 0.25, -0.25, 0.5, 1.0),
                                                       vec4(-0.25, -0.25, 0.5, 1.0),
                                                       vec4( 0.25, 0.25, 0.5, 1.0));
                      // Add "offset" to our hard-coded vertex position
                      gl_Position = vertices[gl_VertexID] + offset;
                      // Output a fixed value for vs_color
                      Δ3out.color = color;
                 }"""

vertex★ =     """#version 330 core

                 layout (location = 0) in vec4 position;

                 void main(void)
                 {
                      gl_Position = position;
                 }"""
