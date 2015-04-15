module Types
# We could define our own types here.
#
using ModernGL
# Our top type is AbstractOpenGLData, all concrete data type(e.g. VertexData) should be a subtype of it.
abstract AbstractOpenGLData{T,N} <: AbstractArray{T,N}
typealias AbstractOpenGLVectorData{T} AbstractOpenGLData{T,1}
# VertexData #
#=
Note that the data here is constraint to a vector, which is consistent with our corresponding scripts.
And component, stride and offset are three parameters of glVertexAttribPointer() which specify data format.

More details:
datatype --> the data type of each component
component --> the number of components per vertex attribute
stride --> the byte offset between consecutive attributes
offset --> a byte offset from the beginning of the buffer to the first attribute in the buffer
=#
type VertexData{T, A<:AbstractVector} <: AbstractOpenGLVectorData{T}
    data::A
    datatype::GLenum
    component::Uint
    stride::Uint
    offset::Ptr{None}

end
#VertexData(data; args...) = VertexData{eltype(data), typeof(data)}(data, datatype, component, stride, offset)
VertexData(data, datatype, component, stride, offset) = VertexData{eltype(data), typeof(data)}(data, datatype, component, stride, offset)

# extend size() getindex() setindex!() and similar() in Base
import Base.size
import Base.getindex
import Base.setindex!
import Base.similar

size(vd::AbstractOpenGLData) = size(vd.data)
getindex(vd::AbstractOpenGLData, i::Real) = getindex(vd.data, i)
setindex!(vd::AbstractOpenGLData, X, i::Real) = setindex!(vd.data, X, i)
similar(vd::AbstractOpenGLData) = VertexData(similar(vd.data), vd.datatype, vd.component, vd.stride, vd.offset)
similar(vd::AbstractOpenGLData, dims::Dims) = VertexData(similar(vd.data, dims), vd.datatype, vd.component, vd.stride, vd.offset)
similar{T}(vd::AbstractOpenGLData, ::Type{T}, dims::Dims) = VertexData(similar(vd.data, T, dims), vd.datatype, vd.component, vd.stride, vd.offset)


# Uniform Data #



end

