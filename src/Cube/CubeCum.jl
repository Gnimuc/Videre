## Cube Cumbersome Δ ##




# Deps #
using GLFW, ModernGL

# Load Source #
include("../pipeline/front-end stages/VertexShader.jl")
include("../pipeline/back-end stages/FragmentShader.jl")

# Callbacks #
# key callbacks : press Esc to escape
function key_callback(window::GLFW.Window, key::Cint, scancode::Cint, action::Cint, mods::Cint)
    if (key == GLFW.KEY_ESCAPE && action == GLFW.PRESS)
        GLFW.SetWindowShouldClose(window, GL_TRUE)
    end
end

# Constants #
const WIDTH = convert(GLuint, 800)
const HEIGHT = convert(GLuint, 600)

# Window Initialization #
GLFW.Init()
#GLFW.WindowHint(GLFW.CONTEXT_VERSION_MAJOR, 3)
#GLFW.WindowHint(GLFW.CONTEXT_VERSION_MINOR, 3)
#GLFW.WindowHint(GLFW.OPENGL_PROFILE, GLFW.OPENGL_CORE_PROFILE)
#GLFW.WindowHint(GLFW.RESIZABLE, GL_FALSE)
# if using Macintosh
#GLFW.WindowHint(GLFW.OPENGL_FORWARD_COMPAT, GL_TRUE)
# debug
#GLFW.DefaultWindowHints()

# Create Window #
window = GLFW.CreateWindow(WIDTH, HEIGHT, "Videre", GLFW.NullMonitor, GLFW.NullWindow)
# create OpenGL context
GLFW.MakeContextCurrent(window)
# set up viewport
glViewport(0, 0, WIDTH, HEIGHT)
# set callbacks
GLFW.SetKeyCallback(window, key_callback)

# Vertex Shader #
vertexShaderSourceptr = convert(Ptr{GLchar}, pointer(vertexΔ4))
vertexShader = glCreateShader(GL_VERTEX_SHADER)
glShaderSource(vertexShader, 1, convert(Ptr{Uint8}, pointer([vertexShaderSourceptr])), C_NULL)
glCompileShader(vertexShader)
# checkout compile status
success = GLuint[0]
infoLog = GLchar[512]
glGetShaderiv(vertexShader, GL_COMPILE_STATUS, pointer(success))
if success[1] != 1
  println("Vertex shader compile failed.")
end

# Fragment Shader #
fragmentShaderSourceptr = convert(Ptr{GLchar}, pointer(fragmentΔ4))
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

# Data Buffer #
include("../data/Buffer.jl")
# pass data
glBufferSubData(GL_ARRAY_BUFFER, 0, sizeof(dataΔ4), dataΔ4)

# Uniforms #
mv_location = glGetUniformLocation(shaderProgram, "mv_matrix")
proj_location = glGetUniformLocation(shaderProgram, "proj_matrix")



# VAO #
VAO = GLuint[0]
glGenVertexArrays(1, convert(Ptr{GLuint}, pointer(VAO)) )
glBindVertexArray(VAO[1])
# set vertex attribute
glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, C_NULL)
glEnableVertexAttribArray(0)

# Loop #
while !GLFW.WindowShouldClose(window)
  # check and call events
  GLFW.PollEvents()
  # rendering commands here
  glClearColor(0.7, 0.4, 0.2, 1.0)
  glClear(GL_COLOR_BUFFER_BIT)
  # draw
  # transformation
  # Transform #
  include("../transform/Matrix.jl")
 # mv_matrix = translation * rotation
 # proj_matrix = perspective

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
GLFW.Terminate()

