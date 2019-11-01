using CSyntax
using Quaternions
using GLTF

@static if Sys.isapple()
    const VERSION_MAJOR = 4
    const VERSION_MINOR = 1
end

include(joinpath(@__DIR__, "glutils.jl"))
include(joinpath(@__DIR__, "camera.jl"))

# init window
width, height = fb_width, fb_height = 640, 480
window = startgl(width, height)

glEnable(GL_DEPTH_TEST)
glDepthFunc(GL_LESS)

# we use glTF file format because it's OpenGL friendly and we don't need to care about
# how to parse and extract mesh data from other mesh file format like .obj format.
# load glTF file
sphere = GLTF.load(joinpath(@__DIR__, "sphere.gltf"))
sphere_data = [read(joinpath(@__DIR__, b.uri)) for b in sphere.buffers]

# load sphere position metadata
search_name(x, keyword) = x[findfirst(x->occursin(keyword, x.name), x)]
pos = search_name(sphere.accessors, "position")
pos_bv = sphere.bufferViews[pos.bufferView]
# load sphere index metadata
indices = search_name(sphere.accessors, "indices")
idx_bv = sphere.bufferViews[indices.bufferView]

# create VBO and EBO
vbo = GLuint(0)
@c glGenBuffers(1, &vbo)
glBindBuffer(pos_bv.target, vbo)
glBufferData(pos_bv.target, pos_bv.byteLength, C_NULL, GL_STATIC_DRAW)
pos_data = sphere_data[pos_bv.buffer]
@c glBufferSubData(pos_bv.target, 0, pos_bv.byteLength, &pos_data[pos_bv.byteOffset])

ebo = GLuint(0)
@c glGenBuffers(1, &ebo)
glBindBuffer(idx_bv.target, ebo)
glBufferData(idx_bv.target, idx_bv.byteLength, C_NULL, GL_STATIC_DRAW)
idx_data = sphere_data[idx_bv.buffer]
@c glBufferSubData(idx_bv.target, 0, idx_bv.byteLength, &idx_data[idx_bv.byteOffset])

# create VAO
vao = GLuint(0)
@c glGenVertexArrays(1, &vao)
glBindVertexArray(vao)
glBindBuffer(pos_bv.target, vbo)
glVertexAttribPointer(0, 3, pos.componentType, pos.normalized, pos_bv.byteStride, Ptr{Cvoid}(pos.byteOffset))
glEnableVertexAttribArray(0)

# load and compile shaders from file
vert_shader = createshader(joinpath(@__DIR__, "quat.vert"), GL_VERTEX_SHADER)
frag_shader = createshader(joinpath(@__DIR__, "quat.frag"), GL_FRAGMENT_SHADER)

# link program
shader_prog = createprogram(vert_shader, frag_shader)

# enable cull face
glEnable(GL_CULL_FACE)
glCullFace(GL_BACK)
glFrontFace(GL_CCW)
# set background color to gray
glClearColor(0.2, 0.2, 0.2, 1.0)

# camera
camera = PerspectiveCamera()
setposition!(camera, [0.0, 0.0, 5.0])
model_loc = glGetUniformLocation(shader_prog, "model")
view_loc = glGetUniformLocation(shader_prog, "view")
proj_loc = glGetUniformLocation(shader_prog, "proj")
glUseProgram(shader_prog)
glUniformMatrix4fv(view_loc, 1, GL_FALSE, get_view_matrix(camera))
glUniformMatrix4fv(proj_loc, 1, GL_FALSE, get_projective_matrix(window, camera))

# spheres in world
sphere_world = GLfloat[-2.0 0.0  0.0;
                        2.0 0.0  0.0;
                       -2.0 0.0 -2.0;
                        1.5 1.0 -1.0]
model_mats = map(1:4) do i
    GLfloat[ 1.0 0.0 0.0 sphere_world[i,1];
             0.0 1.0 0.0 sphere_world[i,2];
             0.0 0.0 1.0 sphere_world[i,3];
             0.0 0.0 0.0       1.0        ]
end

let
updatefps = FPSCounter()
while !GLFW.WindowShouldClose(window)
    updatefps(window)
    # clear drawing surface
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
    glViewport(0, 0, GLFW.GetFramebufferSize(window)...)
    # drawing
    glUseProgram(shader_prog)
    glBindVertexArray(vao)
    glBindBuffer(idx_bv.target, ebo)
    for i = 1:4
        glUniformMatrix4fv(model_loc, 1, GL_FALSE, model_mats[i])
        glDrawElements(GL_TRIANGLES, indices.count, indices.componentType, Ptr{Cvoid}(0))
    end
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
