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

# set camera
resetcamera()
set_camera_position(GLfloat[0.0, 0.0, 5.0])

# load glTF file
suzanne = JSON.parsefile(joinpath(@__DIR__, "suzanne.gltf"))
accessors = OffsetArray(suzanne["accessors"], -1)
bufferViews = OffsetArray(suzanne["bufferViews"], -1)
buffers = OffsetArray(suzanne["buffers"], -1)
positionAccessor, normalAccessor, texcoordAccessor, indexAccessor = accessors
# load suzanne position & normal & texture coordinate & index bufferView
positionBufferView = bufferViews[positionAccessor["bufferView"]]
normalBufferView = bufferViews[normalAccessor["bufferView"]]
texcoordBufferView = bufferViews[texcoordAccessor["bufferView"]]
indexBufferView = bufferViews[indexAccessor["bufferView"]]

# load buffer-blobs
readblob(uri, length, offset) = open(uri) do f
                                    skip(f, offset)
                                    blob = read(f, length)
                                end
blobs = Vector{UInt8}[]
for bv in bufferViews
    uri = buffers[bv["buffer"]]["uri"]
    push!(blobs, readblob(joinpath(@__DIR__, uri), bv["byteLength"], bv["byteOffset"]))
end
blobs = OffsetArray(blobs, -1)

# create buffers located in the memory of graphic card
positionVBO = Ref{GLuint}(0)
glGenBuffers(1, positionVBO)
positionTarget = positionBufferView["target"]
glBindBuffer(positionTarget, positionVBO[])
glBufferData(positionTarget, positionBufferView["byteLength"], blobs[positionAccessor["bufferView"]], GL_STATIC_DRAW)

normalVBO = Ref{GLuint}(0)
glGenBuffers(1, normalVBO)
normalTarget = normalBufferView["target"]
glBindBuffer(normalTarget, normalVBO[])
glBufferData(normalTarget, normalBufferView["byteLength"], blobs[normalAccessor["bufferView"]], GL_STATIC_DRAW)

texcoordVBO = Ref{GLuint}(0)
glGenBuffers(1, texcoordVBO)
texcoordTarget = texcoordBufferView["target"]
glBindBuffer(texcoordTarget, texcoordVBO[])
glBufferData(texcoordTarget, texcoordBufferView["byteLength"], blobs[texcoordAccessor["bufferView"]], GL_STATIC_DRAW)

indexEBO = Ref{GLuint}(0)
glGenBuffers(1, indexEBO)
indexTarget = indexBufferView["target"]
glBindBuffer(indexTarget, indexEBO[])
glBufferData(indexTarget, indexBufferView["byteLength"], blobs[indexAccessor["bufferView"]], GL_STATIC_DRAW)

# create VAO
vaoID = Ref{GLuint}(0)
glGenVertexArrays(1, vaoID)
glBindVertexArray(vaoID[])

positionComponentType = positionAccessor["componentType"]
positionByteStride = positionBufferView["byteStride"]
positionByteOffset = positionAccessor["byteOffset"]
glBindBuffer(positionTarget, positionVBO[])
glVertexAttribPointer(0, 3, positionComponentType, GL_FALSE, GLsizei(positionByteStride), Ptr{Void}(positionByteOffset))
glEnableVertexAttribArray(0)

normalComponentType = normalAccessor["componentType"]
normalByteStride = normalBufferView["byteStride"]
normalByteOffset = normalAccessor["byteOffset"]
glBindBuffer(normalTarget, normalVBO[])
glVertexAttribPointer(1, 3, normalComponentType, GL_FALSE, GLsizei(normalByteStride), Ptr{Void}(normalByteOffset))
glEnableVertexAttribArray(1)

texcoordComponentType = texcoordAccessor["componentType"]
texcoordByteStride = texcoordBufferView["byteStride"]
texcoordByteOffset = texcoordAccessor["byteOffset"]
glBindBuffer(texcoordTarget, texcoordVBO[])
glVertexAttribPointer(2, 2, texcoordComponentType, GL_FALSE, GLsizei(texcoordByteStride), Ptr{Void}(texcoordByteOffset))
glEnableVertexAttribArray(2)

# create shader program
vertexShaderPath = joinpath(@__DIR__, "debug.vert")
fragmentShaderPath = joinpath(@__DIR__, "debug.frag")
shaderProgramID = createprogram(vertexShaderPath, fragmentShaderPath)
viewMatrixLocation = glGetUniformLocation(shaderProgramID, "view")
projMatrixLocation = glGetUniformLocation(shaderProgramID, "proj")
diffuseMapLocation = glGetUniformLocation(shaderProgramID, "diffuse_map")
specularMapLocation = glGetUniformLocation(shaderProgramID, "specular_map")
ambientMapLocation = glGetUniformLocation(shaderProgramID, "ambient_map")
emissionMapLocation = glGetUniformLocation(shaderProgramID, "emission_map")
glUseProgram(shaderProgramID)
glUniformMatrix4fv(viewMatrixLocation, 1, GL_FALSE, get_view_matrix())
glUniformMatrix4fv(projMatrixLocation, 1, GL_FALSE, get_projective_matrix())
glUniform1i(diffuseMapLocation, 0)
glUniform1i(specularMapLocation, 1)
glUniform1i(ambientMapLocation, 2)
glUniform1i(emissionMapLocation, 3)

glActiveTexture(GL_TEXTURE0)
loadtexture(joinpath(@__DIR__, "boulder_diff.png"))
loadtexture(joinpath(@__DIR__, "boulder_spec.png"))
loadtexture(joinpath(@__DIR__, "ao.png"))
loadtexture(joinpath(@__DIR__, "tileable9b_emiss.png"))

# # enable cull face
glEnable(GL_CULL_FACE)
glCullFace(GL_BACK)
glFrontFace(GL_CCW)
# set background color to gray
glClearColor(0.2, 0.2, 0.2, 1.0)

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
    glBindVertexArray(vaoID[])
    glBindBuffer(indexTarget, indexEBO[])
    glDrawElements(GL_TRIANGLES, indexCount, indexComponentType, Ptr{Void}(indexByteOffset))
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
