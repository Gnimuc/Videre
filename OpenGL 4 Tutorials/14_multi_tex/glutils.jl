using GLFW
using ModernGL
using Memento
using Reactive
using Quaternions
using Images

# checkout shader infos
function shaderlog(shaderID::GLuint)
    max_length = Ref{GLsizei}(0)
    glGetShaderiv(shaderID, GL_INFO_LOG_LENGTH, max_length)
    actualLength = Ref{GLsizei}(0)
    log = Vector{GLchar}(max_length[])
    glGetShaderInfoLog(shaderID, max_length[], actualLength, log)
    logger = getlogger(current_module())
    info(logger, string("shader info log for GL index ", shaderID, ":"))
    info(logger, String(log))
end

# checkout program infos
function programlog(programID::GLuint)
    max_length = Ref{GLsizei}(0)
    glGetProgramiv(programID, GL_INFO_LOG_LENGTH, max_length)
    actualLength = Ref{GLsizei}(0)
    log = Vector{GLchar}(max_length[])
    glGetProgramInfoLog(programID, max_length[], actualLength, log)
    logger = getlogger(current_module())
    info(logger, string("program info log for GL index ", programID, ":"))
    info(logger, String(log))
end

# print verbose infos
function printall(shaderProgramID::GLuint)
    result = Ref{GLint}(-1)
    logger = getlogger(current_module())
    info(logger, string("Shader Program ", shaderProgramID, " verbose info:"))
    glGetProgramiv(shaderProgramID, GL_LINK_STATUS, result)
    info(logger, string("GL_LINK_STATUS = ", result[]))

    glGetProgramiv(shaderProgramID, GL_ATTACHED_SHADERS, result)
    info(logger, string("GL_ATTACHED_SHADERS = ", result[]))

    glGetProgramiv(shaderProgramID, GL_ACTIVE_ATTRIBUTES, result)
    info(logger, string("GL_ACTIVE_ATTRIBUTES = ", result[]))

    for i in 1:result[]
        max_length = Ref{GLsizei}(0)
        glGetProgramiv(shaderProgramID, GL_ACTIVE_ATTRIBUTE_MAX_LENGTH, max_length)
        actualLength = Ref{GLsizei}(0)
        attributeSize = Ref{GLint}(0)
        attributeType = Ref{GLenum}(0)
        name = Vector{GLchar}(max_length[])
        glGetActiveAttrib(shaderProgramID, i-1, max_length[], actualLength, attributeSize, attributeType, name)
        if attributeSize[] > 1
            for j = 1:attributeSize[]
                longName = @sprintf "%s[%i]" name j
                location = glGetAttribLocation(shaderProgramID, longName)
                log = string("  ", i, ") type:", GLENUM(attributeType[]).name, " name:", String(longName), " location:", location)
                info(logger, log)
            end
        else
            location = glGetAttribLocation(shaderProgramID, name)
            log = string("  ", i, ") type:", GLENUM(attributeType[]).name, " name:", String(name), " location:", location)
            info(logger, log)
        end
    end

    glGetProgramiv(shaderProgramID, GL_ACTIVE_UNIFORMS, result)
    info(logger, string("GL_ACTIVE_UNIFORMS = ", result[]))
    for i in 1:result[]
        max_length = Ref{GLsizei}(0)
        glGetProgramiv(shaderProgramID, GL_ACTIVE_UNIFORM_MAX_LENGTH, max_length)
        actualLength = Ref{GLsizei}(0)
        attributeSize = Ref{GLint}(0)
        attributeType = Ref{GLenum}(0)
        name = Vector{GLchar}(max_length[])
        glGetActiveUniform(shaderProgramID, i-1, max_length[], actualLength, attributeSize, attributeType, name)
        if attributeSize[] > 1
            for j = 1:attributeSize[]
                longName = @sprintf "%s[%i]" name j
                location = glGetUniformLocation(shaderProgramID, longName)
                log = string("  ", i, ") type:", GLENUM(attributeType[]).name, " name:", String(longName), " location:", location)
                info(logger, log)
            end
        else
            location = glGetUniformLocation(shaderProgramID, name)
            log = string("  ", i, ") type:", GLENUM(attributeType[]).name, " name:", String(name), " location:", location)
            info(logger, log)
        end
    end
    programlog(shaderProgramID)
