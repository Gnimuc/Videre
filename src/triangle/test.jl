include("triangleCum.jl")

include("triangleSim.jl")

offset

b = similar(offset)
b.component


color

a = [offset, color]

a.component

c = VertexData[offset,color]

typeof(c)

d = Array{VertexData,1}

d <: typeof(c)

