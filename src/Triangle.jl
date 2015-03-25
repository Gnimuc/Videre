# Deps #
using GLFW, ModernGL, GLAbstraction

# Load Source #
include("./pipeline/front-end stages/VertexShader.jl")
include("./pipeline/back-end stages/FragmentShader.jl")

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
vertexShaderSourceptr = convert(Ptr{GLchar}, pointer(vertexΔ))
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
fragmentShaderSourceptr = convert(Ptr{GLchar}, pointer(fragmentΔ))
fragmentShader = glCreateShader(GL_FRAGMENT_SHADER)
glShaderSource(fragmentShader, 1, convert(Ptr{Uint8}, pointer([fragmentShaderSourceptr])), C_NULL)
glCompileShader(fragmentShader)
# checkout compile status
glGetShaderiv(fragmentShader, GL_COMPILE_STATUS, pointer(success) )
if success[1] != 1
  println("Vertex shader compile failed.")
end

# Link Shaders #
shaderProgram = glCreateProgram()
glAttachShader(shaderProgram, vertexShader)
glAttachShader(shaderProgram, fragmentShader)
glLinkProgram(shaderProgram)

# VAO #
VAO = GLuint[0]
glGenVertexArrays(1,VAO)
glBindVertexArray(pointer(VAO))


#VBO
#VBO = GLuint[0]
#glGenBuffers(1, VBO)
#glBindBuffer(GL_ARRAY_BUFFER, pointer(VBO))
#glVertexAttribPointer(0, 4, GL_FLOAT, GL_FALSE, 0, C_NULL)
#glEnableVertexAttribArray(0)

# Loop #
while !GLFW.WindowShouldClose(window)
  # Check and call events
  GLFW.PollEvents()
  # Rendering commands here
  glClearColor(0.2, 0.5, 0.5, 1.0)
  glClear(GL_COLOR_BUFFER_BIT)
  # draw
  glUseProgram(shaderProgram)
  #glBindVertexArray(pointer(VAO))
  glDrawArrays(GL_TRIANGLES, 0, 3)
  #glBindVertexArray(0)
  # Swap the buffers
  GLFW.SwapBuffers(window)
end
# Terminate
glDeleteShader(vertexShader)
glDeleteShader(fragmentShader)
glDeleteProgram(shaderProgram)

GLFW.Terminate()











