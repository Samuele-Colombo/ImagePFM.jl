"""
    InvalidPfmFileFormat(msg)

The parsed PFM file is not conform to standard or is corrupted. Read `msg` for root cause.
"""
struct InvalidPfmFileFormat <: Exception
    msg::String
end
Base.showerror(io::IO, e::InvalidPfmFileFormat) = print(io, typeof(e), ": ", e.msg)