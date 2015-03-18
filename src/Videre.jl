## Videre ##
# deps #
using GLFW, ModernGL, GLAbstraction

include("./pipeline/VertexShader.jl")

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
#GLFW.DefaultWindowHints()
## Create a window
window = GLFW.CreateWindow(WIDTH, HEIGHT, "Videre", GLFW.NullMonitor, GLFW.NullWindow)
GLFW.MakeContextCurrent(window)
GLFW.SetKeyCallback(window, key_callback)
glViewport(0, 0, WIDTH, HEIGHT)

## Testing ##



# Loop #
while !GLFW.WindowShouldClose(window)
  # Check and call events
  GLFW.PollEvents()
  # Rendering commands here
  color = GLfloat[0.5abs(sin(time())), 0.3abs(cos(time())), 1, 1.0]
  println(0.5abs(sin(time())))
  glClearBufferfv(GL_COLOR, 0, color)
  # draw

  # Swap the buffers
  GLFW.SwapBuffers(window)
end
# Terminate
GLFW.Terminate()









