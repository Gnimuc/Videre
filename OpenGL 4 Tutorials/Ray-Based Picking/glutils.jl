using GLFW, ModernGL




## OpenGL logs
# initialize OpenGL log file
function loginit(filename::ASCIIString)
    logfile = open(filename, "w")
    println(logfile, filename, " local time: ", now())
    close(logfile)
    return true
end
# add a message to the log file
function logadd(filename::ASCIIString, message::ASCIIString)
    logfile = open(filename, "a")
    println(logfile, message)
    close(logfile)
    return true
end
# add error message to the log file and throw an error to STDERR
function logerror(filename::ASCIIString, message::ASCIIString)
    logfile = open(filename, "a")
    println(logfile, message)
    println(STDERR, message)
    close(logfile)
    return true
end
# load OpenGL parameters info
function glparams()
    v = GLint[0, 0]
    s = GLboolean[0]
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

    logadd("gl.log","\nGL Context Params:")
    for i = 1:10
        local v = GLint[0]
        glGetIntegerv(params[i], Ref(v))
        logadd("gl.log", string(names[i], ": ", v[]))
    end
    glGetIntegerv(params[11], Ref(v))  # ?
    logadd("gl.log", string(names[11], ": ", v[1], " | ", v[2]))
    glGetBooleanv(params[12], Ref(s))
    logadd("gl.log", string(names[12], ": ", s[]))
    logadd("gl.log", "-----------------------------\n")
    return nothing
end




## GLFW initialization
# set up GLFW key callbacks : press Esc to escape
function key_callback(window::GLFW.Window, key::Cint, scancode::Cint, action::Cint, mods::Cint)
    if (key == GLFW.KEY_ESCAPE && action == GLFW.PRESS)
        GLFW.SetWindowShouldClose(window, GL_TRUE)
    end
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
    s = @sprintf "GLFW ERROR: code %i msg: %s" error description
	logerror("gl.log", s)
    return nothing
end


# start OpenGL
function startgl()
    # initialize GLFW library, error check is already wrapped.
    GLFW.Init()

    # set up window creation hints
    @osx ? (
    begin
        GLFW.WindowHint(GLFW.CONTEXT_VERSION_MAJOR, VERSION_MAJOR)
        GLFW.WindowHint(GLFW.CONTEXT_VERSION_MINOR, VERSION_MINOR)
        GLFW.WindowHint(GLFW.OPENGL_PROFILE, GLFW.OPENGL_CORE_PROFILE)
        GLFW.WindowHint(GLFW.OPENGL_FORWARD_COMPAT, GL_TRUE)
    end
    : begin
        GLFW.DefaultWindowHints()
    end
    )
    # set up GLFW log and error callbacks
    logadd("gl.log", "\nstarting GLFW ...")
    logadd("gl.log", GLFW.GetVersionString())
    GLFW.SetErrorCallback(error_callback)

    # create window
    global window = GLFW.CreateWindow(glfwWidth, glfwHeight, "Ray-Based Picking")
    if window == C_NULL
        println("error: GLFW window creating failed.")
        GLFW.Terminate()
    end

    # set callbacks
    GLFW.SetKeyCallback(window, key_callback)
    GLFW.SetWindowSizeCallback(window, window_size_callback)

    # make current context
    GLFW.MakeContextCurrent(window)
    GLFW.WindowHint(GLFW.SAMPLES, 4)

    # get version info
    renderer = bytestring(glGetString(GL_RENDERER))
    version = bytestring(glGetString(GL_VERSION))
    println("Renderder: ", renderer)
    println("OpenGL version supported: ", version)
    @assert parse(Float64, version[1:3]) >= 3.2 "OpenGL version must ≥ 3.2, Please upgrade your graphic driver."
    # save logs
    logadd("gl.log", string("renderer: ", renderer, "\nversion: ", version))
    glparams()

    return true
end




