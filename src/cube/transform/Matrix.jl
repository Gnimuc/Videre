## Transform Matrix ##
# Translation #
tx = 0                                      # translation in the x axes
ty = 0                                      # translation in the y axes
tz = -(1.0+2.0*abs(sin(time()*0.1)))        # translation in the z axes
translation = GLfloat[ 1.0 0.0 0.0 tx;
                       0.0 1.0 0.0 ty;
                       0.0 0.0 1.0 tz;
                       0.0 0.0 0.0 1.0 ]

# Rotation Matrix #
θ = 2pi*sin(time()*0.2)         # rotation around the x axis by an angle of θ
ϕ = 2pi*sin(time()*0.2)         # rotation around the y axis by an angle of ϕ
ψ = 2pi*abs(sin(time()*0.2))    # rotation around the z axis by an angle of ψ
rotationX = GLfloat[ 1.0     0.0     0.0 0.0;
                     0.0  cos(θ) -sin(θ) 0.0;
                     0.0  sin(θ)  cos(θ) 0.0;
                     0.0     0.0     0.0 1.0 ]

rotationY = GLfloat[  cos(ϕ)  0.0  sin(ϕ) 0.0;
                         0.0  1.0     0.0 0.0;
                     -sin(ϕ)  0.0  cos(ϕ) 0.0;
                         0.0  0.0     0.0 1.0 ]

rotationZ = GLfloat[ cos(ψ) -sin(ψ) 0.0 0.0;
                     sin(ψ)  cos(ψ) 0.0 0.0;
                        0.0     0.0 1.0 0.0;
                        0.0     0.0 0.0 1.0 ]

rotation = rotationZ * rotationY * rotationX

# Perspective Matrix #
#=
near = 1.0
far = 100.0
left = -0.25
right = 0.25
top = 0.25
bottom = -0.25

perspective = GLfloat[ 2near/(right-left)     0.0          (right+left)/(right-left)         0.0;
                            0.0        2near/(top-bottom)  (top+bottom)/(top-bottom)         0.0;
                            0.0               0.0            (near+far)/(near-far)   2near*far/(near-far);
                            0.0               0.0                    -1.0                    0.0 ]
=#

near = 1.0
far = 100.0
aspect = 800/600
fov = deg2rad(45)

perspective = GLfloat[ 1.0/(aspect*tan(fov/2))    0.0               0.0                       0.0;
                                0.0         1.0 / tan(fov/2)        0.0                       0.0;
                                0.0               0.0      (near+far)/(near-far) (2.0*near*far)/(near-far);
                                0.0               0.0              -1.0                       0.0 ]


