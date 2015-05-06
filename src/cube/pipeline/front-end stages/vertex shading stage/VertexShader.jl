## Vertex Shading Stage ##
#=
:: mandatory
>> raw vertex data
   execute for each vertex
<< processed vertex data
=#

# Note that you may need to modify the version number(e.g. 410 here) to fit your specific case.

cube♡v = """#version 410 core
            // 'in's
            // attributes
            layout (location = 0) in vec4 position;

            // 'out's
            // interface blocks
            out CubeColor
            {
                vec4 color;
            } cubecolor;

            uniform mat4 mv_matrix;
            uniform mat4 proj_matrix;

            void main(void)
            {
                gl_Position = proj_matrix * mv_matrix * position;
                cubecolor.color = position * 2.0 + vec4(0.5, 0.5, 0.5, 0.0);
            }"""

