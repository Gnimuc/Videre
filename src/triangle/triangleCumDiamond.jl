## Triangle ♢ ##
#=
Code Style: cumbersome
Functionality: to draw our lovely red triangle
Usage: see triangleCum.jl

More Details:
← use "hard-coded" vertex data in GLSL source code ×
← use interface blocks in GLSL source code ×
← use attributes in GLSL source code ✓
← return compile status ✓
→ use Default Block Uniform ∮

=#

# Note that you must create a OpenGL context before running these code.

# set up viewport
glViewport(0, 0, WIDTH, HEIGHT)

# pipeline #
# vertex shading stage
include("./pipeline/front-end stages/vertex shading stage/VertexShader.jl")
vertexShaderSourceptr = convert(Ptr{GLchar}, pointer(triangle♢v))
vertexShader = glCreateShader(GL_VERTEX_SHADER)
glShaderSource(vertexShader, 1, convert(Ptr{Uint8}, pointer([vertexShaderSourceptr])), C_NULL)
glCompileShader(vertexShader)
# checkout compile status ∮
success = GLuint[0]
glGetShaderiv(vertexShader, GL_COMPILE_STATUS, pointer(success))
if success[1] != 1
  println("Vertex shader compile failed.")
end

# fragment shading stage
include("./pipeline/back-end stages/fragment shading stage/FragmentShader.jl")
fragmentShaderSourceptr = convert(Ptr{GLchar}, pointer(triangle♢f))
fragmentShader = glCreateShader(GL_FRAGMENT_SHADER)
glShaderSource(fragmentShader, 1, convert(Ptr{Uint8}, pointer([fragmentShaderSourceptr])), C_NULL)
glCompileShader(fragmentShader)
# checkout compile status ∮
glGetShaderiv(fragmentShader, GL_COMPILE_STATUS, pointer(success) )
if success[1] != 1
  println("Fragment shader compile failed.")
end

# link shaders #
shaderProgram = glCreateProgram()
glAttachShader(shaderProgram, vertexShader)
glAttachShader(shaderProgram, fragmentShader)
glLinkProgram(shaderProgram)

# VBO #
offset = GLfloat[0.5, 0.0, 0.0, 0.0,
                 0.5, 0.0, 0.0, 0.0,
                 0.5, 0.0, 0.0, 0.0]

# generate two buffers
buffer = GLuint[0]
glGenBuffers(1, pointer(buffer) )
# pass offset to buffer 1
glBindBuffer(GL_ARRAY_BUFFER, buffer[1] )
glBufferData(GL_ARRAY_BUFFER, sizeof(offset), offset, GL_STATIC_DRAW)

# VAO #
VAO = GLuint[0]
glGenVertexArrays(1, convert(Ptr{GLuint}, pointer(VAO)) )
glBindVertexArray(VAO[1])
# connect buffer to vertex attributes
glBindBuffer(GL_ARRAY_BUFFER, buffer[1] )
glVertexAttribPointer(0, 4, GL_FLOAT, GL_FALSE, 0, C_NULL)
glEnableVertexAttribArray(0)

# loop #
while !GLFW.WindowShouldClose(window)
  # check and call events
  GLFW.PollEvents()
  # rendering commands here
  glClearColor(255/256, 250/256, 205/256, 1.0)
  glClear(GL_COLOR_BUFFER_BIT)
  # use uniforms to change color ∮
  red = convert(GLfloat, (sin(time())/2) + 0.5)
  ucolorLocation = glGetUniformLocation(shaderProgram, "ucolor")
  glUseProgram(shaderProgram)
  glUniform4f(ucolorLocation, red, 0.0, 0.0, 1.0)
  # draw
  glDrawArrays(GL_TRIANGLES, 0, 3)
  # swap the buffers
  GLFW.SwapBuffers(window)
end
# clean up #
glDeleteShader(vertexShader)
glDeleteShader(fragmentShader)
glDeleteProgram(shaderProgram)
glDeleteVertexArrays(1, VAO)
glDeleteBuffers(1, buffer)