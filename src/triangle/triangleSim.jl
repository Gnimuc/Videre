## Triangle-Simplified ##
#=
This script only depends on GLFW.jl and ModernGL.jl.
You can install these two packages by running:
Pkg.add("GLFW")
Pkg.add("ModernGL")
=#
# Deps #
using GLFW, ModernGL

# Change path #
# change julia's current working directory to Videre working directory #
# you may need to edit this path, I currently don't know how to fix it elegantly. #
if OS_NAME == :Windows
    cd(string(homedir(),"\\Desktop\\Videre"))
end
if OS_NAME == :Darwin
    cd(string(homedir(),"/Documents/Videre"))
end

# Functions #
# modify GLSL version
function glslversion!(source::ASCIIString, major, minor)
    index = search(source, "#version ")
    replace(source, source[index.stop+1:index.stop+2], "$major$minor")
    return source
end
# create shader --> load shader source --> compile shader
function shadercompiler(shaderSource::ASCIIString, shaderType::GLenum)
    typestring = Dict([(GL_COMPUTE_SHADER, "compute"),
                     (GL_VERTEX_SHADER,"vertex"),
                     (GL_TESS_CONTROL_SHADER, "tessellation control"),
                     (GL_TESS_EVALUATION_SHADER, "tessellation evaluation"),
                     (GL_GEOMETRY_SHADER, "geometry"),
                     (GL_FRAGMENT_SHADER, "fragment")])
    # create shader & load source
    shader = glCreateShader(shaderType)
    @assert shader != 0 "Error creating $(typestring[shaderType]) shader."
    shaderSource = glslversion!(shaderSource, VERSION_MAJOR, VERSION_MINOR)
    shaderSourceptr = convert(Ptr{GLchar}, pointer(shaderSource))
    glShaderSource(shader, 1, convert(Ptr{Uint8}, pointer([shaderSourceptr])), C_NULL)
    # compile shader
    glCompileShader(shader)
    # compile error handling
    result = GLint[0]
    glGetShaderiv(shader, GL_COMPILE_STATUS, pointer(result))
    if result[1] == GL_FALSE
        println("$(typestring[shaderType]) shader compile failed.")
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
    return shader::GLuint
end
# create program handler --> attach shader --> link shader
function programer(shaderArray::Array{GLuint,1})
    # create program handler
    programHandle = glCreateProgram()
    @assert programHandle != 0 "Error creating program object."
    # attach shader
    for s in shaderArray
       glAttachShader(programHandle, s)
    end
    # link
    glLinkProgram(programHandle)
    # link error handling
    status = GLint[0]
    glGetProgramiv(programHandle, GL_LINK_STATUS, pointer(status))
    if status[1] == GL_FALSE
        println("Failed to link shader program.")
        logLen = GLint[0]
        glGetProgramiv(programHandle, GL_INFO_LOG_LENGTH, pointer(logLen))
        if logLen[1] > 0
            log = Array(GLchar, logLen[1])
            logptr = convert(Ptr{GLchar}, pointer(log))
            written = GLsizei[0]
            writtenptr = convert(Ptr{GLsizei}, pointer(written))
            glGetProgramInfoLog(shader, logLen[1], writtenptr, logptr )
            info = convert(ASCIIString, log)
            println("$info")
        end
    end
    return programHandle::GLuint
end

# Constants #
const WIDTH = convert(GLuint, 800)
const HEIGHT = convert(GLuint, 600)
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
if OS_NAME == :Darwin
    GLFW.WindowHint(GLFW.OPENGL_FORWARD_COMPAT, GL_TRUE)
end
# if that doesn't work, try to uncomment the code below and checkout your OpenGL context version
GLFW.DefaultWindowHints()

# Create Window #
window = GLFW.CreateWindow(WIDTH, HEIGHT, "Videre", GLFW.NullMonitor, GLFW.NullWindow)
# set callbacks
GLFW.SetKeyCallback(window, key_callback)
# create OpenGL context
GLFW.MakeContextCurrent(window)

# Choose one of the ♡  ♠  ♢  ♣  #
# ♡ (\heartsuit)
include("triangleSimHeart.jl")
# ♠ (\spadesuit)
#include("triangleSimSpade.jl")
# ♢ (\clubsuit)
#include("triangleSimDiamond.jl")
# ♣ (\diamondsuit)
#include("triangleSimClub.jl")

# GLFW Terminating #
GLFW.Terminate()
