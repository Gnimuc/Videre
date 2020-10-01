using GLFW
using VulkanCore
using VulkanCore.LibVulkan
using CSyntax

@assert GLFW.VulkanSupported()

const WIDTH = 800
const HEIGHT = 600

enableValidationLayers = true

## init GLFW window
GLFW.WindowHint(GLFW.CLIENT_API, GLFW.NO_API)    # not to create an OpenGL context
GLFW.WindowHint(GLFW.RESIZABLE, 0)
window = GLFW.CreateWindow(WIDTH, HEIGHT, "Vulkan")

## init Vulkan
# creating instance
# fill application info
sType = VK_STRUCTURE_TYPE_APPLICATION_INFO
pApplicationName = pointer("Vulkan Instance")
applicationVersion = VK_MAKE_VERSION(1, 0, 0)
pEngineName = pointer("No Engine")
engineVersion = VK_MAKE_VERSION(1, 0, 0)
apiVersion = VK_API_VERSION_1_2
appInfoRef = VkApplicationInfo(
    sType,
    C_NULL,
    pApplicationName,
    applicationVersion,
    pEngineName,
    engineVersion,
    apiVersion,
) |> Ref

# checking for extension support
requiredExtensions = GLFW.GetRequiredInstanceExtensions()
if enableValidationLayers 
    push!(requiredExtensions, VK_EXT_DEBUG_UTILS_EXTENSION_NAME)  # for debugging, see message callback section
end

extensionCount = Cuint(0)
@c vkEnumerateInstanceExtensionProperties(C_NULL, &extensionCount, C_NULL)
extensions = Vector{VkExtensionProperties}(undef, extensionCount)
@c vkEnumerateInstanceExtensionProperties(C_NULL, &extensionCount, extensions)
extensionNames = map(extensions) do extension
    extension.extensionName |> collect |> String |> x -> strip(x, '\0')
end
extensionVersions = [ext.specVersion |> Int for ext in extensions]

@info "available extensions:"
for (ext, ver) in zip(extensionNames, extensionVersions)
    @info "  $ext: $ver"
end
if !all(x->x in extensionNames, requiredExtensions)
    @error "not all required extensions are supported."
end

# using validation layers
requiredLayers = ["VK_LAYER_KHRONOS_validation"]
layerCount = Cuint(0)
@c vkEnumerateInstanceLayerProperties(&layerCount, C_NULL)
availableLayers = Vector{VkLayerProperties}(undef, layerCount)
@c vkEnumerateInstanceLayerProperties(&layerCount, availableLayers)
availableLayerNames = [strip(String(collect(layer.layerName)), '\0') for layer in availableLayers]
availableLayerDescription = [strip(String(collect(layer.description)), '\0') for layer in availableLayers]
@info "available layers:"
for (name,description) in zip(availableLayerNames, availableLayerDescription)
    @info "  $name: $description"
end
if !all(x->x in availableLayerNames, requiredLayers)
    @error "not all required layers are supported."
end

# add required extensions and layers
enabledExtensionCount = Cuint(length(requiredExtensions))
ppEnabledExtensionNames = Base.unsafe_convert(Ptr{Cstring}, Base.cconvert(Ptr{Cstring}, requiredExtensions))

enabledLayerCount = Cuint(length(requiredLayers))
ppEnabledLayerNames = Base.unsafe_convert(Ptr{Cstring}, Base.cconvert(Ptr{Cstring}, requiredLayers))

# create instance after setting up the debug messenger
instance = VkInstance(C_NULL)

## message callback
function debug_callback(severity::VkDebugUtilsMessageSeverityFlagBitsEXT, type::VkDebugUtilsMessageTypeFlagsEXT, pCallbackData::Ptr{VkDebugUtilsMessengerCallbackDataEXT}, pUserData::Ptr{Cvoid})::VkBool32
    # data = unsafe_pointer_to_objref(pCallbackData)
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

