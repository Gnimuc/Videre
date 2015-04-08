## Triangle-Cumbersome ##
#=
This script only depends on GLFW.jl and ModernGL.jl. #
You can install these two packages by running:
Pkg.add("GLFW")
Pkg.add("ModernGL")
=#
# Deps #
using GLFW, ModernGL

# functions #
function shadercompiler(shaderSource::ASCIIString, shaderType::GLenum)
    shaderSourceptr = convert(Ptr{GLchar}, pointer(shaderSource))
    shader = glCreateShader(shaderType)
    glShaderSource(shader, 1, convert(Ptr{Uint8}, pointer([shaderSourceptr])), C_NULL)
    glCompileShader(shader)
    success = GLuint[0]
    glGetShaderiv(shader, GL_COMPILE_STATUS, pointer(success))
    if success[1] != 1
        println("shader compile failed.")
    end

    return shader
end

function programer(vertexShader::GLuint, fragmentShader::GLuint)
    program = glCreateProgram()
    glAttachShader(program, vertexShader)
    glAttachShader(program, fragmentShader)
    glLinkProgram(program)
    return program
end

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
#include("triangleSimHeart.jl")
# ♠ (\spadesuit)
include("triangleSimSpade.jl")
# ♢ (\clubsuit)
#include("triangleSimDiamond.jl")
# ♣ (\diamondsuit)
#include("triangleSimClub.jl")

# GLFW Terminating #
GLFW.Terminate()







