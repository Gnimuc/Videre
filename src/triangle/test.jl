include("triangleCum.jl")

include("triangleSim.jl")

























# old test #


typeof([offsetbuffer, colorbuffer])
typeof(offsetbuffer)
length(offsetbuffer)
methods(data2buffer)
methods(buffer2attrib)

typeof(GL_FLOAT)
<: AbstractOpenGLData

super(offset.value)
typeof(offset)


Vector <: AbstractOpenGLData

# temporary testing code
abstract AbstractOpenGLData{T} <: AbstractVector{T}
abstract AbstractOpenGLDataFormat{T}
# VertexDataFormat #
type VertexDataFormat{T} <: AbstractOpenGLDataFormat{T}
    datatype::DataType
    component::Uint
    stride::Uint
    offset::Ptr{None}

end
# VertexData #
#=
Note that the data here is constraint to a vector, which is consistent with our corresponding scripts.
And component, stride and offset are three parameters of glVertexAttribPointer() which specify data format.

More details:
component --> the number of components per vertex attribute
stride --> the byte offset between consecutive attributes
offset --> a byte offset from the beginning of the buffer to the first attribute in the buffer
=#
type VertexData{T} <: AbstractOpenGLData{T}
    value::Vector{T}
    format::VertexDataFormat

end

typeof(VertexData)

typeof(VertexDataFormat)

a = VertexData{GLfloat}([0.1,0.2,0.3], b )
typeof(a)
a.format
b = VertexDataFormat{GLfloat}( GLfloat, 1, 1, C_NULL)


super(Float32)
typeof(Float32)

b.datatype == Float32




type DataFormat
    format1::DataType
    format2::Uint
    format3::Uint
    format4::Ptr{None}

end

type Data{T} <: AbstractVector{T}
    value::Vector{T}
    format::DataFormat

end

myformat = DataFormat(Float32, 0, 0, C_NULL)

mydata = Data{Float32}([0.1, 0.2, 0.3], myformat)

