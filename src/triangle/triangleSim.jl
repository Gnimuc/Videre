## Triangle-Simplified ##
#=
This script only depends on GLFW.jl and ModernGL.jl. #
You can install these two packages by running:
Pkg.add("GLFW")
Pkg.add("ModernGL")
=#
# Deps #
using GLFW, ModernGL

# add Videre working directory to julia's PATH #
# you may need to edit this path, I currently don't know  #
if OS_NAME == :Windows
    cd(string(homedir(),"\\Desktop"))
end
if OS_NAME == :MAC
    cd(string(homedir(),"/Documents/"))
end
# functions #
function shadercompiler(shaderSource::ASCIIString, shaderType::GLenum)
    shaderSourceptr = convert(Ptr{GLchar}, pointer(shaderSource))
    shader = glCreateShader(shaderType)
    @assert shader != 0 "Error creating vertex shader."
    glShaderSource(shader, 1, convert(Ptr{Uint8}, pointer([shaderSourceptr])), C_NULL)
    glCompileShader(shader)
    result = GLuint[0]
    glGetShaderiv(shader, GL_COMPILE_STATUS, pointer(result))
    if result[1] == GL_FALSE
        println("shader compile failed.")
        logLen = GLint[0]
        glGetShaderiv(shader, GL_INFO_LOG_LENGTH, pointer(logLen))
        if logLen[1] > 0
            log = Array(GLchar, logLen[1])
            logptr = convert(Ptr{GLchar}, pointer(log))
            written = GLsizei[0]
            writtenptr = convert(Ptr{GLsizei}, pointer(written))
            glGetShaderInfoLog(shader, logLen[1], writtenptr, logptr )
            info = convert(ASCIIString, log)
            println("$info")

        end
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
GLFW.DefaultWindowHints()

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







