# load dependency packages
using GLFW, ModernGL
include("./glutils.jl")



# set up OpenGL context version(Mac only)
@osx_only const VERSION_MAJOR = 4    # it seems OSX will stuck on OpenGL 4.1.
@osx_only const VERSION_MINOR = 1


# window init global variables
glfwWidth = 640
glfwHeight = 480
window = C_NULL




# OpenGL init
@assert loginit("gl.log")
@assert startgl()

# enable depth test
glEnable(GL_DEPTH_TEST)
glDepthFunc(GL_LESS)




# load shaders from file
const vertexShader = readall(string(dirname(@__FILE__), "/vbo.vert"))
const fragmentShader = readall(string(dirname(@__FILE__), "/vbo.frag"))


# compile shaders and check for shader compile errors
vertexShaderID = glCreateShader(GL_VERTEX_SHADER)
glShaderSource(vertexShaderID, 1, [pointer(vertexShader)], C_NULL)
glCompileShader(vertexShaderID)
# get shader compile status
compileResult = GLint[-1]
glGetShaderiv(vertexShaderID, GL_COMPILE_STATUS, Ref(compileResult))
if compileResult[] != GL_TRUE
    logerror("gl.log", string("\nERROR: GL vertex shader(index", vertexShaderID, ")did not compile."))
    shaderlog(vertexShaderID)
end


fragmentShaderID = glCreateShader(GL_FRAGMENT_SHADER)
glShaderSource(fragmentShaderID, 1, [pointer(fragmentShader)], C_NULL)
glCompileShader(fragmentShaderID)
# checkout shader compile status
compileResult = GLint[-1]
glGetShaderiv(fragmentShaderID, GL_COMPILE_STATUS, Ref(compileResult))
if compileResult[] != GL_TRUE
    logerror("gl.log", string("\nERROR: GL fragment shader(index ", fragmentShaderID, " )did not compile."))
    shaderlog(fragmentShaderID)
end


# create and link shader program
shaderProgramID = glCreateProgram()
glAttachShader(shaderProgramID, vertexShaderID)
glAttachShader(shaderProgramID, fragmentShaderID)
glLinkProgram(shaderProgramID)
# checkout programe linking status
linkingResult = GLint[-1]
glGetProgramiv(shaderProgramID, GL_LINK_STATUS, Ref(linkingResult))
if linkingResult[] != GL_TRUE
    logerror("gl.log", string("\nERROR: could not link shader programme GL index: ", shaderProgramID))
    programlog(shaderProgramID)
end




# vertex data
points = GLfloat[ 0.0,  0.5, 0.0,
                  0.5, -0.5, 0.0,
                 -0.5, -0.5, 0.0]

colors = GLfloat[ 1.0, 0.0, 0.0,
                  0.0, 1.0, 0.0,
                  0.0, 0.0, 1.0]




# create buffers located in the memory of graphic card
pointsVBO = GLuint[0]
glGenBuffers(1, Ref(pointsVBO))
glBindBuffer(GL_ARRAY_BUFFER, pointsVBO[])
glBufferData(GL_ARRAY_BUFFER, sizeof(points), points, GL_STATIC_DRAW)

colorsVBO = GLuint[0]
glGenBuffers(1, Ref(colorsVBO))
glBindBuffer(GL_ARRAY_BUFFER, colorsVBO[])
glBufferData(GL_ARRAY_BUFFER, sizeof(colors), colors, GL_STATIC_DRAW)




# create VAO
vaoID = GLuint[0]
glGenVertexArrays(1, Ref(vaoID))
glBindVertexArray(vaoID[])
glBindBuffer(GL_ARRAY_BUFFER, pointsVBO[])
glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, C_NULL)
glBindBuffer(GL_ARRAY_BUFFER, colorsVBO[])
glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 0, C_NULL)
glEnableVertexAttribArray(0)
glEnableVertexAttribArray(1)




# enable cull face
glEnable(GL_CULL_FACE)
glCullFace(GL_BACK)
glFrontFace(GL_CW)




# loop
while !GLFW.WindowShouldClose(window)
    # show FPS
    updatefps(window)
    # clear drawing surface
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
    glViewport(0, 0, glfwWidth, glfwHeight)
    # drawing
    glUseProgram(shaderProgramID)
    glBindVertexArray(vaoID[])
    glDrawArrays(GL_TRIANGLES, 0, 3)
    # check and call events
    GLFW.PollEvents()
    # swap the buffers
    GLFW.SwapBuffers(window)
end




GLFW.Terminate()
