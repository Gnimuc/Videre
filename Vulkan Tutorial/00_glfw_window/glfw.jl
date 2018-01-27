using GLFW

const WIDTH = 800
const HEIGHT = 600

## init GLFW window
GLFW.Init()    # this is actually not necessary, since GLFW already did it in the __init__() function
GLFW.WindowHint(GLFW.CLIENT_API, GLFW.NO_API)    # not to create an OpenGL context
GLFW.WindowHint(GLFW.RESIZABLE, 0)
window = GLFW.CreateWindow(WIDTH, HEIGHT, "Vulkan")

## init Vulkan

## main loop
while !GLFW.WindowShouldClose(window)
    GLFW.PollEvents()
end

## clean up
GLFW.DestroyWindow(window)
GLFW.Terminate()    # this is actually not necessary, since GLFW will automatically do it when program exits
