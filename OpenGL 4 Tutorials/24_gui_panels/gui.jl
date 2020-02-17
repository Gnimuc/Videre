using CSyntax

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
setposition!(camera, [0.0, 1.0, 5.0])

# vertex data
points = GLfloat[-1.0, -1.0,
                  1.0, -1.0,
                 -1.0,  1.0,
                 -1.0,  1.0,
                  1.0, -1.0,
                  1.0,  1.0]

# create VBO
points_vbo = GLuint(0)
@c glGenBuffers(1, &points_vbo)
glBindBuffer(GL_ARRAY_BUFFER, points_vbo)
glBufferData(GL_ARRAY_BUFFER, sizeof(points), points, GL_STATIC_DRAW)

# create VAO
vao = GLuint(0)
@c glGenVertexArrays(1, &vao)
glBindVertexArray(vao)
glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 0, C_NULL)
glEnableVertexAttribArray(0)

# create ground shader program
ground_vert_shader = createshader(joinpath(@__DIR__, "ground.vert"), GL_VERTEX_SHADER)
ground_frag_shader = createshader(joinpath(@__DIR__, "ground.frag"), GL_FRAGMENT_SHADER)
ground_shader_prog = createprogram(ground_vert_shader, ground_frag_shader)

view_loc = glGetUniformLocation(ground_shader_prog, "view")
proj_loc = glGetUniformLocation(ground_shader_prog, "proj")
glUseProgram(ground_shader_prog)
glUniformMatrix4fv(view_loc, 1, GL_FALSE, get_view_matrix(camera))
glUniformMatrix4fv(proj_loc, 1, GL_FALSE, get_projective_matrix(window, camera))

# create gui shader program
gui_vert_shader = createshader(joinpath(@__DIR__, "gui.vert"), GL_VERTEX_SHADER)
gui_frag_shader = createshader(joinpath(@__DIR__, "gui.frag"), GL_FRAGMENT_SHADER)
gui_shader_prog = createprogram(gui_vert_shader, gui_frag_shader)

gui_scale_loc = glGetUniformLocation(gui_shader_prog, "gui_scale")
glUseProgram(gui_shader_prog)

# load texture
glActiveTexture(GL_TEXTURE0)
gui_tex = load_texture(joinpath(@__DIR__, "skulluvmap.png"))
ground_tex = load_texture(joinpath(@__DIR__, "tile2-diamonds256x256.png"))


# enable cull face
glEnable(GL_CULL_FACE)
glCullFace(GL_BACK)
glFrontFace(GL_CCW)
# set background color to gray
glClearColor(0.2, 0.2, 0.2, 1.0)

# render
const panel_width = GLfloat(256)
const panel_height = GLfloat(256)
let
updatefps = FPSCounter()
# render
while !GLFW.WindowShouldClose(window)
    updatefps(window)
    # clear drawing surface
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
    glViewport(0, 0, GLFW.GetFramebufferSize(window)...)
    # draw ground plane
    glEnable(GL_DEPTH_TEST)
    glActiveTexture(GL_TEXTURE0)
    glBindTexture(GL_TEXTURE_2D, ground_tex)
    glBindVertexArray(vao)
    glUseProgram(ground_shader_prog)
    glDrawArrays(GL_TRIANGLES, 0, 6)
    # draw GUI panel
    glDisable(GL_DEPTH_TEST)
    glActiveTexture(GL_TEXTURE0)
    glBindTexture(GL_TEXTURE_2D, gui_tex)
    glUseProgram(gui_shader_prog)
    # resize panel
    x_scale = panel_width / width
    y_scale = panel_height / height
    glUniform2f(gui_scale_loc, x_scale, y_scale)
    glBindVertexArray(vao)
    glDrawArrays(GL_TRIANGLES, 0, 6)
    # check and call events
    GLFW.PollEvents()
    # move camera
    updatecamera!(window, camera)
    glUseProgram(ground_shader_prog)
    glUniformMatrix4fv(view_loc, 1, GL_FALSE, get_view_matrix(camera))
    # swap the buffers
    GLFW.SwapBuffers(window)
end
end # let

GLFW.DestroyWindow(window)