end

# validate shader program
function validprogram(shaderProgramID::GLuint)
    validResult = Ref{GLint}(-1)
    glValidateProgram(shaderProgramID)
    glGetProgramiv(shaderProgramID, GL_VALIDATE_STATUS, validResult)
    log = string("program ", shaderProgramID, " GL_VALIDATE_STATUS = ", validResult[])
    logger = getlogger(current_module())
    info(logger, log)
    if validResult[] != GL_TRUE
        programlog(shaderProgramID)
        return false
    end
    return true
end

# load OpenGL parameters info
function glparams()
    params = GLenum[ GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS,
                     GL_MAX_CUBE_MAP_TEXTURE_SIZE,
                     GL_MAX_DRAW_BUFFERS,
                     GL_MAX_FRAGMENT_UNIFORM_COMPONENTS,
                     GL_MAX_TEXTURE_IMAGE_UNITS,
                     GL_MAX_TEXTURE_SIZE,
                     GL_MAX_VARYING_FLOATS,
                     GL_MAX_VERTEX_ATTRIBS,
                     GL_MAX_VERTEX_TEXTURE_IMAGE_UNITS,
                     GL_MAX_VERTEX_UNIFORM_COMPONENTS,
                     GL_MAX_VIEWPORT_DIMS,
                     GL_STEREO ]
    names = [ "GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS",
    	 	  "GL_MAX_CUBE_MAP_TEXTURE_SIZE",
    		  "GL_MAX_DRAW_BUFFERS",
    		  "GL_MAX_FRAGMENT_UNIFORM_COMPONENTS",
        	  "GL_MAX_TEXTURE_IMAGE_UNITS",
        	  "GL_MAX_TEXTURE_SIZE",
        	  "GL_MAX_VARYING_FLOATS",
        	  "GL_MAX_VERTEX_ATTRIBS",
        	  "GL_MAX_VERTEX_TEXTURE_IMAGE_UNITS",
        	  "GL_MAX_VERTEX_UNIFORM_COMPONENTS",
        	  "GL_MAX_VIEWPORT_DIMS",
        	  "GL_STEREO" ]

    logger = getlogger(current_module())
    info(logger, "GL Context Params:")
    for i = 1:10
        v = Ref{GLint}(0)
        glGetIntegerv(params[i], v)
        info(logger, string(names[i], ": ", v[]))
    end
    v = GLint[0, 0]
    s = Ref{GLboolean}(0)
    glGetIntegerv(params[11], v)
    info(logger, string(names[11], ": ", v[1], " | ", v[2]))
    glGetBooleanv(params[12], s)
    info(logger, string(names[12], ": ", s[]))
    info(logger, "-----------------------------")
    return nothing
end

# init key signals
const KEYS = (:A, :D, :Q, :E, :W, :S, :LEFT, :RIGHT, :UP, :DOWN, :Z, :C)
for key in KEYS
    signame = Symbol("sig$key")
    @eval $signame = Signal(false)
end

