using GLFW
using VulkanCore
using VulkanCore.LibVulkan

@assert GLFW.VulkanSupported()

const WIDTH = 800
const HEIGHT = 600

enableValidationLayers = true

## init GLFW window
GLFW.WindowHint(GLFW.CLIENT_API, GLFW.NO_API)    # not to create an OpenGL context
GLFW.WindowHint(GLFW.RESIZABLE, 0)
# error callback
error_callback(err::GLFW.GLFWError) = @error "GLFW ERROR: code $(err.code) msg: $(err.description)"
GLFW.SetErrorCallback(error_callback)
# create window
window = GLFW.CreateWindow(WIDTH, HEIGHT, "Vulkan")

## init Vulkan
## creating instance
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

extensionCountRef = Ref(Cuint(0))
vkEnumerateInstanceExtensionProperties(C_NULL, extensionCountRef, C_NULL)
extensions = Vector{VkExtensionProperties}(undef, extensionCountRef[])
vkEnumerateInstanceExtensionProperties(C_NULL, extensionCountRef, extensions)
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
layerCountRef = Ref(Cuint(0))
vkEnumerateInstanceLayerProperties(layerCountRef, C_NULL)
availableLayers = Vector{VkLayerProperties}(undef, layerCountRef[])
vkEnumerateInstanceLayerProperties(layerCountRef, availableLayers)
availableLayerNames = map(availableLayers) do layer
    strip(String(collect(layer.layerName)), '\0')
end
availableLayerDescription = map(availableLayers) do layer
    strip(String(collect(layer.description)), '\0')
end

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
instanceRef = Ref(VkInstance(C_NULL))

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
createInfoRef = VkInstanceCreateInfo(
    sType,
    pNext,
    flags,
    pApplicationInfo,
    enabledLayerCount,
    ppEnabledLayerNames,
    enabledExtensionCount,
    ppEnabledExtensionNames,
) |> Ref

result = GC.@preserve appInfoRef requiredExtensions requiredLayers debugCreateInfoRef vkCreateInstance(createInfoRef, C_NULL, instanceRef)
@assert result == VK_SUCCESS "failed to create instance!"

# set debug messenger
if CreateDebugUtilsMessengerEXT(instanceRef[], debugCreateInfoRef, C_NULL, debugMessengerRef) != VK_SUCCESS
    @error "failed to set up debug messenger!"
end

## window surface
surface = GLFW.CreateWindowSurface(instanceRef[], window, C_NULL)
surfaceRef = Ref(surface)

## physical device
deviceCountRef = Ref(UInt32(0))
vkEnumeratePhysicalDevices(instanceRef[], deviceCountRef, C_NULL)
deviceCount = deviceCountRef[]
if deviceCount == 0
    @error "failed to find GPUs with Vulkan support!"
end

# device suitability checks
mutable struct QueueFamilyIndices
    graphicsFamily::Union{Nothing,Cuint}
    presentFamily::Union{Nothing,Cuint}
end
QueueFamilyIndices() = QueueFamilyIndices(nothing, nothing)
is_complete(x::QueueFamilyIndices) = (x.graphicsFamily != nothing) && (x.presentFamily != nothing)

function get_queue_family_properties(device::VkPhysicalDevice)
    count_ref = Ref{Cuint}(0)
    vkGetPhysicalDeviceQueueFamilyProperties(device, count_ref, C_NULL)
    properties = Vector{VkQueueFamilyProperties}(undef, count_ref[])
    vkGetPhysicalDeviceQueueFamilyProperties(device, count_ref, properties)
    return properties
end

