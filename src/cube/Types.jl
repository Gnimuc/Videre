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
typealias AbstractOpenGLMatrixData{T} AbstractOpenGLData{T,2}
typealias AbstractOpenGLVecOrMatData{T} Union(AbstractOpenGLVectorData{T}, AbstractOpenGLMatrixData{T})

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
# not fully tested yet
type UniformData{T, A<:AbstractVecOrMat} <: AbstractOpenGLData{T}
    data::A
    name::ASCIIString
    tag::ASCIIString
    suffixsize::ASCIIString
    suffixtype::ASCIIString
    count::GLsizei
#=
    function UniformData(data, name, tag, count)
        # specify suffix size
        datasize = size(data)
        typeof(data) <: Matrix ? suffixsize = string(datasize[1],"x",datasize[2]) : suffixsize = string(datasize[1])
        # specify suffix type
        typestring = Dict([(GLfloat, "f"), (GLint, "i"), (GLuint, "ui")])
        suffixtype = typestring[eltype(data)]

        obj = new(data, name, tag, suffixsize, suffixtype, count)
        obj
    end
=#
end
function UniformData(data, name, tag, count)
    # specify suffix size
    datasize = size(data)
    if typeof(data) <: Vector
        suffixsize = string(datasize[1])
    elseif datasize[1] == datasize[2]
        suffixsize = string(datasize[1])
    else
        suffixsize = string(datasize[1],"x",datasize[2])
    end
    # specify suffix type
    typestring = Dict([(GLfloat, "f"), (GLint, "i"), (GLuint, "ui")])
    suffixtype = typestring[eltype(data)]

    UniformData{eltype(data), typeof(data)}(data, name, tag, suffixsize, suffixtype, count)
end

# extend size() getindex() setindex!() and similar() in Base
size(ud::UniformData) = size(ud.data)
getindex(ud::UniformData, i::Real) = getindex(ud.data, i)
setindex!(ud::UniformData, X, i::Real) = setindex!(ud.data, X, i)
similar(ud::UniformData) = UniformData(similar(ud.data), ud.name, ud.tag, ud.count)
similar(ud::UniformData, dims::Dims) = UniformData(similar(ud.data, dims), ud.name, ud.tag, ud.count)
similar{T}(ud::UniformData, ::Type{T}, dims::Dims) = UniformData(similar(ud.data, T, dims), ud.name, ud.tag, ud.count)



end

