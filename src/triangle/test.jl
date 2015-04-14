include("triangleCum.jl")

include("triangleSim.jl")

abstract AbstractOpenGLData{T} <: AbstractVector{T}
abstract AbstractOpenGLDataFormat{T}
# VertexDataFormat #
type VertexDataFormat{T} <: AbstractOpenGLDataFormat{T}
    datatype::T
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
    format

end

typeof(VertexData)

typeof(VertexDataFormat)

a = VertexData{Float32}([0.1,0.2,0.3], b )

b = VertexDataFormat{Float32}(0.1, 1, 1, C_NULL)

typeof(b)


typeof(b.datatype) == Float32

