using GLFW
using VulkanCore

include(joinpath(@__DIR__, "..", "vkhelper.jl"))

const WIDTH = 800
const HEIGHT = 600

## init GLFW window
GLFW.WindowHint(GLFW.CLIENT_API, GLFW.NO_API)    # not to create an OpenGL context
GLFW.WindowHint(GLFW.RESIZABLE, 0)
window = GLFW.CreateWindow(WIDTH, HEIGHT, "Vulkan")

## init Vulkan
# fill info
apiVersion = vk.VK_VERSION
appInfoRef = VkApplicationInfo("Application Name: Create Instance", v"1.0.0", "No Engine Name", v"1.0.0", apiVersion) |> Ref
requiredExtensions = GLFW.GetRequiredInstanceExtensions()
# check extension
checkextensions(requiredExtensions)
enabledExtensionCount = length(requiredExtensions)
ppEnabledExtensionNames = strings2pp(requiredExtensions)
# validation layer
checklayers(["VK_LAYER_LUNARG_standard_validation"])
enabledLayerCount = Cuint(length(requiredLayers))
ppEnabledLayerNames = strings2pp(requiredLayers)
createInfoRef = VkInstanceCreateInfo(appInfoRef, enabledLayerCount, ppEnabledLayerNames, enabledExtensionCount, ppEnabledExtensionNames) |> Ref

# create instance
instanceRef = Ref{vk.VkInstance}(C_NULL)
result = vk.vkCreateInstance(createInfoRef, C_NULL, instanceRef)
result != vk.VK_SUCCESS && error("failed to create instance!")
instance = instanceRef[]

## main loop
while !GLFW.WindowShouldClose(window)
    GLFW.PollEvents()
end

## clean up
vk.vkDestroyInstance(instance, C_NULL)
GLFW.DestroyWindow(window)
