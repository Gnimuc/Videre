using VulkanCore
using VulkanCore.LibVulkan

# utils
"""
    unsafe_strings2pp(names) -> Ptr{String}
Dump a pointer that is of type `Ptr{String}` from a Julia `String` array.
"""
unsafe_strings2pp(names::Vector{String}) = Base.unsafe_convert(Ptr{Cstring}, Base.cconvert(Ptr{Cstring}, names))

"""
    to_string(x::NTuple{N,UInt8}) -> String
Convert a `NTuple{N,UInt8}` to `String` dropping all of the `\0`s.
"""
to_string(x::NTuple{N,UInt8}) where {N} = rstrip(String(collect(x)), '\0')

# extension & layer checking 
struct ExtensionProperties
    name::String
    version::Int
end
ExtensionProperties(extension::VkExtensionProperties) =
    ExtensionProperties(to_string(extension.extensionName), extension.specVersion)

struct LayerProperties
    layerName::String
    specVersion::Int
    implementationVersion::Int
    description::String
end
LayerProperties(layer::VkLayerProperties) = LayerProperties(
    to_string(layer.layerName),
    layer.specVersion,
    layer.implementationVersion,
    to_string(layer.description),
)

"""
    get_supported_extensions() -> Vector{String}
Return a vector of supported extensions.
"""
function get_supported_extensions()
    count_ref = Ref{Cuint}(0)
    vkEnumerateInstanceExtensionProperties(C_NULL, count_ref, C_NULL)
    count = count_ref[]
    extensions = Vector{VkExtensionProperties}(undef, count)
    vkEnumerateInstanceExtensionProperties(C_NULL, count_ref, extensions)
    return [ExtensionProperties(ext) for ext in extensions]
end

"""
    check_extensions(required_extensions::Vector{<:AbstractString}) -> Bool
Return `true` when all of the `required_extensions` are supported.
"""
function check_extensions(required_extensions::Vector{<:AbstractString})
    supported = get_supported_extensions()
    @info "available extensions:"
    for x in supported
        @info "  $(x.name): $(x.version)"
    end
    names = [x.name for x in supported]
    return all(x->x in names, required_extensions)
end

# instance
function LibVulkan.VkApplicationInfo(app_name::AbstractString, app_ver::VersionNumber, engine_name::AbstractString, engine_ver::VersionNumber, api_ver::Integer)
    sType = VK_STRUCTURE_TYPE_APPLICATION_INFO
    pNext = C_NULL    # reserved for extension-specific structure
    pApplicationName = pointer(app_name)
    vkApplicationVersion = VK_MAKE_VERSION(app_ver.major, app_ver.minor, app_ver.patch)
    pEngineName = pointer(engine_name)
    vkEngineVersion = VK_MAKE_VERSION(engine_ver.major, engine_ver.minor, engine_ver.patch)
    return VkApplicationInfo(sType, pNext, pApplicationName, vkApplicationVersion, pEngineName, vkEngineVersion, Cuint(api_ver))
end

function LibVulkan.VkInstanceCreateInfo(app_info_ref::Ref{VkApplicationInfo}, layers::Vector{String}, extensions::Vector{String})
    sType = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO
    pNext = C_NULL       # reserved for extension-specific structure
    flags = UInt32(0)    # reserved for future use
    ppEnabledLayerNames = isempty(layers) ? C_NULL : unsafe_strings2pp(layers)
    ppEnabledExtensionNames = isempty(extensions) ? C_NULL : unsafe_strings2pp(extensions)
    pApplicationInfo = Base.unsafe_convert(Ptr{VkApplicationInfo}, app_info_ref)
    return VkInstanceCreateInfo(sType, pNext, flags, pApplicationInfo, length(layers), ppEnabledLayerNames, length(extensions), ppEnabledExtensionNames)
end