using CSyntax
using StaticArrays

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

# set camera
camera = PerspectiveCamera()
setposition!(camera, [0.0, 0.0, 2.0])

# vertex and normal
points = GLfloat[ 0.0, 0.5, 0.0,
                  0.5,-0.5, 0.0,
                 -0.5,-0.5, 0.0]

normals = GLfloat[0.0, 0.0, 1.0,
                  0.0, 0.0, 1.0,
                  0.0, 0.0, 1.0]

# create buffers located in the memory of graphic card
points_vbo = GLuint(0)
@c glGenBuffers(1, &points_vbo)
glBindBuffer(GL_ARRAY_BUFFER, points_vbo)
glBufferData(GL_ARRAY_BUFFER, sizeof(points), points, GL_STATIC_DRAW)

normal_vbo = GLuint(0)
@c glGenBuffers(1, &normal_vbo)
glBindBuffer(GL_ARRAY_BUFFER, normal_vbo)
glBufferData(GL_ARRAY_BUFFER, sizeof(normals), normals, GL_STATIC_DRAW)

# create VAO
vao = GLuint(0)
@c glGenVertexArrays(1, &vao)
glBindVertexArray(vao)
glBindBuffer(GL_ARRAY_BUFFER, points_vbo)
glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, C_NULL)
glBindBuffer(GL_ARRAY_BUFFER, normal_vbo)
glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 0, C_NULL)
glEnableVertexAttribArray(0)
glEnableVertexAttribArray(1)

# load and compile shaders from file
vert_shader = createshader(joinpath(@__DIR__, "phong.vert"), GL_VERTEX_SHADER)
frag_shader = createshader(joinpath(@__DIR__, "phong.frag"), GL_FRAGMENT_SHADER)

# link program
shader_prog = createprogram(vert_shader, frag_shader)

model_loc = glGetUniformLocation(shader_prog, "model_mat")
view_loc = glGetUniformLocation(shader_prog, "view_mat")
proj_loc = glGetUniformLocation(shader_prog, "projection_mat")
glUseProgram(shader_prog)
model_mat = Matrix{GLfloat}(I, 4, 4)
glUniformMatrix4fv(model_loc, 1, GL_FALSE, model_mat)
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
    model_mat[1,4] = sin(time())
    glUniformMatrix4fv(model_loc, 1, GL_FALSE, model_mat)
    glDrawArrays(GL_TRIANGLES, 0, 3)
    # check and call events
    GLFW.PollEvents()
    # move camera
    updatecamera!(window, camera)
    glUniformMatrix4fv(view_loc, 1, GL_FALSE, get_view_matrix(camera))
    # swap the buffers
    GLFW.SwapBuffers(window)
end
end # let

GLFW.DestroyWindow(window)
