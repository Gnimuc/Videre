# load dependency packages
using GLFW, ModernGL

# set up OpenGL context version
const VERSION_MAJOR = 4
@windows_only const VERSION_MINOR = 4
@linux_only const VERSION_MINOR = 4
@osx_only const VERSION_MINOR = 1    # it seems OSX will stuck on OpenGL 4.1.

# initialize GLFW library, error check is already wrapped.
GLFW.Init()

# set up window creation hints
GLFW.WindowHint(GLFW.CONTEXT_VERSION_MAJOR, VERSION_MAJOR)
GLFW.WindowHint(GLFW.CONTEXT_VERSION_MINOR, VERSION_MINOR)
GLFW.WindowHint(GLFW.OPENGL_PROFILE, GLFW.OPENGL_CORE_PROFILE)
@osx_only GLFW.WindowHint(GLFW.OPENGL_FORWARD_COMPAT, GL_TRUE)

# create window
window = GLFW.CreateWindow(640, 480, "Initialization", GLFW.NullMonitor, GLFW.NullWindow)
if window == C_NULL
    println("error: GLFW window creating failed.")
    GLFW.Terminate()
end

# make current context
GLFW.MakeContextCurrent(window)

# get version info
renderer = bytestring(glGetString(GL_RENDERER))
version = bytestring(glGetString(GL_VERSION))
println("Renderder: ", renderer)
println("OpenGL version supported: ", version)

GLFW.Terminate()
