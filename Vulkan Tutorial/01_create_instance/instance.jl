using GLFW
using VulkanCore
using VulkanCore.LibVulkan
using CSyntax

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
appInfoRef =
    VkApplicationInfo(
        sType,
        C_NULL,
        pApplicationName,
        applicationVersion,
        pEngineName,
        engineVersion,
        apiVersion,
    ) |> Ref

# fill create info
sType = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO
flags = UInt32(0)
pApplicationInfo = Base.unsafe_convert(Ptr{VkApplicationInfo}, appInfoRef)
enabledExtensionCountRef = Ref(Cuint(0))
ppEnabledExtensionNames = GLFW.GetRequiredInstanceExtensions(enabledExtensionCountRef)
enabledExtensionCount = enabledExtensionCountRef[]
enabledLayerCount = Cuint(0)
ppEnabledLayerNames = C_NULL
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
result = GC.@preserve appInfoRef vkCreateInstance(createInfoRef, C_NULL, instanceRef)
@assert result == VK_SUCCESS "failed to create instance!"

## main loop
while !GLFW.WindowShouldClose(window)
    GLFW.PollEvents()
end

## cleaning up
vkDestroyInstance(instanceRef[], C_NULL)
GLFW.DestroyWindow(window)