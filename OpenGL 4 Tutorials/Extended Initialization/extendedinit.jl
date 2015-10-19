# load dependency packages
using GLFW, ModernGL




# set up OpenGL context version
@osx_only const VERSION_MAJOR = 4    # it seems OSX will stuck on OpenGL 4.1.
@osx_only const VERSION_MINOR = 1




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
        s = @sprintf "opengl @ fps: %.2f" fps
        GLFW.SetWindowTitle(window, s)
        frameCount = 0
    end
    frameCount = frameCount + 1
end




# OpenGL logs
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




# set up GLFW log and error callbacks
@assert loginit("gl.log")
logadd("gl.log", "\nstarting GLFW ...")
logadd("gl.log", GLFW.GetVersionString())
# error callback
function error_callback(error::Cint, description::Ptr{GLchar})
    s = @sprintf "GLFW ERROR: code %i msg: %s" error description
	logerror("gl.log", s)
    return nothing
end
GLFW.SetErrorCallback(error_callback)

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




# create window
global glfwWidth = 640
global glfwHeight = 480
window = GLFW.CreateWindow(glfwWidth, glfwHeight, "Extended Init.", GLFW.NullMonitor, GLFW.NullWindow)
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

# enable depth test
glEnable(GL_DEPTH_TEST)
glDepthFunc(GL_LESS)




# get version info
renderer = bytestring(glGetString(GL_RENDERER))
version = bytestring(glGetString(GL_VERSION))
println("Renderder: ", renderer)
println("OpenGL version supported: ", version)
@assert parse(Float32, version[1:3]) >= 3.2 "OpenGL version must ≥ 3.2, Please upgrade your graphic driver."
# save logs
logadd("gl.log", string("renderer: ", renderer, "\nversion: ", version))
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
vboID = GLuint[0]
glGenBuffers(1, Ref(vboID))
glBindBuffer(GL_ARRAY_BUFFER, vboID[])
glBufferData(GL_ARRAY_BUFFER, sizeof(points), points, GL_STATIC_DRAW)




# create VAO
vaoID = GLuint[0]
glGenVertexArrays(1, Ref(vaoID))
glBindVertexArray(vaoID[])
glBindBuffer(GL_ARRAY_BUFFER, vboID[])
glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, C_NULL)
glEnableVertexAttribArray(0)




# loop
while !GLFW.WindowShouldClose(window)
    # show FPS
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
