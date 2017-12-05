using GLFW
using ModernGL
using Memento
using Reactive

# checkout shader infos
function shaderlog(shaderID::GLuint)
    maxLength = Ref{GLsizei}(0)
    glGetShaderiv(shaderID, GL_INFO_LOG_LENGTH, maxLength)
    actualLength = Ref{GLsizei}(0)
    log = Vector{GLchar}(maxLength[])
    glGetShaderInfoLog(shaderID, maxLength[], actualLength, log)
    logger = get_logger(current_module())
    info(logger, string("shader info log for GL index ", shaderID, ":"))
    info(logger, String(log))
end

# checkout program infos
function programlog(programID::GLuint)
    maxLength = Ref{GLsizei}(0)
    glGetProgramiv(programID, GL_INFO_LOG_LENGTH, maxLength)
    actualLength = Ref{GLsizei}(0)
    log = Vector{GLchar}(maxLength[])
    glGetProgramInfoLog(programID, maxLength[], actualLength, log)
    logger = get_logger(current_module())
    info(logger, string("program info log for GL index ", programID, ":"))
    info(logger, String(log))
end

# print verbose infos
function printall(shaderProgramID::GLuint)
    result = Ref{GLint}(-1)
    logger = get_logger(current_module())
    info(logger, string("Shader Program ", shaderProgramID, " verbose info:"))
    glGetProgramiv(shaderProgramID, GL_LINK_STATUS, result)
    info(logger, string("GL_LINK_STATUS = ", result[]))

    glGetProgramiv(shaderProgramID, GL_ATTACHED_SHADERS, result)
    info(logger, string("GL_ATTACHED_SHADERS = ", result[]))

    glGetProgramiv(shaderProgramID, GL_ACTIVE_ATTRIBUTES, result)
    info(logger, string("GL_ACTIVE_ATTRIBUTES = ", result[]))

    for i in 1:result[]
        maxLength = Ref{GLsizei}(0)
        glGetProgramiv(shaderProgramID, GL_ACTIVE_ATTRIBUTE_MAX_LENGTH, maxLength)
        actualLength = Ref{GLsizei}(0)
        attributeSize = Ref{GLint}(0)
        attributeType = Ref{GLenum}(0)
        name = Vector{GLchar}(maxLength[])
        glGetActiveAttrib(shaderProgramID, i-1, maxLength[], actualLength, attributeSize, attributeType, name)
        if attributeSize[] > 1
            for j = 1:attributeSize[]
                longName = @sprintf "%s[%i]" name j
                location = glGetAttribLocation(shaderProgramID, longName)
                log = string("  ", i, ") type:", GLENUM(attributeType[]).name, " name:", String(longName), " location:", location)
                info(logger, log)
            end
        else
            location = glGetAttribLocation(shaderProgramID, name)
            log = string("  ", i, ") type:", GLENUM(attributeType[]).name, " name:", String(name), " location:", location)
            info(logger, log)
        end
    end

    glGetProgramiv(shaderProgramID, GL_ACTIVE_UNIFORMS, result)
    info(logger, string("GL_ACTIVE_UNIFORMS = ", result[]))
    for i in 1:result[]
        maxLength = Ref{GLsizei}(0)
        glGetProgramiv(shaderProgramID, GL_ACTIVE_UNIFORM_MAX_LENGTH, maxLength)
        actualLength = Ref{GLsizei}(0)
        attributeSize = Ref{GLint}(0)
        attributeType = Ref{GLenum}(0)
        name = Vector{GLchar}(maxLength[])
        glGetActiveUniform(shaderProgramID, i-1, maxLength[], actualLength, attributeSize, attributeType, name)
        if attributeSize[] > 1
            for j = 1:attributeSize[]
                longName = @sprintf "%s[%i]" name j
                location = glGetUniformLocation(shaderProgramID, longName)
                log = string("  ", i, ") type:", GLENUM(attributeType[]).name, " name:", String(longName), " location:", location)
                info(logger, log)
            end
        else
            location = glGetUniformLocation(shaderProgramID, name)
            log = string("  ", i, ") type:", GLENUM(attributeType[]).name, " name:", String(name), " location:", location)
            info(logger, log)
        end
    end
    programlog(shaderProgramID)
end

