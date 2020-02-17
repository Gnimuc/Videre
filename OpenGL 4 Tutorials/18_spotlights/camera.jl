using Quaternions
using LinearAlgebra
using StaticArrays

abstract type AbstractCamera end

"""
    PerspectiveCamera
"""
mutable struct PerspectiveCamera <: AbstractCamera
    near::GLfloat
    far::GLfloat
    fov::GLfloat
    movingSpeed::GLfloat
    headingSpeed::GLfloat
    position::SVector{3,GLfloat}
    rotationMatrix::SMatrix{3,3,GLfloat,9}
    viewMatrix::SMatrix{4,4,GLfloat,16}
    quaternion::Quaternion{GLfloat}
    forward::SVector{3,GLfloat}
    right::SVector{3,GLfloat}
    up::SVector{3,GLfloat}
end
PerspectiveCamera(; near=0.1, far=1000.0, fov=deg2rad(67),
                    movingSpeed=5.0, headingSpeed=50, position=[0,0,0],
                    rotationMatrix=Matrix(I,3,3), viewMatrix=Matrix(I,4,4),
                    quaternion=qrotation([0,1,0], 0), forward=[0,0,-1],
                    right=[1,0,0], up=[0,1,0]) = PerspectiveCamera(near, far, fov, movingSpeed, headingSpeed, position,
                                                                   rotationMatrix, viewMatrix, quaternion,
                                                                   forward, right, up)

"""
    OrthographicCamera
"""
mutable struct OrthographicCamera <: AbstractCamera
    near::GLfloat
    far::GLfloat
    movingSpeed::GLfloat
    headingSpeed::GLfloat
    position::SVector{3,GLfloat}
    rotationMatrix::SMatrix{3,3,GLfloat,9}
    viewMatrix::SMatrix{4,4,GLfloat,16}
    quaternion::Quaternion{GLfloat}
    forward::SVector{3,GLfloat}
    right::SVector{3,GLfloat}
    up::SVector{3,GLfloat}
end
OrthographicCamera(; near=0.1, far=1000.0,
                     movingSpeed=5.0, headingSpeed=50, position=[0,0,0],
                     rotationMatrix=Matrix(I,3,3), viewMatrix=Matrix(I,4,4),
                     quaternion=qrotation([0,1,0], 0), forward=[0,0,-1],
                     right=[1,0,0], up=[0,1,0]) = OrthographicCamera(near, far, movingSpeed, headingSpeed, position,
                                                                     rotationMatrix, viewMatrix, quaternion,
                                                                     forward, right, up)

"""
    rotate!(camera, axis, angle; fwd=[0,0,-1], rgt=[1,0,0], up=[0,1,0])
Incrementally rotate `camera` about `axis` by `angle` in degree.
"""
function rotate!(camera::AbstractCamera, axis, angle::Real; fwd=[0,0,-1], rgt=[1,0,0], up=[0,1,0])
    camera.quaternion = qrotation(Vector(axis), deg2rad(angle)) * camera.quaternion    # incrementally update quaternion
    camera.rotationMatrix = rotationmatrix(camera.quaternion)    # update new rotation matrix
    camera.forward = camera.rotationMatrix * fwd    # update new forward direction vector
    camera.right = camera.rotationMatrix * rgt    # update new right direction vector
    camera.up = camera.rotationMatrix * up    # update new up direction vector
    return camera
end

"""
    get_view_matrix(camera)
Retrieve camera's latest view matrix. Generally speaking, there is no need to directly
set view matrix to some hard-coded values. You should update view matrix via [`update_view_matrix!`](@ref).
"""
get_view_matrix(camera::AbstractCamera) = camera.viewMatrix

"""
    update_view_matrix!(camera::AbstractCamera, move)
Translate `camera` about `right` axis by `move[1]`; `up` axis by `move[2]`; `forward` axis by `move[3]`.
"""
function update_view_matrix!(camera::AbstractCamera, move::AbstractVector)
    camera.position += camera.forward * move[3]
    camera.position += camera.up * move[2]
    camera.position += camera.right * move[1]
    camera.rotationMatrix = rotationmatrix(camera.quaternion)
    homogenousMatrix = vcat([camera.rotationMatrix camera.position], SMatrix{1,4,GLfloat,4}(0,0,0,1))
    # note that, view matrix is for transforming objects to eye space, but our goal is
    # to transform camera(eye space), so we need an inverse here.
    camera.viewMatrix = inv(homogenousMatrix)
end

function get_current_aspectratio(window::GLFW.Window)
    width, height = GLFW.GetFramebufferSize(window)
    return width / height
end

function get_projective_matrix(camera::PerspectiveCamera, aspectRatio::Real)
    near = camera.near
    far = camera.far
    fov = camera.fov
    range = tan(0.5*fov) * near
    Sx = 2.0*near / (range * aspectRatio + range * aspectRatio)
    Sy = near / range
    Sz = -(far + near) / (far - near)
    Pz = -(2.0*far*near) / (far - near)
    return @SMatrix GLfloat[ Sx  0.0  0.0  0.0;
                            0.0   Sy  0.0  0.0;
                            0.0  0.0   Sz   Pz;
                            0.0  0.0 -1.0  0.0]
