module transform

using ModernGL

function translationmatrix( tx::GLfloat, ty::GLfloat, tz::GLfloat )
    translation = GLfloat[ 1.0 0.0 0.0 tx;
                           0.0 1.0 0.0 ty;
                           0.0 0.0 1.0 tz;
                           0.0 0.0 0.0 1.0 ]
    return translation
end

function scalematrix( sx::GLfloat, sy::GLfloat, sz::GLfloat )
    scale = GLfloat[ 1.0, 0.0, 0.0, 0.0,
                     0.0, 1.0, 0.0, 0.0,
                     0.0, 0.0, 1.0, 0.0,
                     0.0, 0.0, 0.0, 1.0 ]
    return scale
end

function rotationmatrix( x::GLfloat, y::GLfloat, z::GLfloat )
    θ = x*pi/180
    ϕ = y*pi/180
    ψ = z*pi/180
    rotationX = GLfloat[ 1.0     0.0    0.0 0.0;
                         0.0  cos(θ) sin(θ) 0.0;
                         0.0 -sin(θ) cos(θ) 0.0;
                         0.0     0.0    0.0 1.0 ]

    rotationY = GLfloat[ cos(ϕ) 0.0 -sin(ϕ) 0.0;
                            0.0 1.0     0.0 0.0;
                         sin(ϕ) 0.0  cos(ϕ) 0.0;
                            0.0 0.0     0.0 1.0 ]

    rotationZ = GLfloat[ cos(ψ) -sin(ψ) 0.0 0.0;
                         sin(ψ)  cos(ψ) 0.0 0.0;
                            0.0     0.0 1.0 0.0;
                            0.0     0.0 0.0 1.0 ]

    rotation = rotationZ * rotationY * rotationX
    return rotation
end





end # module

