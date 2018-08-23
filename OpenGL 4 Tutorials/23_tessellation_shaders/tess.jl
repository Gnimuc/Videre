include(joinpath(@__DIR__, "glutils.jl"))

@static if Sys.isapple()
    const VERSION_MAJOR = 4
    const VERSION_MINOR = 1
end

# window init global variables
glfwWidth = 640
glfwHeight = 480
window = C_NULL

# start OpenGL
@assert startgl()

glEnable(GL_DEPTH_TEST)
glDepthFunc(GL_LESS)

# load shaders from file
const vertexShader = readstring(joinpath(@__DIR__, "tess.vert"))
const tessellationControlShader = readstring(joinpath(@__DIR__, "tess.tesc"))
const tessellationEvaluationShader = readstring(joinpath(@__DIR__, "tess.tese"))
const fragmentShader = readstring(joinpath(@__DIR__, "tess.frag"))

# compile shaders and check for shader compile errors
vertexShaderID = glCreateShader(GL_VERTEX_SHADER)
glShaderSource(vertexShaderID, 1, Ptr{GLchar}[pointer(vertexShader)], C_NULL)
glCompileShader(vertexShaderID)
# get shader compile status
compileResult = Ref{GLint}(-1)
glGetShaderiv(vertexShaderID, GL_COMPILE_STATUS, compileResult)
if compileResult[] != GL_TRUE
    logger = getlogger(current_module())
    warn(logger, string("GL vertex shader(index", vertexShaderID, ")did not compile."))
    shaderlog(vertexShaderID)
    error("GL vertex shader(index ", vertexShaderID, " )did not compile.")
end

tessellationControlShaderID = glCreateShader(GL_TESS_CONTROL_SHADER)
glShaderSource(tessellationControlShaderID, 1, Ptr{GLchar}[pointer(tessellationControlShader)], C_NULL)
glCompileShader(tessellationControlShaderID)
# get shader compile status
compileResult = Ref{GLint}(-1)
glGetShaderiv(tessellationControlShaderID, GL_COMPILE_STATUS, compileResult)
if compileResult[] != GL_TRUE
    logger = getlogger(current_module())
    warn(logger, string("GL vertex shader(index", tessellationControlShaderID, ")did not compile."))
    shaderlog(tessellationControlShaderID)
    error("GL vertex shader(index ", tessellationControlShaderID, " )did not compile.")
end

tessellationEvaluationShaderID = glCreateShader(GL_TESS_EVALUATION_SHADER)
glShaderSource(tessellationEvaluationShaderID, 1, Ptr{GLchar}[pointer(tessellationEvaluationShader)], C_NULL)
glCompileShader(tessellationEvaluationShaderID)
# get shader compile status
compileResult = Ref{GLint}(-1)
glGetShaderiv(tessellationEvaluationShaderID, GL_COMPILE_STATUS, compileResult)
if compileResult[] != GL_TRUE
    logger = getlogger(current_module())
    warn(logger, string("GL vertex shader(index", tessellationEvaluationShaderID, ")did not compile."))
    shaderlog(tessellationEvaluationShaderID)
    error("GL vertex shader(index ", tessellationEvaluationShaderID, " )did not compile.")
end

fragmentShaderID = glCreateShader(GL_FRAGMENT_SHADER)
glShaderSource(fragmentShaderID, 1, Ptr{GLchar}[pointer(fragmentShader)], C_NULL)
glCompileShader(fragmentShaderID)
# checkout shader compile status
compileResult = Ref{GLint}(-1)
glGetShaderiv(fragmentShaderID, GL_COMPILE_STATUS, compileResult)
if compileResult[] != GL_TRUE
    logger = getlogger(current_module())
    warn(logger, string("GL fragment shader(index ", fragmentShaderID, " )did not compile."))
    shaderlog(fragmentShaderID)
    error("GL fragment shader(index ", fragmentShaderID, " )did not compile.")
end

