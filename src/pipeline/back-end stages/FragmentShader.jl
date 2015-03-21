## FragmentShader Shader ##







# GLSL #
fragmentGLSL★ = """#version 330 core
                  // Input from the vertex shader
                  in vec4 vs_color;

                  // Output to the framebuffer
                  out vec4 color;

                  void main(void)
                  {
                       // Simply assign the color we were given by the vertex shader
                       // to our output
                       color = vs_color;
                  }"""

fragmentGLSL★★ = """#version 330 core
                  // Declare VS_OUT as an input interface block
                  in VS_OUT
                  {
                     vec4 color; // Send color to the next stage
                  } fs_in;

                  // Output to the framebuffer
                  out vec4 color;

                  void main(void)
                  {
                       // Simply assign the color we were given by the vertex shader
                       // to our output
                       color = fs_in.color;
                  }"""

