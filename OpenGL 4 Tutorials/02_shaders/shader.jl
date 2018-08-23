@static if Sys.isapple()
    const VERSION_MAJOR = 4
    const VERSION_MINOR = 1
end

include(joinpath(@__DIR__, "glutils.jl"))

# window init global variables
glfwWidth = 640
glfwHeight = 480
window = C_NULL

# print errors in shader compilation
function shader_info_log(shader::GLuint)
    maxLengthRef = Ref{GLsizei}(0)
    glGetShaderiv(shader, GL_INFO_LOG_LENGTH, maxLengthRef)
    actualLengthRef = Ref{GLsizei}(0)
    log = Vector{GLchar}(undef, maxLengthRef[])
    glGetShaderInfoLog(shader, maxLengthRef[], actualLengthRef, log)
    @info "shader info log for GL index $shader: $(String(log))"
end

# print errors in shader linking
function programme_info_log(program::GLuint)
    maxLengthRef = Ref{GLsizei}(0)
    glGetProgramiv(program, GL_INFO_LOG_LENGTH, maxLengthRef)
    actualLengthRef = Ref{GLsizei}(0)
    log = Vector{GLchar}(undef, maxLengthRef[])
    glGetProgramInfoLog(program, maxLengthRef[], actualLengthRef, log)
    @info "program info log for GL index $program: $(String(log))"
end

# validate shader program
function is_valid(shaderProgram::GLuint)
    paramsRef = Ref{GLint}(-1)
    glValidateProgram(shaderProgram)
    glGetProgramiv(shaderProgram, GL_VALIDATE_STATUS, paramsRef)
    @info "program $shaderProgram GL_VALIDATE_STATUS = $(paramsRef[])"
    if paramsRef[] != GL_TRUE
        programme_info_log(shaderProgram)
        return false
    end
    return true
end

# print verbose infos
function print_all(shaderProgram::GLuint)
    paramsRef = Ref{GLint}(-1)

    @debug "-------------------------"
    @debug "Shader programme $shaderProgram info:"
    glGetProgramiv(shaderProgram, GL_LINK_STATUS, paramsRef)
    @debug "GL_LINK_STATUS = $(paramsRef[])"

    glGetProgramiv(shaderProgram, GL_ATTACHED_SHADERS, paramsRef)
    @debug "GL_ATTACHED_SHADERS = $(paramsRef[])"

    glGetProgramiv(shaderProgram, GL_ACTIVE_ATTRIBUTES, paramsRef)
    @debug "GL_ACTIVE_ATTRIBUTES = $(paramsRef[])"

    maxLengthRef = Ref{GLsizei}(0)
    glGetProgramiv(shaderProgram, GL_ACTIVE_ATTRIBUTE_MAX_LENGTH, maxLengthRef)
    name = Vector{GLchar}(undef, maxLengthRef[])
    for i in 0:paramsRef[]-1
        actualLengthRef = Ref{GLsizei}(0)
        sizeRef = Ref{GLint}(0)
        typeRef = Ref{GLenum}(0)
        glGetActiveAttrib(shaderProgram, i, maxLengthRef[], actualLengthRef, sizeRef, typeRef, name)
        if sizeRef[] > 1
            for j = 0:sizeRef[]-1
                longName = @sprintf "%s[%i]" name j
                location = glGetAttribLocation(shaderProgram, longName)
                @debug "  $i): type -> $(GLENUM(typeRef[]).name), name -> $(String(longName)), location -> $location."
            end
        else
            location = glGetAttribLocation(shaderProgram, name)
            @debug "  $i): type -> $(GLENUM(typeRef[]).name), name -> $(String(name)), location -> $location."
        end
    end

    glGetProgramiv(shaderProgram, GL_ACTIVE_UNIFORMS, paramsRef)
    @debug "GL_ACTIVE_UNIFORMS = $(paramsRef[])"
    for i in 0:paramsRef[]-1
        maxLengthRef = Ref{GLsizei}(0)
        glGetProgramiv(shaderProgram, GL_ACTIVE_UNIFORM_MAX_LENGTH, maxLengthRef)
        name = Vector{GLchar}(undef, maxLengthRef[])
        actualLengthRef = Ref{GLsizei}(0)
        sizeRef = Ref{GLint}(0)
        typeRef = Ref{GLenum}(0)
        glGetActiveUniform(shaderProgram, i, maxLengthRef[], actualLengthRef, sizeRef, typeRef, name)
        if sizeRef[] > 1
            for j = 0:sizeRef[]-1
                longName = @sprintf "%s[%i]" name j
                location = glGetUniformLocation(shaderProgram, longName)
                @debug "  $i): type -> $(GLENUM(typeRef[]).name), name -> $(String(longName)), location -> $location."
            end
        else
            location = glGetUniformLocation(shaderProgram, name)
            @debug "  $i): type -> $(GLENUM(typeRef[]).name), name -> $(String(name)), location -> $location."
        end
    end

    programme_info_log(shaderProgram)
end


# start OpenGL
@assert startgl()

glEnable(GL_DEPTH_TEST)
glDepthFunc(GL_LESS)

# load shaders from file
const vertexShaderSource = read(joinpath(@__DIR__, "shader.vert"), String)
const fragmentShaderSource = read(joinpath(@__DIR__, "shader.frag"), String)

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

# create buffers located in the memory of graphic card
vboRef = Ref{GLuint}(0)
glGenBuffers(1, vboRef)
glBindBuffer(GL_ARRAY_BUFFER, vboRef[])
glBufferData(GL_ARRAY_BUFFER, sizeof(points), points, GL_STATIC_DRAW)

# create VAO
vaoRef = Ref{GLuint}(0)
glGenVertexArrays(1, vaoRef)
glBindVertexArray(vaoRef[])
glBindBuffer(GL_ARRAY_BUFFER, vaoRef[])
glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, C_NULL)
glEnableVertexAttribArray(0)

# specify color
colorLocation = glGetUniformLocation(shaderProgram, "inputColour")
@assert colorLocation > -1
glUseProgram(shaderProgram)
glUniform4f(colorLocation, 1.0, 0.0, 0.0, 1.0)

# verbose infos
print_all(shaderProgram)
@assert is_valid(shaderProgram)

# set background color to gray
glClearColor(0.2, 0.2, 0.2, 1.0)

# render
while !GLFW.WindowShouldClose(window)
    updatefps(window)
    # clear drawing surface
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
    glViewport(0, 0, glfwWidth, glfwHeight)
    # drawing
    glUseProgram(shaderProgram)
    glBindVertexArray(vaoRef[])
    glDrawArrays(GL_TRIANGLES, 0, 3)
    # check and call events
    GLFW.PollEvents()
    # swap the buffers
    GLFW.SwapBuffers(window)
end

GLFW.DestroyWindow(window)
