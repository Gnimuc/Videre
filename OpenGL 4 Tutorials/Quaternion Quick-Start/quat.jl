# load dependency packages
using GLFW, ModernGL, Quaternions, GLTF
include("./glutils.jl")



# set up OpenGL context version(Mac only)
@osx_only const VERSION_MAJOR = 4    # it seems OSX will get stuck on OpenGL 4.1.
@osx_only const VERSION_MINOR = 1


# window init global variables
glfwWidth = 800
glfwHeight = 800
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




# camera
viewMatrix = zeros(GLfloat, 4, 4)
projectionMatrix = zeros(4, 4)
cameraPosition = GLfloat[0.0, 0.0, 5.0]
# perspective
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
projectionMatrix = GLfloat[ Sx   0.0  0.0  0.0;
                            0.0   Sy  0.0  0.0;
                            0.0  0.0   Sz   Pz;
                            0.0  0.0 -1.0  0.0]
# view matrix
cameraSpeed = 5.0
cameraHeadingSpeed = 100.0
cameraHeading = 0.0

transMatrix = GLfloat[ 1.0 0.0 0.0 -cameraPosition[1];
                       0.0 1.0 0.0 -cameraPosition[2];
                       0.0 0.0 1.0 -cameraPosition[3];
                       0.0 0.0 0.0                1.0]

quat = qrotation([0.0, 1.0, 0.0], deg2rad(-cameraHeading))
quatMatrix = rotationmatrix(quat)
rotationMatrix = eye(GLfloat, 4, 4)
rotationMatrix[1:3, 1:3] = deepcopy(quatMatrix)
viewMatrix = rotationMatrix * transMatrix

glUseProgram(shaderProgramID)
glUniformMatrix4fv(viewMatrixLocation, 1, GL_FALSE, viewMatrix)
glUniformMatrix4fv(projectionMatrixLocation, 1, GL_FALSE, projectionMatrix)

# spheres in world
sphereWorildPositions = GLfloat[-2.0 0.0  0.0;
                                 2.0 0.0  0.0;
                                -2.0 0.0 -2.0;
                                 1.5 1.0 -1.0]
modelMatrices = Array{Matrix, 1}(4)
for i = 1:4
    modelMatrices[i] = GLfloat[ 1.0 0.0 0.0 sphereWorildPositions[i,1];
                                0.0 1.0 0.0 sphereWorildPositions[i,2];
                                0.0 0.0 1.0 sphereWorildPositions[i,3];
                                0.0 0.0 0.0                        1.0]
end

fwd = GLfloat[0.0, 0.0, -1.0, 0.0]
rgt = GLfloat[1.0, 0.0, 0.0, 0.0]
up = GLfloat[0.0, 1.0, 0.0, 0.0]



