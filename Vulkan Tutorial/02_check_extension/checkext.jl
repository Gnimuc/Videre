using GLFW
using VulkanCore
using VulkanCore.LibVulkan
using CSyntax

@assert GLFW.VulkanSupported()

include(joinpath(@__DIR__, "vkhelper.jl"))

const WIDTH = 800
const HEIGHT = 600

## init GLFW window
GLFW.WindowHint(GLFW.CLIENT_API, GLFW.NO_API)    # not to create an OpenGL context
GLFW.WindowHint(GLFW.RESIZABLE, 0)
window = GLFW.CreateWindow(WIDTH, HEIGHT, "Vulkan")

## init Vulkan
# creating instance
appInfoRef = VkApplicationInfo(
    "Application Name: Create Instance",
    v"1.0.0",
    "No Engine Name",
    v"1.0.0",
    VK_API_VERSION_1_2,
) |> Ref

layers = String[]
extensions = GLFW.GetRequiredInstanceExtensions()
@assert check_extensions(extensions)
createInfo = LibVulkan.VkInstanceCreateInfo(appInfoRef, layers, extensions)

instance = VkInstance(C_NULL)
result = GC.@preserve appInfoRef layers extensions @c vkCreateInstance(&createInfo, C_NULL, &instance)
@assert result == VK_SUCCESS "failed to create instance!"

## main loop
while !GLFW.WindowShouldClose(window)
    GLFW.PollEvents()
end

## cleaning up
vkDestroyInstance(instance, C_NULL)
GLFW.DestroyWindow(window)
