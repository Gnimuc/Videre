## Cube ♡ ##
#=
Code Style: cumbersome
Functionality: to draw our rotating cube
Usage: see CubeCum.jl

=#


# Note that you must create a OpenGL context before running these code.
# and make sure that your context version is matching those in VertexShader.jl and FragmentShader.jl.

# set up viewport
glViewport(0, 0, WIDTH, HEIGHT)

# pipeline #
# vertex shading stage
include("./pipeline/front-end stages/vertex shading stage/VertexShader.jl")
vertexShaderSourceptr = convert(Ptr{GLchar}, pointer(cube♡v))
vertexShader = glCreateShader(GL_VERTEX_SHADER)
glShaderSource(vertexShader, 1, convert(Ptr{Uint8}, pointer([vertexShaderSourceptr])), C_NULL)
glCompileShader(vertexShader)
# checkout compile status
success = GLuint[0]
glGetShaderiv(vertexShader, GL_COMPILE_STATUS, pointer(success))
if success[1] != 1
  println("Vertex shader compile failed.")
end

# fragment shading stage
include("./pipeline/back-end stages/fragment shading stage/FragmentShader.jl")
fragmentShaderSourceptr = convert(Ptr{GLchar}, pointer(cube♡f))
fragmentShader = glCreateShader(GL_FRAGMENT_SHADER)
glShaderSource(fragmentShader, 1, convert(Ptr{Uint8}, pointer([fragmentShaderSourceptr])), C_NULL)
glCompileShader(fragmentShader)
# checkout compile status
glGetShaderiv(fragmentShader, GL_COMPILE_STATUS, pointer(success) )
if success[1] != 1
  println("Fragment shader compile failed.")
end

# link shaders #
shaderProgram = glCreateProgram()
glAttachShader(shaderProgram, vertexShader)
glAttachShader(shaderProgram, fragmentShader)
glLinkProgram(shaderProgram)

# Data Buffer #
# cube
position = GLfloat[ -0.25, 0.25, -0.25,
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

# VBO #
# generate buffer
buffer = GLuint[0]
glGenBuffers(1, pointer(buffer) )
# pass offset to buffer 1
glBindBuffer(GL_ARRAY_BUFFER, buffer[1] )
glBufferData(GL_ARRAY_BUFFER, sizeof(position), position, GL_STATIC_DRAW)

# Uniforms #
mv_location = glGetUniformLocation(shaderProgram, "mv_matrix")
proj_location = glGetUniformLocation(shaderProgram, "proj_matrix")

# VAO #
VAO = GLuint[0]
glGenVertexArrays(1, convert(Ptr{GLuint}, pointer(VAO)) )
glBindVertexArray(VAO[1])
# connect buffer to vertex attributes
glBindBuffer(GL_ARRAY_BUFFER, buffer[1] )
glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, C_NULL)
glEnableVertexAttribArray(0)

# Loop #
while !GLFW.WindowShouldClose(window)
  # check and call events
  GLFW.PollEvents()
  # rendering commands here
  glClearColor(0.0, 0.0, 0.0, 1.0)
  glClear(GL_COLOR_BUFFER_BIT)
  # draw
  # transformation
  # Transform #
  include("./transform/Matrix.jl")
  #mv_matrix = translation * rotation
  #proj_matrix = perspective

  mv_matrix = translation
  proj_matrix = rotation
  glUseProgram(shaderProgram)
  glUniformMatrix4fv(mv_location, 1, GL_FALSE, mv_matrix)
  glUniformMatrix4fv(proj_location, 1, GL_FALSE, proj_matrix)
  glDrawArrays(GL_TRIANGLES, 0, 36)
  # swap the buffers
  GLFW.SwapBuffers(window)
end
# Clean up and Terminate #
glDeleteShader(vertexShader)
glDeleteShader(fragmentShader)
glDeleteProgram(shaderProgram)
glDeleteBuffers(1, buffer)
glDeleteVertexArrays(1, VAO)
