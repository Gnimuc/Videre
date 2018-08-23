@static if Sys.isapple()
    const VERSION_MAJOR = 4
    const VERSION_MINOR = 1
end

include(joinpath(@__DIR__, "glutils.jl"))

# window init global variables
glfwWidth = 640
glfwHeight = 480
window = C_NULL

# start OpenGL
@assert startgl()

glEnable(GL_DEPTH_TEST)
glDepthFunc(GL_LESS)

# start OpenGL
@assert startgl()

glEnable(GL_DEPTH_TEST)
glDepthFunc(GL_LESS)

# load shaders from file
const vertexShaderSource = read(joinpath(@__DIR__, "vecmat.vert"), String)
const fragmentShaderSource = read(joinpath(@__DIR__, "vecmat.frag"), String)

# compile shaders and check for shader compile errors
vertexShader = glCreateShader(GL_VERTEX_SHADER)
glShaderSource(vertexShader, 1, Ptr{GLchar}[pointer(vertexShaderSource)], C_NULL)
glCompileShader(vertexShader)
# get shader compile status
resultRef = Ref{GLint}(-1)
glGetShaderiv(vertexShader, GL_COMPILE_STATUS, resultRef)
if resultRef[] != GL_TRUE
    shader_info_log(vertexShader)
    @error "GL vertex shader(index $vertexShader) did not compile."
end

fragmentShader = glCreateShader(GL_FRAGMENT_SHADER)
glShaderSource(fragmentShader, 1, Ptr{GLchar}[pointer(fragmentShaderSource)], C_NULL)
glCompileShader(fragmentShader)
# checkout shader compile status
resultRef = Ref{GLint}(-1)
glGetShaderiv(fragmentShader, GL_COMPILE_STATUS, resultRef)
if resultRef[] != GL_TRUE
    shaderlog(fragmentShader)
    @error "GL fragment shader(index $fragmentShader) did not compile."
end

# create and link shader program
shaderProgram = glCreateProgram()
glAttachShader(shaderProgram, vertexShader)
glAttachShader(shaderProgram, fragmentShader)
glLinkProgram(shaderProgram)
# checkout programe linking status
resultRef = Ref{GLint}(-1)
glGetProgramiv(shaderProgram, GL_LINK_STATUS, resultRef)
if resultRef[] != GL_TRUE
    programme_info_log(shaderProgram)
    @error "Could not link shader programme GL index: $shaderProgram"
end

# vertex data
points = GLfloat[ 0.0,  0.5, 0.0,
                  0.5, -0.5, 0.0,
                 -0.5, -0.5, 0.0]

colors = GLfloat[ 1.0, 0.0, 0.0,
                  0.0, 1.0, 0.0,
                  0.0, 0.0, 1.0]

# create buffers located in the memory of graphic card
pointsRef = Ref{GLuint}(0)
glGenBuffers(1, pointsRef)
glBindBuffer(GL_ARRAY_BUFFER, pointsRef[])
glBufferData(GL_ARRAY_BUFFER, sizeof(points), points, GL_STATIC_DRAW)

colorsRef = Ref{GLuint}(0)
glGenBuffers(1, colorsRef)
glBindBuffer(GL_ARRAY_BUFFER, colorsRef[])
glBufferData(GL_ARRAY_BUFFER, sizeof(colors), colors, GL_STATIC_DRAW)

# create VAO
vaoRef = Ref{GLuint}(0)
glGenVertexArrays(1, vaoRef)
glBindVertexArray(vaoRef[])
glBindBuffer(GL_ARRAY_BUFFER, pointsRef[])
glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, C_NULL)
glBindBuffer(GL_ARRAY_BUFFER, colorsRef[])
glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 0, C_NULL)
glEnableVertexAttribArray(0)
glEnableVertexAttribArray(1)

# create buffers located in the memory of graphic card
vboRef = Ref{GLuint}(0)
glGenBuffers(1, vboRef)
glBindBuffer(GL_ARRAY_BUFFER, vboRef[])
glBufferData(GL_ARRAY_BUFFER, sizeof(points), points, GL_STATIC_DRAW)

# enable cull face
glEnable(GL_CULL_FACE)
glCullFace(GL_BACK)
glFrontFace(GL_CW)
# set background color to gray
glClearColor(0.2, 0.2, 0.2, 1.0)

# transform matrix
matrix = GLfloat[1.0 0.0 0.0 0.5;
                 0.0 1.0 0.0 0.0;
                 0.0 0.0 1.0 0.0;
                 0.0 0.0 0.0 1.0]

matrixLocation = glGetUniformLocation(shaderProgram, "matrix")
glUseProgram(shaderProgram)
glUniformMatrix4fv(matrixLocation, 1, GL_FALSE, matrix)

# render
while !GLFW.WindowShouldClose(window)
    updatefps(window)
    # clear drawing surface
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
    glViewport(0, 0, glfwWidth, glfwHeight)
    # drawing
    glUseProgram(shaderProgram)
    # update matrix
    matrix[1,4] = sin(time())
    glUniformMatrix4fv(matrixLocation, 1, GL_FALSE, matrix)
    # drawcall
    glBindVertexArray(vaoRef[])
    glDrawArrays(GL_TRIANGLES, 0, 3)
    # check and call events
    GLFW.PollEvents()
    # swap the buffers
    GLFW.SwapBuffers(window)
end

GLFW.DestroyWindow(window)
