using Test

import ImagePFM
import ImagePFM: little_endian, _read_line, _read_type, _parse_endianness, _parse_int, _parse_img_size, _TypeStream, _read_matrix, 
    InvalidPfmFileFormat
import ColorTypes: RGB
import FileIO: @format_str

# testset variables
endian_f        = little_endian ? ltoh : ntoh
test_matrix     = RGB{Float32}[RGB(1.0e1, 2.0e1, 3.0e1) RGB(1.0e2, 2.0e2, 3.0e2)
                               RGB(4.0e1, 5.0e1, 6.0e1) RGB(4.0e2, 5.0e2, 6.0e2)
                               RGB(7.0e1, 8.0e1, 9.0e1) RGB(7.0e2, 8.0e2, 9.0e2)]
expected_output = open(read, little_endian ? "reference_le.pfm" : "reference_be.pfm")

# test color write to IO
@testset "write" begin
    image = test_matrix
    io = IOBuffer()
    ImagePFM.write(io, format"PFM", image)
    @test take!(io) == expected_output
end

# test _parse_endianness
@testset "_parse_endianness" begin
    @test _parse_endianness("1.0") == ntoh
    @test _parse_endianness("-1.0") == ltoh
    @test_throws InvalidPfmFileFormat _parse_endianness("abba")
    @test_throws InvalidPfmFileFormat _parse_endianness("2.0")
end

# test _parse_int
@testset "_parse_int" begin
    @test _parse_int("12") === UInt(12)
    @test_throws InvalidPfmFileFormat _parse_int("abba")
    @test_throws InvalidPfmFileFormat _parse_int("-1")
    @test_throws InvalidPfmFileFormat _parse_int("1.0")
end

# test _parse_img_size
@testset "_parse_img_size" begin
    @test _parse_img_size("1920 1080") == UInt[1920, 1080]

    # test exceptions
    @test_throws InvalidPfmFileFormat _parse_img_size("abba 1920")
    @test_throws InvalidPfmFileFormat _parse_img_size("1920 -1080")
    @test_throws InvalidPfmFileFormat _parse_img_size("1920 1080 256")
    @test_throws InvalidPfmFileFormat _parse_img_size("1920")
end

# test _read_line
@testset "_read_line" begin
    io = IOBuffer(b"hello\nworld")
    @test _read_line(io) == "hello\n"
    @test _read_line(io) == "world"
    @test _read_line(io) === nothing
    
    # test exceptions
    io = IOBuffer(b"è")
    @test_throws InvalidPfmFileFormat _read_line(io)
end

# test _read_matrix
@testset "_read_matrix" begin
    io = IOBuffer()
    write(io, test_matrix)
    seekstart(io)
    @test all(_read_matrix(io, eltype(test_matrix), size(test_matrix)...) .== test_matrix)
    
    # test exceptions
    io = IOBuffer()
    write(io, test_matrix[begin:end-1])
    seekstart(io)
    @test_throws EOFError _read_matrix(io, eltype(test_matrix), size(test_matrix)...)
end

# test read(io, ::FE"PFM"
@testset "read" begin
    img = ImagePFM.read(IOBuffer(expected_output), format"PFM")
    @test size(img) == size(test_matrix)
    @test all(img == test_matrix)
    
    # test exceptions
    @test_throws InvalidPfmFileFormat ImagePFM.read(IOBuffer(b"PF\n3 2\n-1.0\nstop"), format"PFM")
end

#test write/read compatibility
@testset "write/read compatibility" begin
    img = test_matrix
    io = IOBuffer()
    ImagePFM.write(io, format"PFM", img)
    seekstart(io)
    @test all(ImagePFM.read(io, format"PFM") == img)
end