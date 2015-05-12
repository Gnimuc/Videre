# Functions #
# modify GLSL version
function glslversion!(source::ASCIIString, major, minor)
    index = search(source, "#version ")
    source = replace(source, source[index.stop+1:index.stop+2], "$major$minor")
    return source
end

# create shader --> load shader source --> compile shader
function shadercompiler(shaderSource::ASCIIString, shaderType::GLenum)
    typestring = Dict([(GL_COMPUTE_SHADER, "compute"),
                     (GL_VERTEX_SHADER,"vertex"),
                     (GL_TESS_CONTROL_SHADER, "tessellation control"),
                     (GL_TESS_EVALUATION_SHADER, "tessellation evaluation"),
                     (GL_GEOMETRY_SHADER, "geometry"),
                     (GL_FRAGMENT_SHADER, "fragment")])
    # create shader & load source
    shader = glCreateShader(shaderType)
    @assert shader != 0 "Error creating $(typestring[shaderType]) shader."
    shaderSource = glslversion!(shaderSource, VERSION_MAJOR, VERSION_MINOR)
    shaderSourceptr = convert(Ptr{GLchar}, pointer(shaderSource))
    glShaderSource(shader, 1, convert(Ptr{Uint8}, pointer([shaderSourceptr])), C_NULL)
    # compile shader
    glCompileShader(shader)
    # compile error handling
    result = GLint[0]
    glGetShaderiv(shader, GL_COMPILE_STATUS, pointer(result))
    if result[1] == GL_FALSE
        println("$(typestring[shaderType]) shader compile failed.")
        logLen = GLint[0]
        glGetShaderiv(shader, GL_INFO_LOG_LENGTH, pointer(logLen))
        if logLen[1] > 0
            log = Array(GLchar, logLen[1])
            logptr = convert(Ptr{GLchar}, pointer(log))
            written = GLsizei[0]
            writtenptr = convert(Ptr{GLsizei}, pointer(written))
            glGetShaderInfoLog(shader, logLen[1], writtenptr, logptr )
            info = convert(ASCIIString, log)
            println("$info")
        end
    end
    return shader::GLuint
end

# create program handler --> attach shader --> link shader
function programer(shaderArray::Array{GLuint,1})
    # create program handler
    programHandle = glCreateProgram()
    @assert programHandle != 0 "Error creating program object."
    # attach shader
    for s in shaderArray
       glAttachShader(programHandle, s)
    end
    # link
    glLinkProgram(programHandle)
    # link error handling
    status = GLint[0]
    glGetProgramiv(programHandle, GL_LINK_STATUS, pointer(status))
    if status[1] == GL_FALSE
        println("Failed to link shader program.")
        logLen = GLint[0]
        glGetProgramiv(programHandle, GL_INFO_LOG_LENGTH, pointer(logLen))
        if logLen[1] > 0
            log = Array(GLchar, logLen[1])
            logptr = convert(Ptr{GLchar}, pointer(log))
            written = GLsizei[0]
            writtenptr = convert(Ptr{GLsizei}, pointer(written))
            glGetProgramInfoLog(programHandle, logLen[1], writtenptr, logptr )
            info = convert(ASCIIString, log)
            println("$info")
        end
    end
    return programHandle::GLuint
end

# pass data to buffer
function data2buffer(gldata::AbstractOpenGLData, bufferTarget::GLenum, bufferUsage::GLenum )
    # generate buffer
    buffer = GLuint[0]
    glGenBuffers(1, pointer(buffer) )
    # bind target
    glBindBuffer(bufferTarget, buffer[1] )
    # pass data to buffer
    glBufferData(bufferTarget, sizeof(gldata.data), gldata.data, bufferUsage)
    # release target
    glBindBuffer(bufferTarget, 0)
    return buffer
end

# connect buffer data to vertex attributes
function buffer2attrib(buffer::Array{GLuint, 1}, attriblocation::Array{GLuint, 1}, gldata::Array{VertexData, 1})
    # generate vertex array object
    vao = GLuint[0]
    glGenVertexArrays(1, convert(Ptr{GLuint}, pointer(vao)) )
    glBindVertexArray(vao[1])
    # connecting
    @assert length(buffer) == length(attriblocation) "the number of buffers and attributes do not match."
    for i = 1:length(buffer)
        glBindBuffer(GL_ARRAY_BUFFER, buffer[i] )
        glEnableVertexAttribArray(attriblocation[i])
        glVertexAttribPointer(attriblocation[i], gldata[i].component, gldata[i].datatype, GL_FALSE,
                              gldata[i].stride, gldata[i].offset)
    end
    return vao
end

# pass data to uniform
function data2uniform(gldata::UniformData, programHandle::GLuint)
    location = glGetUniformLocation(programHandle, gldata.name)
    # select uniform API
    if gldata.tag == "Scalar"
        functionName = string("glUniform", gldata.suffixsize, gldata.suffixtype)
        expression = Expr(:call, symbol(functionName), location)
        for i = 1:size(gldata)[1]
            push!(expression.args, gldata[i])
        end
    elseif gldata.tag == "Vector"
        functionName = string("glUniform", gldata.suffixsize, gldata.suffixtype, "v")
        expression = Expr(:call, symbol(functionName), location, gldata.count, gldata.data)
    else gldata.tag == "Matrix"
        functionName = string("glUniform", "Matrix", gldata.suffixsize, gldata.suffixtype, "v")
        expression = Expr(:call, symbol(functionName), location, gldata.count, GL_FALSE, gldata.data)
    end
    eval(expression)
end