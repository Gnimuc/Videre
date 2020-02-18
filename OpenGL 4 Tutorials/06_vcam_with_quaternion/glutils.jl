using GLFW
using ModernGL
using CSyntax
using Printf

# print errors in shader compilation
function shader_info_log(shader::GLuint)
    max_length = GLint(0)
    @c glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &max_length)
    actual_length = GLsizei(0)
    log = Vector{GLchar}(undef, max_length)
    @c glGetShaderInfoLog(shader, max_length, &actual_length, log)
    @info "shader info log for GL index $shader: $(String(log))"
end

# print errors in shader linking
function programme_info_log(program::GLuint)
    max_length = GLint(0)
    @c glGetShaderiv(program, GL_INFO_LOG_LENGTH, &max_length)
    actual_length = GLsizei(0)
    log = Vector{GLchar}(undef, max_length)
    @c glGetShaderInfoLog(program, max_length, &actual_length, log)
    @info "program info log for GL index $program: $(String(log))"
end

# validate shader program
function is_valid(program::GLuint)
    params = GLint(-1)
    glValidateProgram(program)
    @c glGetProgramiv(program, GL_VALIDATE_STATUS, &params)
    @info "program $program GL_VALIDATE_STATUS = $params"
    params == GL_TRUE && return true
    programme_info_log(program)
    return false
end

# print verbose infos
function print_all(shader_prog::GLuint)
    params = GLint(-1)

    @debug "-------------------------"
    @debug "Shader programme $shader_prog info:"
    @c glGetProgramiv(shader_prog, GL_LINK_STATUS, &params)
    @debug "GL_LINK_STATUS = $params"

    @c glGetProgramiv(shader_prog, GL_ATTACHED_SHADERS, &params)
    @debug "GL_ATTACHED_SHADERS = $params"

    @c glGetProgramiv(shader_prog, GL_ACTIVE_ATTRIBUTES, &params)
    @debug "GL_ACTIVE_ATTRIBUTES = $params"

    max_length = GLint(0)
    @c glGetProgramiv(shader_prog, GL_ACTIVE_ATTRIBUTE_MAX_LENGTH, &max_length)
    name = Vector{GLchar}(undef, max_length)
    for i in 0:params-1
        actual_length = GLsizei(0)
        size = GLint(0)
        type = GLenum(0)
        @c glGetActiveAttrib(shader_prog, i, max_length, &actual_length, &size, &type, name)
        if size > 1
            for j = 0:size-1
                longname = @sprintf "%s[%i]" name j
                location = glGetAttribLocation(shader_prog, longname)
                @debug "  $i): type -> $(GLENUM(type).name), name -> $(String(longname)), location -> $location."
            end
        else
            location = glGetAttribLocation(shader_prog, name)
            @debug "  $i): type -> $(GLENUM(type).name), name -> $(String(name)), location -> $location."
        end
    end

    @c glGetProgramiv(shader_prog, GL_ACTIVE_UNIFORMS, &params)
    @debug "GL_ACTIVE_UNIFORMS = $(paramsRef[])"
    for i in 0:params-1
        max_length = GLint(0)
        @c glGetProgramiv(shader_prog, GL_ACTIVE_UNIFORM_MAX_LENGTH, &max_length)
        name = Vector{GLchar}(undef, max_length)
        actual_length = GLsizei(0)
        size = GLint(0)
        type = GLenum(0)
        @c glGetActiveUniform(shader_prog, i, max_length, &actual_length, &size, &type, name)
        if size > 1
            for j = 0:size-1
                longname = @sprintf "%s[%i]" name j
                location = glGetUniformLocation(shader_prog, longname)
                @debug "  $i): type -> $(GLENUM(type).name), name -> $(String(longname)), location -> $location."
            end
        else
            location = glGetUniformLocation(shader_prog, name)
            @debug "  $i): type -> $(GLENUM(type).name), name -> $(String(name)), location -> $location."
        end
    end

    programme_info_log(shader_prog)
end

# create shader
function createshader(path::AbstractString, type::GLenum)
    source = read(path, String)
    id = glCreateShader(type)
    glShaderSource(id, 1, Ptr{GLchar}[pointer(source)], C_NULL)
    glCompileShader(id)
    # get shader compile status and print logs
    result = GLint(-1)
    @c glGetShaderiv(id, GL_COMPILE_STATUS, &result)
    if result != GL_TRUE
        @error "$(GLENUM(type).name)(id:$id) failed to compile!"
        max_length = GLint(0)
        @c glGetShaderiv(id, GL_INFO_LOG_LENGTH, &max_length)
        actual_length = GLsizei(0)
        log = Vector{GLchar}(undef, max_length)
        @c glGetShaderInfoLog(id, max_length, &actual_length, log)
        @error String(log)
    end
    @info "$(GLENUM(type).name)(id:$id) successfully compiled!"
    return id
