## Cube ♡ ##
#=
Code Style: cumbersome
Functionality: to draw our rotating cube
Usage: see CubeCum.jl

More Details:
→ use perspective projection ∮
→ use glDrawElements() ∮

=#


# Note that you must create a OpenGL context before running these code.
# and make sure that your context version is matching those in VertexShader.jl and FragmentShader.jl.

# set up viewport
glViewport(0, 0, WIDTH, HEIGHT)
# set up culling
glEnable(GL_CULL_FACE)

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

# Data #
# cube
position = GLfloat[ -0.25, -0.25, -0.25,
                    -0.25,  0.25, -0.25,
                     0.25, -0.25, -0.25,
                     0.25,  0.25, -0.25,
                     0.25, -0.25,  0.25,
                     0.25,  0.25,  0.25,
                    -0.25, -0.25,  0.25,
                    -0.25,  0.25,  0.25 ]

cubeindices = GLushort[ 0, 1, 2,
                        2, 1, 3,
                        2, 3, 4,
                        4, 3, 5,
                        4, 5, 6,
                        6, 5, 7,
                        6, 7, 0,
                        0, 7, 1,
                        6, 0, 2,
                        2, 4, 6,
                        7, 5, 3,
                        7, 3, 1 ]

# VBO #
# generate buffer
buffer = GLuint[0]
glGenBuffers(1, pointer(buffer) )
# pass offset to buffer 1
glBindBuffer(GL_ARRAY_BUFFER, buffer[1] )
glBufferData(GL_ARRAY_BUFFER, sizeof(position), position, GL_STATIC_DRAW)

indexbuffer = GLuint[0]
glGenBuffers(1, pointer(indexbuffer) )
# pass offset to buffer 1
glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexbuffer[1] )
glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(cubeindices), cubeindices, GL_STATIC_DRAW)

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
  # transformations
  include("./transform/Matrix.jl")
  modelViewMatrix = translation * rotation
  projectionMatrix = perspective    # ∮
  modelViewLocation = glGetUniformLocation(shaderProgram, "modelViewMatrix")
  projectionLocation = glGetUniformLocation(shaderProgram, "projectionMatrix")
  glUniformMatrix4fv(modelViewLocation, 1, GL_FALSE, modelViewMatrix)
  glUniformMatrix4fv(projectionLocation, 1, GL_FALSE, projectionMatrix)
  # draw elements
  glUseProgram(shaderProgram)
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexbuffer[1])
  glDrawElements(GL_TRIANGLES, 36, GL_UNSIGNED_SHORT, 0)    # ∮
  # swap the buffers
  GLFW.SwapBuffers(window)
end
# Clean up and Terminate #
glDeleteShader(vertexShader)
glDeleteShader(fragmentShader)
glDeleteProgram(shaderProgram)
glDeleteBuffers(1, buffer)
glDeleteBuffers(1, indexbuffer)
glDeleteVertexArrays(1, VAO)
