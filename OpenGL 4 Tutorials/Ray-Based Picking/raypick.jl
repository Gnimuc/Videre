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
global const NUM_SPHERES = 4
global const SPHERE_RADIUS = 1
global selectedSphere = -1




# OpenGL init
@assert loginit("gl.log")
@assert startgl()



# ray casting
function screen2world(mouseX::AbstractFloat, mouseY::AbstractFloat)
    # screen space (window space)
    x = 2*mouseX/glfwWidth - 1
    y = 1 - (2*mouseY)/glfwHeight
    z = 1
    # normalised device space [-1:1, -1:1, -1:1]
    rayNDS = GLfloat[x, y, z]
    # clip space [-1:1, -1:1, -1:1, -1:1]
    rayClip = GLfloat[rayNDS[1], rayNDS[2], -1, 1]
    # eye space [-x:x, -y:y, -z:z, -w:w]
    rayEye = inv(projectionMatrix) * rayClip
    rayEye = GLfloat[rayEye[1], rayEye[2], -1, 0]
    # world space [-x:x, -y:y, -z:z, -w:w]
    rayWorld = inv(viewMatrix) * rayEye
    # normalize
    rayWorld = rayWorld/norm(rayWorld)
    return rayWorld[1:3]
end

function raysphere(rayOriginWorld, rayDirectionWorld, sphereCenterWorld, shpereRadius)
    intersectionDistance::GLfloat = 0
    # quadratic parameters
    distance = rayOriginWorld - sphereCenterWorld
    b = (rayDirectionWorld' * distance)[1]
    c = (distance' * distance)[1] - shpereRadius * shpereRadius
    b²MinusC = b * b - c
    # no intersection
    if b²MinusC < 0
        flag = false
    end
    # one intersection (tangent ray)
    if b²MinusC == 0
        # if behind viewer, throw away
        t = -b + sqrt(b²MinusC)
        if t < 0
            flag = false
        end
        intersectionDistance = t
        flag = true
    end
    # two intersections (secant ray)
    if b²MinusC > 0
        t₁ = -b + sqrt(b²MinusC)
        t₂ = -b - sqrt(b²MinusC)
        intersectionDistance = t₂
        # if behind viewer, throw away
        if t₁ < 0
            if t₂ < 0
                flag = false
            end
        elseif t₂ < 0
            intersectionDistance = t₁
        end
        flag = true
    end
    return flag, intersectionDistance
end

function mouse_click_callback(window::GLFW.Window, button::Cint, action::Cint, mods::Cint)
    if GLFW.PRESS == action
        xpos, ypos = GLFW.GetCursorPos(window)
        rayWorld = screen2world(xpos, ypos)
        # ray sphere
        closestSphereClicked = -1
        closestIntersection = 0
        for i = 1:NUM_SPHERES
            sp = collect(sphereWorildPositions[i,:])
            flag, distance = raysphere(cameraPosition, rayWorld, sp, SPHERE_RADIUS)
            if flag
                if (closestSphereClicked == -1) || (distance < closestIntersection)
                    closestSphereClicked = i
                    closestIntersection = distance
                end
            end
        end
        global selectedSphere = closestSphereClicked
        println("sphere ", selectedSphere, " was clicked")
    end
    return nothing
end
# set mouse click callback
GLFW.SetMouseButtonCallback(window, mouse_click_callback)




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
glBindBuffer(get(positionBufferView.target), pointsVBO[])
glBufferData(get(positionBufferView.target), positionBufferView.byteLength, points, GL_STATIC_DRAW)

indicesEBO = GLuint[0]
glGenBuffers(1, Ref(indicesEBO))
glBindBuffer(get(indicesBufferView.target), indicesEBO[])
glBufferData(get(indicesBufferView.target), indicesBufferView.byteLength, indices, GL_STATIC_DRAW)




# create VAO
vaoID = GLuint[0]
glGenVertexArrays(1, Ref(vaoID))
glBindVertexArray(vaoID[])
glBindBuffer(get(positionBufferView.target), pointsVBO[])
stride = positionAccessor.byteStride
offset = positionAccessor.byteOffset + positionBufferView.byteOffset
glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, GLsizei(stride), Ptr{Void}(offset))
glEnableVertexAttribArray(0)




# create program
shaderProgramID = createprogram("raypick.vert", "raypick.frag")
modelMatrixLocation = glGetUniformLocation(shaderProgramID, "model")
viewMatrixLocation = glGetUniformLocation(shaderProgramID, "view")
projectionMatrixLocation = glGetUniformLocation(shaderProgramID, "proj")
blueLocation = glGetUniformLocation(shaderProgramID, "blue")




# camera
global viewMatrix = zeros(GLfloat, 4, 4)
global projectionMatrix = zeros(4, 4)
global cameraPosition = GLfloat[0.0, 0.0, 5.0]
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
    glBindBuffer(get(indicesBufferView.target), indicesEBO[])
    for i = 1:NUM_SPHERES
        if i == selectedSphere
            glUniform1f(blueLocation, 1.0)
        else
            glUniform1f(blueLocation, 0.0)
        end
        glUniformMatrix4fv(modelMatrixLocation, 1, GL_FALSE, modelMatrices[i])
        glDrawElements(GL_TRIANGLES, indicesAccessor.count, indicesAccessor.componentType, Ptr{Void}(indicesAccessor.byteOffset))
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
