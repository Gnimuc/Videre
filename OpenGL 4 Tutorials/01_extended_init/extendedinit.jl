using GLFW
using ModernGL
using CSyntax
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

# set up GLFW error callbacks
@info "starting GLFW ..."
@info GLFW.GetVersionString()

# error callback
error_callback(err::GLFW.GLFWError) = @error "GLFW ERROR: code $(err.code) msg: $(err.description)"
GLFW.SetErrorCallback(error_callback)

# set up GLFW key callbacks : press Esc to escape
function key_callback(window::GLFW.Window, key::GLFW.Key, scancode::Cint, action::GLFW.Action, mods::Cint)
	key == GLFW.KEY_ESCAPE && action == GLFW.PRESS && GLFW.SetWindowShouldClose(window, GL_TRUE)
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

width, height = fb_width, fb_height = 640, 480
window = GLFW.CreateWindow(width, height, "Extended Init.")
@assert window != C_NULL "could not open window with GLFW3."

GLFW.SetKeyCallback(window, key_callback)
GLFW.SetWindowSizeCallback(window, window_size_callback)
GLFW.SetFramebufferSizeCallback(window, framebuffer_size_callback)
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
const vert_source = """
#version 410 core
in vec3 vp;
void main(void)
{
    gl_Position = vec4(vp, 1.0);
}"""
const frag_source = """
#version 410 core
out vec4 frag_colour;
void main(void)
{
    frag_colour = vec4(0.5, 0.0, 0.5, 1.0);
}"""

# compile shaders
vert_shader = glCreateShader(GL_VERTEX_SHADER)
glShaderSource(vert_shader, 1, Ptr{GLchar}[pointer(vert_source)], C_NULL)
glCompileShader(vert_shader)
frag_shader = glCreateShader(GL_FRAGMENT_SHADER)
glShaderSource(frag_shader, 1, Ptr{GLchar}[pointer(frag_source)], C_NULL)
glCompileShader(frag_shader)

# create and link shader program
shader_prog = glCreateProgram()
glAttachShader(shader_prog, vert_shader)
glAttachShader(shader_prog, frag_shader)
glLinkProgram(shader_prog)

# vertex data
points = GLfloat[ 0.0,  0.5, 0.0,
                  0.5, -0.5, 0.0,
                 -0.5, -0.5, 0.0]

# create buffers located in the memory of graphic card
vbo = GLuint(0)
@c glGenBuffers(1, &vbo)
glBindBuffer(GL_ARRAY_BUFFER, vbo)
glBufferData(GL_ARRAY_BUFFER, sizeof(points), points, GL_STATIC_DRAW)

# create VAO
vao = GLuint(0)
@c glGenVertexArrays(1, &vao)
glBindVertexArray(vao)
glBindBuffer(GL_ARRAY_BUFFER, vbo)
glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, C_NULL)
glEnableVertexAttribArray(0)

# set background color to gray
glClearColor(0.2, 0.2, 0.2, 1.0)

# render
while !GLFW.WindowShouldClose(window)
    updatefps(window)
    # clear drawing surface
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
    glViewport(0, 0, width, height)
    # drawing
    glUseProgram(shader_prog)
    glBindVertexArray(vao)
    glDrawArrays(GL_TRIANGLES, 0, 3)
    # check and call events
    GLFW.PollEvents()
    # swap the buffers
    GLFW.SwapBuffers(window)
end

GLFW.DestroyWindow(window)
