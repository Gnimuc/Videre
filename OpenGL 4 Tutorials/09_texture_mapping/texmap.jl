using CSyntax
using STBImage.LibSTBImage

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

# load texture
function load_texture(path::AbstractString)
    x, y, n = Cint(0), Cint(0), Cint(0)
    force_channels = 4
    stbi_set_flip_vertically_on_load(true)
    tex_data = @c stbi_load(path, &x, &y, &n, force_channels)
    if tex_data == C_NULL
        @error "could not load $path."
        return nothing
    end
    ( ( x & ( x - 1 ) ) != 0 || ( y & ( y - 1 ) ) != 0 ) && @warn "texture $path is not power-of-2 dimensions."
    id = GLuint(0)
    @c glGenTextures(1, &id)
    glActiveTexture(GL_TEXTURE0)
    glBindTexture(GL_TEXTURE_2D, id)
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, x, y, 0, GL_RGBA, GL_UNSIGNED_BYTE, tex_data)
    glGenerateMipmap(GL_TEXTURE_2D)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR)
    return id
end
load_texture(joinpath(@__DIR__, "skulluvmap.png"))

# vertex data
points = GLfloat[-0.5, -0.5, 0.0,
                  0.5, -0.5, 0.0,
                  0.5,  0.5, 0.0,
                  0.5,  0.5, 0.0,
                 -0.5,  0.5, 0.0,
                 -0.5, -0.5, 0.0]

texcoords = GLfloat[0.0, 0.0,
                    1.0, 0.0,
                    1.0, 1.0,
                    1.0, 1.0,
                    0.0, 1.0,
                    0.0, 0.0]

# create buffers located in the memory of graphic card
points_vbo = GLuint(0)
@c glGenBuffers(1, &points_vbo)
glBindBuffer(GL_ARRAY_BUFFER, points_vbo)
glBufferData(GL_ARRAY_BUFFER, sizeof(points), points, GL_STATIC_DRAW)

texcoords_vbo = GLuint(0)
@c glGenBuffers(1, &texcoords_vbo)
glBindBuffer(GL_ARRAY_BUFFER, texcoords_vbo)
glBufferData(GL_ARRAY_BUFFER, sizeof(texcoords), texcoords, GL_STATIC_DRAW)

# create VAO
vao = GLuint(0)
@c glGenVertexArrays(1, &vao)
glBindVertexArray(vao)
glBindBuffer(GL_ARRAY_BUFFER, points_vbo)
glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, C_NULL)
glBindBuffer(GL_ARRAY_BUFFER, texcoords_vbo)
glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 0, C_NULL)
glEnableVertexAttribArray(0)
glEnableVertexAttribArray(1)

# load and compile shaders from file
vert_shader = createshader(joinpath(@__DIR__, "texmap.vert"), GL_VERTEX_SHADER)
frag_shader = createshader(joinpath(@__DIR__, "texmap.frag"), GL_FRAGMENT_SHADER)

# link program
shader_prog = createprogram(vert_shader, frag_shader)

view_loc = glGetUniformLocation(shader_prog, "view")
proj_loc = glGetUniformLocation(shader_prog, "proj")
glUseProgram(shader_prog)
glUniformMatrix4fv(view_loc, 1, GL_FALSE, get_view_matrix(camera))
glUniformMatrix4fv(proj_loc, 1, GL_FALSE, get_projective_matrix(window, camera))

# enable cull face
glEnable(GL_CULL_FACE)
glCullFace(GL_BACK)
glFrontFace(GL_CCW)
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
    glBindVertexArray(vao)
    glDrawArrays(GL_TRIANGLES, 0, 6)
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