## shaders
# checkout shader infos
function shaderlog(shaderID::GLuint)
    maxLength = GLsizei[0]
    glGetShaderiv(shaderID, GL_INFO_LOG_LENGTH, Ref(maxLength))
    actualLength = GLsizei[0]
    log = Array{GLchar}(maxLength[])
    glGetShaderInfoLog(shaderID, maxLength[], Ref(actualLength), Ref(log))
    # print log
    println("shader info log for GL index ", shaderID, ":")
    println(ASCIIString(log))
    # save log
    logadd("gl.log", string("shader info log for GL index ", shaderID, ":"))
    logadd("gl.log", ASCIIString(log))
end

# checkout program infos
function programlog(programID::GLuint)
    maxLength = GLsizei[0]
    glGetProgramiv(programID, GL_INFO_LOG_LENGTH, Ref(maxLength))
    actualLength = GLsizei[0]
    log = Array{GLchar}(maxLength[])
    glGetProgramInfoLog(programID, maxLength[], Ref(actualLength), Ref(log))
    # print log
    println("program info log for GL index ", programID, ":")
    println(ASCIIString(log))
    # save log
    logadd("gl.log", string("program info log for GL index ", programID, ":"))
    logadd("gl.log", ASCIIString(log))
end

# verbose log infos
function programlogverbose(shaderProgramID::GLuint)
    result = GLint[-1]

    logerror("gl.log", string("--------------------\nshader program ", shaderProgramID, " verbose info:\n"))
    glGetProgramiv(shaderProgramID, GL_LINK_STATUS, Ref(result))
    logerror("gl.log", string("GL_LINK_STATUS = ", result[]))

    glGetProgramiv(shaderProgramID, GL_ATTACHED_SHADERS, Ref(result))
    logerror("gl.log", string("GL_ATTACHED_SHADERS = ", result[]))

    glGetProgramiv(shaderProgramID, GL_ACTIVE_ATTRIBUTES, Ref(result))
    logerror("gl.log", string("GL_ACTIVE_ATTRIBUTES = ", result[]))

    for i in eachindex(result)
        maxLength = GLsizei[0]
        glGetProgramiv(shaderProgramID, GL_ACTIVE_ATTRIBUTE_MAX_LENGTH, Ref(maxLength))
        actualLength = GLsizei[0]
        attributeSize = GLint[0]
        attributeType = GLenum[0]
        name = Array{GLchar}(maxLength[])
        glGetActiveAttrib(shaderProgramID, i-1, maxLength[], Ref(actualLength), Ref(attributeSize), Ref(attributeType), Ref(name))
        if attributeSize[] > 1
            for j = 1: attributeSize[]
                longName = @sprintf "%s[%i]" name j
                location = glGetAttribLocation(shaderProgramID, Ref(longName))
                log = string("  ", i, ") type:", GLENUM(attributeType[]).name, " name:", ASCIIString(longName), " location:", location)
                println(log)
                logadd("gl.log", log)
            end
        else
            location = glGetAttribLocation(shaderProgramID, Ref(name))
            log = string("  ", i, ") type:", GLENUM(attributeType[]).name, " name:", ASCIIString(name), " location:", location)
            println(log)
            logadd("gl.log", log)
        end
    end

    glGetProgramiv(shaderProgramID, GL_ACTIVE_UNIFORMS, Ref(result))
    logerror("gl.log", string("GL_ACTIVE_UNIFORMS = ", result[]))
    for i in eachindex(result)
        maxLength = GLsizei[0]
        glGetProgramiv(shaderProgramID, GL_ACTIVE_UNIFORM_MAX_LENGTH, Ref(maxLength))
        actualLength = GLsizei[0]
        attributeSize = GLint[0]
        attributeType = GLenum[0]
        name = Array{GLchar}(maxLength[])
        glGetActiveUniform(shaderProgramID, i-1, maxLength[], Ref(actualLength), Ref(attributeSize), Ref(attributeType), Ref(name))
        if attributeSize[] > 1
            for j = 1: attributeSize[]
                longName = @sprintf "%s[%i]" name j
                location = glGetUniformLocation(shaderProgramID, Ref(longName))
                log = string("  ", i, ") type:", GLENUM(attributeType[]).name, " name:", ASCIIString(longName), " location:", location)
                println(log)
                logadd("gl.log", log)
            end
        else
            location = glGetUniformLocation(shaderProgramID, Ref(name))
            log = string("  ", i, ") type:", GLENUM(attributeType[]).name, " name:", ASCIIString(name), " location:", location)
            println(log)
            logadd("gl.log", log)
        end
    end
    programlog(shaderProgramID)
