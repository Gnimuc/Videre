## Temporary Test Code ##

GLfloat vertices[] = {
    // Positions    // Colors
     0.5f, -0.5f,   1.0f, 0.0f, 0.0f,   // Bottom Right
    -0.5f, -0.5f,   0.0f, 1.0f, 0.0f,   // Bottom Left
     0.0f,  0.5f,   0.0f, 0.0f, 1.0f    // Top
};



# the 1st way
GLuint buffer
glGenBuffers(1, &buffer)
glBindBuffer(GL_ARRAY_BUFFER, buffer)
glBufferData(GL_ARRAY_BUFFER, 1024 * 1024, NULL, GL_STATIC_DRAW)

# the 2nd way
const float data[] =
    {
         0.25, -0.25, 0.5, 1.0,
        -0.25, -0.25, 0.5, 1.0,
         0.25,  0.25, 0.5, 1.0
    }
glBufferSubData(GL_ARRAY_BUFFER, 0, sizeof(data), data);


# the 3rd way
static const float data[] =
    {
         0.25, -0.25, 0.5, 1.0,
        -0.25, -0.25, 0.5, 1.0,
         0.25,  0.25, 0.5, 1.0
    };
void * ptr = glMapBuffer(GL_ARRAY_BUFFER, GL_WRITE_ONLY);
memcpy(ptr, data, sizeof(data));
glUnmapBuffer(GL_ARRAY_BUFFER);
