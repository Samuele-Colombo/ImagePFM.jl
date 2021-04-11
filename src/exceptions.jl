struct InvalidPfmFileFormat <: Exception
end
Base.showerror(io::IO, e::InvalidPfmFileFormat) = print(io, typeof(e), ": ", e.message)