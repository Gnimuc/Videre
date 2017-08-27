include(joinpath(dirname(@__FILE__), "..", "03_vertex_buffer_objects", "glutils.jl"))

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

# load shaders from file
const vertexShader = readstring(joinpath(dirname(@__FILE__), "camera.vert"))
const fragmentShader = readstring(joinpath(dirname(@__FILE__), "camera.frag"))

# compile shaders and check for shader compile errors
vertexShaderID = glCreateShader(GL_VERTEX_SHADER)
glShaderSource(vertexShaderID, 1, [pointer(vertexShader)], C_NULL)
glCompileShader(vertexShaderID)
# get shader compile status
compileResult = Ref{GLint}(-1)
glGetShaderiv(vertexShaderID, GL_COMPILE_STATUS, compileResult)
if compileResult[] != GL_TRUE
    logger = get_logger(current_module())
    warn(logger, string("GL vertex shader(index", vertexShaderID, ")did not compile."))
    shaderlog(vertexShaderID)
    error("GL vertex shader(index ", vertexShaderID, " )did not compile.")
end

fragmentShaderID = glCreateShader(GL_FRAGMENT_SHADER)
glShaderSource(fragmentShaderID, 1, [pointer(fragmentShader)], C_NULL)
glCompileShader(fragmentShaderID)
# checkout shader compile status
compileResult = Ref{GLint}(-1)
glGetShaderiv(fragmentShaderID, GL_COMPILE_STATUS, compileResult)
if compileResult[] != GL_TRUE
    logger = get_logger(current_module())
    warn(logger, string("GL fragment shader(index ", fragmentShaderID, " )did not compile."))
    shaderlog(fragmentShaderID)
    error("GL fragment shader(index ", fragmentShaderID, " )did not compile.")
end

# create and link shader program
shaderProgramID = glCreateProgram()
glAttachShader(shaderProgramID, vertexShaderID)
glAttachShader(shaderProgramID, fragmentShaderID)
glLinkProgram(shaderProgramID)
# checkout programe linking status
linkingResult = Ref{GLint}(-1)
glGetProgramiv(shaderProgramID, GL_LINK_STATUS, linkingResult)
if linkingResult[] != GL_TRUE
    logger = get_logger(current_module())
    warn(logger, string("Could not link shader programme GL index: ", shaderProgramID))
    programlog(shaderProgramID)
    error("Could not link shader programme GL index: ", shaderProgramID)
end

# vertex data
points = GLfloat[ 0.0,  0.5, 0.0,
                  0.5, -0.5, 0.0,
                 -0.5, -0.5, 0.0]

colors = GLfloat[ 1.0, 0.0, 0.0,
                  0.0, 1.0, 0.0,
                  0.0, 0.0, 1.0]

# create buffers located in the memory of graphic card
pointsVBO = Ref{GLuint}(0)
glGenBuffers(1, pointsVBO)
glBindBuffer(GL_ARRAY_BUFFER, pointsVBO[])
glBufferData(GL_ARRAY_BUFFER, sizeof(points), points, GL_STATIC_DRAW)

colorsVBO = Ref{GLuint}(0)
glGenBuffers(1, colorsVBO)
glBindBuffer(GL_ARRAY_BUFFER, colorsVBO[])
glBufferData(GL_ARRAY_BUFFER, sizeof(colors), colors, GL_STATIC_DRAW)

# create VAO
vaoID = Ref{GLuint}(0)
glGenVertexArrays(1, vaoID)
glBindVertexArray(vaoID[])
glBindBuffer(GL_ARRAY_BUFFER, pointsVBO[])
glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, C_NULL)
glBindBuffer(GL_ARRAY_BUFFER, colorsVBO[])
glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 0, C_NULL)
glEnableVertexAttribArray(0)
glEnableVertexAttribArray(1)

# enable cull face
glEnable(GL_CULL_FACE)
glCullFace(GL_BACK)
glFrontFace(GL_CW)


# camera
near = 0.1            # clipping near plane
far = 100.0             # clipping far plane
fov = deg2rad(67)
aspectRatio = glfwWidth / glfwHeight
# perspective matrix
range = tan(0.5*fov) * near
Sx = 2.0*near / (range *aspectRatio + range * aspectRatio)
Sy = near / range
Sz = -(far + near) / (far - near)
Pz = -(2.0*far*near) / (far - near)
projMatrix = GLfloat[ Sx   0.0  0.0  0.0;
                      0.0   Sy  0.0  0.0;
                      0.0  0.0   Sz   Pz;
                      0.0  0.0 -1.0  0.0]