# enable depth test
glEnable(GL_DEPTH_TEST)
glDepthFunc(GL_LESS)
# enable cull face
glEnable(GL_CULL_FACE)
glCullFace(GL_BACK)
glFrontFace(GL_CCW)
glClearColor(0.2, 0.2, 0.2, 1.0)
glViewport(0, 0, glfwWidth, glfwHeight)




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
    for i = 1:4
        glUniformMatrix4fv(modelMatrixLocation, 1, GL_FALSE, modelMatrices[i])
        glDrawElements(GL_TRIANGLES, indicesAccessor.count, GLenum(indicesAccessor.componentType), Ptr{Void}(indicesAccessor.byteOffset))
    end
    # check and call events
    GLFW.PollEvents()
    # camera key callbacks
    cameraMovedFlag = false
    move = GLfloat[0.0, 0.0, 0.0]
    cameraYaw = GLfloat(0.0)
    cameraPitch = GLfloat(0.0)
    cameraRoll = GLfloat(0.0)
    if GLFW.GetKey(window, GLFW.KEY_A)
        move[1] -= cameraSpeed * elapsedCameraTime
        cameraMovedFlag = true
    end
    if GLFW.GetKey(window, GLFW.KEY_D)
        move[1] += cameraSpeed * elapsedCameraTime
        cameraMovedFlag = true
    end
    if GLFW.GetKey(window, GLFW.KEY_Q)
        move[2] += cameraSpeed * elapsedCameraTime
        cameraMovedFlag = true
    end
    if GLFW.GetKey(window, GLFW.KEY_E)
        move[2] -= cameraSpeed * elapsedCameraTime
        cameraMovedFlag = true
    end
    if GLFW.GetKey(window, GLFW.KEY_W)
        move[3] -= cameraSpeed * elapsedCameraTime
        cameraMovedFlag = true
    end
    if GLFW.GetKey(window, GLFW.KEY_S)
        move[3] += cameraSpeed * elapsedCameraTime
        cameraMovedFlag = true
    end
    if GLFW.GetKey(window, GLFW.KEY_LEFT)
        cameraYaw += cameraHeadingSpeed * elapsedCameraTime
        cameraMovedFlag = true
        # use quaternion
        quatYaw = qrotation([up[1], up[2], up[3]], deg2rad(cameraYaw))
        quat = quatYaw * quat
        quatMatrix = rotationmatrix(quat)
        rotationMatrix = eye(GLfloat, 4, 4)
        rotationMatrix[1:3, 1:3] = deepcopy(quatMatrix)
        fwd = rotationMatrix * GLfloat[0.0, 0.0, -1.0, 0.0]
        rgt = rotationMatrix * GLfloat[1.0, 0.0, 0.0, 0.0]
        up = rotationMatrix * GLfloat[0.0, 1.0, 0.0, 0.0]
    end
    if GLFW.GetKey(window, GLFW.KEY_RIGHT)
        cameraYaw -= cameraHeadingSpeed * elapsedCameraTime
        cameraMovedFlag = true
        # use quaternion
        quatYaw = qrotation([up[1], up[2], up[3]], deg2rad(cameraYaw))
        quat = quatYaw * quat
        quatMatrix = rotationmatrix(quat)
        rotationMatrix = eye(GLfloat, 4, 4)
        rotationMatrix[1:3, 1:3] = deepcopy(quatMatrix)
        fwd = rotationMatrix * GLfloat[0.0, 0.0, -1.0, 0.0]
        rgt = rotationMatrix * GLfloat[1.0, 0.0, 0.0, 0.0]
        up = rotationMatrix * GLfloat[0.0, 1.0, 0.0, 0.0]
    end
    if GLFW.GetKey(window, GLFW.KEY_UP)
        cameraPitch += cameraHeadingSpeed * elapsedCameraTime
        cameraMovedFlag = true
        # use quaternion
        quatPitch = qrotation([rgt[1], rgt[2], rgt[3]], deg2rad(cameraPitch))
        quat = quatPitch * quat
        quatMatrix = rotationmatrix(quat)
        rotationMatrix = eye(GLfloat, 4, 4)
        rotationMatrix[1:3, 1:3] = deepcopy(quatMatrix)
        fwd = rotationMatrix * GLfloat[0.0, 0.0, -1.0, 0.0]
        rgt = rotationMatrix * GLfloat[1.0, 0.0, 0.0, 0.0]
        up = rotationMatrix * GLfloat[0.0, 1.0, 0.0, 0.0]
    end
    if GLFW.GetKey(window, GLFW.KEY_DOWN)
        cameraPitch -= cameraHeadingSpeed * elapsedCameraTime
        cameraMovedFlag = true
        # use quaternion
        quatPitch = qrotation([rgt[1], rgt[2], rgt[3]], deg2rad(cameraPitch))
        quat = quatPitch * quat
        quatMatrix = rotationmatrix(quat)
        rotationMatrix = eye(GLfloat, 4, 4)
        rotationMatrix[1:3, 1:3] = deepcopy(quatMatrix)
        fwd = rotationMatrix * GLfloat[0.0, 0.0, -1.0, 0.0]
        rgt = rotationMatrix * GLfloat[1.0, 0.0, 0.0, 0.0]
        up = rotationMatrix * GLfloat[0.0, 1.0, 0.0, 0.0]
    end
    if GLFW.GetKey(window, GLFW.KEY_Z)
        cameraRoll -= cameraHeadingSpeed * elapsedCameraTime
        cameraMovedFlag = true
        # use quaternion
        quatRoll = qrotation([fwd[1], fwd[2], fwd[3]], deg2rad(cameraRoll))
        quat = quatRoll * quat
        quatMatrix = rotationmatrix(quat)
        rotationMatrix = eye(GLfloat, 4, 4)
        rotationMatrix[1:3, 1:3] = deepcopy(quatMatrix)
        fwd = rotationMatrix * GLfloat[0.0, 0.0, -1.0, 0.0]
        rgt = rotationMatrix * GLfloat[1.0, 0.0, 0.0, 0.0]
        up = rotationMatrix * GLfloat[0.0, 1.0, 0.0, 0.0]
    end
    if GLFW.GetKey(window, GLFW.KEY_C)
        cameraRoll += cameraHeadingSpeed * elapsedCameraTime
        cameraMovedFlag = true
        # use quaternion
        quatRoll = qrotation([fwd[1], fwd[2], fwd[3]], deg2rad(cameraRoll))
        quat = quatRoll * quat
        quatMatrix = rotationmatrix(quat)
        rotationMatrix = eye(GLfloat, 4, 4)
        rotationMatrix[1:3, 1:3] = deepcopy(quatMatrix)
        fwd = rotationMatrix * GLfloat[0.0, 0.0, -1.0, 0.0]
        rgt = rotationMatrix * GLfloat[1.0, 0.0, 0.0, 0.0]
        up = rotationMatrix * GLfloat[0.0, 1.0, 0.0, 0.0]
    end

    if cameraMovedFlag
        cameraPosition = cameraPosition + fwd[1:3] * -move[3]
        cameraPosition = cameraPosition + up[1:3] * move[2]
        cameraPosition = cameraPosition + rgt[1:3] * move[1]
        transMatrix = GLfloat[ 1.0 0.0 0.0 cameraPosition[1];
                               0.0 1.0 0.0 cameraPosition[2];
                               0.0 0.0 1.0 cameraPosition[3];
                               0.0 0.0 0.0               1.0]

        viewMatrix = inv(rotationMatrix) * inv(transMatrix)
        glUniformMatrix4fv(viewMatrixLocation, 1, GL_FALSE, viewMatrix)
    end
    # swap the buffers
    GLFW.SwapBuffers(window)
end




GLFW.Terminate()
