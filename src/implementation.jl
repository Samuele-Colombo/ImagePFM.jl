# ImagePFM.jl
# FileIO.jl integration for PFM image files.
# Copyright (c) 2021 Samuele Colombo, Paolo Galli


"""
    little_endian

`true` if system is little endian, `false` if big endian.
"""
const little_endian = ENDIAN_BOM == 0x04030201


"""
    write(io::IO, ::Type{format"PFM"}, image::AbstractMatrix{<:RGB})

Write an image to stream in PFM format.

A PFM files has an head containing, in order,
    - the magic bytes `PF\\n`,
    - the image width and height,
    - either -1.0 or 1.0 for little and big endian encoding of binary data respectively.
Then the `RGB(Float32)` image will be written as binary data scanning the image left to right - bottom to top.

# Examples
```jldoctest
julia> image = RGB{Float32}[RGB(1.0e1, 2.0e1, 3.0e1) RGB(1.0e2, 2.0e2, 3.0e2)
                            RGB(4.0e1, 5.0e1, 6.0e1) RGB(4.0e2, 5.0e2, 6.0e2)
                            RGB(7.0e1, 8.0e1, 9.0e1) RGB(7.0e2, 8.0e2, 9.0e2)];

julia> io = IOBuffer();

julia> ImagePFM.write(io, format"PFM", image) # write to stream in pfm format, return number of bytes written
84
```
"""
function write(io::IO, ::Type{format"PFM"}, image::AbstractMatrix{<:RGB})
    head = transcode(UInt8, "PF\n$(join(size(image)," "))\n$(little_endian ? -1. : 1.)\n")
    write(io, head, (c for c ∈ @view image[:, end:-1:begin])...)
end


"""
    write(io::IO, c::RGB{Float32})

Overload of the `write` function for the RGB type behavior is similar to the one of a generic container.
"""
function write(io::IO, c::RGB{Float32})
    write(io, c.r, c.g, c.b)
end


"""
    write(io::IO, c::RGB)

Throw error if `eltype(c) != Float32``
"""
function write(io::IO, c::RGB)
    throw(InvalidRGBEltype())
end


"""
    read(io::IO, fmt::Type{format"PFM"})

Read a PFM image from stream.

After skipping the magic bytes `PF\\n` the image width and height will be parsed, then the source endiannes.
The `RGB(Float32)` matrix will be read up to the `(width * height)`th element. The presence of additional data won't be considered an error.
Note that, unlike `read`, this function will convert endiannes for you from the declared source endiannes to the host endiannes.
"""
function read(io::IO, fmt::Type{format"PFM"})
    try
        skipmagic(io, fmt)
    catch e
        isa(e, ErrorException) && throw(InvalidPfmFileFormat("invalid head in PFM file: magic: expected $(magic(fmt))"))
    end
    img_width, img_height = io |> _read_line |> _parse_img_size
    endian_f = io |> _read_line |> _parse_endianness

    try
        map(endian_f, _read_matrix(io, RGB{Float32}, img_width, img_height))[:, end:-1:begin]
    catch e
        isa(e, ArgumentError) && throw(InvalidPfmFileFormat("invalid bytestream in PFM file: corrupted binary data."))
        isa(e, EOFError) && rethrow(InvalidPfmFileFormat("invalid bytestream in PFM file: found less floats than declared in head."))
        rethrow(e)
    end
end


#####################
# SUPPORT FUNCTIONS #
#####################


"""
    _parse_img_size(line::String)

Parse a string formatted like "img_width img_height" and return both values
"""
function _parse_img_size(line::String)
    elements = split(line, ' ')
    correct_length = 2
    (length(elements) == correct_length) || throw(InvalidPfmFileFormat("invalid head in PFM file: image size: expected $correct_length dimensions got $(length(elements))."))
    map(_parse_int ∘ string, elements)
end


"""
    _parse_int(str::String)

Verify that the given String is parsable to a type `UInt` and return its parsed value
"""
function _parse_int(str::String)
    DestT = UInt
    try
        parse(DestT, str)
    catch e
        isa(e, ArgumentError) && throw(InvalidPfmFileFormat("invalid head in PFM file: image size: \"$str\" is not parsable to type $DestT."))
        rethrow(e)
    end
end


"""
    _parse_endianness(line::String)

Verify that the given String is parsable to type `Float32` and is equal to ±1.0:
if the parsed value is equal to +1.0 then file endianness is big-endian,
else if it is equal to -1.0 then endianness is little-endian.

Return a function that translates from file endianness to host endianness.
"""
function _parse_endianness(line::String)
    DestT = Float32
    endian_spec = try
        parse(DestT, line)
    catch e
        isa(e, ArgumentError) && throw(InvalidPfmFileFormat("invalid head in PFM file: endianness: \"$line\" is not parsable to type $DestT."))
        rethrow(e)
    end

    valid_spec = one(DestT)
    if endian_spec == valid_spec
        return ntoh
    elseif endian_spec == -valid_spec
        return ltoh
    else
        throw(InvalidPfmFileFormat("invalid head in PFM file: endianness: expected ±$valid_spec got $endian_spec."))
    end
end


"""
    _read_line(io::IO)

Read line from stream, return nothing if eof, throw exceptions if read string is not ascii
and if newlines are not LF conform (it may signal that file corruption occurred
in file transfer from other systems) else return line.
"""
function _read_line(io::IO)
    eof(io) && return nothing
    line = readline(io, keep=true)
    ('\r' ∈ line) && throw(InvalidPfmFileFormat("invalid head in PFM file: newline is not LF conform."))
    isascii(line) || throw(InvalidPfmFileFormat("invalid head in PFM file: found non-ascii line."))
    line
end


"""
    _read_type(io::IO, DestT::Type)

Read a DestT instance from stream, return read value.
"""
function _read_type(io::IO, DestT::Type)
    eof(io) && return nothing
    len = sizeof(DestT)
    data = Array{UInt8, 1}(undef, len)
    readbytes!(io, data, len)
    reinterpret(DestT, data)[1]
end


"""
    _TypeStream

Utility interface for a stram containing at least `n` `T` type instances.
Useful for reading sets of values in a more compact notation.
"""
struct _TypeStream
    io::IO
    T::Type
    n::Integer
end


"""
    iterate(s::_TypeStream, state = 1)

Iterator over the interface.
"""
function iterate(s::_TypeStream, state = 1)
    if state <= s.n
        eof(s.io) && throw(EOFError())
        (_read_type(s.io, s.T), state + 1)
    else
        nothing
    end
end


"""
    _read(io::IO, C::Type{RGB{Float32}})

Utility function to read single instance of an `RGB` type.
"""
function _read(io::IO, C::Type{RGB{Float32}})
    C(_TypeStream(io, eltype(C), 3)...)
end


"""
    _read(io::IO, C::Type{<:RGB})

    Throw error if `eltype(c) != Float32``
"""
function _read(io::IO, C::Type{<:RGB})
    throw(InvalidRGBEltype())
end


"""
    _read_matrix(io::IO, DestT::Type, mat_width, mat_height)

Utility function to read the image matrix from file.
"""
function _read_matrix(io::IO, DestT::Type, mat_width, mat_height)
    mat = Matrix{DestT}(undef, mat_width, mat_height)
    for i in LinearIndices(mat)
        mat[i] = _read(io, DestT)
    end
    mat
end
