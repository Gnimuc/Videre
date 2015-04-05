## FragmentShader Shader ##
#=


=#

# Note that you may need to modify the version number(e.g. 330 here) to fit your specific case.

triangle♡f = """#version 330 core
                out vec4 color;
                void main(void)
                {
                    color = vec4(1.0, 0.0, 0.0, 1.0);
                }"""

triangle♠f = """#version 330 core
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
                }"""



