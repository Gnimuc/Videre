using GLFW
using ModernGL
using Printf

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
