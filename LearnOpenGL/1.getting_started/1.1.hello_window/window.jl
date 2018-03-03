using GLFW, ModernGL

# whenever the window size changed (by OS or user resize) this callback function executes
function framebuffer_size_callback(window::GLFW.Window, width::Cint, height::Cint)
    # make sure the viewport matches the new window dimensions; note that width and
    # height will be significantly larger than specified on retina displays.
	glViewport(0, 0, width, height)
end

# process all input: query GLFW whether relevant keys are pressed/released this frame and react accordingly
function processInput(window::GLFW.Window)
    GLFW.GetKey(window, GLFW.KEY_ESCAPE) == GLFW.PRESS && GLFW.SetWindowShouldClose(window, true)
end

# misc. config
const SCR_WIDTH = 800
const SCR_HEIGHT = 600

GLFW.WindowHint(GLFW.CONTEXT_VERSION_MAJOR, 3)
GLFW.WindowHint(GLFW.CONTEXT_VERSION_MINOR, 3)
GLFW.WindowHint(GLFW.OPENGL_PROFILE, GLFW.OPENGL_CORE_PROFILE)
GLFW.WindowHint(GLFW.OPENGL_FORWARD_COMPAT, GL_TRUE)

# create window
window = GLFW.CreateWindow(SCR_WIDTH, SCR_HEIGHT, "LearnOpenGL")
window == C_NULL && error("Failed to create GLFW window.")
GLFW.MakeContextCurrent(window)
GLFW.SetFramebufferSizeCallback(window, framebuffer_size_callback)

# render loop
while !GLFW.WindowShouldClose(window)
    processInput(window)
    # swap buffers and poll IO events
    GLFW.SwapBuffers(window)
    GLFW.PollEvents()
end

GLFW.DestroyWindow(window)
