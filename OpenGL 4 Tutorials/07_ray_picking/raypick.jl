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

# camera
camera = PerspectiveCamera()
setposition!(camera, [0.0, 0.0, 5.0])

# ray casting
function screen2world(window::GLFW.Window, mouse_x::Real, mouse_y::Real)
    # screen space (window space)
    x = 2.0 * mouse_x / width - 1.0
    y = 1.0 - (2.0 * mouse_y) / height
    z = 1.0
    # normalised device space [-1:1, -1:1, -1:1]
    ray_nds = GLfloat[x, y, z]
    # clip space [-1:1, -1:1, -1:1, -1:1]
    ray_clip = GLfloat[ray_nds[1], ray_nds[2], -1, 1]
    # eye space [-x:x, -y:y, -z:z, -w:w]
    ray_eye = inv(get_projective_matrix(window, camera)) * ray_clip
    ray_eye = GLfloat[ray_eye[1], ray_eye[2], -1, 0]
    # world space [-x:x, -y:y, -z:z, -w:w]
    ray_world_homogenous = inv(get_view_matrix(camera)) * ray_eye
    ray_world = ray_world_homogenous[1:3]
    # normalize
    normalize!(ray_world)
    return ray_world
end

function raysphere(ray_origin_world, ray_direction_world, sphere_center_world, sphere_radius)
    intersection_dist = 0
    # quadratic parameters
    dist = ray_origin_world - sphere_center_world
    b = ray_direction_world ⋅ dist
    c = dist ⋅ dist - sphere_radius * sphere_radius
    Δ = b * b - c
    # no intersection
    Δ < 0 && (flag = false;)
    # one intersection (tangent ray)
    if Δ == 0
        # if behind viewer, throw away
        t = -b + √(Δ)
        t < 0 && (flag = false;)
        intersection_dist = t
        flag = true
    end
    # two intersections (secant ray)
    if Δ > 0
        t₁ = -b + √(Δ)
        t₂ = -b - √(Δ)
        intersection_dist = t₂
        # if behind viewer, throw away
        t₁ < 0 && t₂ < 0 && (flag = false;)
        t₁ ≥ 0 && t₂ < 0 && (intersection_dist = t₁;)
        flag = true
    end
    return flag, intersection_dist
end

# spheres in world
const NUM_SPHERES = 4
sphere_world = GLfloat[-2.0 0.0  0.0;
                        2.0 0.0  0.0;
                       -2.0 0.0 -2.0;
                        1.5 1.0 -1.0]
model_mats = Vector{Matrix}(undef, NUM_SPHERES)
for i = 1:NUM_SPHERES
    model_mats[i] = GLfloat[ 1.0 0.0 0.0 sphere_world[i,1];
                             0.0 1.0 0.0 sphere_world[i,2];
                             0.0 0.0 1.0 sphere_world[i,3];
                             0.0 0.0 0.0               1.0]
end

const SPHERE_RADIUS = 1
selected = -1
function mouse_click_callback(window::GLFW.Window, button::GLFW.MouseButton, action::GLFW.Action, mods::Cint)
    if GLFW.PRESS == action
        xpos, ypos = GLFW.GetCursorPos(window)
        ray_world = screen2world(window, xpos, ypos)
        # ray sphere
        clicked = -1
        intersect = 0
        for i = 1:NUM_SPHERES
            sp = collect(sphere_world[i,:])
            flag, dist = raysphere(vec(camera.position), ray_world, sp, SPHERE_RADIUS)
            flag || continue
            if (clicked == -1) || (dist < intersect)
                clicked = i
                intersect = dist
            end
        end
        global selected = clicked
        println("sphere ", selected, " was clicked")
    end
    return nothing
end
# set mouse click callback
GLFW.SetMouseButtonCallback(window, mouse_click_callback)

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
vert_shader = createshader(joinpath(@__DIR__, "raypick.vert"), GL_VERTEX_SHADER)
frag_shader = createshader(joinpath(@__DIR__, "raypick.frag"), GL_FRAGMENT_SHADER)

# link program
shader_prog = createprogram(vert_shader, frag_shader)

model_loc = glGetUniformLocation(shader_prog, "model")
view_loc = glGetUniformLocation(shader_prog, "view")
proj_loc = glGetUniformLocation(shader_prog, "proj")
blue_loc = glGetUniformLocation(shader_prog, "blue")
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
    for i = 1:NUM_SPHERES
        if i == selected
            glUniform1f(blue_loc, 1.0)
        else
            glUniform1f(blue_loc, 0.0)
        end
        glUniformMatrix4fv(model_loc, 1, GL_FALSE, model_mats[i])
        glDrawElements(GL_TRIANGLES, count, type, Ptr{Cvoid}(offset))
    end
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
