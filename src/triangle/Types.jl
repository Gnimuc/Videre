module Types
# We could define our own types in this module.

# load essentials
using ModernGL

import Base.size
import Base.getindex
import Base.setindex!
import Base.similar

# Our top type is AbstractOpenGLData, all concrete data type(e.g. VertexData) should be a subtype of it.
# We make AbstractOpenGLData a subtype of AbstractArray in order to implement some convenient array operations.
abstract AbstractOpenGLData{T,N} <: AbstractArray{T,N}
typealias AbstractOpenGLVectorData{T} AbstractOpenGLData{T,1}

# VertexData #
#=
Note that the data here is constraint to a vector, which is consistent with our corresponding scripts in this folder.
And datatype, component, stride and offset are four parameters of glVertexAttribPointer() which specify data format.

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
VertexData(data, datatype, component, stride=0, offset=C_NULL) = VertexData{eltype(data), typeof(data)}(data, datatype, component, stride, offset)

# extend size() getindex() setindex!() and similar() in Base
size(vd::VertexData) = size(vd.data)
getindex(vd::VertexData, i::Real) = getindex(vd.data, i)
setindex!(vd::VertexData, X, i::Real) = setindex!(vd.data, X, i)
similar(vd::VertexData) = VertexData(similar(vd.data), vd.datatype, vd.component, vd.stride, vd.offset)
similar(vd::VertexData, dims::Dims) = VertexData(similar(vd.data, dims), vd.datatype, vd.component, vd.stride, vd.offset)
similar{T}(vd::VertexData, ::Type{T}, dims::Dims) = VertexData(similar(vd.data, T, dims), vd.datatype, vd.component, vd.stride, vd.offset)


# Uniform Data #



end