## GLFW initialization
# set up GLFW key callbacks :
#   Esc -> escape
#   A -> slide left
#   D -> slide right
#   W -> move forward
#   S -> move backward
#   Q -> move upward
#   E -> move downward
#   LEFT -> yaw left
#   RIGHT -> yaw right
#   UP -> pitch up
#   DOWN -> pitch down
#   Z -> roll left
#   C -> roll right
function key_callback(window::GLFW.Window, key::Cint, scancode::Cint, action::Cint, mods::Cint)
    key == GLFW.KEY_ESCAPE && action == GLFW.PRESS && GLFW.SetWindowShouldClose(window, true)
    key == GLFW.KEY_A && action == GLFW.PRESS && push!(sigA, true)
    key == GLFW.KEY_A && action == GLFW.RELEASE && push!(sigA, false)
    key == GLFW.KEY_D && action == GLFW.PRESS && push!(sigD, true)
    key == GLFW.KEY_D && action == GLFW.RELEASE && push!(sigD, false)
    key == GLFW.KEY_W && action == GLFW.PRESS && push!(sigW, true)
    key == GLFW.KEY_W && action == GLFW.RELEASE && push!(sigW, false)
    key == GLFW.KEY_S && action == GLFW.PRESS && push!(sigS, true)
    key == GLFW.KEY_S && action == GLFW.RELEASE && push!(sigS, false)
    key == GLFW.KEY_Q && action == GLFW.PRESS && push!(sigQ, true)
    key == GLFW.KEY_Q && action == GLFW.RELEASE && push!(sigQ, false)
    key == GLFW.KEY_E && action == GLFW.PRESS && push!(sigE, true)
    key == GLFW.KEY_E && action == GLFW.RELEASE && push!(sigE, false)
    key == GLFW.KEY_LEFT && action == GLFW.PRESS && push!(sigLEFT, true)
    key == GLFW.KEY_LEFT && action == GLFW.RELEASE && push!(sigLEFT, false)
    key == GLFW.KEY_RIGHT && action == GLFW.PRESS && push!(sigRIGHT, true)
    key == GLFW.KEY_RIGHT && action == GLFW.RELEASE && push!(sigRIGHT, false)
    key == GLFW.KEY_UP && action == GLFW.PRESS && push!(sigUP, true)
    key == GLFW.KEY_UP && action == GLFW.RELEASE && push!(sigUP, false)
    key == GLFW.KEY_DOWN && action == GLFW.PRESS && push!(sigDOWN, true)
    key == GLFW.KEY_DOWN && action == GLFW.RELEASE && push!(sigDOWN, false)
    key == GLFW.KEY_Z && action == GLFW.PRESS && push!(sigZ, true)
    key == GLFW.KEY_Z && action == GLFW.RELEASE && push!(sigZ, false)
    key == GLFW.KEY_C && action == GLFW.PRESS && push!(sigC, true)
    key == GLFW.KEY_C && action == GLFW.RELEASE && push!(sigC, false)
end

# : change window size
function window_size_callback(window::GLFW.Window, width::Cint, height::Cint)
    global glfwWidth = width
    global glfwHeight = height
    println("width", width, "height", height)
    # update any perspective matrices used here
    return nothing
end

# error callback
function error_callback(error::Cint, description::Ptr{GLchar})
    logger = getlogger(current_module())
    s = @sprintf "GLFW ERROR: code %i msg: %s" error description
	error(logger, s)
    return nothing
end


# start OpenGL
function startgl()
    @static if Sys.isapple()
        GLFW.WindowHint(GLFW.CONTEXT_VERSION_MAJOR, VERSION_MAJOR)
        GLFW.WindowHint(GLFW.CONTEXT_VERSION_MINOR, VERSION_MINOR)
        GLFW.WindowHint(GLFW.OPENGL_PROFILE, GLFW.OPENGL_CORE_PROFILE)
        GLFW.WindowHint(GLFW.OPENGL_FORWARD_COMPAT, GL_TRUE)
    else
        GLFW.DefaultWindowHints()
    end

    # set up GLFW log and error callbacks
    Memento.config("notice"; fmt="[ {date} | {level} ]: {msg}")
    logger = getlogger(current_module())
    push!(logger, DefaultHandler("gl.log", DefaultFormatter("[{date} | {level}]: {msg}")))
    setlevel!(logger, "info")
    info(logger, "starting GLFW ...")
    info(logger, GLFW.GetVersionString())
    GLFW.SetErrorCallback(error_callback)

    # create window
    global window = GLFW.CreateWindow(glfwWidth, glfwHeight, "Extended Init.")
    @assert window != C_NULL "could not open window with GLFW3."

    # set callbacks
    GLFW.SetKeyCallback(window, key_callback)
    GLFW.SetWindowSizeCallback(window, window_size_callback)
    GLFW.MakeContextCurrent(window)
    GLFW.WindowHint(GLFW.SAMPLES, 4)

    # get version info
    renderer = unsafe_string(glGetString(GL_RENDERER))
    version = unsafe_string(glGetString(GL_VERSION))
    info("Renderder: ", renderer)
    info("OpenGL version supported: ", version)
    glparams()

    return true
end

# _update_fps_counter
let previousTime = time()
    frameCount = 0
    global function updatefps(window::GLFW.Window)
        currentTime = time()
        elapsedTime = currentTime - previousTime
        if elapsedTime > 0.25
            previousTime = currentTime
            fps = frameCount / elapsedTime
            s = @sprintf "opengl @ fps: %.2f" fps
            GLFW.SetWindowTitle(window, s)
            frameCount = 0
        end
        frameCount = frameCount + 1
    end
