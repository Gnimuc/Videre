using GLFW
using VulkanCore

# helper functions
function GetRequiredInstanceExtensions()
    count = Ref{Cuint}(0)
    ptr = ccall((:glfwGetRequiredInstanceExtensions, GLFW.lib), Ptr{Ptr{Cchar}}, (Ref{Cuint},), count)
    return count[], ptr, unsafe_string.(unsafe_wrap(Array, ptr, count[]))
end

# helper constructors
function VkApplicationInfo(applicationName::AbstractString, applicationVersion::VersionNumber, engineName::AbstractString, engineVersion::VersionNumber, apiVersion::Integer)
    sType = vk.VK_STRUCTURE_TYPE_APPLICATION_INFO
    pNext = C_NULL    # reserved for extension-specific structure
    pApplicationName = pointer(UInt8[applicationName...])    # TODO: use codeunits(applicationName) in julia-v0.7+
    vkApplicationVersion = vk.VK_MAKE_VERSION(applicationVersion.major, applicationVersion.minor, applicationVersion.patch)
    pEngineName = pointer(UInt8[engineName...])    # TODO: use codeunits(engineName) in julia-v0.7+
    vkEngineVersion = vk.VK_MAKE_VERSION(engineVersion.major, engineVersion.minor, engineVersion.patch)
    return vk.VkApplicationInfo(sType, pNext, pApplicationName, vkApplicationVersion, pEngineName, vkEngineVersion, Cuint(apiVersion))
end

function VkInstanceCreateInfo(applicationInfoRef::Ref{vk.VkApplicationInfo}, enabledLayerCount::Integer, ppEnabledLayerNames, enabledExtensionCount::Integer, ppEnabledExtensionNames)
    sType = vk.VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO
    pNext = C_NULL    # reserved for extension-specific structure
    flags = UInt32(0)    # reserved for future use
    pApplicationInfo = Base.unsafe_convert(Ptr{vk.VkApplicationInfo}, applicationInfoRef)
    return vk.VkInstanceCreateInfo(sType, pNext, flags, pApplicationInfo, Cuint(enabledLayerCount), ppEnabledLayerNames, Cuint(enabledExtensionCount), ppEnabledExtensionNames)
end
