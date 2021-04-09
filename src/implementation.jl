const little_endian = ENDIAN_BOM == 0x04030201

# write on stream in PFM format
# need HdrImage broadcasting
"""
    write(io::IO, format"PFM", image)

Write an image to stream in PFM format.
# Examples
```jldoctest
julia> image = HdrImage(RGB{Float32}[RGB(1.0e1, 2.0e1, 3.0e1) RGB(1.0e2, 2.0e2, 3.0e2)
                                     RGB(4.0e1, 5.0e1, 6.0e1) RGB(4.0e2, 5.0e2, 6.0e2)
                                     RGB(7.0e1, 8.0e1, 9.0e1) RGB(7.0e2, 8.0e2, 9.0e2)]);

julia> io = IOBuffer();

julia> write(io, FE("pfm"), image) # write to stream in pfm format, return number of bytes written
84
```
"""
function write(io::IO, ::Type{format"PFM"}, image::AbstractMatrix{<:RGB})
    head = transcode(UInt8, "PF\n$(join(size(image)," "))\n$(little_endian ? -1. : 1.)\n")
    Base.write(io, head, (c for c ∈ @view image[:, end:-1:begin])...)
end

function Base.write(io::IO, c::RGB)
    Base.write(io, c.r, c.g, c.b)
end

# read PFM file from stream
"""
    read(io::IO, format"PFM")

Read a PFM image from stream.
"""
function read(io::IO, fmt::::Type{format"PFM"})
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

# parse a string formatted like "$img_width $img_height" and return both values
function _parse_img_size(line::String)
    elements = split(line, ' ')
    correct_length = 2
    (length(elements) == correct_length) || throw(InvalidPfmFileFormat("invalid head in PFM file: image size: expected $correct_length dimensions got $(length(elements))."))
    img_width, img_height = map(_parse_int ∘ string, elements)
end

# verify that the given String is parsable to type and return its parsed value
function _parse_int(str::String)
    DestT = UInt
    try
        parse(DestT, str)
    catch e
        isa(e, ArgumentError) && throw(InvalidPfmFileFormat("invalid head in PFM file: image size: \"$str\" is not parsable to type $DestT."))
        rethrow(e)
    end
end

# verify that the given String is parsable to type Float32 and is equal to ±1.0
# if the parsed value is equal to +1.0 then file endianness is big-endian
# else if it is equal to -1.0 then endianness is little-endian
# return a function that translates from file endianness to host endianness
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

# read line from stream, return nothing if eof, throw exceptions if read string is not ascii
# and if newlines are not LF conform (it may signal that file corruption occurred
# in file transfer from other systems) else return line
function _read_line(io::IO)
    eof(io) && return nothing
    line = readline(io, keep=true)
    ('\r' ∈ line) && throw(InvalidPfmFileFormat("invalid head in PFM file: newline is not LF conform."))
    isascii(line) || throw(InvalidPfmFileFormat("invalid head in PFM file: found non-ascii line."))
    line
end

# read a DestT instance from stream, return read value
function _read_type(io::IO, DestT::Type)
    eof(io) && return nothing
    len = sizeof(DestT)
    data = Array{UInt8, 1}(undef, len)
    readbytes!(io, data, len)
    reinterpret(DestT, data)[1]
end

# Utility interface for a stram containing at least n T type instances. Useful to read sets of values in a more compact notation
struct _TypeStream
    io::IO
    T::Type
    n::Integer
end

# Iterator over the interface
function iterate(s::_TypeStream, state = 1)
    if state <= s.n
        eof(s.io) && throw(EOFError())
        (_read_type(s.io, s.T), state + 1)
    else
        nothing
    end
end

function _read(io::IO, C::Type{<:RGB})
    C(_TypeStream(io, eltype(C), 3)...)
end

# utility function to read the image matrix from file
function _read_matrix(io::IO, DestT::Type, mat_width, mat_height)
    mat = Matrix{DestT}(undef, mat_width, mat_height)
    for i in LinearIndices(mat)
        mat[i] = _read(io, DestT)
    end
    mat
end