# set debug messenger
debugMessengerRef = Ref(VkDebugUtilsMessengerEXT(C_NULL))

sType = VK_STRUCTURE_TYPE_DEBUG_UTILS_MESSENGER_CREATE_INFO_EXT
flags = UInt32(0)
messageSeverity = VK_DEBUG_UTILS_MESSAGE_SEVERITY_VERBOSE_BIT_EXT | VK_DEBUG_UTILS_MESSAGE_SEVERITY_WARNING_BIT_EXT | VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT
messageType = VK_DEBUG_UTILS_MESSAGE_TYPE_GENERAL_BIT_EXT | VK_DEBUG_UTILS_MESSAGE_TYPE_VALIDATION_BIT_EXT | VK_DEBUG_UTILS_MESSAGE_TYPE_PERFORMANCE_BIT_EXT
pfnUserCallback = @cfunction(debug_callback, VkBool32, (VkDebugUtilsMessageSeverityFlagBitsEXT, VkDebugUtilsMessageTypeFlagsEXT, Ptr{VkDebugUtilsMessengerCallbackDataEXT},Ptr{Cvoid}))
pUserData = C_NULL
debugCreateInfoRef = VkDebugUtilsMessengerCreateInfoEXT(sType, C_NULL, flags, messageSeverity, messageType, pfnUserCallback, pUserData) |> Ref

function CreateDebugUtilsMessengerEXT(instance::VkInstance, pCreateInfo::Ref{VkDebugUtilsMessengerCreateInfoEXT}, pAllocator, pDebugMessenger::Ref{VkDebugUtilsMessengerEXT})
    fp = vkGetInstanceProcAddr(instance, "vkCreateDebugUtilsMessengerEXT")
    if fp != C_NULL
        ccall(fp, VkResult, (VkInstance, Ptr{VkDebugUtilsMessengerCreateInfoEXT}, Ptr{VkAllocationCallbacks}, Ptr{VkDebugUtilsMessengerEXT}), instance, pCreateInfo, pAllocator, pDebugMessenger)
    else
        return VK_ERROR_EXTENSION_NOT_PRESENT
    end
end

# create instance
sType = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO
flags = UInt32(0)
pApplicationInfo = Base.unsafe_convert(Ptr{VkApplicationInfo}, appInfoRef)
pNext = Base.unsafe_convert(Ptr{Cvoid}, debugCreateInfoRef)
createInfo = VkInstanceCreateInfo(
    sType,
    pNext,
    flags,
    pApplicationInfo,
    enabledLayerCount,
    ppEnabledLayerNames,
    enabledExtensionCount,
    ppEnabledExtensionNames,
)

result = GC.@preserve appInfoRef requiredExtensions requiredLayers debugCreateInfoRef @c vkCreateInstance(&createInfo, C_NULL, &instance)
@assert result == VK_SUCCESS "failed to create instance!"

# set debug messenger
if CreateDebugUtilsMessengerEXT(instance, debugCreateInfoRef, C_NULL, debugMessengerRef) != VK_SUCCESS
    @error "failed to set up debug messenger!"
end

## main loop
while !GLFW.WindowShouldClose(window)
    GLFW.PollEvents()
end

## cleaning up
function DestroyDebugUtilsMessengerEXT(instance::VkInstance, debugMessenger::VkDebugUtilsMessengerEXT, pAllocator)
    fp = vkGetInstanceProcAddr(instance, "vkDestroyDebugUtilsMessengerEXT")
    if fp != C_NULL
        ccall(fp, VkResult, (VkInstance, VkDebugUtilsMessengerEXT, Ptr{VkAllocationCallbacks}), instance, debugMessenger, pAllocator)
    end
end

# intentionally trigger error
# if enableValidationLayers
#     DestroyDebugUtilsMessengerEXT(instance, debugMessengerRef[], C_NULL)
# end

vkDestroyInstance(instance, C_NULL)
GLFW.DestroyWindow(window)