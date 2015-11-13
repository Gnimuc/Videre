# load dependency packages
using GLFW, ModernGL, Quaternions, GLTF
include("./glutils.jl")



# set up OpenGL context version(Mac only)
@osx_only const VERSION_MAJOR = 4    # it seems OSX will get stuck on OpenGL 4.1.
@osx_only const VERSION_MINOR = 1


# window init global variables
glfwWidth = 640
glfwHeight = 480
window = C_NULL




# OpenGL init
@assert loginit("gl.log")
@assert startgl()




# load glTF file
rootDict = JSON.parsefile(string(dirname(@__FILE__), "/sphere.gltf"))

positionAccessor = GLTF.loadaccessor("accessor_position", rootDict)
positionBufferView = positionAccessor.bufferView
positionBuffer = positionBufferView.buffer

indicesAccessor = GLTF.loadaccessor("accessor_index_0", rootDict)
indicesBufferView = indicesAccessor.bufferView
indicesBuffer = indicesBufferView.buffer

# load buffer-blob
f = open(string(dirname(@__FILE__), "/sphere.bin"), "r")
points = readbytes(f, positionBufferView.byteLength)
indices = readbytes(f, indicesBufferView.byteLength)
close(f)




# quaternions
qx = qrotation([1,0,0], pi/4)




# create buffers located in the memory of graphic card
pointsVBO = GLuint[0]
glGenBuffers(1, Ref(pointsVBO))
glBindBuffer(GLenum(get(positionBufferView.target)), pointsVBO[])
glBufferData(GLenum(get(positionBufferView.target)), positionBufferView.byteLength, points, GL_STATIC_DRAW)

indicesEBO = GLuint[0]
glGenBuffers(1, Ref(indicesEBO))
glBindBuffer(GLenum(get(indicesBufferView.target)), indicesEBO[])
glBufferData(GLenum(get(indicesBufferView.target)), indicesBufferView.byteLength, indices, GL_STATIC_DRAW)




# create VAO
vaoID = GLuint[0]
glGenVertexArrays(1, Ref(vaoID))
glBindVertexArray(vaoID[])
glBindBuffer(GLenum(get(positionBufferView.target)), pointsVBO[])
stride = positionAccessor.byteStride
offset = positionAccessor.byteOffset + positionBufferView.byteOffset
glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, GLsizei(stride), Ptr{Void}(offset))
glEnableVertexAttribArray(0)




# create program
shaderProgramID = createprogram("quat.vert", "quat.frag")
modelMatrixLocation = glGetUniformLocation(shaderProgramID, "model")
viewMatrixLocation = glGetUniformLocation(shaderProgramID, "view")
projectionMatrixLocation = glGetUniformLocation(shaderProgramID, "proj")




# enable depth test
glEnable(GL_DEPTH_TEST)
glDepthFunc(GL_LESS)
# enable cull face
glEnable(GL_CULL_FACE)
glCullFace(GL_BACK)
glFrontFace(GL_CW)
glClearColor(0.2, 0.2, 0.2, 1.0)
glViewport(0, 0, glfwWidth, glfwHeight)




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
                      0.0  0.0 -1.0  0.0 ]
# view matrix
cameraSpeed = 1.0
cameraSpeedY = 10.0
cameraPosition = GLfloat[0.0, 0.0, 2.0]
cameraRotationY = 0.0
transMatrix = GLfloat[ 1.0 0.0 0.0 -cameraPosition[1];
                       0.0 1.0 0.0 -cameraPosition[2];
                       0.0 0.0 1.0 -cameraPosition[3];
                       0.0 0.0 0.0                1.0 ]
rotationY = GLfloat[  cos(deg2rad(-cameraRotationY))  0.0  sin(deg2rad(-cameraRotationY)) 0.0;
                                                 0.0  1.0                             0.0 0.0;
                     -sin(deg2rad(-cameraRotationY))  0.0  cos(deg2rad(-cameraRotationY)) 0.0;
                                                 0.0  0.0                             0.0 1.0 ]
viewMatrix =  rotationY * transMatrix

viewMatrixLocation = glGetUniformLocation(shaderProgramID, "view")
projMatrixLocation = glGetUniformLocation(shaderProgramID, "proj")
glUseProgram(shaderProgramID)
glUniformMatrix4fv(viewMatrixLocation, 1, GL_FALSE, viewMatrix)
glUniformMatrix4fv(projMatrixLocation, 1, GL_FALSE, projMatrix)




# loop
previousCameraTime = time()
while !GLFW.WindowShouldClose(window)
    # show FPS
    updatefps(window)
    currentCameraTime = time()
    elapsedCameraTime = currentCameraTime - previousCameraTime
    previousCameraTime = currentCameraTime
    # clear drawing surface
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
    # drawing
    glUseProgram(shaderProgramID)
    glBindBuffer(GLenum(get(indicesBufferView.target)), indicesEBO[])
    glDrawElements(GL_TRIANGLES, indicesAccessor.count, GLenum(indicesAccessor.componentType), Ptr{Void}(indicesAccessor.byteOffset))
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
                               0.0 0.0 0.0                1.0 ]
        rotationY = GLfloat[  cos(deg2rad(-cameraRotationY))  0.0  sin(deg2rad(-cameraRotationY)) 0.0;
                                                         0.0  1.0                             0.0 0.0;
                             -sin(deg2rad(-cameraRotationY))  0.0  cos(deg2rad(-cameraRotationY)) 0.0;
                                                         0.0  0.0                             0.0 1.0 ]
        viewMatrix = rotationY * transMatrix
        glUniformMatrix4fv(viewMatrixLocation, 1, GL_FALSE, viewMatrix)
    end
    # swap the buffers
    GLFW.SwapBuffers(window)
end




GLFW.Terminate()
