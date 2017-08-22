include(joinpath(dirname(@__FILE__), "glutils.jl"))

@static if is_apple()
    const VERSION_MAJOR = 4
    const VERSION_MINOR = 1
end

# window init global variables
glfwWidth = 640
glfwHeight = 480
window = C_NULL

# checkout shader infos
function shaderlog(shaderID::GLuint)
    maxLength = Ref{GLsizei}(0)
    glGetShaderiv(shaderID, GL_INFO_LOG_LENGTH, maxLength)
    actualLength = Ref{GLsizei}(0)
    log = Vector{GLchar}(maxLength[])
    glGetShaderInfoLog(shaderID, maxLength[], actualLength, log)
    logger = get_logger(current_module())
    info(logger, string("shader info log for GL index ", shaderID, ":"))
    info(logger, String(log))
end

# checkout program infos
function programlog(programID::GLuint)
    maxLength = Ref{GLsizei}(0)
    glGetProgramiv(programID, GL_INFO_LOG_LENGTH, maxLength)
    actualLength = Ref{GLsizei}(0)
    log = Vector{GLchar}(maxLength[])
    glGetProgramInfoLog(programID, maxLength[], actualLength, log)
    logger = get_logger(current_module())
    info(logger, string("program info log for GL index ", programID, ":"))
    info(logger, String(log))
end

# print verbose infos
function printall(shaderProgramID::GLuint)
    result = Ref{GLint}(-1)
    logger = get_logger(current_module())
    info(logger, string("Shader Program ", shaderProgramID, " verbose info:"))
    glGetProgramiv(shaderProgramID, GL_LINK_STATUS, result)
    info(logger, string("GL_LINK_STATUS = ", result[]))

    glGetProgramiv(shaderProgramID, GL_ATTACHED_SHADERS, result)
    info(logger, string("GL_ATTACHED_SHADERS = ", result[]))

    glGetProgramiv(shaderProgramID, GL_ACTIVE_ATTRIBUTES, result)
    info(logger, string("GL_ACTIVE_ATTRIBUTES = ", result[]))

    for i in 1:result[]
        maxLength = Ref{GLsizei}(0)
        glGetProgramiv(shaderProgramID, GL_ACTIVE_ATTRIBUTE_MAX_LENGTH, maxLength)
        actualLength = Ref{GLsizei}(0)
        attributeSize = Ref{GLint}(0)
        attributeType = Ref{GLenum}(0)
        name = Vector{GLchar}(maxLength[])
        glGetActiveAttrib(shaderProgramID, i-1, maxLength[], actualLength, attributeSize, attributeType, name)
        if attributeSize[] > 1
            for j = 1:attributeSize[]
                longName = @sprintf "%s[%i]" name j
                location = glGetAttribLocation(shaderProgramID, longName)
                log = string("  ", i, ") type:", GLENUM(attributeType[]).name, " name:", String(longName), " location:", location)
                info(logger, log)
            end
        else
            location = glGetAttribLocation(shaderProgramID, name)
            log = string("  ", i, ") type:", GLENUM(attributeType[]).name, " name:", String(name), " location:", location)
            info(logger, log)
        end
    end

    glGetProgramiv(shaderProgramID, GL_ACTIVE_UNIFORMS, result)
    info(logger, string("GL_ACTIVE_UNIFORMS = ", result[]))
    for i in 1:result[]
        maxLength = Ref{GLsizei}(0)
        glGetProgramiv(shaderProgramID, GL_ACTIVE_UNIFORM_MAX_LENGTH, maxLength)
        actualLength = Ref{GLsizei}(0)
        attributeSize = Ref{GLint}(0)
        attributeType = Ref{GLenum}(0)
        name = Vector{GLchar}(maxLength[])
        glGetActiveUniform(shaderProgramID, i-1, maxLength[], actualLength, attributeSize, attributeType, name)
        if attributeSize[] > 1
            for j = 1:attributeSize[]
                longName = @sprintf "%s[%i]" name j
                location = glGetUniformLocation(shaderProgramID, longName)
                log = string("  ", i, ") type:", GLENUM(attributeType[]).name, " name:", String(longName), " location:", location)
                info(logger, log)
            end
        else
            location = glGetUniformLocation(shaderProgramID, name)
            log = string("  ", i, ") type:", GLENUM(attributeType[]).name, " name:", String(name), " location:", location)
            info(logger, log)
        end
    end
    programlog(shaderProgramID)
