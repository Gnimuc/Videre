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

const fragmentShader1Source = """
	#version 330 core
	out vec4 FragColor;
	void main(void)
	{
	    FragColor = vec4(1.0f, 0.5f, 0.2f, 1.0f);
	}"""

const fragmentShader2Source = """
	#version 330 core
	out vec4 FragColor;
	void main(void)
	{
	    FragColor = vec4(1.0f, 1.0f, 0.0f, 1.0f);
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
fragmentShaderOrange = glCreateShader(GL_FRAGMENT_SHADER)
fragmentShaderYellow = glCreateShader(GL_FRAGMENT_SHADER)
shaderProgramOrange = glCreateProgram()
shaderProgramYellow = glCreateProgram()

glShaderSource(vertexShader, 1, Ptr{GLchar}[pointer(vertexShaderSource)], C_NULL)
glCompileShader(vertexShader)
glShaderSource(fragmentShaderOrange, 1, Ptr{GLchar}[pointer(fragmentShader1Source)], C_NULL)
glCompileShader(fragmentShaderOrange)
glShaderSource(fragmentShaderYellow, 1, Ptr{GLchar}[pointer(fragmentShader2Source)], C_NULL)
glCompileShader(fragmentShaderYellow)

# link shaders
glAttachShader(shaderProgramOrange, vertexShader)
glAttachShader(shaderProgramOrange, fragmentShaderOrange)
glLinkProgram(shaderProgramOrange)

glAttachShader(shaderProgramYellow, vertexShader)
glAttachShader(shaderProgramYellow, fragmentShaderYellow)
glLinkProgram(shaderProgramYellow)

# set up vertex data (and buffer(s)) and configure vertex attributes
firstTriangle = GLfloat[-0.9,  0.5, 0.0,    # left
                         0.0, -0.5, 0.0,    # right
                         0.45, 0.5, 0.0]    # top
secondTriangle = GLfloat[0.0, -0.5, 0.0,    # left
						 0.9, -0.5, 0.0,    # right
					     0.45, 0.5, 0.0]    # top
vbos = zeros(GLuint, 2)
vaos = zeros(GLuint, 2)
glGenVertexArrays(2, vaos)
glGenBuffers(2, vbos)
# first triangle setup
glBindVertexArray(vaos[1])
glBindBuffer(GL_ARRAY_BUFFER, vbos[1])
glBufferData(GL_ARRAY_BUFFER, sizeof(firstTriangle), firstTriangle, GL_STATIC_DRAW)
glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(GLfloat), Ptr{Void}(0))
glEnableVertexAttribArray(0)
# second triangle setup
glBindVertexArray(vaos[2])
glBindBuffer(GL_ARRAY_BUFFER, vbos[2])
glBufferData(GL_ARRAY_BUFFER, sizeof(secondTriangle), secondTriangle, GL_STATIC_DRAW)
glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(GLfloat), Ptr{Void}(0))
glEnableVertexAttribArray(0)

# uncomment this call to draw in wireframe polygons.
# glPolygonMode(GL_FRONT_AND_BACK, GL_LINE)

# render loop
while !GLFW.WindowShouldClose(window)
    processInput(window)

    # render
    glClearColor(0.2, 0.3, 0.3, 1.0)
    glClear(GL_COLOR_BUFFER_BIT)


	# draw first triangle
	glUseProgram(shaderProgramOrange)
    glBindVertexArray(vaos[1])
	glDrawArrays(GL_TRIANGLES, 0, 3)

	# draw  second triangle
	glUseProgram(shaderProgramYellow)
    glBindVertexArray(vaos[2])
	glDrawArrays(GL_TRIANGLES, 0, 3)

    # swap buffers and poll IO events
    GLFW.SwapBuffers(window)
    GLFW.PollEvents()
end

# optional: de-allocate all resources once they've outlived their purpose
glDeleteVertexArrays(2, vaos)
glDeleteBuffers(2, vbos)

GLFW.DestroyWindow(window)
