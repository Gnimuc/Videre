## Triangle ♢ ##
#=
Code Style: simplified
Functionality: to draw our flipping triangle
Usage: see triangleSim.jl

More Details:
← using shadercompiler() in triangleSim.jl ✓
← using programer() in triangleSim.jl ✓
← define our own data type in Types.jl ✓
← using data2buffer() in triangleSim.jl ✓
← using buffer2attrib() in triangleSim.jl ✓

=#

# Note that you must create a OpenGL context before running these code.

# set up viewport
glViewport(0, 0, WIDTH, HEIGHT)

# shader compiling #
source = readall("./src/triangle/pipeline/front-end stages/vertex shading stage/glsl/diamond.vert")
vertexShader = shadercompiler(source, GL_VERTEX_SHADER)
source = readall("./src/triangle/pipeline/back-end stages/fragment shading stage/glsl/diamond.frag")
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

# loop #
while !GLFW.WindowShouldClose(window)
  # check and call events
  GLFW.PollEvents()
  # rendering commands here
  glClearColor(255/256, 250/256, 205/256, 1.0)
  glClear(GL_COLOR_BUFFER_BIT)
  # use uniforms to change color
  red = convert(GLfloat, (sin(time())/2) + 0.5)
  ϕ = pi*sin(time()/2)
  rotationY = GLfloat[ cos(ϕ) 0.0 -sin(ϕ) 0.0;
                          0.0 1.0     0.0 0.0;
                       sin(ϕ) 0.0  cos(ϕ) 0.0;
                          0.0 0.0     0.0 1.0 ]
  rotationMatrixLocation = glGetUniformLocation(shaderProgram, "rotationMatrix")
  ucolorLocation = glGetUniformLocation(shaderProgram, "ucolor")
  glUniformMatrix4fv(rotationMatrixLocation, 1, GL_FALSE, convert(Ptr{GLfloat}, pointer(rotationY)) )
  glUniform4f(ucolorLocation, red, 0.0, 0.0, 1.0)
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

