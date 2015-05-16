## Triangle ♣ ##
#=
Code Style: cumbersome
Functionality: to draw our fuzzy triangle
GL Version: 430+
Usage: could NOT be used yet, because my graphics does not support binding layout identifier.

More Details:


=#

# Note that you must create a OpenGL context before running these code
# and make sure that your context version is matching those in VertexShader.jl and FragmentShader.jl.

# set up viewport
glViewport(0, 0, WIDTH, HEIGHT)

# pipeline #
# vertex shading stage
include("./pipeline/front-end stages/vertex shading stage/VertexShader.jl")
vertexShaderSourceptr = convert(Ptr{GLchar}, pointer(triangle♣v))
vertexShader = glCreateShader(GL_VERTEX_SHADER)
glShaderSource(vertexShader, 1, convert(Ptr{Uint8}, pointer([vertexShaderSourceptr])), C_NULL)
glCompileShader(vertexShader)
# checkout compile status
success = GLuint[0]
glGetShaderiv(vertexShader, GL_COMPILE_STATUS, pointer(success))
if success[1] != 1
  println("Vertex shader compile failed.")
end

# fragment shading stage
include("./pipeline/back-end stages/fragment shading stage/FragmentShader.jl")
fragmentShaderSourceptr = convert(Ptr{GLchar}, pointer(triangle♣f))
fragmentShader = glCreateShader(GL_FRAGMENT_SHADER)
glShaderSource(fragmentShader, 1, convert(Ptr{Uint8}, pointer([fragmentShaderSourceptr])), C_NULL)
glCompileShader(fragmentShader)
# checkout compile status
glGetShaderiv(fragmentShader, GL_COMPILE_STATUS, pointer(success) )
if success[1] != 1
  println("Fragment shader compile failed.")
end

# link shaders #
shaderProgram = glCreateProgram()
glAttachShader(shaderProgram, vertexShader)
glAttachShader(shaderProgram, fragmentShader)
glLinkProgram(shaderProgram)

# Data #
position = GLfloat[0.5, -0.5, 0.0,
                   0.0, 0.5, 0.0,
                  -0.5, -0.5, 0.0]
# VBO #
# generate buffer
buffer = GLuint[0]
glGenBuffers(1, pointer(buffer) )
# pass offset to buffer 1
glBindBuffer(GL_ARRAY_BUFFER, buffer[1] )
glBufferData(GL_ARRAY_BUFFER, sizeof(position), position, GL_STATIC_DRAW)

# VAO #
VAO = GLuint[0]
glGenVertexArrays(1, convert(Ptr{GLuint}, pointer(VAO)) )
glBindVertexArray(VAO[1])
# connect buffer to vertex attributes
glBindBuffer(GL_ARRAY_BUFFER, buffer[1] )
glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, C_NULL)
glEnableVertexAttribArray(0)

# Uniform Blocks #
# get block index
blockIndex = glGetUniformBlockIndex(shaderProgram, "FuzzyTriangle")
# allocate uniform block buffer
blockSize = GLint[0]
glGetActiveUniformBlockiv(shaderProgram, blockIndex, GL_UNIFORM_BLOCK_DATA_SIZE, pointer(blockSize))
blockBuffer = c_malloc(blockSize[1])
# get indices and offsets
names = ["InnerColor", "OuterColor", "RadiusInner", "RadiusOuter"]
namesptr = zeros(Ptr{GLchar}, 4)
for i = 1:4
    namesptr[i] = convert(Ptr{GLchar}, pointer(names[i]))
end
indices = zeros(GLuint, 4)
glGetUniformIndices(shaderProgram, 4, convert(Ptr{GLchar}, pointer(namesptr)), pointer(indices))
offset = zeros(GLint, 4)
glGetActiveUniformsiv(shaderProgram, 4, pointer(indices), GL_UNIFORM_OFFSET, pointer(offset))
# specify data
outerColor = GLfloat[0.0, 0.0, 0.0, 0.0]
innerColor = GLfloat[1.0, 0.0, 0.0, 1.0]
innerRadius = GLfloat[0.23]
outerRadius = GLfloat[0.45]
# copy data
unsafe_copy!(convert(Ptr{GLfloat}, blockBuffer), convert(Ptr{GLfloat}, pointer(innerColor)), 4*sizeof(GLfloat))
unsafe_copy!(convert(Ptr{GLfloat}, blockBuffer + offset[1]), convert(Ptr{GLfloat}, pointer(outerColor)), 4*sizeof(GLfloat))
unsafe_copy!(convert(Ptr{GLfloat}, blockBuffer + offset[2]), convert(Ptr{GLfloat}, pointer(innerRadius)), sizeof(GLfloat))
unsafe_copy!(convert(Ptr{GLfloat}, blockBuffer + offset[3]), convert(Ptr{GLfloat}, pointer(outerRadius)), sizeof(GLfloat))
# UBO
uboBuffer = GLuint[0]
glGenBuffers( 1, pointer(uboBuffer) )
glBindBuffer( GL_UNIFORM_BUFFER, uboBuffer[1] )
glBufferData( GL_UNIFORM_BUFFER, blockSize[1], blockBuffer, GL_DYNAMIC_DRAW )
glBindBufferBase(GL_UNIFORM_BUFFER, 0, uboBuffer[1])

# loop #
while !GLFW.WindowShouldClose(window)
  # check and call events
  GLFW.PollEvents()
  # rendering commands here
  glClearColor(255/256, 250/256, 205/256, 1.0)
  glClear(GL_COLOR_BUFFER_BIT)
  # draw
  glUseProgram(shaderProgram)
  glDrawArrays(GL_TRIANGLES, 0, 3)
  # swap the buffers
  GLFW.SwapBuffers(window)
end
# clean up #
glDeleteShader(vertexShader)
glDeleteShader(fragmentShader)
glDeleteProgram(shaderProgram)
glDeleteVertexArrays(1, VAO)
glDeleteBuffers(1, buffer)
glDeleteBuffers(1, uboBuffer)
