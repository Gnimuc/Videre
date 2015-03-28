## Transform Matrix ##

# Identity Matrix #
identity = GLfloat[ 1.0, 0.0, 0.0, 0.0,
                    0.0, 1.0, 0.0, 0.0,
                    0.0, 0.0, 1.0, 0.0,
                    0.0, 0.0, 0.0, 1.0 ]

# Translation Matrix #
tx = sin(time())/2  # translation in the x axes
ty = sin(time())/2  # translation in the y axes
tz = sin(time())/2  # translation in the z axes
translation = GLfloat[ 1.0 0.0 0.0 tx;
                       0.0 1.0 0.0 ty;
                       0.0 0.0 1.0 tz;
                       0.0 0.0 0.0 1.0 ]

# Rotation Matrix #
θ =  pi/6*abs(sin(time()))  # rotation around the x axis by an angle of θ
ϕ =  pi/2*abs(sin(time()))  # rotation around the y axis by an angle of ϕ
ψ =  pi*abs(sin(time()))  # rotation around the z axis by an angle of ψ
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

# Lookat Matrix #



# Perspective Matrix #
near = 0.1
far = 1000.0
#=left = 800.0
right = 0.0
top = 0.0
bottom = 600.0

perspective = GLfloat[ 2near/(right-left)     0.0          (right+left)/(right-left)         0.0;
                            0.0        2near/(top-bottom)  (top+bottom)/(top-bottom)         0.0;
                            0.0               0.0            (near+far)/(near-far)   2near*far/(near-far);
                            0.0               0.0                    -1.0                    0.0 ]
=#
aspect = 800/600
q = 1.0 / tan(0.5*45/180*pi)
A = q / aspect
B = (near + far) / (near - far)
C = (2.0 * near * far) / (near - far)

perspective = GLfloat[       A                0.0                     0.0        0.0;
                            0.0                q                      0.0        0.0;
                            0.0               0.0                      B          C;
                            0.0               0.0                    -1.0        0.0 ]



# test
#perspective*translation*rotation

