# Run Cumbersome
include("triangleCum.jl")
# Run Simplified
include("triangleSim.jl")


function ma(a, b, c)
    println(a)
    println(b)
    println(c)
end

ma(1, 2, 3)


ex = :(ma(1, 2, 3))

dump(ex)


eval(ex)

gldatatype = "iv"

f = string("glUniform",gldatatype)

ex = symbol(f)
location = 6



ex = Expr(:call, symbol(f), location, 2, 3, 4)
ex.args[3] = exp
ex

macro uniform(gldatatype)
    functionName = string("glUniform",gldatatype)
    return Expr(:call, symbol(functionName), location, -2, 3, 4)
end

@SelectUniformAPI("iv")

