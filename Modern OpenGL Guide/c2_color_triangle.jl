using LibCSFML
using ModernGL
using CSyntax
using CSyntax.CSwitch

# shader sources
const vert_source = """
    #version 150 core
    in vec2 position;
    in vec3 color;
    out vec3 Color;
    void main()
    {
        Color = color;
        gl_Position = vec4(position, 0.0, 1.0);
    }"""

const frag_source = """
    #version 150 core
    in vec3 Color;
    out vec4 outColor;
    void main()
    {
        outColor = vec4(Color, 1.0);
    }"""


# SFML settings
settings = sfContextSettings(24, 8, 0, 3, 3, sfContextCore, true)
window = @c sfWindow_create(sfVideoMode(800, 600, 32), "OpenGL", sfTitlebar | sfClose, &settings)

# create Vertex Array Object
vao = GLuint(0)
@c glGenVertexArrays(1, &vao)
glBindVertexArray(vao)

# create a Vertex Buffer Object and copy the vertex data to it
vbo = GLuint(0)
@c glGenBuffers(1, &vbo)

vertices = GLfloat[
     0.0,  0.5, 1.0, 0.0, 0.0,
     0.5, -0.5, 0.0, 1.0, 0.0,
    -0.5, -0.5, 0.0, 0.0, 1.0]

glBindBuffer(GL_ARRAY_BUFFER, vbo)
glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW)

# create and compile the vertex shader
vert_shader = glCreateShader(GL_VERTEX_SHADER)
glShaderSource(vert_shader, 1, Ptr{GLchar}[pointer(vert_source)], C_NULL)
glCompileShader(vert_shader)

# create and compile the fragment shader
frag_shader = glCreateShader(GL_FRAGMENT_SHADER)
glShaderSource(frag_shader, 1, Ptr{GLchar}[pointer(frag_source)], C_NULL)
glCompileShader(frag_shader)

# link the vertex and fragment shader into a shader program
shader_prog = glCreateProgram()
glAttachShader(shader_prog, vert_shader)
glAttachShader(shader_prog, frag_shader)
glBindFragDataLocation(shader_prog, 0, "outColor")
glLinkProgram(shader_prog)
glUseProgram(shader_prog)

# specify the layout of the vertex data
pos_attrib = glGetAttribLocation(shader_prog, "position")
glEnableVertexAttribArray(pos_attrib)
glVertexAttribPointer(pos_attrib, 2, GL_FLOAT, GL_FALSE, 5 * sizeof(GLfloat), C_NULL)

color_attrib = glGetAttribLocation(shader_prog, "color")
glEnableVertexAttribArray(color_attrib);
glVertexAttribPointer(color_attrib, 3, GL_FLOAT, GL_FALSE, 5 * sizeof(GLfloat), Ptr{Cvoid}(2 * sizeof(GLfloat)))

window_event_ref = Ref(sfEvent(sfEvtClosed))
running = true
while running
    global running; global window_event_ref;
    while Bool(sfWindow_pollEvent(window, window_event_ref))
        @cswitch window_event_ref[].type begin
            @case sfEvtClosed
                running = false
                break
        end
    end

    # clear the screen to black
    glClearColor(0.0, 0.0, 0.0, 1.0)
    glClear(GL_COLOR_BUFFER_BIT)

    # draw a triangle from the 3 vertices
    glDrawArrays(GL_TRIANGLES, 0, 3)

    # swap buffers
    sfWindow_display(window)
end

glDeleteProgram(shader_prog)
glDeleteShader(frag_shader)
glDeleteShader(vert_shader)

@c glDeleteBuffers(1, &vbo)

@c glDeleteVertexArrays(1, &vao)

sfWindow_close(window)
sfWindow_destroy(window)
