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
# creating instance
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
enabledExtensionCount = Cuint(0)
ppEnabledExtensionNames = @c GLFW.GetRequiredInstanceExtensions(&enabledExtensionCount)
enabledLayerCount = Cuint(0)
ppEnabledLayerNames = C_NULL
createInfo = VkInstanceCreateInfo(
    sType,
    C_NULL,
    flags,
    pApplicationInfo,
    enabledLayerCount,
    ppEnabledLayerNames,
    enabledExtensionCount,
    ppEnabledExtensionNames,
)

# create instance
instance = VkInstance(C_NULL)
result = GC.@preserve appInfoRef @c vkCreateInstance(&createInfo, C_NULL, &instance)
@assert result == VK_SUCCESS "failed to create instance!"

## main loop
while !GLFW.WindowShouldClose(window)
    GLFW.PollEvents()
end

## cleaning up
vkDestroyInstance(instance, C_NULL)
GLFW.DestroyWindow(window)