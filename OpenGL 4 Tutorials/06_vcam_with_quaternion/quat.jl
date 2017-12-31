using Quaternions
using OffsetArrays
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

# load shaders from file
const vertexShader = readstring(joinpath(@__DIR__, "quat.vert"))
const fragmentShader = readstring(joinpath(@__DIR__, "quat.frag"))

# compile shaders and check for shader compile errors
vertexShaderID = glCreateShader(GL_VERTEX_SHADER)
glShaderSource(vertexShaderID, 1, Ptr{GLchar}[pointer(vertexShader)], C_NULL)
glCompileShader(vertexShaderID)
# get shader compile status
compileResult = Ref{GLint}(-1)
glGetShaderiv(vertexShaderID, GL_COMPILE_STATUS, compileResult)
if compileResult[] != GL_TRUE
    logger = getlogger(current_module())
    warn(logger, string("GL vertex shader(index", vertexShaderID, ")did not compile."))
    shaderlog(vertexShaderID)
    error("GL vertex shader(index ", vertexShaderID, " )did not compile.")
end

fragmentShaderID = glCreateShader(GL_FRAGMENT_SHADER)
glShaderSource(fragmentShaderID, 1, Ptr{GLchar}[pointer(fragmentShader)], C_NULL)
glCompileShader(fragmentShaderID)
# checkout shader compile status
compileResult = Ref{GLint}(-1)
glGetShaderiv(fragmentShaderID, GL_COMPILE_STATUS, compileResult)
if compileResult[] != GL_TRUE
    logger = getlogger(current_module())
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
    logger = getlogger(current_module())
    warn(logger, string("Could not link shader programme GL index: ", shaderProgramID))
    programlog(shaderProgramID)
    error("Could not link shader programme GL index: ", shaderProgramID)
end


# load glTF file
sphere = JSON.parsefile(joinpath(@__DIR__, "sphere.gltf"))
accessors = OffsetArray(sphere["accessors"], -1)
bufferViews = OffsetArray(sphere["bufferViews"], -1)
buffers = OffsetArray(sphere["buffers"], -1)
# load sphere position metadata
positionAccessor = accessors[0]
positionBufferView = bufferViews[positionAccessor["bufferView"]]
posBuffer = buffers[positionBufferView["buffer"]]
# load sphere index metadata
indexAccessor = accessors[3]
indexBufferView = bufferViews[indexAccessor["bufferView"]]
indexBuffer = buffers[indexBufferView["buffer"]]

# load buffer-blobs
readblob(uri, length, offset) = open(uri) do f
                                    skip(f, offset)
                                    blob = read(f, length)
                                end
positionBlob = readblob(joinpath(@__DIR__, indexBuffer["uri"]), positionBufferView["byteLength"], positionBufferView["byteOffset"])
indexBlob = readblob(joinpath(@__DIR__, indexBuffer["uri"]), indexBufferView["byteLength"], indexBufferView["byteOffset"])
position = reinterpret(GLfloat, positionBlob) # GLENUM(posAccessor["componentType"]).name => GLfloat
index = reinterpret(GLushort, indexBlob) # GLENUM(indexAccessor["componentType"]).name => GLushort

# create buffers located in the memory of graphic card
positionVBO = Ref{GLuint}(0)
glGenBuffers(1, positionVBO)
positionTarget = positionBufferView["target"]
glBindBuffer(positionTarget, positionVBO[])
glBufferData(positionTarget, positionBufferView["byteLength"], positionBlob, GL_STATIC_DRAW)

indexEBO = Ref{GLuint}(0)
glGenBuffers(1, indexEBO)
indexTarget = indexBufferView["target"]
glBindBuffer(indexTarget, indexEBO[])
glBufferData(indexTarget, indexBufferView["byteLength"], indexBlob, GL_STATIC_DRAW)

# create VAO
vaoID = Ref{GLuint}(0)
glGenVertexArrays(1, vaoID)
glBindVertexArray(vaoID[])
glBindBuffer(positionTarget, positionVBO[])
glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, Ptr{Void}(positionAccessor["byteOffset"]))
glEnableVertexAttribArray(0)

# enable cull face
glEnable(GL_CULL_FACE)
glCullFace(GL_BACK)
glFrontFace(GL_CCW)
# set background color to gray
glClearColor(0.2, 0.2, 0.2, 1.0)