# validate shader program
function validprogram(shaderProgramID::GLuint)
    validResult = Ref{GLint}(-1)
    glValidateProgram(shaderProgramID)
    glGetProgramiv(shaderProgramID, GL_VALIDATE_STATUS, validResult)
    log = string("program ", shaderProgramID, " GL_VALIDATE_STATUS = ", validResult[])
    logger = get_logger(current_module())
    info(logger, log)
    if validResult[] != GL_TRUE
        programlog(shaderProgramID)
        return false
    end
    return true
end

# load OpenGL parameters info
function glparams()
    params = GLenum[ GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS,
                     GL_MAX_CUBE_MAP_TEXTURE_SIZE,
                     GL_MAX_DRAW_BUFFERS,
                     GL_MAX_FRAGMENT_UNIFORM_COMPONENTS,
                     GL_MAX_TEXTURE_IMAGE_UNITS,
                     GL_MAX_TEXTURE_SIZE,
                     GL_MAX_VARYING_FLOATS,
                     GL_MAX_VERTEX_ATTRIBS,
                     GL_MAX_VERTEX_TEXTURE_IMAGE_UNITS,
                     GL_MAX_VERTEX_UNIFORM_COMPONENTS,
                     GL_MAX_VIEWPORT_DIMS,
                     GL_STEREO ]
    names = [ "GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS",
    	 	  "GL_MAX_CUBE_MAP_TEXTURE_SIZE",
    		  "GL_MAX_DRAW_BUFFERS",
    		  "GL_MAX_FRAGMENT_UNIFORM_COMPONENTS",
        	  "GL_MAX_TEXTURE_IMAGE_UNITS",
        	  "GL_MAX_TEXTURE_SIZE",
        	  "GL_MAX_VARYING_FLOATS",
        	  "GL_MAX_VERTEX_ATTRIBS",
        	  "GL_MAX_VERTEX_TEXTURE_IMAGE_UNITS",
        	  "GL_MAX_VERTEX_UNIFORM_COMPONENTS",
        	  "GL_MAX_VIEWPORT_DIMS",
        	  "GL_STEREO" ]

    logger = get_logger(current_module())
    info(logger, "GL Context Params:")
    for i = 1:10
        v = Ref{GLint}(0)
        glGetIntegerv(params[i], v)
        info(logger, string(names[i], ": ", v[]))
    end
    v = GLint[0, 0]
    s = Ref{GLboolean}(0)
    glGetIntegerv(params[11], v)
    info(logger, string(names[11], ": ", v[1], " | ", v[2]))
    glGetBooleanv(params[12], s)
    info(logger, string(names[12], ": ", s[]))
    info(logger, "-----------------------------")
    return nothing
end

# init key signals
const KEYS = (:A, :D, :Q, :E, :W, :S, :LEFT, :RIGHT, :UP, :DOWN, :Z, :C)
for key in KEYS
    signame = Symbol("sig$key")
    @eval $signame = Signal(false)
end

