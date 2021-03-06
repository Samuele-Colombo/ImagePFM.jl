# ImagePFM.jl
# FileIO.jl integration for PFM image files.
# Copyright (c) 2021 Samuele Colombo, Paolo Galli


"""
    ImagePFM

FileIO.jl integration for PFM image files.
"""
module ImagePFM


using Base: Float32
import Base:
    iterate, read, write

import ColorTypes:
    RGB

using FileIO:
    @format_str,
    DataFormat, File, Stream,
    query, skipmagic, stream

export
    InvalidPfmFileFormat, InvalidRGBEltype


include("exceptions.jl")
include("implementation.jl")


#=
Here we implement the `load` and `save` methods for the PFM data format that will be used by `FileIO`
For more information consult the `FileIO` documentation on adding new formats and implementing load/save behavior
=#


function load(f::File{DataFormat{:PFM}}; kwargs...)
    open(f) do s
        load(s, kwargs...)
    end
end
function load(s::Stream{FMT}; permute_horizontal=false, kwargs...) where {FMT<:DataFormat{:PFM}}
    if permute_horizontal
        return read(stream(s), FMT, kwargs...)
    else
        return permutedims(read(stream(s), FMT, kwargs...), (2, 1))
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
        return write(stream(s), FMT, imgout, kwargs...)
    else
        perm = ndims(imgout) == 2 ? (2, 1) : error("$(ndims(imgout)) dims array is not supported")
        return write(stream(s), FMT, PermutedDimsArray(imgout, perm), kwargs...)
    end
end


end # module ImagePFM
