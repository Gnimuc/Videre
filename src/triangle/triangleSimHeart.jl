## Triangle ♡ ##
#=
Code Style: simplified
Functionality: to draw our lovely red triangle
Usage: see triangleSim.jl

More Details:
→ shadercompiler
→ programer

=#

# Note that you must create a OpenGL context before running these code.

# functions #
function shadercompiler(shaderSource::ASCIIString, shaderType::GLenum)
    shaderSourceptr = convert(Ptr{GLchar}, pointer(shaderSource))
    shader = glCreateShader(shaderType)
    glShaderSource(shader, 1, convert(Ptr{Uint8}, pointer([shaderSourceptr])), C_NULL)
    glCompileShader(shader)
    return shader
end

function programer(vertexShader::GLuint, fragmentShader::GLuint)
    program = glCreateProgram()
    glAttachShader(program, vertexShader)
    glAttachShader(program, fragmentShader)
    glLinkProgram(program)
    return program
end

# set up viewport
glViewport(0, 0, WIDTH, HEIGHT)

# shader compiling #
# change working dir |you may need to edit this path, I currently don't know how to use a relative path in julia| #
cd("C:\\Users\\Administrator\\Desktop\\Videre\\src\\triangle")
source = readall("./pipeline/front-end stages/vertex shading stage/glsl/heart.vert")
vertexShader = shadercompiler(source, GL_VERTEX_SHADER)
source = readall("./pipeline/back-end stages/fragment shading stage/glsl/heart.frag")
fragmentShader = shadercompiler(source, GL_FRAGMENT_SHADER)

# shader linking #
shaderProgram = programer(vertexShader, fragmentShader)

# VAO #
VAO = GLuint[0]
glGenVertexArrays(1, convert(Ptr{GLuint}, pointer(VAO)) )
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