end

# camera
let
    cameraSpeed = GLfloat(1.0)
    cameraHeadingSpeed = GLfloat(10.0)
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

# projective matrix
let
    near = 0.1            # clipping near plane
    far = 100.0           # clipping far plane
    fov = deg2rad(67)
    global function get_projective_matrix()
        aspectRatio = glfwWidth / glfwHeight
        range = tan(0.5*fov) * near
        Sx = 2.0*near / (range * aspectRatio + range * aspectRatio)
        Sy = near / range
        Sz = -(far + near) / (far - near)
        Pz = -(2.0*far*near) / (far - near)
        return GLfloat[ Sx   0.0  0.0  0.0;
                        0.0   Sy  0.0  0.0;
                        0.0  0.0   Sz   Pz;
                        0.0  0.0 -1.0  0.0]
    end
end

# create shader
function createshader(source::AbstractString, shaderType::GLenum)
    logger = getlogger(current_module())
    info(logger, string("creating shader from ", source, "..."))
    shader = readstring(source)
    shaderID = glCreateShader(shaderType)
    glShaderSource(shaderID, 1, Ptr{GLchar}[pointer(shader)], C_NULL)
    glCompileShader(shaderID)
    # get shader compile status
    compileResult = Ref{GLint}(-1)
    glGetShaderiv(shaderID, GL_COMPILE_STATUS, compileResult)
    if compileResult[] != GL_TRUE
        warn(logger, string("GL shader(index ", shaderID, " )did not compile.", " Shader Type: ", GLENUM(shaderType).name))
        shaderlog(shaderID)
        error("GL shader(index ", shaderID, " )did not compile.", " Shader Type: ", GLENUM(shaderType).name)
    end
    info(logger, string("shader compiled. index ", shaderID, " Shader Type: ", GLENUM(shaderType).name))
    return shaderID
end

# create program
function createprogram(vertID::GLuint, fragID::GLuint)
    shaderProgramID = glCreateProgram()
    logger = getlogger(current_module())
    info(logger, string("creating program ", shaderProgramID, " attaching shaders: ", vertID, " and ", fragID, "..."))
    glAttachShader(shaderProgramID, vertID)
    glAttachShader(shaderProgramID, fragID)
    glLinkProgram(shaderProgramID)
    # checkout programe linking status
    linkingResult = Ref{GLint}(-1)
    glGetProgramiv(shaderProgramID, GL_LINK_STATUS, linkingResult)
    if linkingResult[] != GL_TRUE
        warn(logger, string("\nERROR: could not link shader programme GL index: ", shaderProgramID))
        programlog(shaderProgramID)
        error(string("\nERROR: could not link shader programme GL index: ", shaderProgramID))
    end
    @assert validprogram(shaderProgramID)
    glDeleteShader(vertID)
    glDeleteShader(fragID)
    return shaderProgramID
end

# create program from files
function createprogram(vertSource::AbstractString, fragSource::AbstractString)
    vertexShader = createshader(vertSource, GL_VERTEX_SHADER)
    fragmentShader = createshader(fragSource, GL_FRAGMENT_SHADER)
    shaderProgramID = createprogram(vertexShader, fragmentShader)
    return shaderProgramID
end

# screen capture
function screencapture()
    buffer = zeros(RGB{N0f8}, glfwWidth, glfwHeight)
    glReadPixels(0, 0, glfwWidth, glfwHeight, GL_RGB, GL_UNSIGNED_BYTE, buffer)
    save(joinpath(@__DIR__, "$(basename(tempname())).png"), flipdim(buffer.',1))
end

# load texture
function loadtexture(path::AbstractString)
    texImg = load(path)
    texWidth, texHeight = size(texImg) .|> GLsizei
    texID = Ref{GLuint}(0)
    glGenTextures(1, texID)
    glBindTexture(GL_TEXTURE_2D, texID[])
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, texWidth, texHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, flipdim(texImg.',2))
    glGenerateMipmap(GL_TEXTURE_2D)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR)
    return texID
end
