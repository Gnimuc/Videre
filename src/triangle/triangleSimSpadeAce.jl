## Triangle ♠ ##
#=
Code Style: simplified
Functionality: to draw our colorful triangle
Usage: see triangleSim.jl

More Details:
← using shadercompiler() in triangleSim.jl ✓
← using programer() in triangleSim.jl ✓
→ using data2buffer() in triangleSim.jl
⅁ using glBindVertexBuffer(),glVertexAttribFormat() and glVertexAttribBinding() instead of glVertexAttribPointer().
  glVertexAttribPointer() acctually does two things:
    1.connecting buffer data to vertex attributes
    2.specify data format
  so, it's better to do these two things separately.

=#

# Note that you must create a OpenGL context before running these code.

# set up viewport
glViewport(0, 0, WIDTH, HEIGHT)

# shader compiling #
source = readall("./src/triangle/pipeline/front-end stages/vertex shading stage/glsl/spade.vert")
vertexShader = shadercompiler(source, GL_VERTEX_SHADER)
source = readall("./src/triangle/pipeline/back-end stages/fragment shading stage/glsl/spade.frag")
fragmentShader = shadercompiler(source, GL_FRAGMENT_SHADER)

# shader linking #
shaderProgram = programer([vertexShader, fragmentShader])

# data #
offset = GLfloat[0.5, 0.0, 0.0,
                 0.5, 0.0, 0.0,
                 0.5, 0.0, 0.0]

color = GLfloat[1.0, 0.0, 0.0, 1.0,
                0.0, 1.0, 0.0, 1.0,
                0.0, 0.0, 1.0, 1.0]
# pass data to buffer
offsetbuffer = data2buffer(offset, GL_ARRAY_BUFFER, GL_STATIC_DRAW)
colorbuffer = data2buffer(color, GL_ARRAY_BUFFER, GL_STATIC_DRAW)

# VAO #
# Note that this time we don't use glVertexAttribPointer() which is used in the cumbersome version
# of this script to connect buffer data to vertex attributes and specify data format.
VAO = GLuint[0]
glGenVertexArrays(1, convert(Ptr{GLuint}, pointer(VAO)) )
glBindVertexArray(VAO[1])
glEnableVertexAttribArray(0)
glEnableVertexAttribArray(1)

# bind buffer to the index within the vertex buffer binding point
glBindVertexBuffer(0, offsetbuffer, 0, 3*sizeof(GLfloat))
glBindVertexBuffer(1, colorbuffer, 0, 4*sizeof(GLfloat))

glVertexAttribFormat(0, 3, GL_FLOAT, GL_FALSE, 0)
glVertexAttribFormat(1, 4, GL_FLOAT, GL_FALSE, 0)

glVertexAttribBinding(0, 0)
glVertexAttribBinding(1, 1)

# loop #
while !GLFW.WindowShouldClose(window)
  # check and call events
  GLFW.PollEvents()
  # rendering commands here
  glClearColor(255/256, 250/256, 205/256, 1.0)
  glClear(GL_COLOR_BUFFER_BIT)
  # draw
  glUseProgram(shaderProgram)
  glDrawArrays(GL_TRIANGLES, 0, 3)
  # swap the buffers
  GLFW.SwapBuffers(window)
end

# clean up #
glDeleteShader(vertexShader)
glDeleteShader(fragmentShader)
glDeleteProgram(shaderProgram)
glDeleteVertexArrays(1, offsetVAO)
glDeleteVertexArrays(1, colorVAO)
glDeleteBuffers(1, offsetbuffer)
glDeleteBuffers(1, colorbuffer)
