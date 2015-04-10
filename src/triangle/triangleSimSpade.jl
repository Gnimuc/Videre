## Triangle ♠ ##
#=
Code Style: simplified
Functionality: to draw our colorful triangle
Usage: see triangleSim.jl

More Details:
← shadercompiler ✓
← programer ✓

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

# VBO #
offset = GLfloat[0.5, 0.0, 0.0, 0.0,
                 0.5, 0.0, 0.0, 0.0,
                 0.5, 0.0, 0.0, 0.0]

color = GLfloat[1.0, 0.0, 0.0, 1.0,
                0.0, 1.0, 0.0, 1.0,
                0.0, 0.0, 1.0, 1.0]
# generate two buffers
buffer = GLuint[0,0]
glGenBuffers(2, pointer(buffer) )
# pass offset to buffer 1
glBindBuffer(GL_ARRAY_BUFFER, buffer[1] )
glBufferData(GL_ARRAY_BUFFER, sizeof(offset), offset, GL_STATIC_DRAW)
# pass color to buffer 2
glBindBuffer(GL_ARRAY_BUFFER, buffer[2] )
glBufferData(GL_ARRAY_BUFFER, sizeof(color), color, GL_STATIC_DRAW)

# VAO #
VAO = GLuint[0]
glGenVertexArrays(1, convert(Ptr{GLuint}, pointer(VAO)) )
glBindVertexArray(VAO[1])
# connect buffer to vertex attributes
glBindBuffer(GL_ARRAY_BUFFER, buffer[1] )
glVertexAttribPointer(0, 4, GL_FLOAT, GL_FALSE, 0, C_NULL)
glEnableVertexAttribArray(0)
glBindBuffer(GL_ARRAY_BUFFER, buffer[2] )
glVertexAttribPointer(1, 4, GL_FLOAT, GL_FALSE, 0, C_NULL)
glEnableVertexAttribArray(1)

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
glDeleteVertexArrays(1, VAO)
glDeleteBuffers(2, buffer)