end

# validate shader program
function validprogram(shaderProgramID::GLuint)
    validResult = GLint[-1]
    glValidateProgram(shaderProgramID)
    glGetProgramiv(shaderProgramID, GL_VALIDATE_STATUS, Ref(validResult))
    log = string("program ", shaderProgramID, " GL_VALIDATE_STATUS = ", validResult[])
    logadd("gl.log", log)
    println(log)
    if validResult[] != GL_TRUE
        programlog(shaderProgramID)
        return false
    end
    return true
end

# create shader
function createshader(source::ASCIIString, shaderType::GLenum)
    logadd("gl.log", string("creating shader from ", source, "..."))
    const shader = readall(string(dirname(@__FILE__), "/", source))
    shaderID = glCreateShader(shaderType)
    glShaderSource(shaderID, 1, [pointer(shader)], C_NULL)
    glCompileShader(shaderID)
    # get shader compile status
    compileResult = GLint[-1]
    glGetShaderiv(shaderID, GL_COMPILE_STATUS, Ref(compileResult))
    if compileResult[] != GL_TRUE
        logerror("gl.log", string("\nERROR: GL vertex shader(index", shaderID, ")did not compile."))
        shaderlog(shaderID)
    end
    logadd("gl.log", string("shader compiled. index ", shaderID))
    return shaderID::GLuint
end

# create program
function createprogram(vertID::GLuint, fragID::GLuint)
    shaderProgramID = glCreateProgram()
    logadd("gl.log", string("creating program ", shaderProgramID, " attaching shaders: ", vertID, " and ", fragID, "..."))
    glAttachShader(shaderProgramID, vertID)
    glAttachShader(shaderProgramID, fragID)
    glLinkProgram(shaderProgramID)
    # checkout programe linking status
    linkingResult = GLint[-1]
    glGetProgramiv(shaderProgramID, GL_LINK_STATUS, Ref(linkingResult))
    if linkingResult[] != GL_TRUE
        logerror("gl.log", string("\nERROR: could not link shader programme GL index: ", shaderProgramID))
        programlog(shaderProgramID)
    end
    @assert validprogram(shaderProgramID)
    glDeleteShader(vertID)
    glDeleteShader(fragID)
    return shaderProgramID::GLuint
end

# create program from files
function createprogram(vertSource::ASCIIString, fragSource::ASCIIString)
    vertexShader = createshader(vertSource, GL_VERTEX_SHADER)
    fragmentShader = createshader(fragSource, GL_FRAGMENT_SHADER)
    shaderProgramID = createprogram(vertexShader, fragmentShader)
    return shaderProgramID
end


## other functionalities
# show FPS on title
previousTime = time()
frameCount = 0
function updatefps(window::GLFW.Window)
    global previousTime
    global frameCount
    currentTime = time()
    elapsedTime = currentTime - previousTime
    if elapsedTime > 0.25
        previousTime = currentTime
        fps = frameCount / elapsedTime
        s = @sprintf "Ray-Based Picking @ fps: %.2f" fps
        GLFW.SetWindowTitle(window, s)
        frameCount = 0
    end
    frameCount = frameCount + 1
end
