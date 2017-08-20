using GLFW
using ModernGL
using Memento

GLFW.Init()

# set up OpenGL context version
# it seems OpenGL 4.1 is the highest version supported by MacOS.
@static if is_apple()
    const VERSION_MAJOR = 4
    const VERSION_MINOR = 1
end

@static if is_apple()
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
            s = @sprintf "opengl @ fps: %.2f" fps
            GLFW.SetWindowTitle(window, s)
            frameCount = 0
        end
        frameCount = frameCount + 1
    end
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


# set up GLFW log and error callbacks
Memento.config("notice"; fmt="[ {date} | {level} ]: {msg}")
logger = get_logger(current_module())
add_handler(logger, DefaultHandler("gl.log", DefaultFormatter("[{date} | {level}]: {msg}")))
set_level(logger, "info")
info(logger, "starting GLFW ...")
info(logger, GLFW.GetVersionString())

# error callback
function error_callback(error::Cint, description::Ptr{GLchar})
    logger = get_logger(current_module())
    s = @sprintf "GLFW ERROR: code %i msg: %s" error description
	error(logger, s)
    return nothing
end
GLFW.SetErrorCallback(error_callback)

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
info("Renderder: ", renderer)
info("OpenGL version supported: ", version)
@assert parse(Float64, version[1:3]) >= 3.2 "OpenGL version must ≥ 3.2, Please upgrade your graphic driver."
glparams()

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
glShaderSource(vertexShaderID, 1, [pointer(vertexShader)], C_NULL)
glCompileShader(vertexShaderID)
fragmentShaderID = glCreateShader(GL_FRAGMENT_SHADER)
glShaderSource(fragmentShaderID, 1, [pointer(fragmentShader)], C_NULL)
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
vboID = Ref{GLuint}(0)
glGenBuffers(1, vboID)
glBindBuffer(GL_ARRAY_BUFFER, vboID[])
glBufferData(GL_ARRAY_BUFFER, sizeof(points), points, GL_STATIC_DRAW)

# create VAO
vaoID = Ref{GLuint}(0)
glGenVertexArrays(1, vaoID)
glBindVertexArray(vaoID[])
glBindBuffer(GL_ARRAY_BUFFER, vboID[])
glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, C_NULL)
glEnableVertexAttribArray(0)

# render
while !GLFW.WindowShouldClose(window)
    updatefps(window)
    # clear drawing surface
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
    glViewport(0, 0, glfwWidth, glfwHeight)
    # drawing
    glUseProgram(shaderProgram)
    glBindVertexArray(vaoID[])
    glDrawArrays(GL_TRIANGLES, 0, 3)
    # check and call events
    GLFW.PollEvents()
    # swap the buffers
    GLFW.SwapBuffers(window)
end

GLFW.Terminate()
