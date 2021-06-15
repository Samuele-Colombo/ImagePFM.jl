# ImagePFM.jl
# FileIO.jl integration for PFM image files.
# Copyright (c) 2021 Samuele Colombo, Paolo Galli


"""
    InvalidPfmFileFormat <: Exception

The parsed PFM file is not conform to standard or is corrupted. Read `msg` for root cause.
"""
struct InvalidPfmFileFormat <: Exception
    msg::String
end

Base.showerror(io::IO, e::InvalidPfmFileFormat) = print(io, typeof(e), ": ", e.msg)


"""
    InvalidRGBEltype <: Exception

The eltype of RGB can only be Float32.
"""
struct InvalidRGBEltype <: Exception end

Base.showerror(io::IO, e::InvalidRGBEltype) = print(io, typeof(e), ": eltype of RGB can only be Float32")
