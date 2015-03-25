## Buffer ##
# Buffers are linear allocations of memory in OpenGL world. #
# We can use these buffers to store data. #

## Specify Data ##
data = GLfloat[-0.5, -0.5, 0.0, 1.0,
                0.5, -0.5, 0.0, 1.0,
                0.0, 0.5, 0.0, 1.0]

## Initialize Buffer ##
buffer = GLuint[0]
glGenBuffers(1, buffer)
glBindBuffer(GL_ARRAY_BUFFER, pointer(buffer) )
glBufferData(GL_ARRAY_BUFFER, 1024*1024, C_NULL, GL_STATIC_DRAW)

## Pass Data ##
glBufferSubData(GL_ARRAY_BUFFER, 0, sizeof(data), data)

# or copy data directly from memory
#ptr = glMapBuffer(GL_ARRAY_BUFFER, GL_WRITE_ONLY);
#unsafe_copy!(ptr, data, sizeof(data))
#glUnmapBuffer(GL_ARRAY_BUFFER);

# or use glClearBufferSubData() to put a constant value into the buffer
# or use glCopyBufferSubData() to copy data from a existed buffer






#GLfloat vertices[] = {
#    // Positions    // Colors
#     0.5f, -0.5f,   1.0f, 0.0f, 0.0f,   // Bottom Right
#    -0.5f, -0.5f,   0.0f, 1.0f, 0.0f,   // Bottom Left
#     0.0f,  0.5f,   0.0f, 0.0f, 1.0f    // Top
#};




