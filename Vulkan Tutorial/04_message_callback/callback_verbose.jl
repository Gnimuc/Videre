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
push!(requiredExtensions, "VK_EXT_debug_report")
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
enabledExtensionCount = Cuint(length(requiredExtensions))
ppEnabledExtensionNames = strings2pp(requiredExtensions)
# validation layer
requiredLayers = ["VK_LAYER_LUNARG_standard_validation"]
layerCountRef = Ref{Cuint}(0)
vk.vkEnumerateInstanceLayerProperties(layerCountRef, C_NULL)
layerCount = layerCountRef[]
availableLayers = Vector{vk.VkLayerProperties}(layerCount)
vk.vkEnumerateInstanceLayerProperties(layerCountRef, availableLayers)
availableLayerNames = [layer.layerName |> collect |> String |> x->strip(x, '\0') for layer in availableLayers]
availableLayerDescription = [layer.description |> collect |> String |> x->strip(x, '\0') for layer in availableLayers]
println("available layers:")
for (name,description) in zip(availableLayerNames, availableLayerDescription)
    println("  ", name, ": ", description)
end
setdiff(requiredLayers, availableLayerNames) |> isempty || error("all required layers are supported.")
enabledLayerCount = Cuint(length(requiredLayers))
ppEnabledLayerNames = strings2pp(requiredLayers)
createInfoRef = vk.VkInstanceCreateInfo(sType, C_NULL, flags, pApplicationInfo, enabledLayerCount, ppEnabledLayerNames, enabledExtensionCount, ppEnabledExtensionNames) |> Ref

# create instance
instanceRef = Ref{vk.VkInstance}(C_NULL)
result = vk.vkCreateInstance(createInfoRef, C_NULL, instanceRef)
result != vk.VK_SUCCESS && error("failed to create instance!")
instance = instanceRef[]


# message callback
function debugCallback(flags::vk.VkDebugReportFlagsEXT, objType::vk.VkDebugReportObjectTypeEXT,
                       obj::Culonglong, location::Csize_t, code::Cint, layerPrefix::Ptr{Cchar},
                       msg::Ptr{Cchar}, userData::Ptr{Void})::vk.VkBool32
    println("validation layer: ", Base.unsafe_string(msg))
    return vk.VK_FALSE
end


# fill callback info
sType = vk.VK_STRUCTURE_TYPE_DEBUG_REPORT_CALLBACK_CREATE_INFO_EXT
pNext = C_NULL
flags = vk.VK_DEBUG_REPORT_ERROR_BIT_EXT
pfnCallback = cfunction(debugCallback, vk.VkBool32, Tuple{vk.VkDebugReportFlagsEXT, vk.VkDebugReportObjectTypeEXT, Culonglong, Csize_t, Cint, Ptr{Cchar}, Ptr{Cchar}, Ptr{Void}})
pUserData = C_NULL
callbackInfoRef = vk.VkDebugReportCallbackCreateInfoEXT(sType, pNext, flags, pfnCallback, pUserData) |> Ref
# register callback
callback = Ref{vk.VkDebugReportCallbackEXT}(C_NULL)
funcptr = vk.vkGetInstanceProcAddr(instance, "vkCreateDebugReportCallbackEXT") |> vk.PFN_vkCreateDebugReportCallbackEXT
ccall(funcptr, vk.VkResult, (vk.VkInstance, Ptr{vk.VkDebugReportCallbackCreateInfoEXT},
    Ptr{vk.VkAllocationCallbacks}, Ptr{vk.VkDebugReportCallbackEXT}), instance, callbackInfoRef, C_NULL, callback)

## main loop
while !GLFW.WindowShouldClose(window)
    GLFW.PollEvents()
end

## clean up
vk.vkDestroyInstance(instance, C_NULL)
GLFW.DestroyWindow(window)
