using CSyntax

@static if Sys.isapple()
    const VERSION_MAJOR = 4
    const VERSION_MINOR = 1
end

include(joinpath(@__DIR__, "glutils.jl"))

# init window
width, height = 640, 480
window = startgl(width, height)

glEnable(GL_DEPTH_TEST)
glDepthFunc(GL_LESS)

# load shaders from file
const vert_source = read(joinpath(@__DIR__, "vecmat.vert"), String)
const frag_source = read(joinpath(@__DIR__, "vecmat.frag"), String)

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

colors = GLfloat[ 1.0, 0.0, 0.0,
                  0.0, 1.0, 0.0,
                  0.0, 0.0, 1.0]

# create buffers located in the memory of graphic card
points_vbo = GLuint(0)
@c glGenBuffers(1, &points_vbo)
glBindBuffer(GL_ARRAY_BUFFER, points_vbo)
glBufferData(GL_ARRAY_BUFFER, sizeof(points), points, GL_STATIC_DRAW)

colors_vbo = GLuint(0)
@c glGenBuffers(1, &colors_vbo)
glBindBuffer(GL_ARRAY_BUFFER, colors_vbo)
glBufferData(GL_ARRAY_BUFFER, sizeof(colors), colors, GL_STATIC_DRAW)

# create VAO
vao = GLuint(0)
@c glGenVertexArrays(1, &vao)
glBindVertexArray(vao)
glBindBuffer(GL_ARRAY_BUFFER, points_vbo)
glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, C_NULL)
glBindBuffer(GL_ARRAY_BUFFER, colors_vbo)
glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 0, C_NULL)
glEnableVertexAttribArray(0)
glEnableVertexAttribArray(1)

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

matrix_location = glGetUniformLocation(shader_prog, "matrix")
glUseProgram(shader_prog)
glUniformMatrix4fv(matrix_location, 1, GL_FALSE, matrix)

# render
while !GLFW.WindowShouldClose(window)
    updatefps(window)
    # clear drawing surface
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
    glViewport(0, 0, width, height)
    # drawing
    glUseProgram(shader_prog)
    # update matrix
    matrix[1,4] = sin(time())
    glUniformMatrix4fv(matrix_location, 1, GL_FALSE, matrix)
    # drawcall
    glBindVertexArray(vao)
    glDrawArrays(GL_TRIANGLES, 0, 3)
    # check and call events
    GLFW.PollEvents()
    # swap the buffers
    GLFW.SwapBuffers(window)
end

GLFW.DestroyWindow(window)
