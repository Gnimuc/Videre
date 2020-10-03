using GLFW
using VulkanCore
using VulkanCore.LibVulkan

@assert GLFW.VulkanSupported()

include(joinpath(@__DIR__, "vkhelper.jl"))

const WIDTH = 800
const HEIGHT = 600

enableValidationLayers = true

## init GLFW window
GLFW.WindowHint(GLFW.CLIENT_API, GLFW.NO_API)    # not to create an OpenGL context
GLFW.WindowHint(GLFW.RESIZABLE, 0)
window = GLFW.CreateWindow(WIDTH, HEIGHT, "Vulkan")

## init Vulkan
## creating instance
appInfoRef = VkApplicationInfo(
    "Application Name: Create Instance",
    v"1.0.0",
    "No Engine Name",
    v"1.0.0",
    VK_API_VERSION_1_2,
) |> Ref

extensions = GLFW.GetRequiredInstanceExtensions()
if enableValidationLayers 
    push!(extensions, VK_EXT_DEBUG_UTILS_EXTENSION_NAME)  # for debugging, see message callback section
end
@assert check_extensions(extensions)

layers = ["VK_LAYER_KHRONOS_validation"]
@assert check_layers(layers)

## message callback
pfnUserCallback = @cfunction(debug_callback, VkBool32, (VkDebugUtilsMessageSeverityFlagBitsEXT, VkDebugUtilsMessageTypeFlagsEXT, Ptr{VkDebugUtilsMessengerCallbackDataEXT},Ptr{Cvoid}))
debugCreateInfoRef = VkDebugUtilsMessengerCreateInfoEXT(pfnUserCallback, C_NULL) |> Ref

## create instance
createInfoRef = VkInstanceCreateInfo(appInfoRef, debugCreateInfoRef, layers, extensions) |> Ref

instanceRef = Ref(VkInstance(C_NULL)) 
result = GC.@preserve appInfoRef layers extensions debugCreateInfoRef vkCreateInstance(createInfoRef, C_NULL, instanceRef)
@assert result == VK_SUCCESS "failed to create instance!"

debugMessengerRef = Ref(VkDebugUtilsMessengerEXT(C_NULL))
if CreateDebugUtilsMessengerEXT(instanceRef[], debugCreateInfoRef, C_NULL, debugMessengerRef) != VK_SUCCESS
    @error "failed to set up debug messenger!"
end

## physical device
physicalDeviceRef = Ref(VkPhysicalDevice(VK_NULL_HANDLE))
devices = get_devices(instanceRef[])

# device suitability checks
function is_device_suitable(device::VkPhysicalDevice)
    indices = find_queue_families(device)
    return is_complete(indices)
end

for device in devices
    if is_device_suitable(device)
        physicalDeviceRef[] = device
        break
    end
end

if physicalDeviceRef[] == VkPhysicalDevice(VK_NULL_HANDLE)
    @error "failed to find a suitable GPU!"
end

## create logical device
queuePriorityRef = Ref(Cfloat(1.0))
indices = find_queue_families(physicalDeviceRef[])
queueCreateInfoRef = VkDeviceQueueCreateInfo(indices, 1, queuePriorityRef) |> Ref

deviceFeaturesRef = Ref(VkPhysicalDeviceFeatures())
logicalCreateInfoRef = VkDeviceCreateInfo(1, queueCreateInfoRef, deviceFeaturesRef) |> Ref

deviceRef = Ref(VkDevice())
GC.@preserve queuePriorityRef queueCreateInfoRef deviceFeaturesRef begin
    result = vkCreateDevice(physicalDeviceRef[], logicalCreateInfoRef, C_NULL, deviceRef)
end 
@assert result == VK_SUCCESS "failed to logical device!"

## retrieving queue handles
graphicsQueueRef = Ref(VkQueue(C_NULL))
vkGetDeviceQueue(deviceRef[], indices.graphicsFamily, 0, graphicsQueueRef)
@assert graphicsQueueRef[] != VkQueue(C_NULL) "failed to retrieve queue handles!"


## main loop
while !GLFW.WindowShouldClose(window)
    GLFW.PollEvents()
end

## cleaning up
if enableValidationLayers
    DestroyDebugUtilsMessengerEXT(instanceRef[], debugMessengerRef[], C_NULL)
end

vkDestroyDevice(deviceRef[], C_NULL)
vkDestroyInstance(instanceRef[], C_NULL)
GLFW.DestroyWindow(window)