## GLFW initialization
# set up GLFW key callbacks :
#   Esc -> escape
#   A -> slide left
#   D -> slide right
#   W -> move forward
#   S -> move backward
#   Q -> move upward
#   E -> move downward
#   LEFT -> yaw left
#   RIGHT -> yaw right
#   UP -> pitch up
#   DOWN -> pitch down
#   Z -> roll left
#   C -> roll right
function key_callback(window::GLFW.Window, key::Cint, scancode::Cint, action::Cint, mods::Cint)
    key == GLFW.KEY_ESCAPE && action == GLFW.PRESS && GLFW.SetWindowShouldClose(window, true)
    key == GLFW.KEY_A && action == GLFW.PRESS && push!(sigA, true)
    key == GLFW.KEY_A && action == GLFW.RELEASE && push!(sigA, false)
    key == GLFW.KEY_D && action == GLFW.PRESS && push!(sigD, true)
    key == GLFW.KEY_D && action == GLFW.RELEASE && push!(sigD, false)
    key == GLFW.KEY_W && action == GLFW.PRESS && push!(sigW, true)
    key == GLFW.KEY_W && action == GLFW.RELEASE && push!(sigW, false)
    key == GLFW.KEY_S && action == GLFW.PRESS && push!(sigS, true)
    key == GLFW.KEY_S && action == GLFW.RELEASE && push!(sigS, false)
    key == GLFW.KEY_Q && action == GLFW.PRESS && push!(sigQ, true)
    key == GLFW.KEY_Q && action == GLFW.RELEASE && push!(sigQ, false)
    key == GLFW.KEY_E && action == GLFW.PRESS && push!(sigE, true)
    key == GLFW.KEY_E && action == GLFW.RELEASE && push!(sigE, false)
    key == GLFW.KEY_LEFT && action == GLFW.PRESS && push!(sigLEFT, true)
    key == GLFW.KEY_LEFT && action == GLFW.RELEASE && push!(sigLEFT, false)
    key == GLFW.KEY_RIGHT && action == GLFW.PRESS && push!(sigRIGHT, true)
    key == GLFW.KEY_RIGHT && action == GLFW.RELEASE && push!(sigRIGHT, false)
    key == GLFW.KEY_UP && action == GLFW.PRESS && push!(sigUP, true)
    key == GLFW.KEY_UP && action == GLFW.RELEASE && push!(sigUP, false)
    key == GLFW.KEY_DOWN && action == GLFW.PRESS && push!(sigDOWN, true)
    key == GLFW.KEY_DOWN && action == GLFW.RELEASE && push!(sigDOWN, false)
    key == GLFW.KEY_Z && action == GLFW.PRESS && push!(sigZ, true)
    key == GLFW.KEY_Z && action == GLFW.RELEASE && push!(sigZ, false)
    key == GLFW.KEY_C && action == GLFW.PRESS && push!(sigC, true)
    key == GLFW.KEY_C && action == GLFW.RELEASE && push!(sigC, false)
end

# : change window size
function window_size_callback(window::GLFW.Window, width::Cint, height::Cint)
    global glfwWidth = width
    global glfwHeight = height
    println("width", width, "height", height)
    # update any perspective matrices used here
    return nothing
end

# error callback
function error_callback(error::Cint, description::Ptr{GLchar})
    logger = get_logger(current_module())
    s = @sprintf "GLFW ERROR: code %i msg: %s" error description
	error(logger, s)
    return nothing
end


# start OpenGL
function startgl()
    @static if is_apple()
        GLFW.WindowHint(GLFW.CONTEXT_VERSION_MAJOR, VERSION_MAJOR)
        GLFW.WindowHint(GLFW.CONTEXT_VERSION_MINOR, VERSION_MINOR)
        GLFW.WindowHint(GLFW.OPENGL_PROFILE, GLFW.OPENGL_CORE_PROFILE)
        GLFW.WindowHint(GLFW.OPENGL_FORWARD_COMPAT, GL_TRUE)
    else
        GLFW.DefaultWindowHints()
    end

    # set up GLFW log and error callbacks
    Memento.config("notice"; fmt="[ {date} | {level} ]: {msg}")
    logger = get_logger(current_module())
    add_handler(logger, DefaultHandler("gl.log", DefaultFormatter("[{date} | {level}]: {msg}")))
    set_level(logger, "info")
    info(logger, "starting GLFW ...")
    info(logger, GLFW.GetVersionString())
    GLFW.SetErrorCallback(error_callback)

    # create window
    global window = GLFW.CreateWindow(glfwWidth, glfwHeight, "Extended Init.")
    window == C_NULL && error("could not open window with GLFW3.")

    # set callbacks
    GLFW.SetKeyCallback(window, key_callback)
    GLFW.SetWindowSizeCallback(window, window_size_callback)
    GLFW.MakeContextCurrent(window)
    GLFW.WindowHint(GLFW.SAMPLES, 4)

    # get version info
    renderer = unsafe_string(glGetString(GL_RENDERER))
    version = unsafe_string(glGetString(GL_VERSION))
    info("Renderder: ", renderer)
    info("OpenGL version supported: ", version)
    glparams()

    return true
end

# _update_fps_counter
let previousTime = time()
    frameCount = 0
    global function updatefps(window::GLFW.Window)
        currentTime = time()
        elapsedTime = currentTime - previousTime
        if elapsedTime > 0.25
            previousTime = currentTime
            fps = frameCount / elapsedTime
            s = @sprintf "opengl @ fps: %.2f" fps
            GLFW.SetWindowTitle(window, s)
            frameCount = 0
        end
        frameCount = frameCount + 1
    end
end
