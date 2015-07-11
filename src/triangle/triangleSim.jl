## Triangle-Simplified ##
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

# Change path #
# change julia's current working directory to Videre working directory #
# you may need to edit this path by yourself, I currently don't know how to do it elegantly. #

@windows_only cd(string(homedir(),"\\Documents\\Videre"))
@osx_only cd(string(homedir(),"/Documents/Videre"))

# Constants #
const WIDTH = convert(GLuint, 800)
const HEIGHT = convert(GLuint, 600)
const VERSION_MAJOR = 4
const VERSION_MINOR = 4

# Types #
include("Types.jl")
using Types.AbstractOpenGLData
using Types.AbstractOpenGLVectorData
using Types.AbstractOpenGLMatrixData
using Types.AbstractOpenGLVecOrMatData
using Types.VertexData
using Types.UniformData

# Functions #
include("Utils.jl")

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

# Choose one of the ♡  ♠  ♢  ♣ and uncomment the corresponding line #
# ♡ (\heartsuit)
#include("triangleSimHeart.jl")
# ♠ (\spadesuit)
#include("triangleSimSpade.jl")
# ♢ (\clubsuit)
include("triangleSimDiamond.jl")
# ♣ (\diamondsuit)
#include("triangleSimClub.jl")

# GLFW Terminating #
GLFW.Terminate()
