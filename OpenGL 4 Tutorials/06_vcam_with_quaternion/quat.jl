using CSyntax
using Quaternions
using OffsetArrays
using JSON

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

# load glTF file
sphere = JSON.parsefile(joinpath(@__DIR__, "sphere.gltf"))
accessors = OffsetArray(sphere["accessors"], -1)
bufferViews = OffsetArray(sphere["bufferViews"], -1)
buffers = OffsetArray(sphere["buffers"], -1)
# load sphere position metadata
pos_accessor = accessors[0]
pos_bv = bufferViews[pos_accessor["bufferView"]]
pos_uri = joinpath(@__DIR__, buffers[pos_bv["buffer"]]["uri"])
# load sphere index metadata
idx_accessor = accessors[3]
idx_bv = bufferViews[idx_accessor["bufferView"]]
idx_uri = joinpath(@__DIR__, buffers[idx_bv["buffer"]]["uri"])

# load buffer-blobs
readblob(uri, length, offset) = open(uri) do f
                                    skip(f, offset)
                                    blob = read(f, length)
                                end
pos_blob = readblob(pos_uri, pos_bv["byteLength"], pos_bv["byteOffset"])
idx_blob = readblob(idx_uri, idx_bv["byteLength"], idx_bv["byteOffset"])
position = reinterpret(GLfloat, pos_blob) # GLENUM(pos_accessor["componentType"]).name => GLfloat
index = reinterpret(GLushort, idx_blob) # GLENUM(idx_accessor["componentType"]).name => GLushort

# create buffers located in the memory of graphic card
pos_vbo = GLuint(0)
@c glGenBuffers(1, &pos_vbo)
glBindBuffer(pos_bv["target"], pos_vbo)
glBufferData(pos_bv["target"], pos_bv["byteLength"], position, GL_STATIC_DRAW)

idx_ebo = GLuint(0)
@c glGenBuffers(1, &idx_ebo)
glBindBuffer(idx_bv["target"], idx_ebo)
glBufferData(idx_bv["target"], idx_bv["byteLength"], index, GL_STATIC_DRAW)

# create VAO
vao = GLuint(0)
@c glGenVertexArrays(1, &vao)
glBindVertexArray(vao)
glBindBuffer(pos_bv["target"], pos_vbo)
glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, Ptr{Cvoid}(pos_accessor["byteOffset"]))
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
model_mats = Vector{Matrix}(undef, 4)
for i = 1:4
    model_mats[i] = GLfloat[ 1.0 0.0 0.0 sphere_world[i,1];
                             0.0 1.0 0.0 sphere_world[i,2];
                             0.0 0.0 1.0 sphere_world[i,3];
                             0.0 0.0 0.0               1.0]
end

let
updatefps = FPSCounter()
count = idx_accessor["count"]
type = idx_accessor["componentType"]
offset = idx_accessor["byteOffset"]
# render
while !GLFW.WindowShouldClose(window)
    updatefps(window)
    # clear drawing surface
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
    glViewport(0, 0, GLFW.GetFramebufferSize(window)...)
    # drawing
    glUseProgram(shader_prog)
    glBindBuffer(idx_bv["target"], idx_ebo)
    for i = 1:4
        glUniformMatrix4fv(model_loc, 1, GL_FALSE, model_mats[i])
        glDrawElements(GL_TRIANGLES, count, type, Ptr{Cvoid}(offset))
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
