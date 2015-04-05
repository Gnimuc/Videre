## Triangle ♠ ##
#=
Code Style: cumbersome
Functionality: to draw our lovely black triangle
Usage: see triangleCum.jl

=#

# Note that you must create a OpenGL context before running these code.

# set up viewport
glViewport(0, 0, WIDTH, HEIGHT)

# Vertex Shader #
include("./pipeline/front-end stages/vertex shading stage/VertexShader.jl")
vertexShaderSourceptr = convert(Ptr{GLchar}, pointer(triangle♠v))    # you can change shader source here
vertexShader = glCreateShader(GL_VERTEX_SHADER)
glShaderSource(vertexShader, 1, convert(Ptr{Uint8}, pointer([vertexShaderSourceptr])), C_NULL)
glCompileShader(vertexShader)
# checkout compile status
success = GLuint[0]
glGetShaderiv(vertexShader, GL_COMPILE_STATUS, pointer(success))
if success[1] != 1
  println("Vertex shader compile failed.")
end

# Fragment Shader #
include("./pipeline/back-end stages/fragment shading stage/FragmentShader.jl")
fragmentShaderSourceptr = convert(Ptr{GLchar}, pointer(triangle♠f))    # you can change shader source here
fragmentShader = glCreateShader(GL_FRAGMENT_SHADER)
glShaderSource(fragmentShader, 1, convert(Ptr{Uint8}, pointer([fragmentShaderSourceptr])), C_NULL)
glCompileShader(fragmentShader)
# checkout compile status
glGetShaderiv(fragmentShader, GL_COMPILE_STATUS, pointer(success) )
if success[1] != 1
  println("Fragment shader compile failed.")
end

# Link Shaders #
shaderProgram = glCreateProgram()
glAttachShader(shaderProgram, vertexShader)
glAttachShader(shaderProgram, fragmentShader)
glLinkProgram(shaderProgram)

# VAO #
VAO = GLuint[0]
glGenVertexArrays(1, convert(Ptr{GLuint}, pointer(VAO)) )
glBindVertexArray(VAO[1])

# Loop #
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
# Clean up and Terminate #
glDeleteShader(vertexShader)
glDeleteShader(fragmentShader)
glDeleteProgram(shaderProgram)
glDeleteVertexArrays(1, VAO)


