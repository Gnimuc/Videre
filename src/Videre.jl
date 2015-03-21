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
attrib = GLfloat[0.5sin(time()), 0.6cos(time()) ,0.0, 0.0]

vertexShaderSourceptr = convert(Ptr{GLchar}, pointer(vertexGLSL))
vertexShader = glCreateShader(GL_VERTEX_SHADER)
glShaderSource(vertexShader, 1, convert(Ptr{Uint8}, pointer([vertexShaderSourceptr])), C_NULL)
glCompileShader(vertexShader)



# Loop #
while !GLFW.WindowShouldClose(window)
  # Check and call events
  GLFW.PollEvents()
  # Rendering commands here

  # draw

  # Swap the buffers
  GLFW.SwapBuffers(window)
end
# Terminate
GLFW.Terminate()









############ Scraps #############
color = GLfloat[0.5+0.1rand(), 0.5+0.1rand(), 0.5+0.1rand(), 1.0]
glClearBufferfv(GL_COLOR, 0, color)



## failed to find glVertexAttrib4fv in ModernGL.jl
glVertexAttrib4fv(0, attrib)
attrib = GLfloat[0.5sin(time()), 0.6cos(time()) ,0.0, 0.0]
ccall(@ModernGL.getFuncPointer("glVertexAttrib4fv"), Void, (GLuint, Ptr{GLfloat}), 0, attrib)
