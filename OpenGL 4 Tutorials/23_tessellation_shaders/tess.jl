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
points = GLfloat[ 0.0, 0.75, 0.0,
                  0.5, 0.25, 0.0,
                 -0.5, 0.25, 0.0,
                  0.5,-0.25, 0.0,
                  0.0,-0.75, 0.0,
                 -0.5,-0.25, 0.0]

# create buffers located in the memory of graphic card
points_vbo = GLuint(0)
@c glGenBuffers(1, &points_vbo)
glBindBuffer(GL_ARRAY_BUFFER, points_vbo)
glBufferData(GL_ARRAY_BUFFER, sizeof(points), points, GL_STATIC_DRAW)

# create VAO
vao = GLuint(0)
@c glGenVertexArrays(1, &vao)
glBindVertexArray(vao)
glBindBuffer(GL_ARRAY_BUFFER, points_vbo)
glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, C_NULL)
glEnableVertexAttribArray(0)

# load and compile shaders from file
vert_shader = createshader(joinpath(@__DIR__, "tess.vert"), GL_VERTEX_SHADER)
tesc_shader = createshader(joinpath(@__DIR__, "tess.tesc"), GL_TESS_CONTROL_SHADER)
tese_shader = createshader(joinpath(@__DIR__, "tess.tese"), GL_TESS_EVALUATION_SHADER)
frag_shader = createshader(joinpath(@__DIR__, "tess.frag"), GL_FRAGMENT_SHADER)

# link program
shader_prog = createprogram(vert_shader, tesc_shader, tese_shader, frag_shader)

inner_tess_factor_loc = glGetUniformLocation(shader_prog, "tess_fac_inner")
outer_tess_factor_loc = glGetUniformLocation(shader_prog, "tess_fac_outer")

glEnable(GL_CULL_FACE)
glCullFace(GL_BACK)
glFrontFace(GL_CW)
glPolygonMode(GL_FRONT_AND_BACK, GL_LINE)
glPatchParameteri(GL_PATCH_VERTICES, 3)

# set background color to gray
glClearColor(0.2, 0.2, 0.2, 1.0)

# render
let
inner_tess_factor = GLfloat(1)
outer_tess_factor = GLfloat(4)
qWasDown = false
aWasDown = false
wWasDown = false
sWasDown = false
updatefps = FPSCounter()
while !GLFW.WindowShouldClose(window)
    updatefps(window)
    # clear drawing surface
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
    glViewport(0, 0, width, height)
    # drawing
    glUseProgram(shader_prog)
    glBindVertexArray(vao)
    glDrawArrays(GL_PATCHES, 0, 6)
    # check and call events
    GLFW.PollEvents()
    if GLFW.GetKey(window, GLFW.KEY_Q)
        if !qWasDown
            inner_tess_factor += 1
            println("inner tessellation factor = $inner_tess_factor.")
            glUniform1f(inner_tess_factor_loc, inner_tess_factor)
            qWasDown = true
        end
    else
        qWasDown = false
    end
    if GLFW.GetKey(window, GLFW.KEY_A)
        if !aWasDown
            inner_tess_factor -= 1
            println("inner tessellation factor = $inner_tess_factor.")
            glUniform1f(inner_tess_factor_loc, inner_tess_factor)
            aWasDown = true
        end
    else
        aWasDown = false
    end
    if GLFW.GetKey(window, GLFW.KEY_W)
        if !wWasDown
            outer_tess_factor += 1
            println("outer tessellation factor = $outer_tess_factor.")
            glUniform1f(outer_tess_factor_loc, outer_tess_factor)
            wWasDown = true
        end
    else
        wWasDown = false
    end
    if GLFW.GetKey(window, GLFW.KEY_S)
        if !sWasDown
            outer_tess_factor -= 1
            println("outer tessellation factor = $outer_tess_factor.")
            glUniform1f(outer_tess_factor_loc, outer_tess_factor)
            sWasDown = true
        end
    else
        sWasDown = false
    end
    # swap the buffers
    GLFW.SwapBuffers(window)
end
end # let
GLFW.DestroyWindow(window)
