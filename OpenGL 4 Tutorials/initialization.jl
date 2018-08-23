using GLFW
using ModernGL

GLFW.Init()

# set up OpenGL context version
# it seems OpenGL 4.1 is the highest version supported by MacOS.
@static if Sys.isapple()
    const VERSION_MAJOR = 4
    const VERSION_MINOR = 1
end

@static if Sys.isapple()
    GLFW.WindowHint(GLFW.CONTEXT_VERSION_MAJOR, VERSION_MAJOR)
    GLFW.WindowHint(GLFW.CONTEXT_VERSION_MINOR, VERSION_MINOR)
    GLFW.WindowHint(GLFW.OPENGL_PROFILE, GLFW.OPENGL_CORE_PROFILE)
    GLFW.WindowHint(GLFW.OPENGL_FORWARD_COMPAT, GL_TRUE)
else
    GLFW.DefaultWindowHints()
end

window = GLFW.CreateWindow(640, 480, "Initialization")
window == C_NULL && error("could not open window with GLFW3.")

GLFW.MakeContextCurrent(window)

# dump version info
renderer = unsafe_string(glGetString(GL_RENDERER))
version = unsafe_string(glGetString(GL_VERSION))
println("Renderder: ", renderer)
println("OpenGL version supported: ", version)
@assert parse(Float64, version[1:3]) >= 3.2 "OpenGL version must ≥ 3.2, Please upgrade your graphic driver."

GLFW.Terminate()
