# load dependency packages
using GLFW, ModernGL


# set up OpenGL context version
@osx_only const VERSION_MAJOR = 4    # it seems OSX will stuck on OpenGL 4.1.
@osx_only const VERSION_MINOR = 1


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

# create window
window = GLFW.CreateWindow(640, 480, "Hello Triangle", GLFW.NullMonitor, GLFW.NullWindow)
if window == C_NULL
    println("error: GLFW window creating failed.")
    GLFW.Terminate()
end
# set callbacks
GLFW.SetKeyCallback(window, key_callback)
# make current context
GLFW.MakeContextCurrent(window)

# get version info
renderer = bytestring(glGetString(GL_RENDERER))
version = bytestring(glGetString(GL_VERSION))
println("Renderder: ", renderer)
println("OpenGL version supported: ", version)

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
vboID = convert(GLuint, 0)
ref_vboID = Ref(vboID)
glGenBuffers(1, ref_vboID)
vboID = ref_vboID[]
glBindBuffer(GL_ARRAY_BUFFER, vboID)
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
    # clear drawing surface
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
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
