## Cube-Cumbersome ##
#=
This script only depends on two julia packages: GLFW.jl and ModernGL.jl.
You can install these two packages by running:
Pkg.update()
Pkg.add("GLFW")
Pkg.add("ModernGL")
and use Pkg.status() to checkout the current package status.
=#
# Deps #
using GLFW, ModernGL

# Constants #
const WIDTH = convert(GLuint, 800)
const HEIGHT = convert(GLuint, 600)
# Note that if you need to modify these two version numbers, you have to edit
# those in VertexShader.jl and FragmentShader.jl as well. You can find these two files in "pipeline/".
const VERSION_MAJOR = 3
const VERSION_MINOR = 3

# GLFW's Callbacks #
# key callbacks : press Esc to escape
function key_callback(window::GLFW.Window, key::Cint, scancode::Cint, action::Cint, mods::Cint)
    if (key == GLFW.KEY_ESCAPE && action == GLFW.PRESS)
        GLFW.SetWindowShouldClose(window, GL_TRUE)
    end
end

# Window Initialization #
GLFW.Init()
GLFW.WindowHint(GLFW.CONTEXT_VERSION_MAJOR, VERSION_MAJOR)
GLFW.WindowHint(GLFW.CONTEXT_VERSION_MINOR, VERSION_MINOR)
GLFW.WindowHint(GLFW.OPENGL_PROFILE, GLFW.OPENGL_CORE_PROFILE)
GLFW.WindowHint(GLFW.RESIZABLE, GL_FALSE)
# if you're running on Macintosh
@osx_only GLFW.WindowHint(GLFW.OPENGL_FORWARD_COMPAT, GL_TRUE)
# if that doesn't work, try to uncomment the code below and checkout your OpenGL context version
#GLFW.DefaultWindowHints()

# Create Window #
window = GLFW.CreateWindow(WIDTH, HEIGHT, "Videre", GLFW.NullMonitor, GLFW.NullWindow)
# set callbacks
GLFW.SetKeyCallback(window, key_callback)
# create OpenGL context
GLFW.MakeContextCurrent(window)
# show OpenGL version information
println(bytestring(glGetString(GL_RENDERER)))
println(bytestring(glGetString(GL_VENDOR)))
println(bytestring(glGetString(GL_VERSION)))
println(bytestring(glGetString(GL_SHADING_LANGUAGE_VERSION)))

# Choose one of the ♡  ♠  ♢  ♣ and uncomment the corresponding line #
# ♡ (\heartsuit)
include("CubeCumHeart.jl")
# ♠ (\spadesuit)
#include("CubeCumSpade.jl")
# ♢ (\clubsuit)
#include("CubeCumDiamond.jl")
# ♣ (\diamondsuit)
#include("CubeCumClub.jl")

# GLFW Terminating #
GLFW.Terminate()