end
get_projective_matrix(window, camera) = get_projective_matrix(camera, get_current_aspectratio(window))

function get_projective_matrix(window::GLFW.Window, camera::OrthographicCamera)
    width, height = GLFW.GetFramebufferSize(window)
    right = width/2
    left = -width/2
    top = height/2
    bottom = -height/2
    near = camera.near
    far = camera.far
    Sx = 2 / (right - left)
    Sy = 2 / (top - bottom)
    Sz = -2 / (far - near)
    Px = -(right + left) / (right-left)
    Py = -(top + bottom) / (top - bottom)
    Pz = -(far + near) / (far - near)
    return @SMatrix GLfloat[ Sx  0.0  0.0   Px;
                            0.0   Sy  0.0   Py;
                            0.0  0.0   Sz   Pz;
                            0.0  0.0  0.0  1.0]
end

"""
    updatecamera!(window, camera)
Incrementally update camera's position/orientation.
### Keymap
- `A`: slide left
- `D`: slide right
- `W`: move forward
- `S`: move backward
- `Q`: move upward
- `E`: move downward
- `ARROW LEFT`: yaw left
- `ARROW RIGHT`: yaw right
- `ARROW UP`: pitch up
- `ARROW DOWN`: pitch down
- `Z`: roll left
- `C`: roll right
"""
function updatecamera! end

let
    previousTime = time_ns()/1e9
    global function updatecamera!(window::GLFW.Window, camera::AbstractCamera)
        currentTime = time_ns()/1e9
        elapsedTime = currentTime - previousTime
        previousTime = currentTime
        moveFlag = false
        singleFrameMove = zeros(GLfloat, 3)
        GLFW.GetKey(window, GLFW.KEY_A) && (singleFrameMove[1] -= camera.movingSpeed * elapsedTime; moveFlag=true)
        GLFW.GetKey(window, GLFW.KEY_D) && (singleFrameMove[1] += camera.movingSpeed * elapsedTime; moveFlag=true)
        GLFW.GetKey(window, GLFW.KEY_Q) && (singleFrameMove[2] -= camera.movingSpeed * elapsedTime; moveFlag=true)
        GLFW.GetKey(window, GLFW.KEY_E) && (singleFrameMove[2] += camera.movingSpeed * elapsedTime; moveFlag=true)
        GLFW.GetKey(window, GLFW.KEY_S) && (singleFrameMove[3] -= camera.movingSpeed * elapsedTime; moveFlag=true)
        GLFW.GetKey(window, GLFW.KEY_W) && (singleFrameMove[3] += camera.movingSpeed * elapsedTime; moveFlag=true)
        GLFW.GetKey(window, GLFW.KEY_LEFT)  && (rotate!(camera, camera.up, camera.headingSpeed * elapsedTime); moveFlag=true)
        GLFW.GetKey(window, GLFW.KEY_RIGHT) && (rotate!(camera, camera.up, -camera.headingSpeed * elapsedTime); moveFlag=true)
        GLFW.GetKey(window, GLFW.KEY_UP)    && (rotate!(camera, camera.right, camera.headingSpeed * elapsedTime); moveFlag=true)
        GLFW.GetKey(window, GLFW.KEY_DOWN)  && (rotate!(camera, camera.right, -camera.headingSpeed * elapsedTime); moveFlag=true)
        GLFW.GetKey(window, GLFW.KEY_Z)     && (rotate!(camera, camera.forward, camera.headingSpeed * elapsedTime); moveFlag=true)
        GLFW.GetKey(window, GLFW.KEY_C)     && (rotate!(camera, camera.forward, -camera.headingSpeed * elapsedTime); moveFlag=true)
        moveFlag && return update_view_matrix!(camera, singleFrameMove)
        return get_view_matrix(camera)
    end
end

function setposition!(camera::AbstractCamera, x::AbstractVector)
     camera.position = x
     camera.viewMatrix = inv(vcat([camera.rotationMatrix camera.position], SMatrix{1,4,GLfloat,4}(0,0,0,1)))
     return camera
end

function setrotation!(camera::AbstractCamera, x::Quaternion; fwd=[0,0,-1], rgt=[1,0,0], up=[0,1,0])
    camera.quaternion = x
    camera.rotationMatrix = rotationmatrix(camera.quaternion)
    camera.forward = camera.rotationMatrix * fwd
    camera.right = camera.rotationMatrix * rgt
    camera.up = camera.rotationMatrix * up
    camera.viewMatrix = inv(vcat([camera.rotationMatrix camera.position], SMatrix{1,4,GLfloat,4}(0,0,0,1)))
    return camera
end

function resetcamera!(camera::AbstractCamera)
    setposition!(camera, [0,0,0])
    setrotation!(camera, qrotation([1,0,0], 0))
    return camera
end
