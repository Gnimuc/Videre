using GLFW
using ModernGL
using Printf

# print errors in shader compilation
function shader_info_log(shader::GLuint)
    maxLengthRef = Ref{GLsizei}(0)
    glGetShaderiv(shader, GL_INFO_LOG_LENGTH, maxLengthRef)
    actualLengthRef = Ref{GLsizei}(0)
    log = Vector{GLchar}(undef, maxLengthRef[])
    glGetShaderInfoLog(shader, maxLengthRef[], actualLengthRef, log)
    @info "shader info log for GL index $shader: $(String(log))"
end

# print errors in shader linking
function programme_info_log(program::GLuint)
    maxLengthRef = Ref{GLsizei}(0)
    glGetProgramiv(program, GL_INFO_LOG_LENGTH, maxLengthRef)
    actualLengthRef = Ref{GLsizei}(0)
    log = Vector{GLchar}(undef, maxLengthRef[])
    glGetProgramInfoLog(program, maxLengthRef[], actualLengthRef, log)
    @info "program info log for GL index $program: $(String(log))"
end

# validate shader program
function is_valid(shaderProgram::GLuint)
    paramsRef = Ref{GLint}(-1)
    glValidateProgram(shaderProgram)
    glGetProgramiv(shaderProgram, GL_VALIDATE_STATUS, paramsRef)
    @info "program $shaderProgram GL_VALIDATE_STATUS = $(paramsRef[])"
    if paramsRef[] != GL_TRUE
        programme_info_log(shaderProgram)
        return false
    end
    return true
end

# print verbose infos
function print_all(shaderProgram::GLuint)
    paramsRef = Ref{GLint}(-1)

    @debug "-------------------------"
    @debug "Shader programme $shaderProgram info:"
    glGetProgramiv(shaderProgram, GL_LINK_STATUS, paramsRef)
    @debug "GL_LINK_STATUS = $(paramsRef[])"

    glGetProgramiv(shaderProgram, GL_ATTACHED_SHADERS, paramsRef)
    @debug "GL_ATTACHED_SHADERS = $(paramsRef[])"

    glGetProgramiv(shaderProgram, GL_ACTIVE_ATTRIBUTES, paramsRef)
    @debug "GL_ACTIVE_ATTRIBUTES = $(paramsRef[])"

    maxLengthRef = Ref{GLsizei}(0)
    glGetProgramiv(shaderProgram, GL_ACTIVE_ATTRIBUTE_MAX_LENGTH, maxLengthRef)
    name = Vector{GLchar}(undef, maxLengthRef[])
    for i in 0:paramsRef[]-1
        actualLengthRef = Ref{GLsizei}(0)
        sizeRef = Ref{GLint}(0)
        typeRef = Ref{GLenum}(0)
        glGetActiveAttrib(shaderProgram, i, maxLengthRef[], actualLengthRef, sizeRef, typeRef, name)
        if sizeRef[] > 1
            for j = 0:sizeRef[]-1
                longName = @sprintf "%s[%i]" name j
                location = glGetAttribLocation(shaderProgram, longName)
                @debug "  $i): type -> $(GLENUM(typeRef[]).name), name -> $(String(longName)), location -> $location."
            end
        else
            location = glGetAttribLocation(shaderProgram, name)
            @debug "  $i): type -> $(GLENUM(typeRef[]).name), name -> $(String(name)), location -> $location."
        end
    end

    glGetProgramiv(shaderProgram, GL_ACTIVE_UNIFORMS, paramsRef)
    @debug "GL_ACTIVE_UNIFORMS = $(paramsRef[])"
    for i in 0:paramsRef[]-1
        maxLengthRef = Ref{GLsizei}(0)
        glGetProgramiv(shaderProgram, GL_ACTIVE_UNIFORM_MAX_LENGTH, maxLengthRef)
        name = Vector{GLchar}(undef, maxLengthRef[])
        actualLengthRef = Ref{GLsizei}(0)
        sizeRef = Ref{GLint}(0)
        typeRef = Ref{GLenum}(0)
        glGetActiveUniform(shaderProgram, i, maxLengthRef[], actualLengthRef, sizeRef, typeRef, name)
        if sizeRef[] > 1
            for j = 0:sizeRef[]-1
                longName = @sprintf "%s[%i]" name j
                location = glGetUniformLocation(shaderProgram, longName)
                @debug "  $i): type -> $(GLENUM(typeRef[]).name), name -> $(String(longName)), location -> $location."
            end
        else
            location = glGetUniformLocation(shaderProgram, name)
            @debug "  $i): type -> $(GLENUM(typeRef[]).name), name -> $(String(name)), location -> $location."
        end
    end

    programme_info_log(shaderProgram)
end

## GLFW initialization
# set up GLFW key callbacks : press Esc to escape
key_callback(window::GLFW.Window, key::Cint, scancode::Cint, action::Cint, mods::Cint) = key == GLFW.KEY_ESCAPE && action == GLFW.PRESS && GLFW.SetWindowShouldClose(window, GL_TRUE)

# change window size
function window_size_callback(window::GLFW.Window, width::Cint, height::Cint)
	global glfwWidth = width
	global glfwHeight = height
	println("width", width, "height", height)
	# update any perspective matrices used here
    return nothing
end

# error callback
error_callback(error::Cint, description::Ptr{GLchar}) = @error "GLFW ERROR: code $error msg: $description"
GLFW.SetErrorCallback(error_callback)


# start OpenGL
function startgl()
    @static if Sys.isapple()
        GLFW.WindowHint(GLFW.CONTEXT_VERSION_MAJOR, VERSION_MAJOR)
        GLFW.WindowHint(GLFW.CONTEXT_VERSION_MINOR, VERSION_MINOR)
        GLFW.WindowHint(GLFW.OPENGL_PROFILE, GLFW.OPENGL_CORE_PROFILE)
        GLFW.WindowHint(GLFW.OPENGL_FORWARD_COMPAT, GL_TRUE)
    else
        GLFW.DefaultWindowHints()
    end

    @info "starting GLFW ..."
    @info GLFW.GetVersionString()

    # create window
    global window = GLFW.CreateWindow(glfwWidth, glfwHeight, "Extended Init.")
    window == C_NULL && error("could not open window with GLFW3.")

    # set callbacks
    GLFW.SetErrorCallback(error_callback)
    GLFW.SetKeyCallback(window, key_callback)
    GLFW.SetWindowSizeCallback(window, window_size_callback)
    GLFW.MakeContextCurrent(window)
    GLFW.WindowHint(GLFW.SAMPLES, 4)

    # get version info
    renderer = unsafe_string(glGetString(GL_RENDERER))
    version = unsafe_string(glGetString(GL_VERSION))
    @info "Renderder: $renderer"
    @info "OpenGL version supported: $version"

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
            GLFW.SetWindowTitle(window, @sprintf("opengl @ fps: %.2f", fps))
            frameCount = 0
        end
        frameCount = frameCount + 1
    end
end
