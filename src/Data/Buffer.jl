## Buffer ##
# Buffers are linear allocations of memory in OpenGL world. #
# We can use these buffers to store data. #

## Specify Data ##
# triangle
data★ = GLfloat[-0.5, -0.5, 0.5, 1.0,
                0.5, -0.5, 0.5, 1.0,
                0.0, 0.5, 0.5, 1.0]

# cube
dataΔ4 = GLfloat[ -0.25, 0.25, -0.25,
                  -0.25, -0.25, -0.25,
                   0.25, -0.25, -0.25,

                   0.25, -0.25, -0.25,
                   0.25, 0.25, -0.25,
                  -0.25, 0.25, -0.25,

                   0.25, -0.25, -0.25,
                   0.25, -0.25, 0.25,
                   0.25, 0.25, -0.25,

                   0.25, -0.25, 0.25,
                   0.25, 0.25, 0.25,
                   0.25, 0.25, -0.25,

                   0.25, -0.25, 0.25,
                  -0.25, -0.25, 0.25,
                   0.25, 0.25, 0.25,

                  -0.25, -0.25, 0.25,
                  -0.25, 0.25, 0.25,
                   0.25, 0.25, 0.25,

                  -0.25, -0.25, 0.25,
                  -0.25, -0.25, -0.25,
                  -0.25, 0.25, 0.25,

                  -0.25, -0.25, -0.25,
                  -0.25, 0.25, -0.25,
                  -0.25, 0.25, 0.25,

                  -0.25, -0.25, 0.25,
                   0.25, -0.25, 0.25,
                   0.25, -0.25, -0.25,

                   0.25, -0.25, -0.25,
                  -0.25, -0.25, -0.25,
                  -0.25, -0.25, 0.25,

                  -0.25, 0.25, -0.25,
                   0.25, 0.25, -0.25,
                   0.25, 0.25, 0.25,

                   0.25, 0.25, 0.25,
                  -0.25, 0.25, 0.25,
                  -0.25, 0.25, -0.25 ]

## Initialize Buffer ##
buffer = GLuint[0]
glGenBuffers(1, pointer(buffer) )
glBindBuffer(GL_ARRAY_BUFFER, buffer[1] )
glBufferData(GL_ARRAY_BUFFER, 1024*1024, C_NULL, GL_STATIC_DRAW)


# or copy data directly from memory
#ptr = glMapBuffer(GL_ARRAY_BUFFER, GL_WRITE_ONLY);
#unsafe_copy!(ptr, data, sizeof(data))
#glUnmapBuffer(GL_ARRAY_BUFFER);

# or use glClearBufferSubData() to put a constant value into the buffer
# or use glCopyBufferSubData() to copy data from a existed buffer






