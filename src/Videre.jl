## Videre ##
# deps #
using GLFW, ModernGL, GLAbstraction


include("./pipeline/front-end stages/VertexShader.jl")
include("./pipeline/back-end stages/FragmentShader.jl")

# Callbacks #
# Key callbacks : Press Esc to escape
function key_callback(window::GLFW.Window, key::Cint, scancode::Cint, action::Cint, mods::Cint)
    if (key == GLFW.KEY_ESCAPE && action == GLFW.PRESS)
        GLFW.SetWindowShouldClose(window, GL_TRUE)
    end
end

const WIDTH = convert(GLuint, 800)
const HEIGHT = convert(GLuint, 600)

# Window Initialization #
GLFW.Init()
GLFW.WindowHint(GLFW.CONTEXT_VERSION_MAJOR, 3)
GLFW.WindowHint(GLFW.CONTEXT_VERSION_MINOR, 3)
GLFW.WindowHint(GLFW.OPENGL_PROFILE, GLFW.OPENGL_CORE_PROFILE)
GLFW.WindowHint(GLFW.RESIZABLE, GL_FALSE)
# If using Macintosh
GLFW.WindowHint(GLFW.OPENGL_FORWARD_COMPAT, GL_TRUE)
# debug
GLFW.DefaultWindowHints()
## Create a window
window = GLFW.CreateWindow(WIDTH, HEIGHT, "Videre", GLFW.NullMonitor, GLFW.NullWindow)
GLFW.MakeContextCurrent(window)
GLFW.SetKeyCallback(window, key_callback)
glViewport(0, 0, WIDTH, HEIGHT)

## Testing ##

# vertex shader
vertexShaderSourceptr = convert(Ptr{GLchar}, pointer(vertexΔ))
vertexShader = glCreateShader(GL_VERTEX_SHADER)
glShaderSource(vertexShader, 1, convert(Ptr{Uint8}, pointer([vertexShaderSourceptr])), C_NULL)
glCompileShader(vertexShader)
success = GLuint[0]
infolog = GLchar[512]
glGetShaderiv(vertexShader, GL_COMPILE_STATUS, pointer(success))
success
# fragment shader
fragmentShaderSourceptr = convert(Ptr{GLchar}, pointer(fragmentΔ))
fragmentShader = glCreateShader(GL_FRAGMENT_SHADER)
glShaderSource(fragmentShader, 1, convert(Ptr{Uint8}, pointer([fragmentShaderSourceptr])), C_NULL)
glCompileShader(fragmentShader)
success = GLuint[0]
infolog = GLchar[512]
glGetShaderiv(fragmentShader, GL_COMPILE_STATUS, pointer(success) )

success

# link shaders
shaderProgram = glCreateProgram()
glAttachShader(shaderProgram, vertexShader)
glAttachShader(shaderProgram, fragmentShader)
glLinkProgram(shaderProgram)

# VAO
VAO = GLuint[0]
glGenVertexArrays(1,VAO)
glBindVertexArray(pointer(VAO))


#VBO
VBO = GLuint[0]
glGenBuffers(1, VBO)
glBindBuffer(GL_ARRAY_BUFFER, pointer(VBO))
glVertexAttribPointer(0, 4, GL_FLOAT, GL_FALSE, 0, C_NULL)
glEnableVertexAttribArray(0)

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









############ Scraps #############
color = GLfloat[0.5+0.1rand(), 0.5+0.1rand(), 0.5+0.1rand(), 1.0]
glClearBufferfv(GL_COLOR, 0, color)



## failed to find glVertexAttrib4fv in ModernGL.jl
glVertexAttrib4fv(0, attrib)
attrib = GLfloat[0.5sin(time()), 0.6cos(time()) ,0.0, 0.0]
ccall(@ModernGL.getFuncPointer("glVertexAttrib4fv"), Void, (GLuint, Ptr{GLfloat}), 0, attrib)
