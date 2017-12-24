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
set_camera_position(GLfloat[0.0, 0.0, 2.0])

# vertex and normal
points = GLfloat[ 0.0, 0.5, 0.0,
                  0.5,-0.5, 0.0,
                 -0.5,-0.5, 0.0]

normals = GLfloat[0.0, 0.0, 1.0,
                  0.0, 0.0, 1.0,
                  0.0, 0.0, 1.0]

# create buffers located in the memory of graphic card
pointsVBO = Ref{GLuint}(0)
glGenBuffers(1, pointsVBO)
glBindBuffer(GL_ARRAY_BUFFER, pointsVBO[])
glBufferData(GL_ARRAY_BUFFER, sizeof(points), points, GL_STATIC_DRAW)

normalsVBO = Ref{GLuint}(0)
glGenBuffers(1, normalsVBO)
glBindBuffer(GL_ARRAY_BUFFER, normalsVBO[])
glBufferData(GL_ARRAY_BUFFER, sizeof(normals), normals, GL_STATIC_DRAW)

# create VAO
vaoID = Ref{GLuint}(0)
glGenVertexArrays(1, vaoID)
glBindVertexArray(vaoID[])
glBindBuffer(GL_ARRAY_BUFFER, pointsVBO[])
glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, C_NULL)
glBindBuffer(GL_ARRAY_BUFFER, normalsVBO[])
glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 0, C_NULL)
glEnableVertexAttribArray(0)
glEnableVertexAttribArray(1)

# create shader program
vertexShaderPath = joinpath(@__DIR__, "phong.vert")
fragmentShaderPath = joinpath(@__DIR__, "phong.frag")
shaderProgramID = createprogram(vertexShaderPath, fragmentShaderPath)
modelMatrixLocation = glGetUniformLocation(shaderProgramID, "model_mat")
viewMatrixLocation = glGetUniformLocation(shaderProgramID, "view_mat")
projMatrixLocation = glGetUniformLocation(shaderProgramID, "projection_mat")
glUseProgram(shaderProgramID)
modelMatrix = eye(GLfloat, 4, 4)
glUniformMatrix4fv(modelMatrixLocation, 1, GL_FALSE, modelMatrix)
glUniformMatrix4fv(viewMatrixLocation, 1, GL_FALSE, get_view_matrix())
glUniformMatrix4fv(projMatrixLocation, 1, GL_FALSE, get_projective_matrix())

# enable cull face
glEnable(GL_CULL_FACE)
glCullFace(GL_BACK)
glFrontFace(GL_CW)
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
    glBindBuffer(GL_ARRAY_BUFFER, vaoID[])
    modelMatrix[1,4] = sin(time())
    glUniformMatrix4fv(modelMatrixLocation, 1, GL_FALSE, modelMatrix)
    glDrawArrays(GL_TRIANGLES, 0, 3)
    # check and call events
    GLFW.PollEvents()
    yield()
    # move camera
    viewMatrix = updatecamera()
    glUniformMatrix4fv(viewMatrixLocation, 1, GL_FALSE, viewMatrix)
    # swap the buffers
    GLFW.SwapBuffers(window)
end

GLFW.DestroyWindow(window)
