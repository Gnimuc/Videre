using Images
include("glutils.jl")

@static if is_apple()
    const VERSION_MAJOR = 4
    const VERSION_MINOR = 1
end

# window init global variables
glfwWidth = 640
glfwHeight = 480
window = C_NULL

# start OpenGL
@assert startgl()

glEnable(GL_DEPTH_TEST)
glDepthFunc(GL_LESS)

# set camera
resetcamera()
set_camera_position(GLfloat[0.0, 0.0, 2.0])

# screen capture
function screencapture()
    buffer = zeros(RGB{N0f8}, glfwWidth, glfwHeight)
    glReadPixels(0, 0, glfwWidth, glfwHeight, GL_RGB, GL_UNSIGNED_BYTE, buffer)
    save(joinpath(@__DIR__, "$(basename(tempname())).png"), flipdim(buffer.',1))
end

# load texture
skull = load(joinpath(@__DIR__, "skulluvmap.png"))
texWidth, texHeight = size(skull) .|> GLsizei
tex = Ref{GLuint}(0)
glGenTextures(1, tex)
glActiveTexture(GL_TEXTURE0)
glBindTexture(GL_TEXTURE_2D, tex[])
glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, texWidth, texHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, flipdim(skull.',2))
glGenerateMipmap(GL_TEXTURE_2D)
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE)
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE)
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR)
# GL_MAX_TEXTURE_MAX_ANISOTROPY_EXT extension is not supported
# max_aniso = Ref{GLfloat}(0.0)
# glGetFloatv(GL_MAX_TEXTURE_MAX_ANISOTROPY_EXT, max_aniso)
# # set the maximum!
# glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAX_ANISOTROPY_EXT, max_aniso)


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
pointsVBO = Ref{GLuint}(0)
glGenBuffers(1, pointsVBO)
glBindBuffer(GL_ARRAY_BUFFER, pointsVBO[])
glBufferData(GL_ARRAY_BUFFER, sizeof(points), points, GL_STATIC_DRAW)

texcoordsVBO = Ref{GLuint}(0)
glGenBuffers(1, texcoordsVBO)
glBindBuffer(GL_ARRAY_BUFFER, texcoordsVBO[])
glBufferData(GL_ARRAY_BUFFER, sizeof(texcoords), texcoords, GL_STATIC_DRAW)

# create VAO
vaoID = Ref{GLuint}(0)
glGenVertexArrays(1, vaoID)
glBindVertexArray(vaoID[])
glBindBuffer(GL_ARRAY_BUFFER, pointsVBO[])
glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, C_NULL)
glBindBuffer(GL_ARRAY_BUFFER, texcoordsVBO[])
glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 0, C_NULL)
glEnableVertexAttribArray(0)
glEnableVertexAttribArray(1)

# create shader program
vertexShaderPath = joinpath(@__DIR__, "screencap.vert")
fragmentShaderPath = joinpath(@__DIR__, "screencap.frag")
shaderProgramID = createprogram(vertexShaderPath, fragmentShaderPath)
viewMatrixLocation = glGetUniformLocation(shaderProgramID, "view")
projMatrixLocation = glGetUniformLocation(shaderProgramID, "proj")
glUseProgram(shaderProgramID)
glUniformMatrix4fv(viewMatrixLocation, 1, GL_FALSE, get_view_matrix())
glUniformMatrix4fv(projMatrixLocation, 1, GL_FALSE, get_projective_matrix())

# enable cull face
glEnable(GL_CULL_FACE)
glCullFace(GL_BACK)
glFrontFace(GL_CCW)
# set background color to gray
glClearColor(0.2, 0.2, 0.2, 1.0)

# render
while !GLFW.WindowShouldClose(window)
    updatefps(window)
    # clear drawing surface
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
    glViewport(0, 0, glfwWidth, glfwHeight)
    # drawing
    glUseProgram(shaderProgramID)
    glBindVertexArray(vaoID[])
    glDrawArrays(GL_TRIANGLES, 0, 6)
    # check and call events
    GLFW.PollEvents()
    yield()
    # screen capture
    GLFW.GetKey(window, GLFW.KEY_SPACE) && (println("screen captured"); screencapture())
    # move camera
    viewMatrix = updatecamera()
    glUniformMatrix4fv(viewMatrixLocation, 1, GL_FALSE, viewMatrix)
    # swap the buffers
    GLFW.SwapBuffers(window)
end

GLFW.DestroyWindow(window)
