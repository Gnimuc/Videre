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
function debug_callback(severity::VkDebugUtilsMessageSeverityFlagBitsEXT, type::VkDebugUtilsMessageTypeFlagsEXT, pCallbackData::Ptr{VkDebugUtilsMessengerCallbackDataEXT}, pUserData::Ptr{Cvoid})::VkBool32
    data = unsafe_load(pCallbackData)
    if severity == VK_DEBUG_UTILS_MESSAGE_SEVERITY_VERBOSE_BIT_EXT
        @debug "validation layer: $(Base.unsafe_string(data.pMessage))"
    elseif severity == VK_DEBUG_UTILS_MESSAGE_SEVERITY_INFO_BIT_EXT
        @info "validation layer: $(Base.unsafe_string(data.pMessage))"
    elseif severity == VK_DEBUG_UTILS_MESSAGE_SEVERITY_WARNING_BIT_EXT
        @warn "validation layer: $(Base.unsafe_string(data.pMessage))"
    elseif severity == VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT
        @error "validation layer: $(Base.unsafe_string(data.pMessage))"
    end
    return VK_FALSE
end

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

## main loop
while !GLFW.WindowShouldClose(window)
    GLFW.PollEvents()
end

## cleaning up
if enableValidationLayers
    DestroyDebugUtilsMessengerEXT(instanceRef[], debugMessengerRef[], C_NULL)
end

vkDestroyInstance(instanceRef[], C_NULL)
GLFW.DestroyWindow(window)
