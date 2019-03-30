using CSyntax

@static if Sys.isapple()
    const VERSION_MAJOR = 4
    const VERSION_MINOR = 1
end

include(joinpath(@__DIR__, "glutils.jl"))

# print errors in shader compilation
function shader_info_log(shader::GLuint)
    max_length = GLsizei(0)
    @c glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &max_length)
    actual_length = GLsizei(0)
    log = Vector{GLchar}(undef, max_length)
    @c glGetShaderInfoLog(shader, max_length, &actual_length, log)
    @info "shader info log for GL index $shader: $(String(log))"
end

# print errors in shader linking
function programme_info_log(program::GLuint)
    max_length = GLsizei(0)
    @c glGetShaderiv(program, GL_INFO_LOG_LENGTH, &max_length)
    actual_length = GLsizei(0)
    log = Vector{GLchar}(undef, max_length)
    @c glGetShaderInfoLog(program, max_length, &actual_length, log)
    @info "program info log for GL index $program: $(String(log))"
end

# validate shader program
function is_valid(program::GLuint)
    params = GLint(-1)
    glValidateProgram(program)
    @c glGetProgramiv(program, GL_VALIDATE_STATUS, &params)
    @info "program $program GL_VALIDATE_STATUS = $params"
    params == GL_TRUE && return true
    programme_info_log(program)
    return false
end

# print verbose infos
function print_all(shader_prog::GLuint)
    params = GLint(-1)

    @debug "-------------------------"
    @debug "Shader programme $shader_prog info:"
    @c glGetProgramiv(shader_prog, GL_LINK_STATUS, &params)
    @debug "GL_LINK_STATUS = $params"

    @c glGetProgramiv(shader_prog, GL_ATTACHED_SHADERS, &params)
    @debug "GL_ATTACHED_SHADERS = $params"

    @c glGetProgramiv(shader_prog, GL_ACTIVE_ATTRIBUTES, &params)
    @debug "GL_ACTIVE_ATTRIBUTES = $params"

    max_length = GLsizei(0)
    @c glGetProgramiv(shader_prog, GL_ACTIVE_ATTRIBUTE_MAX_LENGTH, &max_length)
    name = Vector{GLchar}(undef, max_length)
    for i in 0:params-1
        actual_length = GLsizei(0)
        size = GLint(0)
        type = GLenum(0)
        @c glGetActiveAttrib(shader_prog, i, max_length, &actual_length, &size, &type, name)
        if size > 1
            for j = 0:size-1
                longname = @sprintf "%s[%i]" name j
                location = glGetAttribLocation(shader_prog, longname)
                @debug "  $i): type -> $(GLENUM(type).name), name -> $(String(longname)), location -> $location."
            end
        else
            location = glGetAttribLocation(shader_prog, name)
            @debug "  $i): type -> $(GLENUM(type).name), name -> $(String(name)), location -> $location."
        end
    end

    @c glGetProgramiv(shader_prog, GL_ACTIVE_UNIFORMS, &params)
    @debug "GL_ACTIVE_UNIFORMS = $(paramsRef[])"
    for i in 0:params-1
        max_length = GLsizei(0)
        @c glGetProgramiv(shader_prog, GL_ACTIVE_UNIFORM_MAX_LENGTH, &max_length)
        name = Vector{GLchar}(undef, max_length)
        actual_length = GLsizei(0)
        size = GLint(0)
        type = GLenum(0)
        @c glGetActiveUniform(shader_prog, i, max_length, &actual_length, &size, &type, name)
        if size > 1
            for j = 0:size-1
                longname = @sprintf "%s[%i]" name j
                location = glGetUniformLocation(shader_prog, longname)
                @debug "  $i): type -> $(GLENUM(type).name), name -> $(String(longname)), location -> $location."
            end
        else
            location = glGetUniformLocation(shader_prog, name)
            @debug "  $i): type -> $(GLENUM(type).name), name -> $(String(name)), location -> $location."
        end
    end

    programme_info_log(shader_prog)
end


# init window
width, height = fb_width, fb_height = 640, 480
window = startgl(width, height)

glEnable(GL_DEPTH_TEST)
glDepthFunc(GL_LESS)

# load shaders from file
const vert_source = read(joinpath(@__DIR__, "shader.vert"), String)
const frag_source = read(joinpath(@__DIR__, "shader.frag"), String)

# compile shaders and check for shader compile errors
vert_shader = glCreateShader(GL_VERTEX_SHADER)
glShaderSource(vert_shader, 1, Ptr{GLchar}[pointer(vert_source)], C_NULL)
glCompileShader(vert_shader)
# get shader compile status
result = GLint(-1)
@c glGetShaderiv(vert_shader, GL_COMPILE_STATUS, &result)
if result != GL_TRUE
    shader_info_log(vert_shader)
    @error "GL vertex shader(index $vert_shader) did not compile."
end

frag_shader = glCreateShader(GL_FRAGMENT_SHADER)
glShaderSource(frag_shader, 1, Ptr{GLchar}[pointer(frag_source)], C_NULL)
glCompileShader(frag_shader)
# checkout shader compile status
result = GLint(-1)
@c glGetShaderiv(frag_shader, GL_COMPILE_STATUS, &result)
if result != GL_TRUE
    shaderlog(frag_shader)
    @error "GL fragment shader(index $frag_shader) did not compile."
end

# create and link shader program
shader_prog = glCreateProgram()
glAttachShader(shader_prog, vert_shader)
glAttachShader(shader_prog, frag_shader)
glLinkProgram(shader_prog)
# checkout programe linking status
result = GLint(-1)
@c glGetProgramiv(shader_prog, GL_LINK_STATUS, &result)
if result != GL_TRUE
    programme_info_log(shader_prog)
    @error "Could not link shader programme GL index: $shader_prog"
end

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
glBindBuffer(GL_ARRAY_BUFFER, vao)
glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, C_NULL)
glEnableVertexAttribArray(0)

# specify color
color_location = glGetUniformLocation(shader_prog, "inputColour")
@assert color_location > -1
glUseProgram(shader_prog)
glUniform4f(color_location, 1.0, 0.0, 0.0, 1.0)

# verbose infos
print_all(shader_prog)
@assert is_valid(shader_prog)

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
