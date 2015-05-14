## Triangle ♡ ##
#=
Code Style: cumbersome
Functionality: to draw our lovely red triangle
GL Version: 330+
Usage: see triangleCum.jl

More Details:
→ use "hard-coded" vertex data in GLSL source code

=#

# Note that you must create a OpenGL context before running these code.
# and make sure that your context version is matching those in VertexShader.jl and FragmentShader.jl.

# set up viewport
glViewport(0, 0, WIDTH, HEIGHT)

# pipeline #
# vertex shading stage
include("./pipeline/front-end stages/vertex shading stage/VertexShader.jl")
vertexShaderSourceptr = pointer(triangle♡v)
vertexShader = glCreateShader(GL_VERTEX_SHADER)
glShaderSource(vertexShader, 1, Ref([vertexShaderSourceptr]), C_NULL)
glCompileShader(vertexShader)

# fragment shading stage
include("./pipeline/back-end stages/fragment shading stage/FragmentShader.jl")
fragmentShaderSourceptr = pointer(triangle♡f)
fragmentShader = glCreateShader(GL_FRAGMENT_SHADER)
glShaderSource(fragmentShader, 1, Ref([fragmentShaderSourceptr]), C_NULL)
glCompileShader(fragmentShader)

# link shaders #
shaderProgram = glCreateProgram()
glAttachShader(shaderProgram, vertexShader)
glAttachShader(shaderProgram, fragmentShader)
glLinkProgram(shaderProgram)

# VAO #
VAO = GLuint[0]
glGenVertexArrays(1, Ref(VAO))
glBindVertexArray(VAO[1])

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
