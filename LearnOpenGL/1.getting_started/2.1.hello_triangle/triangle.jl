using GLFW, ModernGL

# whenever the window size changed (by OS or user resize) this callback function executes
function framebuffer_size_callback(window::GLFW.Window, width::Cint, height::Cint)
    # make sure the viewport matches the new window dimensions; note that width and
    # height will be significantly larger than specified on retina displays.
	glViewport(0, 0, width, height)
end

# process all input: query GLFW whether relevant keys are pressed/released this frame and react accordingly
function processInput(window::GLFW.Window)
    GLFW.GetKey(window, GLFW.KEY_ESCAPE) == GLFW.PRESS && GLFW.SetWindowShouldClose(window, true)
end

# misc. config
const SCR_WIDTH = 800
const SCR_HEIGHT = 600

const vertexShaderSource = """
	#version 330 core
	layout (location = 0) in vec3 aPos;
	void main(void)
	{
	    gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);
	}"""

const fragmentShaderSource = """
	#version 330 core
	out vec4 FragColor;
	void main(void)
	{
	    FragColor = vec4(1.0f, 0.5f, 0.2f, 1.0f);
	}"""

GLFW.WindowHint(GLFW.CONTEXT_VERSION_MAJOR, 3)
GLFW.WindowHint(GLFW.CONTEXT_VERSION_MINOR, 3)
GLFW.WindowHint(GLFW.OPENGL_PROFILE, GLFW.OPENGL_CORE_PROFILE)
GLFW.WindowHint(GLFW.OPENGL_FORWARD_COMPAT, GL_TRUE)

# create window
window = GLFW.CreateWindow(SCR_WIDTH, SCR_HEIGHT, "LearnOpenGL")
window == C_NULL && error("Failed to create GLFW window.")
GLFW.MakeContextCurrent(window)
GLFW.SetFramebufferSizeCallback(window, framebuffer_size_callback)

# build and compile shader program
vertexShader = glCreateShader(GL_VERTEX_SHADER)
glShaderSource(vertexShader, 1, Ptr{GLchar}[pointer(vertexShaderSource)], C_NULL)
glCompileShader(vertexShader)
successRef = Ref{GLint}(-1)
glGetShaderiv(vertexShader, GL_COMPILE_STATUS, successRef)
if successRef[] != GL_TRUE
    infoLog = Vector{GLchar}(512)
    glGetShaderInfoLog(vertexShader, 512, C_NULL, infoLog)
    error("ERROR::SHADER::VERTEX::COMPILATION_FAILED\n", String(infoLog))
end

fragmentShader = glCreateShader(GL_FRAGMENT_SHADER)
glShaderSource(fragmentShader, 1, Ptr{GLchar}[pointer(fragmentShaderSource)], C_NULL)
glCompileShader(fragmentShader)
glGetShaderiv(vertexShader, GL_COMPILE_STATUS, successRef)
if successRef[] != GL_TRUE
    infoLog = Vector{GLchar}(512)
    glGetShaderInfoLog(fragmentShader, 512, C_NULL, infoLog)
    error("ERROR::SHADER::FRAGMENT::COMPILATION_FAILED\n", String(infoLog))
end

# link shaders
shaderProgram = glCreateProgram()
glAttachShader(shaderProgram, vertexShader)
glAttachShader(shaderProgram, fragmentShader)
glLinkProgram(shaderProgram)
glGetProgramiv(shaderProgram, GL_LINK_STATUS, successRef)
if successRef[] != GL_TRUE
    infoLog = Vector{GLchar}(512)
    glGetProgramInfoLog(shaderProgram, 512, C_NULL, infoLog)
    error("ERROR::SHADER::PROGRAM::LINKING_FAILED\n", String(infoLog))
end
glDeleteShader(vertexShader)
glDeleteShader(fragmentShader)


# set up vertex data (and buffer(s)) and configure vertex attributes
vertices = GLfloat[-0.5,  0.5, 0.0,   # left
                    0.5, -0.5, 0.0,   # right
                    0.0,  0.5, 0.0]   # top
vboRef = Ref{GLuint}(0)
vaoRef = Ref{GLuint}(0)
glGenVertexArrays(1, vaoRef)
glGenBuffers(1, vboRef)
vao = vaoRef[]
vbo = vboRef[]
glBindVertexArray(vao)
glBindBuffer(GL_ARRAY_BUFFER, vbo)
glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW)
glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(GLfloat), Ptr{Cvoid}(0))
glEnableVertexAttribArray(0)

# note that this is allowed, the call to glVertexAttribPointer registered VBO as
# the vertex attribute's bound vertex buffer object so afterwards we can safely unbind
glBindBuffer(GL_ARRAY_BUFFER, 0);

# You can unbind the VAO afterwards so other VAO calls won't accidentally modify this VAO,
# but this rarely happens. Modifying other VAOs requires a call to glBindVertexArray anyways
# so we generally don't unbind VAOs (nor VBOs) when it's not directly necessary.
glBindVertexArray(0)

# uncomment this call to draw in wireframe polygons.
# glPolygonMode(GL_FRONT_AND_BACK, GL_LINE)


# render loop
while !GLFW.WindowShouldClose(window)
    processInput(window)

    # render
    glClearColor(0.2, 0.3, 0.3, 1.0)
    glClear(GL_COLOR_BUFFER_BIT)

	# draw
	glUseProgram(shaderProgram)
    glBindVertexArray(vao)
	glDrawArrays(GL_TRIANGLES, 0, 3)

    # swap buffers and poll IO events
    GLFW.SwapBuffers(window)
    GLFW.PollEvents()
end

# optional: de-allocate all resources once they've outlived their purpose
glDeleteVertexArrays(1, vaoRef)
glDeleteBuffers(1, vboRef)

GLFW.DestroyWindow(window)
