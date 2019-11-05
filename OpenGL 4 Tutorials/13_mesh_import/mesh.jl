using CSyntax
using GLTF

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

# we use glTF file format because it's OpenGL friendly and we don't need to care about
# how to parse and extract mesh data from other mesh file format like .obj format.
# load glTF file
suzanne = GLTF.load(joinpath(@__DIR__, "monkey2.gltf"))
suzanne_data = [read(joinpath(@__DIR__, b.uri)) for b in suzanne.buffers]

# load suzanne position metadata
search_name(x, keyword) = x[findfirst(x->occursin(keyword, x.name), x)]
pos = search_name(suzanne.accessors, "positions")
pos_bv = suzanne.bufferViews[pos.bufferView]
# load suzanne index metadata
indices = search_name(suzanne.accessors, "indices")
idx_bv = suzanne.bufferViews[indices.bufferView]
# load suzanne texture coordinate metadata
texcoords = search_name(suzanne.accessors, "texcoords")
tex_bv = suzanne.bufferViews[texcoords.bufferView]
# load suzanne normal metadata
normals = search_name(suzanne.accessors, "normals")
normal_bv = suzanne.bufferViews[normals.bufferView]

# create VBO and EBO
pos_vbo = GLuint(0)
@c glGenBuffers(1, &pos_vbo)
glBindBuffer(pos_bv.target, pos_vbo)
glBufferData(pos_bv.target, pos_bv.byteLength, C_NULL, GL_STATIC_DRAW)
pos_data = suzanne_data[pos_bv.buffer]
@c glBufferSubData(pos_bv.target, 0, pos_bv.byteLength, &pos_data[pos_bv.byteOffset])

normal_vbo = GLuint(0)
@c glGenBuffers(1, &normal_vbo)
glBindBuffer(normal_bv.target, normal_vbo)
glBufferData(normal_bv.target, normal_bv.byteLength, C_NULL, GL_STATIC_DRAW)
normal_data = suzanne_data[normal_bv.buffer]
@c glBufferSubData(normal_bv.target, 0, normal_bv.byteLength, &normal_data[normal_bv.byteOffset])

tex_vbo = GLuint(0)
@c glGenBuffers(1, &tex_vbo)
glBindBuffer(tex_bv.target, tex_vbo)
glBufferData(tex_bv.target, tex_bv.byteLength, C_NULL, GL_STATIC_DRAW)
tex_data = suzanne_data[tex_bv.buffer]
@c glBufferSubData(tex_bv.target, 0, tex_bv.byteLength, &tex_data[tex_bv.byteOffset])

idx_ebo = GLuint(0)
@c glGenBuffers(1, &idx_ebo)
glBindBuffer(idx_bv.target, idx_ebo)
glBufferData(idx_bv.target, idx_bv.byteLength, C_NULL, GL_STATIC_DRAW)
idx_data = suzanne_data[idx_bv.buffer]
@c glBufferSubData(idx_bv.target, 0, idx_bv.byteLength, &idx_data[idx_bv.byteOffset])

# create VAO
vao = GLuint(0)
@c glGenVertexArrays(1, &vao)
glBindVertexArray(vao)
# bind position vbo
glBindBuffer(pos_bv.target, pos_vbo)
glVertexAttribPointer(0, 3, pos.componentType, pos.normalized, pos_bv.byteStride, Ptr{Cvoid}(pos.byteOffset))
glEnableVertexAttribArray(0)
# bind normal vbo
glBindBuffer(normal_bv.target, normal_vbo)
glVertexAttribPointer(1, 3, normals.componentType, normals.normalized, normal_bv.byteStride, Ptr{Cvoid}(normals.byteOffset))
glEnableVertexAttribArray(1)
# bind texture coordinate vbo
glBindBuffer(tex_bv.target, tex_vbo)
glVertexAttribPointer(2, 2, texcoords.componentType, texcoords.normalized, tex_bv.byteStride, Ptr{Cvoid}(texcoords.byteOffset))
glEnableVertexAttribArray(2)

# camera
camera = PerspectiveCamera()
setposition!(camera, [0.0, 0.0, 5.0])

# create shader program
vert_shader = createshader(joinpath(@__DIR__, "mesh.vert"), GL_VERTEX_SHADER)
frag_shader = createshader(joinpath(@__DIR__, "mesh.frag"), GL_FRAGMENT_SHADER)

# link program
shader_prog = createprogram(vert_shader, frag_shader)
view_loc = glGetUniformLocation(shader_prog, "view")
proj_loc = glGetUniformLocation(shader_prog, "proj")
glUseProgram(shader_prog)
glUniformMatrix4fv(view_loc, 1, GL_FALSE, get_view_matrix(camera))
glUniformMatrix4fv(proj_loc, 1, GL_FALSE, get_projective_matrix(window, camera))

# # enable cull face
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
    glBindBuffer(idx_bv.target, idx_ebo)
    glDrawElements(GL_TRIANGLES, indices.count, indices.componentType, Ptr{Cvoid}(0))
    # check and call events
    GLFW.PollEvents()
    # move camera
    updatecamera!(window, camera)
    glUniformMatrix4fv(view_loc, 1, GL_FALSE, get_view_matrix(camera))
    glUniformMatrix4fv(proj_loc, 1, GL_FALSE, get_projective_matrix(window, camera))
    # swap the buffers
    GLFW.SwapBuffers(window)
end
end # let

GLFW.DestroyWindow(window)
