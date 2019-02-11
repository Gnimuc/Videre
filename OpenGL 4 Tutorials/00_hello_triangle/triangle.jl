using GLFW
using ModernGL
using CSyntax

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

# create window
window = GLFW.CreateWindow(640, 480, "Hello Triangle")
window == C_NULL && error("could not open window with GLFW3.")
GLFW.MakeContextCurrent(window)

# get version info
renderer = unsafe_string(glGetString(GL_RENDERER))
version = unsafe_string(glGetString(GL_VERSION))
@info "Renderder: $renderer"
@info "OpenGL version supported: $version"

# enable depth test
glEnable(GL_DEPTH_TEST)
glDepthFunc(GL_LESS)

# hard-coded shaders
const vertex_shader = """
#version 410 core
in vec3 vp;
void main(void)
{
    gl_Position = vec4(vp, 1.0);
}"""
const fragment_shader = """
#version 410 core
out vec4 frag_colour;
void main(void)
{
    frag_colour = vec4(0.5, 0.0, 0.5, 1.0);
}"""

# compile shaders
vertex_shader_id = glCreateShader(GL_VERTEX_SHADER)
glShaderSource(vertex_shader_id, 1, Ptr{GLchar}[pointer(vertex_shader)], C_NULL)
glCompileShader(vertex_shader_id)
fragment_shader_id = glCreateShader(GL_FRAGMENT_SHADER)
glShaderSource(fragment_shader_id, 1, Ptr{GLchar}[pointer(fragment_shader)], C_NULL)
glCompileShader(fragment_shader_id)

# create and link shader program
program_id = glCreateProgram()
glAttachShader(program_id, vertex_shader_id)
glAttachShader(program_id, fragment_shader_id)
glLinkProgram(program_id)

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
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
    glUseProgram(program_id)
    glBindVertexArray(vao)
    glDrawArrays(GL_TRIANGLES, 0, 3)
    # check and call events
    GLFW.PollEvents()
    # swap the buffers
    GLFW.SwapBuffers(window)
end

GLFW.DestroyWindow(window)
