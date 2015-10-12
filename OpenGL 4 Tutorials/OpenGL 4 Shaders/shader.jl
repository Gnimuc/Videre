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




# checkout shader infos
function shaderlog(shaderID::GLuint)
    maxLength = GLsizei[0]
    glGetShaderiv(shaderID, GL_INFO_LOG_LENGTH, Ref(maxLength))
    actualLength = GLsizei[0]
    log = Array{GLchar}(maxLength[])
    glGetShaderInfoLog(shaderID, maxLength[], Ref(actualLength), Ref(log))
    # print log
    println("shader info log for GL index ", shaderID, ":")
    println(ASCIIString(log))
    # save log
    logadd("gl.log", string("shader info log for GL index ", shaderID, ":"))
    logadd("gl.log", ASCIIString(log))
end

# checkout program infos
function programlog(programID::GLuint)
    maxLength = GLsizei[0]
    glGetProgramiv(programID, GL_INFO_LOG_LENGTH, Ref(maxLength))
    actualLength = GLsizei[0]
    log = Array{GLchar}(maxLength[])
    glGetProgramInfoLog(programID, maxLength[], Ref(actualLength), Ref(log))
    # print log
    println("program info log for GL index ", programID, ":")
    println(ASCIIString(log))
    # save log
    logadd("gl.log", string("program info log for GL index ", programID, ":"))
    logadd("gl.log", ASCIIString(log))
end

# print verbose infos
function printall(shaderProgramID::GLuint)
    result = GLint[-1]

    logerror("gl.log", string("--------------------\nshader program ", shaderProgramID, " verbose info:\n"))
    glGetProgramiv(shaderProgramID, GL_LINK_STATUS, Ref(result))
    logerror("gl.log", string("GL_LINK_STATUS = ", result[]))

    glGetProgramiv(shaderProgramID, GL_ATTACHED_SHADERS, Ref(result))
    logerror("gl.log", string("GL_ATTACHED_SHADERS = ", result[]))

    glGetProgramiv(shaderProgramID, GL_ACTIVE_ATTRIBUTES, Ref(result))
    logerror("gl.log", string("GL_ACTIVE_ATTRIBUTES = ", result[]))

    for i in eachindex(result)
        maxLength = GLsizei[0]
        glGetProgramiv(shaderProgramID, GL_ACTIVE_ATTRIBUTE_MAX_LENGTH, Ref(maxLength))
        actualLength = GLsizei[0]
        attributeSize = GLint[0]
        attributeType = GLenum[0]
        name = Array{GLchar}(maxLength[])
        glGetActiveAttrib(shaderProgramID, i-1, maxLength[], Ref(actualLength), Ref(attributeSize), Ref(attributeType), Ref(name))
        if attributeSize[] > 1
            for j = 1: attributeSize[]
                longName = @sprintf "%s[%i]" name j
                location = glGetAttribLocation(shaderProgramID, Ref(longName))
                log = string("  ", i, ") type:", GLENUM(attributeType[]).name, " name:", ASCIIString(longName), " location:", location)
                println(log)
                logadd("gl.log", log)
            end
        else
            location = glGetAttribLocation(shaderProgramID, Ref(name))
            log = string("  ", i, ") type:", GLENUM(attributeType[]).name, " name:", ASCIIString(name), " location:", location)
            println(log)
            logadd("gl.log", log)
        end
    end

    glGetProgramiv(shaderProgramID, GL_ACTIVE_UNIFORMS, Ref(result))
    logerror("gl.log", string("GL_ACTIVE_UNIFORMS = ", result[]))
    for i in eachindex(result)
        maxLength = GLsizei[0]
        glGetProgramiv(shaderProgramID, GL_ACTIVE_UNIFORM_MAX_LENGTH, Ref(maxLength))
        actualLength = GLsizei[0]
        attributeSize = GLint[0]
        attributeType = GLenum[0]
        name = Array{GLchar}(maxLength[])
        glGetActiveUniform(shaderProgramID, i-1, maxLength[], Ref(actualLength), Ref(attributeSize), Ref(attributeType), Ref(name))
        if attributeSize[] > 1
            for j = 1: attributeSize[]
                longName = @sprintf "%s[%i]" name j
                location = glGetUniformLocation(shaderProgramID, Ref(longName))
                log = string("  ", i, ") type:", GLENUM(attributeType[]).name, " name:", ASCIIString(longName), " location:", location)
                println(log)
                logadd("gl.log", log)
            end
        else
            location = glGetUniformLocation(shaderProgramID, Ref(name))
            log = string("  ", i, ") type:", GLENUM(attributeType[]).name, " name:", ASCIIString(name), " location:", location)
            println(log)
            logadd("gl.log", log)
        end
    end
            programlog(shaderProgramID)
end

# validate shader program
function validprogram(shaderProgramID::GLuint)
    validResult = GLint[-1]
    glValidateProgram(shaderProgramID)
    glGetProgramiv(shaderProgramID, GL_VALIDATE_STATUS, Ref(validResult))
    log = string("program ", shaderProgramID, " GL_VALIDATE_STATUS = ", validResult[])
    logadd("gl.log", log)
    println(log)
    if validResult[] != GL_TRUE
        programlog(shaderProgramID)
        return false
    end
    return true
end




# OpenGL init
@assert loginit("gl.log")
@assert startgl()

# enable depth test
glEnable(GL_DEPTH_TEST)
glDepthFunc(GL_LESS)




# load shaders from file
const vertexShader = readall(string(dirname(@__FILE__), "/shader.vert"))
const fragmentShader = readall(string(dirname(@__FILE__), "/shader.frag"))


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




# specify color
colorLocation = glGetUniformLocation(shaderProgramID, "inputColour")
@assert colorLocation > -1
glUseProgram(shaderProgramID)
glUniform4f(colorLocation, 1.0, 0.0, 0.0, 1.0)




# verbose infos
printall(shaderProgramID)
@assert validprogram(shaderProgramID)




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
