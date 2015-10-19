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
    global window = GLFW.CreateWindow(glfwWidth, glfwHeight, "Shader", GLFW.NullMonitor, GLFW.NullWindow)
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
    @assert parse(Float32, version[1:3]) >= 3.2 "OpenGL version must ≥ 3.2, Please upgrade your graphic driver."
    # save logs
    logadd("gl.log", string("renderer: ", renderer, "\nversion: ", version))
    glparams()

    return true
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
        s = @sprintf "Shader @ fps: %.2f" fps
        GLFW.SetWindowTitle(window, s)
        frameCount = 0
    end
    frameCount = frameCount + 1
end
