## Vertex Shader ##
# In the pipeline, vertex shader is the second stage and the first programmable stage. #
# The first stage of the pipeline is vertex fetching/pulling which generates inputs to the vertex shader. #
# Vertex shader is the only mandatory in the pipeline #


# GLSL #
vertexGLSL = """#version 330 core
                // "offset" is an input vertex attribute
                layout (location = 0) in vec4 offset;
                void main(void)
                {
                     const vec4 vertices[3] = vec4[3](vec4( 0.25, -0.25, 0.5, 1.0),
                                                      vec4(-0.25, -0.25, 0.5, 1.0),
                                                      vec4( 0.25, 0.25, 0.5, 1.0));
                     // Add "offset" to our hard-coded vertex position
                     gl_Position = vertices[gl_VertexID] + offset;
                 }"""


vertexGLSL★ = """#version 330 core
                 // "offset" and "color" are input vertex attributes
                 layout (location = 0) in vec4 offset;
                 layout (location = 1) in vec4 color;
                 // "vs_color" is an output that will be sent to the next shader stage
                 out vec4 vs_color;

                 void main(void)
                 {
                      const vec4 vertices[3] = vec4[3](vec4( 0.25, -0.25, 0.5, 1.0),
                                                       vec4(-0.25, -0.25, 0.5, 1.0),
                                                       vec4( 0.25, 0.25, 0.5, 1.0));
                      // Add "offset" to our hard-coded vertex position gl_Position = vertices[gl_VertexID] + offset;
                      // Output a fixed value for vs_color
                      vs_color = color;
                 }"""

vertexGLSL★★ = """#version 330 core
                 // "offset" and "color" are input vertex attributes
                 layout (location = 0) in vec4 offset;
                 layout (location = 1) in vec4 color;
                 // Declare VS_OUT as an output interface block out VS_OUT
                 out VS_OUT
                 {
                     vec4 color    // Send color to the next stage
                 } this_out;

                 void main(void)
                 {
                      const vec4 vertices[3] = vec4[3](vec4( 0.25, -0.25, 0.5, 1.0),
                                                       vec4(-0.25, -0.25, 0.5, 1.0),
                                                       vec4( 0.25, 0.25, 0.5, 1.0));
                      // Add "offset" to our hard-coded vertex position gl_Position = vertices[gl_VertexID] + offset;
                      // Output a fixed value for vs_color
                      this_out = color;
                 }"""

vertexGLSL★★★ = """#version 330 core

                 layout (location = 0) in vec4 position;

                 void main(void)
                 {
                      gl_Position = position;
                 }"""





