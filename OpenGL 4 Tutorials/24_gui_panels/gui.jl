using FileIO
include(joinpath(@__DIR__, "glutils.jl"))

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
set_camera_position(GLfloat[0.0, 1.0, 5.0])


# vertex data
points = GLfloat[-1.0, -1.0,
                  1.0, -1.0,
                 -1.0,  1.0,
                 -1.0,  1.0,
                  1.0, -1.0,
                  1.0,  1.0]

# create buffers located in the memory of graphic card
pointsVBO = Ref{GLuint}(0)
glGenBuffers(1, pointsVBO)
glBindBuffer(GL_ARRAY_BUFFER, pointsVBO[])
glBufferData(GL_ARRAY_BUFFER, sizeof(points), points, GL_STATIC_DRAW)

# create VAO
vaoID = Ref{GLuint}(0)
glGenVertexArrays(1, vaoID)
glBindVertexArray(vaoID[])
glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 0, C_NULL)
glEnableVertexAttribArray(0)

# create ground plane shader program
groundVertexShaderPath = joinpath(@__DIR__, "ground.vert")
groundFragmentShaderPath = joinpath(@__DIR__, "ground.frag")
groundShaderProgramID = createprogram(groundVertexShaderPath, groundFragmentShaderPath)
groundViewMatrixLocation = glGetUniformLocation(groundShaderProgramID, "view")
groundProjMatrixLocation = glGetUniformLocation(groundShaderProgramID, "proj")
glUseProgram(groundShaderProgramID)
glUniformMatrix4fv(groundViewMatrixLocation, 1, GL_FALSE, get_view_matrix())
glUniformMatrix4fv(groundProjMatrixLocation, 1, GL_FALSE, get_projective_matrix())

# create gui shader program
guiVertexShaderPath = joinpath(@__DIR__, "gui.vert")
guiFragmentShaderPath = joinpath(@__DIR__, "gui.frag")
guiShaderProgramID = createprogram(guiVertexShaderPath, guiFragmentShaderPath)
guiScaleLocation = glGetUniformLocation(guiShaderProgramID, "gui_scale")
glUseProgram(guiShaderProgramID)

# load texture
glActiveTexture(GL_TEXTURE0)
guiTex = loadtexture(joinpath(@__DIR__, "skulluvmap.png"))
groundTex = loadtexture(joinpath(@__DIR__, "tile2-diamonds256x256.png"))


# enable cull face
glEnable(GL_CULL_FACE)
glCullFace(GL_BACK)
glFrontFace(GL_CCW)
# set background color to gray
glClearColor(0.2, 0.2, 0.2, 1.0)

# render
const panelWidth = GLfloat(256)
const panelHeight = GLfloat(256)
while !GLFW.WindowShouldClose(window)
    updatefps(window)
    # clear drawing surface
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
    glViewport(0, 0, glfwWidth, glfwHeight)
    # draw ground plane
    glEnable(GL_DEPTH_TEST)
    glActiveTexture(GL_TEXTURE0)
    glBindTexture(GL_TEXTURE_2D, groundTex[])
    glBindVertexArray(vaoID[])
    glUseProgram(groundShaderProgramID)
    glDrawArrays(GL_TRIANGLES, 0, 6)
    # draw GUI panel
    glDisable(GL_DEPTH_TEST)
    glActiveTexture(GL_TEXTURE0)
    glBindTexture(GL_TEXTURE_2D, guiTex[])
    glUseProgram(guiShaderProgramID)
    # resize panel
    xScale = panelWidth / glfwWidth
    yScale = panelHeight / glfwHeight
    glUniform2f(guiScaleLocation, xScale, yScale)
    glBindVertexArray(vaoID[])
    glDrawArrays(GL_TRIANGLES, 0, 6)
    # check and call events
    GLFW.PollEvents()
    yield()
    # move camera
    viewMatrix = updatecamera()
    glUseProgram(groundShaderProgramID)
    glUniformMatrix4fv(groundViewMatrixLocation, 1, GL_FALSE, viewMatrix)
    # swap the buffers
    GLFW.SwapBuffers(window)
end

GLFW.DestroyWindow(window)
