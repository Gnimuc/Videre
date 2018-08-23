using GLFW
using ModernGL
using Printf

# set up OpenGL context version
# it seems OpenGL 4.1 is the highest version supported by MacOS.
@static if Sys.isapple()
    const VERSION_MAJOR = 4
    const VERSION_MINOR = 1
end

@static if Sys.isapple()
    GLFW.WindowHint(GLFW.CONTEXT_VERSION_MAJOR, VERSION_MAJOR)
    GLFW.WindowHint(GLFW.CONTEXT_VERSION_MINOR, VERSION_MINOR)
    GLFW.WindowHint(GLFW.OPENGL_PROFILE, GLFW.OPENGL_CORE_PROFILE)
    GLFW.WindowHint(GLFW.OPENGL_FORWARD_COMPAT, GL_TRUE)
else
    GLFW.DefaultWindowHints()
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

# set up GLFW error callbacks
@info "starting GLFW ..."
@info GLFW.GetVersionString()

# error callback
error_callback(error::Cint, description::Ptr{GLchar}) = @error "GLFW ERROR: code $error msg: $description"
GLFW.SetErrorCallback(error_callback)

# set up GLFW key callbacks : press Esc to escape
key_callback(window::GLFW.Window, key::Cint, scancode::Cint, action::Cint, mods::Cint) = key == GLFW.KEY_ESCAPE && action == GLFW.PRESS && GLFW.SetWindowShouldClose(window, GL_TRUE)

# : change window size
function window_size_callback(window::GLFW.Window, width::Cint, height::Cint)
	global glfwWidth = width
	global glfwHeight = height
	println("width", width, "height", height)
	# update any perspective matrices used here
    return nothing
end


global glfwWidth = 640
global glfwHeight = 480
window = GLFW.CreateWindow(glfwWidth, glfwHeight, "Extended Init.")
window == C_NULL && error("could not open window with GLFW3.")

GLFW.SetKeyCallback(window, key_callback)
GLFW.SetWindowSizeCallback(window, window_size_callback)
GLFW.MakeContextCurrent(window)
GLFW.WindowHint(GLFW.SAMPLES, 4)

# enable depth test
glEnable(GL_DEPTH_TEST)
glDepthFunc(GL_LESS)

# get version info
renderer = unsafe_string(glGetString(GL_RENDERER))
version = unsafe_string(glGetString(GL_VERSION))
@info "Renderder: $renderer"
@info "OpenGL version supported: $version"

# hard-coded shaders
const vertexShader = """
#version 410 core
in vec3 vp;
void main(void)
{
    gl_Position = vec4(vp, 1.0);
}"""
const fragmentShader = """
#version 410 core
out vec4 frag_colour;
void main(void)
{
    frag_colour = vec4(0.5, 0.0, 0.5, 1.0);
}"""

# compile shaders
vertexShaderID = glCreateShader(GL_VERTEX_SHADER)
glShaderSource(vertexShaderID, 1, Ptr{GLchar}[pointer(vertexShader)], C_NULL)
glCompileShader(vertexShaderID)
fragmentShaderID = glCreateShader(GL_FRAGMENT_SHADER)
glShaderSource(fragmentShaderID, 1, Ptr{GLchar}[pointer(fragmentShader)], C_NULL)
glCompileShader(fragmentShaderID)

# create and link shader program
shaderProgram = glCreateProgram()
glAttachShader(shaderProgram, vertexShaderID)
glAttachShader(shaderProgram, fragmentShaderID)
glLinkProgram(shaderProgram)

# vertex data
points = GLfloat[ 0.0,  0.5, 0.0,
                  0.5, -0.5, 0.0,
                 -0.5, -0.5, 0.0]

# create buffers located in the memory of graphic card
VBORef = Ref{GLuint}(0)
glGenBuffers(1, VBORef)
glBindBuffer(GL_ARRAY_BUFFER, VBORef[])
glBufferData(GL_ARRAY_BUFFER, sizeof(points), points, GL_STATIC_DRAW)

# create VAO
VAORef = Ref{GLuint}(0)
glGenVertexArrays(1, VAORef)
glBindVertexArray(VAORef[])
glBindBuffer(GL_ARRAY_BUFFER, VBORef[])
glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, C_NULL)
glEnableVertexAttribArray(0)

# set background color to gray
glClearColor(0.2, 0.2, 0.2, 1.0)

# render
while !GLFW.WindowShouldClose(window)
    updatefps(window)
    # clear drawing surface
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
    glViewport(0, 0, glfwWidth, glfwHeight)
    # drawing
    glUseProgram(shaderProgram)
    glBindVertexArray(VAORef[])
    glDrawArrays(GL_TRIANGLES, 0, 3)
    # check and call events
    GLFW.PollEvents()
    # swap the buffers
    GLFW.SwapBuffers(window)
end

GLFW.DestroyWindow(window)
