module ImagePFM
using FileIO: File, Stream, stream, DataFormat, @format_str, skipmagic, query
export read, write

include("exceptions.jl")
include("implementation.jl")

function load(f::File{DataFormat{:PFM}}; kwargs...)
    open(f) do s
        load(s, kwargs...)
    end
end
function load(s::Stream{FMT}; permute_horizontal=false, kwargs...) where {FMT<:DataFormat{:PFM}}
    if permute_horizontal
        return permutedims(read(stream(s), FMT(), kwargs...), (2, 1))
    else
        return read(stream(s), FMT(), kwargs...)
    end
end

function save(f::File{DataFormat{:PFM}}, image::AbstractMatrix; kwargs...)
    open(f, "w") do s
        save(s, image, kwargs...)
    end
end

function save(s::Stream{FMT}, image::AbstractMatrix; permute_horizontal=false, mapi=identity, kwargs...) where {FMT<:DataFormat{:PFM}}
    imgout = map(mapi, image)
    if permute_horizontal
        perm = ndims(imgout) == 2 ? (2, 1) : error("$(ndims(imgout)) dims array is not supported")
        return write(stream(s), FMT(), PermutedDimsArray(imgout, perm), kwargs...)
    else
        return write(stream(s), FMT(), imgout, kwargs...)
    end
end

end # module
