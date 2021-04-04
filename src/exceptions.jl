struct InvalidPfmFileFormat
    message::String
end
Base.showerror(io::IO, e::InvalidPfmFileFormat) = print(io, typeof(e), ": ", e.message)