using CSyntax

@static if Sys.isapple()
    const VERSION_MAJOR = 4
    const VERSION_MINOR = 1
end

include(joinpath(@__DIR__, "glutils.jl"))

# init window
width, height = fb_width, fb_height = 640, 480
window = startgl(width, height)

glEnable(GL_DEPTH_TEST)
glDepthFunc(GL_LESS)

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

# load and compile shaders from file
vert_shader = createshader(joinpath(@__DIR__, "vbo.vert"), GL_VERTEX_SHADER)
frag_shader = createshader(joinpath(@__DIR__, "vbo.frag"), GL_FRAGMENT_SHADER)

# link program
shader_prog = createprogram(vert_shader, frag_shader)

# enable cull face
glEnable(GL_CULL_FACE)
glCullFace(GL_BACK)
glFrontFace(GL_CW)
# set background color to gray
glClearColor(0.2, 0.2, 0.2, 1.0)

let
updatefps = FPSCounter()
# rendering loop
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
end # let

GLFW.DestroyWindow(window)