end

# create program
function createprogram(shaders::GLuint...)
    id = glCreateProgram()
    @info "Creating program(id:$id) ..."
    for shader in shaders
        @info "  attempting to attach shader(id:$shader) ..."
        glAttachShader(id, shader)
    end
    glLinkProgram(id)
    # checkout linking status
    result = GLint(-1)
    @c glGetProgramiv(id, GL_LINK_STATUS, &result)
    if result != GL_TRUE
        @error "Could not link shader program(id:$id)!"
		max_length = GLint(0)
        @c glGetProgramiv(id, GL_INFO_LOG_LENGTH, &max_length)
        actual_length = GLsizei(0)
        log = Vector{GLchar}(undef, max_length)
        @c glGetProgramInfoLog(id, max_length, &actual_length, log)
        @error String(log)
        error("Could not link shader program(id:$id)!")
    end
    @assert is_valid(id)
	foreach(id->glDeleteShader(id), shaders)
    return id
end

## GLFW initialization
# set up GLFW key callbacks : press Esc to escape
function key_callback(window::GLFW.Window, key::GLFW.Key, scancode::Cint, action::GLFW.Action, mods::Cint)
	key == GLFW.KEY_ESCAPE && action == GLFW.PRESS && GLFW.SetWindowShouldClose(window, true)
end

# tell GLFW to run this function whenever the framebuffer size is changed
function framebuffer_size_callback(window::GLFW.Window, w::Cint, h::Cint)
	global fb_width = w
	global fb_height = h
	println("framebuffer size: ($w, $h)")
    return nothing
end

# tell GLFW to run this function whenever the window size is changed
function window_size_callback(window::GLFW.Window, w::Cint, h::Cint)
	global width = w
	global height = h
	println("window size: ($w, $h)")
    return nothing
end

# error callback
error_callback(err::GLFW.GLFWError) = @error "GLFW ERROR: code $(err.code) msg: $(err.description)"
GLFW.SetErrorCallback(error_callback)

# start OpenGL
function startgl(width, height)
	@static if Sys.isapple()
        GLFW.WindowHint(GLFW.CONTEXT_VERSION_MAJOR, VERSION_MAJOR)
        GLFW.WindowHint(GLFW.CONTEXT_VERSION_MINOR, VERSION_MINOR)
        GLFW.WindowHint(GLFW.OPENGL_PROFILE, GLFW.OPENGL_CORE_PROFILE)
        GLFW.WindowHint(GLFW.OPENGL_FORWARD_COMPAT, GL_TRUE)
    else
        GLFW.DefaultWindowHints()
    end

    @info "starting GLFW ..."
    @info GLFW.GetVersionString()

	window = GLFW.CreateWindow(width, height, "Extended Init.")
	@assert window != C_NULL "could not open window with GLFW3."

	GLFW.SetKeyCallback(window, key_callback)
	GLFW.SetWindowSizeCallback(window, window_size_callback)
	GLFW.SetFramebufferSizeCallback(window, framebuffer_size_callback)
	GLFW.MakeContextCurrent(window)
	GLFW.WindowHint(GLFW.SAMPLES, 4)

	# get version info
    renderer = unsafe_string(glGetString(GL_RENDERER))
    version = unsafe_string(glGetString(GL_VERSION))
    @info "Renderder: $renderer"
    @info "OpenGL version supported: $version"

    return window
end

# _update_fps_counter functor
mutable struct FPSCounter{T<:AbstractFloat}
	previous_time::T
	frame_count::Int
end
FPSCounter() = FPSCounter(time(), 0)
function (obj::FPSCounter)(window::GLFW.Window)
	current_time = time()
	elapsed_time = current_time - obj.previous_time
	if elapsed_time > 0.25
		obj.previous_time = current_time
		fps = obj.frame_count / elapsed_time
		GC.@preserve fps GLFW.SetWindowTitle(window, @sprintf("opengl @ fps: %.2f", fps))
		obj.frame_count = 0
	end
	obj.frame_count += 1
end