# create and link shader program
shaderProgramID = glCreateProgram()
glAttachShader(shaderProgramID, vertexShaderID)
glAttachShader(shaderProgramID, tessellationControlShaderID)
glAttachShader(shaderProgramID, tessellationEvaluationShaderID)
glAttachShader(shaderProgramID, fragmentShaderID)
glLinkProgram(shaderProgramID)
# checkout programe linking status
linkingResult = Ref{GLint}(-1)
glGetProgramiv(shaderProgramID, GL_LINK_STATUS, linkingResult)
if linkingResult[] != GL_TRUE
    logger = getlogger(current_module())
    warn(logger, string("Could not link shader programme GL index: ", shaderProgramID))
    programlog(shaderProgramID)
    error("Could not link shader programme GL index: ", shaderProgramID)
end

innerTessFactorLocation = glGetUniformLocation(shaderProgramID, "tess_fac_inner")
outerTessFactorLocation = glGetUniformLocation(shaderProgramID, "tess_fac_outer")

# vertex data
points = GLfloat[ 0.0, 0.75, 0.0,
                  0.5, 0.25, 0.0,
                 -0.5, 0.25, 0.0,
                  0.5,-0.25, 0.0,
                  0.0,-0.75, 0.0,
                 -0.5,-0.25, 0.0]

# create buffers located in the memory of graphic card
pointsVBO = Ref{GLuint}(0)
glGenBuffers(1, pointsVBO)
glBindBuffer(GL_ARRAY_BUFFER, pointsVBO[])
glBufferData(GL_ARRAY_BUFFER, sizeof(points), points, GL_STATIC_DRAW)

# create VAO
vaoID = Ref{GLuint}(0)
glGenVertexArrays(1, vaoID)
glBindVertexArray(vaoID[])
glBindBuffer(GL_ARRAY_BUFFER, pointsVBO[])
glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, C_NULL)
glEnableVertexAttribArray(0)

# verbose infos
printall(shaderProgramID)
@assert validprogram(shaderProgramID)

glEnable(GL_CULL_FACE)
glCullFace(GL_BACK)
glFrontFace(GL_CW)
glPolygonMode(GL_FRONT_AND_BACK, GL_LINE)
glPatchParameteri(GL_PATCH_VERTICES, 3)
# set background color to gray
glClearColor(0.2, 0.2, 0.2, 1.0)

# render
innerTessFactor = GLfloat(1)
outerTessFactor = GLfloat(4)
qWasDown = false
aWasDown = false
wWasDown = false
sWasDown = false
while !GLFW.WindowShouldClose(window)
    updatefps(window)
    # clear drawing surface
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
    glViewport(0, 0, glfwWidth, glfwHeight)
    # drawing
    glUseProgram(shaderProgramID)
    glBindVertexArray(vaoID[])
    glDrawArrays(GL_PATCHES, 0, 6)
    # check and call events
    GLFW.PollEvents()
    if GLFW.PRESS == GLFW.GetKey(window, GLFW.KEY_Q)
        if !qWasDown
            innerTessFactor += 1
            println("inner tessellation factor = $innerTessFactor.")
            glUniform1f(innerTessFactorLocation, innerTessFactor)
            qWasDown = true
        end
    else
        qWasDown = false
    end
    if GLFW.PRESS == GLFW.GetKey(window, GLFW.KEY_A)
        if !aWasDown
            innerTessFactor -= 1
            println("inner tessellation factor = $innerTessFactor.")
            glUniform1f(innerTessFactorLocation, innerTessFactor)
            aWasDown = true
        end
    else
        aWasDown = false
    end
    if GLFW.PRESS == GLFW.GetKey(window, GLFW.KEY_W)
        if !wWasDown
            outerTessFactor += 1
            println("outer tessellation factor = $outerTessFactor.")
            glUniform1f(outerTessFactorLocation, outerTessFactor)
            wWasDown = true
        end
    else
        wWasDown = false
    end
    if GLFW.PRESS == GLFW.GetKey(window, GLFW.KEY_S)
        if !sWasDown
            outerTessFactor -= 1
            println("outer tessellation factor = $outerTessFactor.")
            glUniform1f(outerTessFactorLocation, outerTessFactor)
            sWasDown = true
        end
    else
        sWasDown = false
    end
    # swap the buffers
    GLFW.SwapBuffers(window)
end

GLFW.DestroyWindow(window)
