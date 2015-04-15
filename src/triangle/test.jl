include("triangleCum.jl")

include("triangleSim.jl")


import Base.size
import Base.similar
size(vd::VertexData) = size(vd.data)
similar(vd::VertexData) = VertexData(similar(vd.data), copy(vd.datatype), copy(vd.component), copy(vd.stride), vd.offset)

offset
color
similar(offset)
[offset,color]

super(typeof(offset))


methods(VertexData)
super(VertexData)

typeof(offset)

super(typeof(offset))