let
    cameraSpeed = GLfloat(5.0)
    cameraHeadingSpeed = GLfloat(100.0)
    cameraPosition = GLfloat[0.0, 0.0, 0.0]
    rotationMatrix = eye(GLfloat, 4, 4)
    quat = qrotation([0.0, 1.0, 0.0], 0)
    viewMatrix = eye(4,4)
    # pitch-yaw-roll x-y'-z'' intrinsic convension
    fwd = GLfloat[0.0, 0.0, -1.0, 0.0]  # roll
    rgt = GLfloat[1.0, 0.0, 0.0, 0.0]  # pitch
    up = GLfloat[0.0, 1.0, 0.0, 0.0]  # yaw
    previousCameraTime = time()
    global function updatecamera()
        currentCameraTime = time()
        elapsedCameraTime = currentCameraTime - previousCameraTime
        previousCameraTime = currentCameraTime
        moveFlag = false
        singleFrameMove = GLfloat[0.0, 0.0, 0.0]
        value(sigA) && (singleFrameMove[1] -= cameraSpeed * elapsedCameraTime; moveFlag=true)
        value(sigD) && (singleFrameMove[1] += cameraSpeed * elapsedCameraTime; moveFlag=true)
        value(sigQ) && (singleFrameMove[2] -= cameraSpeed * elapsedCameraTime; moveFlag=true)
        value(sigE) && (singleFrameMove[2] += cameraSpeed * elapsedCameraTime; moveFlag=true)
        value(sigW) && (singleFrameMove[3] -= cameraSpeed * elapsedCameraTime; moveFlag=true)
        value(sigS) && (singleFrameMove[3] += cameraSpeed * elapsedCameraTime; moveFlag=true)
        value(sigLEFT) && (rotate(up, cameraHeadingSpeed * elapsedCameraTime); moveFlag=true)
        value(sigRIGHT) && (rotate(up, -cameraHeadingSpeed * elapsedCameraTime); moveFlag=true)
        value(sigUP) && (rotate(rgt, cameraHeadingSpeed * elapsedCameraTime); moveFlag=true)
        value(sigDOWN) && (rotate(rgt, -cameraHeadingSpeed * elapsedCameraTime); moveFlag=true)
        value(sigZ) && (rotate(fwd, cameraHeadingSpeed * elapsedCameraTime); moveFlag=true)
        value(sigC) && (rotate(fwd, -cameraHeadingSpeed * elapsedCameraTime); moveFlag=true)
        moveFlag && return get_view_matrix(singleFrameMove)
        return viewMatrix
    end
    global get_camera_position() = cameraPosition
    global set_camera_position(p::Vector{GLfloat}) = cameraPosition = p
    global function set_camera_rotation(axis::Vector{GLfloat}, angle)
        quat = qrotation(axis, angle)
        rotationMatrix[1:3,1:3] = rotationmatrix(quat)
        fwd = rotationMatrix * GLfloat[0.0, 0.0, -1.0, 0.0]
        rgt = rotationMatrix * GLfloat[1.0, 0.0, 0.0, 0.0]
        up = rotationMatrix * GLfloat[0.0, 1.0, 0.0, 0.0]
    end
    global function resetcamera()
        set_camera_position(GLfloat[0.0, 0.0, 0.0])
        set_camera_rotation(GLfloat[0.0, 1.0, 0.0], 0.0)
    end
    global function get_view_matrix(move=GLfloat[0.0,0.0,0.0])
        cameraPosition += fwd[1:3] * -move[3]
        cameraPosition += up[1:3] * move[2]
        cameraPosition += rgt[1:3] * move[1]
        transMatrix = GLfloat[ 1.0 0.0 0.0 cameraPosition[1];
                               0.0 1.0 0.0 cameraPosition[2];
                               0.0 0.0 1.0 cameraPosition[3];
                               0.0 0.0 0.0               1.0]
        rotationMatrix[1:3,1:3] = rotationmatrix(quat)
        viewMatrix = inv(rotationMatrix) * inv(transMatrix)
    end
    function rotate(axis, angle)
        quatYaw = qrotation(axis[1:3], deg2rad(angle))
        quat = quatYaw * quat
        rotationMatrix[1:3,1:3] = rotationmatrix(quat)
        fwd = rotationMatrix * GLfloat[0.0, 0.0, -1.0, 0.0]
        rgt = rotationMatrix * GLfloat[1.0, 0.0, 0.0, 0.0]
        up = rotationMatrix * GLfloat[0.0, 1.0, 0.0, 0.0]
    end
end

# camera
near = 0.1            # clipping near plane
far = 100.0             # clipping far plane
fov = deg2rad(67)
aspectRatio = glfwWidth / glfwHeight
# perspective matrix
range = tan(0.5*fov) * near
Sx = 2.0*near / (range * aspectRatio + range * aspectRatio)
Sy = near / range
Sz = -(far + near) / (far - near)
Pz = -(2.0*far*near) / (far - near)
projMatrix = GLfloat[ Sx   0.0  0.0  0.0;
                      0.0   Sy  0.0  0.0;
                      0.0  0.0   Sz   Pz;
                      0.0  0.0 -1.0  0.0]
# view matrix
resetcamera()
set_camera_position(GLfloat[0.0, 0.0, 5.0])
viewMatrix = get_view_matrix()
modelMatrixLocation = glGetUniformLocation(shaderProgramID, "model")
viewMatrixLocation = glGetUniformLocation(shaderProgramID, "view")
projMatrixLocation = glGetUniformLocation(shaderProgramID, "proj")
glUseProgram(shaderProgramID)
glUniformMatrix4fv(viewMatrixLocation, 1, GL_FALSE, viewMatrix)
glUniformMatrix4fv(projMatrixLocation, 1, GL_FALSE, projMatrix)

# spheres in world
sphereWorldPositions = GLfloat[-2.0 0.0  0.0;
                                2.0 0.0  0.0;
                               -2.0 0.0 -2.0;
                                1.5 1.0 -1.0]
modelMatrices = Array{Matrix,1}(4)
for i = 1:4
    modelMatrices[i] = GLfloat[ 1.0 0.0 0.0 sphereWorldPositions[i,1];
                                0.0 1.0 0.0 sphereWorldPositions[i,2];
                                0.0 0.0 1.0 sphereWorldPositions[i,3];
                                0.0 0.0 0.0                      1.0]
end

# render
indexCount = indexAccessor["count"]
indexComponentType = indexAccessor["componentType"]
indexByteOffset = indexAccessor["byteOffset"]
while !GLFW.WindowShouldClose(window)
    updatefps(window)
    # clear drawing surface
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
    glViewport(0, 0, glfwWidth, glfwHeight)
    # drawing
    glUseProgram(shaderProgramID)
    glBindBuffer(indexTarget, indexEBO[])
    for i = 1:4
        glUniformMatrix4fv(modelMatrixLocation, 1, GL_FALSE, modelMatrices[i])
        glDrawElements(GL_TRIANGLES, indexCount, indexComponentType, Ptr{Void}(indexByteOffset))
    end
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
