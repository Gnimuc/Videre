## Tessellation Control Shader ##
# TODO：1.determination of the level of tessellation that will be sent to the tessellation engine
#       2.generation of data that will be sent to the tessellation evaluation shader
#

TcsGLSL = """#version 330 core
             layout (vertices = 3) out;

             void main(void)
             {
                 if (gl_InvocationID == 0)
                 {
                     gl_TessLevelInner[0] = 5.0;
                     gl_TessLevelOuter[0] = 5.0;
                     gl_TessLevelOuter[1] = 5.0;
                     gl_TessLevelOuter[2] = 5.0;
                 }
                 gl_out[gl_InvocationID].gl_Position = gl_in[gl_InvocationID].gl_Position;
             }"""





















