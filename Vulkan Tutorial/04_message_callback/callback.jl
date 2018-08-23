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
push!(requiredExtensions, "VK_EXT_debug_report")
# check extension
checkextensions(requiredExtensions)
enabledExtensionCount = length(requiredExtensions)
ppEnabledExtensionNames = strings2pp(requiredExtensions)
# validation layer
requiredLayers = ["VK_LAYER_LUNARG_standard_validation"]
checklayers(requiredLayers)
enabledLayerCount = Cuint(length(requiredLayers))
ppEnabledLayerNames = strings2pp(requiredLayers)
createInfoRef = VkInstanceCreateInfo(appInfoRef, enabledLayerCount, ppEnabledLayerNames, enabledExtensionCount, ppEnabledExtensionNames) |> Ref

# create instance
instanceRef = Ref{vk.VkInstance}(C_NULL)
result = vk.vkCreateInstance(createInfoRef, C_NULL, instanceRef)
result != vk.VK_SUCCESS && error("failed to create instance!")
instance = instanceRef[]


## message callback
function debugcallback(flags::vk.VkDebugReportFlagsEXT, objType::vk.VkDebugReportObjectTypeEXT,
                       obj::Culonglong, location::Csize_t, code::Cint, layerPrefix::Ptr{Cchar},
                       msg::Ptr{Cchar}, userData::Ptr{Cvoid})::vk.VkBool32
    println("validation layer: ", Base.unsafe_string(msg))
    return vk.VK_FALSE
end

# create debug report callback
flags = vk.VK_DEBUG_REPORT_ERROR_BIT_EXT | vk.VK_DEBUG_REPORT_WARNING_BIT_EXT
callbackInfoRef = VkDebugReportCallbackCreateInfoEXT(debugcallback, flags) |> Ref
callbackRef = Ref{vk.VkDebugReportCallbackEXT}(C_NULL)
VkCreateDebugReportCallbackEXT(instance, callbackInfoRef, callbackRef)
callback = callbackRef[]


## main loop
while !GLFW.WindowShouldClose(window)
    GLFW.PollEvents()
end

## clean up
VkDestroyDebugReportCallbackEXT(instance, callback)
vk.vkDestroyInstance(instance, C_NULL)
GLFW.DestroyWindow(window)