# view matrix
cameraSpeed = 1.0
cameraSpeedY = 10.0
cameraPosition = GLfloat[0.0, 0.0, 2.0]
cameraRotationY = 0.0
transMatrix = GLfloat[ 1.0 0.0 0.0 -cameraPosition[1];
                       0.0 1.0 0.0 -cameraPosition[2];
                       0.0 0.0 1.0 -cameraPosition[3];
                       0.0 0.0 0.0                1.0]
rotationY = GLfloat[  cos(deg2rad(-cameraRotationY))  0.0  sin(deg2rad(-cameraRotationY)) 0.0;
                                                 0.0  1.0                             0.0 0.0;
                     -sin(deg2rad(-cameraRotationY))  0.0  cos(deg2rad(-cameraRotationY)) 0.0;
                                                 0.0  0.0                             0.0 1.0]
viewMatrix = rotationY * transMatrix

viewMatrixLocation = glGetUniformLocation(shaderProgramID, "view")
projMatrixLocation = glGetUniformLocation(shaderProgramID, "proj")
glUseProgram(shaderProgramID)
glUniformMatrix4fv(viewMatrixLocation, 1, GL_FALSE, viewMatrix)
glUniformMatrix4fv(projMatrixLocation, 1, GL_FALSE, projMatrix)


# render
previousCameraTime = time()
while !GLFW.WindowShouldClose(window)
    # show FPS
    updatefps(window)
    currentCameraTime = time()
    elapsedCameraTime = currentCameraTime - previousCameraTime
    previousCameraTime = currentCameraTime
    # clear drawing surface
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
    glViewport(0, 0, glfwWidth, glfwHeight)
    # drawing
    glUseProgram(shaderProgramID)
    glBindVertexArray(vaoID[])
    glDrawArrays(GL_TRIANGLES, 0, 3)
    # check and call events
    GLFW.PollEvents()
    # camera key callbacks
    cameraMovedFlag = false
    if GLFW.GetKey(window, GLFW.KEY_A)
        cameraPosition[1] -= cameraSpeed * elapsedCameraTime
        cameraMovedFlag = true
    end
    if GLFW.GetKey(window, GLFW.KEY_D)
        cameraPosition[1] += cameraSpeed * elapsedCameraTime
        cameraMovedFlag = true
    end
    if GLFW.GetKey(window, GLFW.KEY_PAGE_UP)
        cameraPosition[2] += cameraSpeed * elapsedCameraTime
        cameraMovedFlag = true
    end
    if GLFW.GetKey(window, GLFW.KEY_PAGE_DOWN)
        cameraPosition[2] -= cameraSpeed * elapsedCameraTime
        cameraMovedFlag = true
    end
    if GLFW.GetKey(window, GLFW.KEY_W)
        cameraPosition[3] -= cameraSpeed * elapsedCameraTime
        cameraMovedFlag = true
    end
    if GLFW.GetKey(window, GLFW.KEY_S)
        cameraPosition[3] += cameraSpeed * elapsedCameraTime
        cameraMovedFlag = true
    end
    if GLFW.GetKey(window, GLFW.KEY_LEFT)
        cameraRotationY += cameraSpeedY * elapsedCameraTime
        cameraMovedFlag = true
    end
    if GLFW.GetKey(window, GLFW.KEY_RIGHT)
        cameraRotationY -= cameraSpeedY * elapsedCameraTime
        cameraMovedFlag = true
    end
    if cameraMovedFlag
        transMatrix = GLfloat[ 1.0 0.0 0.0 -cameraPosition[1];
                               0.0 1.0 0.0 -cameraPosition[2];
                               0.0 0.0 1.0 -cameraPosition[3];
                               0.0 0.0 0.0                1.0]
        rotationY = GLfloat[  cos(deg2rad(-cameraRotationY))  0.0  sin(deg2rad(-cameraRotationY)) 0.0;
                                                         0.0  1.0                             0.0 0.0;
                             -sin(deg2rad(-cameraRotationY))  0.0  cos(deg2rad(-cameraRotationY)) 0.0;
                                                         0.0  0.0                             0.0 1.0]
        viewMatrix = rotationY * transMatrix
        glUniformMatrix4fv(viewMatrixLocation, 1, GL_FALSE, viewMatrix)
    end
    # swap the buffers
    GLFW.SwapBuffers(window)
end

GLFW.Terminate()
