module Type
# We could define our own types here.
#

# Our top type is AbstractOpenGLData, all concrete data type(e.g. VertexData) should be a subtype of it.
# AbstractOpenGLDataFormat is our data format, all concrete data format should be a subtype of it.
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
    format::VertexDataFormat{T}

end

# Uniform Data #



end

