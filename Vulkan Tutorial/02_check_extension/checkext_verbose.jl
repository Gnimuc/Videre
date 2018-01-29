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
# create instance
# fill application info
sType = vk.VK_STRUCTURE_TYPE_APPLICATION_INFO
pApplicationName = pointer(b"Vulkan Instance")
applicationVersion = vk.VK_MAKE_VERSION(1, 0, 0)
pEngineName = pointer(b"No Engine")
engineVersion = vk.VK_MAKE_VERSION(1, 0, 0)
apiVersion = vk.VK_VERSION
appInfoRef = vk.VkApplicationInfo(sType, C_NULL, pApplicationName, applicationVersion, pEngineName, engineVersion, apiVersion) |> Ref

# fill create info
sType = vk.VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO
flags = UInt32(0)
pApplicationInfo = Base.unsafe_convert(Ptr{vk.VkApplicationInfo}, appInfoRef)
requiredExtensions = GLFW.GetRequiredInstanceExtensions()
enabledExtensionCount = Cuint(length(requiredExtensions))
ppEnabledExtensionNames = strings2pp(requiredExtensions)
enabledLayerCount = Cuint(0)
ppEnabledLayerNames = C_NULL
createInfoRef = vk.VkInstanceCreateInfo(sType, C_NULL, flags, pApplicationInfo, enabledLayerCount, ppEnabledLayerNames, enabledExtensionCount, ppEnabledExtensionNames) |> Ref

# check extension
extensionCountRef = Ref{Cuint}(0)
vk.vkEnumerateInstanceExtensionProperties(C_NULL, extensionCountRef, C_NULL)
extensionCount = extensionCountRef[]
supportedExtensions = Vector{vk.VkExtensionProperties}(extensionCount)
vk.vkEnumerateInstanceExtensionProperties(C_NULL, extensionCountRef, supportedExtensions)
supportedExtensionNames = [ext.extensionName |> collect |> String |> x->strip(x, '\0') for ext in supportedExtensions]
supportedExtensionVersions = [ext.specVersion |> Int for ext in supportedExtensions]
println("available extensions:")
for (ext, ver) in zip(supportedExtensionNames, supportedExtensionVersions)
    println("  ", ext, ": ", ver)
end
setdiff(requiredExtensions, supportedExtensionNames) |> isempty || error("all required extensions are supported.")

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
