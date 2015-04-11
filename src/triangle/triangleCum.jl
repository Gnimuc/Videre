## Triangle-Cumbersome ##
#=
This script only depends on GLFW.jl and ModernGL.jl. #
You can install these two packages by running:
Pkg.add("GLFW")
Pkg.add("ModernGL")
=#
# Deps #
using GLFW, ModernGL

# Constants #
const WIDTH = convert(GLuint, 800)
const HEIGHT = convert(GLuint, 600)

# GLFW's Callbacks #
# key callbacks : press Esc to escape
function key_callback(window::GLFW.Window, key::Cint, scancode::Cint, action::Cint, mods::Cint)
    if (key == GLFW.KEY_ESCAPE && action == GLFW.PRESS)
        GLFW.SetWindowShouldClose(window, GL_TRUE)
    end
end

# Window Initialization #
GLFW.Init()
GLFW.WindowHint(GLFW.CONTEXT_VERSION_MAJOR, 4)
GLFW.WindowHint(GLFW.CONTEXT_VERSION_MINOR, 1)
GLFW.WindowHint(GLFW.OPENGL_PROFILE, GLFW.OPENGL_CORE_PROFILE)
GLFW.WindowHint(GLFW.RESIZABLE, GL_FALSE)
# if using Macintosh
GLFW.WindowHint(GLFW.OPENGL_FORWARD_COMPAT, GL_TRUE)
# if that doesn't work, try to uncomment the code below
#GLFW.DefaultWindowHints()

# Create Window #
window = GLFW.CreateWindow(WIDTH, HEIGHT, "Videre", GLFW.NullMonitor, GLFW.NullWindow)
# set callbacks
GLFW.SetKeyCallback(window, key_callback)
# create OpenGL context
GLFW.MakeContextCurrent(window)

# Choose one of the ♡  ♠  ♢  ♣  #
# ♡ (\heartsuit)
#include("triangleCumHeart.jl")
# ♠ (\spadesuit)
#include("triangleCumSpade.jl")
# ♢ (\clubsuit)
include("triangleCumDiamond.jl")
# ♣ (\diamondsuit)
#include("triangleCumClub.jl")

# GLFW Terminating #
GLFW.Terminate()



