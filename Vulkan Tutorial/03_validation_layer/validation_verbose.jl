using GLFW
using VulkanCore
using VulkanCore.LibVulkan

@assert GLFW.VulkanSupported()

const WIDTH = 800
const HEIGHT = 600

## init GLFW window
GLFW.WindowHint(GLFW.CLIENT_API, GLFW.NO_API)    # not to create an OpenGL context
GLFW.WindowHint(GLFW.RESIZABLE, 0)
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
enabledExtensionCountRef = Ref(Cuint(length(requiredExtensions)))
ppEnabledExtensionNames = GLFW.GetRequiredInstanceExtensions(enabledExtensionCountRef)
enabledExtensionCount = enabledExtensionCountRef[]

enabledLayerCount = Cuint(length(requiredLayers))
ppEnabledLayerNames = Base.unsafe_convert(Ptr{Cstring}, Base.cconvert(Ptr{Cstring}, requiredLayers))

# create info
sType = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO
flags = UInt32(0)
pApplicationInfo = Base.unsafe_convert(Ptr{VkApplicationInfo}, appInfoRef)
createInfoRef = VkInstanceCreateInfo(
    sType,
    C_NULL,
    flags,
    pApplicationInfo,
    enabledLayerCount,
    ppEnabledLayerNames,
    enabledExtensionCount,
    ppEnabledExtensionNames,
) |> Ref

# create instance
instanceRef = Ref(VkInstance(C_NULL))
result = GC.@preserve appInfoRef requiredLayers vkCreateInstance(createInfoRef, C_NULL, instanceRef)
@assert result == VK_SUCCESS "failed to create instance!"

## main loop
while !GLFW.WindowShouldClose(window)
    GLFW.PollEvents()
end

## cleaning up
vkDestroyInstance(instanceRef[], C_NULL)
GLFW.DestroyWindow(window)