end

# validate shader program
function validprogram(shaderProgramID::GLuint)
    validResult = Ref{GLint}(-1)
    glValidateProgram(shaderProgramID)
    glGetProgramiv(shaderProgramID, GL_VALIDATE_STATUS, validResult)
    log = string("program ", shaderProgramID, " GL_VALIDATE_STATUS = ", validResult[])
    logger = get_logger(current_module())
    info(logger, log)
    if validResult[] != GL_TRUE
        programlog(shaderProgramID)
        return false
    end
    return true
end

# start OpenGL
@assert startgl()

glEnable(GL_DEPTH_TEST)
glDepthFunc(GL_LESS)

# load shaders from file
const vertexShader = readstring(joinpath(dirname(@__FILE__), "shader.vert"))
const fragmentShader = readstring(joinpath(dirname(@__FILE__), "shader.frag"))

# compile shaders and check for shader compile errors
vertexShaderID = glCreateShader(GL_VERTEX_SHADER)
glShaderSource(vertexShaderID, 1, [pointer(vertexShader)], C_NULL)
glCompileShader(vertexShaderID)
# get shader compile status
compileResult = Ref{GLint}(-1)
glGetShaderiv(vertexShaderID, GL_COMPILE_STATUS, compileResult)
if compileResult[] != GL_TRUE
    logger = get_logger(current_module())
    warn(logger, string("GL vertex shader(index", vertexShaderID, ")did not compile."))
    shaderlog(vertexShaderID)
    error("GL vertex shader(index ", vertexShaderID, " )did not compile.")
end

fragmentShaderID = glCreateShader(GL_FRAGMENT_SHADER)
glShaderSource(fragmentShaderID, 1, [pointer(fragmentShader)], C_NULL)
glCompileShader(fragmentShaderID)
# checkout shader compile status
compileResult = Ref{GLint}(-1)
glGetShaderiv(fragmentShaderID, GL_COMPILE_STATUS, compileResult)
if compileResult[] != GL_TRUE
    logger = get_logger(current_module())
    warn(logger, string("GL fragment shader(index ", fragmentShaderID, " )did not compile."))
    shaderlog(fragmentShaderID)
    error("GL fragment shader(index ", fragmentShaderID, " )did not compile.")
end

# create and link shader program
shaderProgramID = glCreateProgram()
glAttachShader(shaderProgramID, vertexShaderID)
glAttachShader(shaderProgramID, fragmentShaderID)
glLinkProgram(shaderProgramID)
# checkout programe linking status
linkingResult = Ref{GLint}(-1)
glGetProgramiv(shaderProgramID, GL_LINK_STATUS, linkingResult)
if linkingResult[] != GL_TRUE
    logger = get_logger(current_module())
    warn(logger, string("Could not link shader programme GL index: ", shaderProgramID))
    programlog(shaderProgramID)
    error("Could not link shader programme GL index: ", shaderProgramID)
end

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

# specify color
colorLocation = glGetUniformLocation(shaderProgramID, "inputColour")
@assert colorLocation > -1
glUseProgram(shaderProgramID)
glUniform4f(colorLocation, 1.0, 0.0, 0.0, 1.0)

# verbose infos
printall(shaderProgramID)
@assert validprogram(shaderProgramID)

# render
while !GLFW.WindowShouldClose(window)
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
