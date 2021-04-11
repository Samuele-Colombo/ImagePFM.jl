struct InvalidPfmFileFormat <: Exception
    msg::String
end
Base.showerror(io::IO, e::InvalidPfmFileFormat) = print(io, typeof(e), ": ", e.msg)