function find_queue_families(device::VkPhysicalDevice, surface::VkSurfaceKHR)
    indices = QueueFamilyIndices()
    families = get_queue_family_properties(device)
    for (i,family) in enumerate(families)
        presentSupportRef = Ref(VkBool32(false))
        vkGetPhysicalDeviceSurfaceSupportKHR(device, i, surface, presentSupportRef)
        if presentSupportRef[] == VkBool32(true)
            indices.presentFamily = i
        end
        if Bool(family.queueFlags & VK_QUEUE_GRAPHICS_BIT)
            indices.graphicsFamily = i
        end
        is_complete(indices) && break
    end
    return indices
end

function is_device_suitable(device::VkPhysicalDevice, surface::VkSurfaceKHR)
    indices = find_queue_families(device, surface)
    return is_complete(indices)
end

physicalDeviceRef = Ref(VkPhysicalDevice(VK_NULL_HANDLE))

devices = Vector{VkPhysicalDevice}(undef, deviceCount)
vkEnumeratePhysicalDevices(instanceRef[], deviceCountRef, devices)

for device in devices
    if is_device_suitable(device, surfaceRef[])
        physicalDeviceRef[] = device
        break
    end
end

if physicalDeviceRef[] == VkPhysicalDevice(VK_NULL_HANDLE)
    @error "failed to find a suitable GPU!"
end

## create logical device
# specifying the queues to be created
queuePriorityRef = Ref(Cfloat(1.0))
indices = find_queue_families(physicalDeviceRef[], surfaceRef[])
uniqueQueueFamilies = Set([indices.graphicsFamily, indices.presentFamily])

queueCreateInfos = VkDeviceQueueCreateInfo[]
for queueFamily in uniqueQueueFamilies
    sType = VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO
    flags = UInt32(0)
    queueFamilyIndex = queueFamily
    queueCount = 1
    pQueuePriorities = Base.unsafe_convert(Ptr{Cfloat}, queuePriorityRef)
    push!(
        queueCreateInfos, 
        VkDeviceQueueCreateInfo(
            sType,
            C_NULL,
            flags,
            queueFamilyIndex,
            queueCount,
            pQueuePriorities,
        )
    )
end

deviceFeaturesRef = Ref(VkPhysicalDeviceFeatures(fill(VK_FALSE,55)...))

sType = VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO
flags = UInt32(0)
queueCreateInfoCount = length(queueCreateInfos)
pQueueCreateInfos = pointer(queueCreateInfos)
pEnabledFeatures = Base.unsafe_convert(Ptr{VkPhysicalDeviceFeatures}, deviceFeaturesRef)
logicalCreateInfoRef = VkDeviceCreateInfo(
    sType,
    C_NULL,
    flags,
    queueCreateInfoCount,
    pQueueCreateInfos,
    0,
    C_NULL,
    0,
    C_NULL,
    pEnabledFeatures,
) |> Ref

deviceRef = Ref(VkDevice())
GC.@preserve queuePriorityRef queueCreateInfos deviceFeaturesRef begin
    result = vkCreateDevice(physicalDeviceRef[], logicalCreateInfoRef, C_NULL, deviceRef)
end 
@assert result == VK_SUCCESS "failed to logical device!"

## retrieving queue handles
graphicsQueueRef = Ref(VkQueue(C_NULL))
vkGetDeviceQueue(deviceRef[], indices.graphicsFamily, 0, graphicsQueueRef)
@assert graphicsQueueRef[] != VkQueue(C_NULL) "failed to retrieve graphics queue handles!"

presentQueueRef = Ref(VkQueue(C_NULL))
vkGetDeviceQueue(deviceRef[], indices.presentFamily, 0, presentQueueRef)
@assert presentQueueRef[] != VkQueue(C_NULL) "failed to retrieve present queue handles!"

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

if enableValidationLayers
    DestroyDebugUtilsMessengerEXT(instanceRef[], debugMessengerRef[], C_NULL)
end

vkDestroyDevice(deviceRef[], C_NULL)
vkDestroySurfaceKHR(instanceRef[], surfaceRef[], C_NULL)
vkDestroyInstance(instanceRef[], C_NULL)
GLFW.DestroyWindow(window)