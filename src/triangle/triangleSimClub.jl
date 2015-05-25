## Triangle ♣ ##
#=
Code Style: simplified
Functionality: to draw our fuzzy triangle
Usage: see triangleSim.jl

More Details:


=#

# Note that you must create a OpenGL context before running these code.

# set up viewport
glViewport(0, 0, WIDTH, HEIGHT)

# shader compiling #
source = readall("./src/triangle/pipeline/front-end stages/vertex shading stage/glsl/club.vert")
vertexShader = shadercompiler(source, GL_VERTEX_SHADER)
source = readall("./src/triangle/pipeline/back-end stages/fragment shading stage/glsl/club.frag")
fragmentShader = shadercompiler(source, GL_FRAGMENT_SHADER)

# shader linking #
shaderProgram = programer([vertexShader, fragmentShader])

# Data #
position = VertexData(GLfloat[0.5, -0.5, 0.0,
                              0.0, 0.5, 0.0,
                             -0.5, -0.5, 0.0], GL_FLOAT, 3, 0, C_NULL)

# VBO # ∮
positionbuffer = data2buffer(position, GL_ARRAY_BUFFER, GL_STATIC_DRAW)

# VAO # ∮
# offset ⇒ offsetbuffer ⇒ attribute index 0
# color ⇒ colorbuffer ⇒ attribute index 1
triangleVAO = buffer2attrib([positionbuffer], GLuint[0], VertexData[position])

# Uniform Blocks #
# need to wrap

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
glDeleteVertexArrays(1, triangleVAO)
glDeleteBuffers(1, positionbuffer)
