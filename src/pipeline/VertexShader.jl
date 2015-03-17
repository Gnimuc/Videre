## Vertex Shader ##
# In the pipeline, vertex shader is the second stage and the first programmable stage. #
# The first stage of the pipeline is vertex fetching/pulling which generate inputs to the vertex shader. #
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



