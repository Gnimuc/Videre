using GLFW
using ModernGL

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

# set background color to gray
glClearColor(0.2, 0.2, 0.2, 1.0)

# render
while !GLFW.WindowShouldClose(window)
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
    glUseProgram(shaderProgram)
    glBindVertexArray(vaoID[])
    glDrawArrays(GL_TRIANGLES, 0, 3)
    # check and call events
    GLFW.PollEvents()
    # swap the buffers
    GLFW.SwapBuffers(window)
end

GLFW.DestroyWindow(window)
