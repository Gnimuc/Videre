using CSyntax
using LinearAlgebra

@static if Sys.isapple()
    const VERSION_MAJOR = 4
    const VERSION_MINOR = 1
end

include(joinpath(@__DIR__, "glutils.jl"))
include(joinpath(@__DIR__, "camera.jl"))

# init window
width, height = 640, 480
window = startgl(width, height)

glEnable(GL_DEPTH_TEST)
glDepthFunc(GL_LESS)

# camera
camera = PerspectiveCamera()
setposition!(camera, [0.0, 0.0, 2.0])

# vertex and normal
points = GLfloat[ 0.0, 0.5, 0.0,
                  0.5,-0.5, 0.0,
                 -0.5,-0.5, 0.0]

normals = GLfloat[0.0, 0.0, 1.0,
                  0.0, 0.0, 1.0,
                  0.0, 0.0, 1.0]

# create VBO
points_vbo = GLuint(0)
@c glGenBuffers(1, &points_vbo)
glBindBuffer(GL_ARRAY_BUFFER, points_vbo)
glBufferData(GL_ARRAY_BUFFER, sizeof(points), points, GL_STATIC_DRAW)

normals_vbo = GLuint(0)
@c glGenBuffers(1, &normals_vbo)
glBindBuffer(GL_ARRAY_BUFFER, normals_vbo)
glBufferData(GL_ARRAY_BUFFER, sizeof(normals), normals, GL_STATIC_DRAW)

# create VAO
vao = GLuint(0)
@c glGenVertexArrays(1, &vao)
glBindVertexArray(vao)
glBindBuffer(GL_ARRAY_BUFFER, points_vbo)
glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, C_NULL)
glBindBuffer(GL_ARRAY_BUFFER, normals_vbo)
glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 0, C_NULL)
glEnableVertexAttribArray(0)
glEnableVertexAttribArray(1)

# create shader program
vert_shader = createshader(joinpath(@__DIR__, "spotlight.vert"), GL_VERTEX_SHADER)
frag_shader = createshader(joinpath(@__DIR__, "spotlight.frag"), GL_FRAGMENT_SHADER)
shader_prog = createprogram(vert_shader, frag_shader)

model_loc = glGetUniformLocation(shader_prog, "model_mat")
view_loc = glGetUniformLocation(shader_prog, "view_mat")
proj_loc = glGetUniformLocation(shader_prog, "projection_mat")
glUseProgram(shader_prog)
model_matrix = Matrix{GLfloat}(I, 4, 4)
glUniformMatrix4fv(model_loc, 1, GL_FALSE, model_matrix)
glUniformMatrix4fv(view_loc, 1, GL_FALSE, get_view_matrix(camera))
glUniformMatrix4fv(proj_loc, 1, GL_FALSE, get_projective_matrix(window, camera))

# enable cull face
glEnable(GL_CULL_FACE)
glCullFace(GL_BACK)
glFrontFace(GL_CW)
# set background color to gray
glClearColor(0.2, 0.2, 0.2, 1.0)

let
updatefps = FPSCounter()
# render
while !GLFW.WindowShouldClose(window)
    updatefps(window)
    # clear drawing surface
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
    glViewport(0, 0, GLFW.GetFramebufferSize(window)...)
    # drawing
    glUseProgram(shader_prog)
    glBindBuffer(GL_ARRAY_BUFFER, vao)
    model_matrix[1,4] = sin(time())
    glUniformMatrix4fv(model_loc, 1, GL_FALSE, model_matrix)
    glDrawArrays(GL_TRIANGLES, 0, 3)
    # check and call events
    GLFW.PollEvents()
    # move camera
    updatecamera!(window, camera)
    glUseProgram(shader_prog)
    glUniformMatrix4fv(view_loc, 1, GL_FALSE, get_view_matrix(camera))
    # swap the buffers
    GLFW.SwapBuffers(window)
end
end # let

GLFW.DestroyWindow(window)
