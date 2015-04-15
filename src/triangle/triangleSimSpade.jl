## Triangle ♠ ##
#=
Code Style: simplified
Functionality: to draw our colorful triangle
Usage: see triangleSim.jl

More Details:
← using shadercompiler() in triangleSim.jl ✓
← using programer() in triangleSim.jl ✓
→ define our own data type in Type.jl
→ using data2buffer() in triangleSim.jl
→ using data2buffer() in triangleSim.jl
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
#
offset = VertexData(GLfloat[0.5, 0.0, 0.0,
                            0.5, 0.0, 0.0,
                            0.5, 0.0, 0.0], GL_FLOAT, 3, 0, C_NULL)

color = VertexData(GLfloat[1.0, 0.0, 0.0, 1.0,
                           0.0, 1.0, 0.0, 1.0,
                           0.0, 0.0, 1.0, 1.0], GL_FLOAT, 4, 0, C_NULL)
offsetbuffer = data2buffer(offset, GL_ARRAY_BUFFER, GL_STATIC_DRAW)
colorbuffer = data2buffer(color, GL_ARRAY_BUFFER, GL_STATIC_DRAW)

# VAO #
triangleVAO = buffer2attrib([offsetbuffer, colorbuffer], GLuint[0, 1], [offset, color])

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
#glDeleteVertexArrays(1, offsetVAO)
#glDeleteVertexArrays(1, colorVAO)
glDeleteBuffers(1, offsetbuffer)
glDeleteBuffers(1, colorbuffer)
