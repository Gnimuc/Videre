using GLFW
using ModernGL
using Printf

## GLFW initialization
# set up GLFW key callbacks : press Esc to escape
function key_callback(window::GLFW.Window, key::GLFW.Key, scancode::Cint, action::GLFW.Action, mods::Cint)
	key == GLFW.KEY_ESCAPE && action == GLFW.PRESS && GLFW.SetWindowShouldClose(window, true)
end

# tell GLFW to run this function whenever the framebuffer size is changed
function framebuffer_size_callback(window::GLFW.Window, w::Cint, h::Cint)
	global fb_width = w
	global fb_height = h
	println("framebuffer size: ($w, $h)")
    return nothing
end

# tell GLFW to run this function whenever the window size is changed
function window_size_callback(window::GLFW.Window, w::Cint, h::Cint)
	global width = w
	global height = h
	println("window size: ($w, $h)")
    return nothing
end

# error callback
error_callback(err::GLFW.GLFWError) = @error "GLFW ERROR: code $(err.code) msg: $(err.description)"
GLFW.SetErrorCallback(error_callback)

# start OpenGL
function startgl(width, height)
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

	window = GLFW.CreateWindow(width, height, "Extended Init.")
	@assert window != C_NULL "could not open window with GLFW3."

	GLFW.SetKeyCallback(window, key_callback)
	GLFW.SetWindowSizeCallback(window, window_size_callback)
	GLFW.SetFramebufferSizeCallback(window, framebuffer_size_callback)
	GLFW.MakeContextCurrent(window)
	GLFW.WindowHint(GLFW.SAMPLES, 4)

	# get version info
    renderer = unsafe_string(glGetString(GL_RENDERER))
    version = unsafe_string(glGetString(GL_VERSION))
    @info "Renderder: $renderer"
    @info "OpenGL version supported: $version"

    return window
end

# _update_fps_counter
let previous = time()
    frame_count = 0
    global function updatefps(window::GLFW.Window)
        current = time()
        elapsed = current - previous
        if elapsed > 0.25
            previous = current
            fps = frame_count / elapsed
            GLFW.SetWindowTitle(window, @sprintf("opengl @ fps: %.2f", fps))
            frame_count = 0
        end
        frame_count += 1
    end
end
