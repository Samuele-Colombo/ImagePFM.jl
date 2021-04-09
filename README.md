# ImageIO.jl

FileIO.jl integration for image files

Provides load/save functionalities from [pfm files](http://www.pauldebevec.com/Research/HDR/PFM/).


## Installation

Verify that your `Project.toml` file does not directly include the original [`FileIO` package](https://github.com/JuliaIO/FileIO.jl) or other packages with conflicting names, then
install with Pkg:

```jl
pkg> # Press ']' to enter te Pkg REPL mode
pkg> add https://github.com/Samuele-Colombo/FileIO.jl # custom fork of `FileIO`
pkg> add https://github.com/Samuele-Colombo/ImagePFM.jl
```

## Usage

This module is not intended to be used directly, it only extends the capabilities of the `FileIO` package including the `pfm` format load/save.

```jl
using FileIO
import ColorTypes: RGB # `ColorTypes` must be in current project
save("test.pfm", rand(RGB, 100, 100))
load("test.pfm")
```
The `save` function will take `::AbstractMatrix{<:RGB}` arguments, but elements will be implicitly converted to `RGB{Float32}`. The `load` function only returns objects of type `Matrix{RGB{Float32}}`.

## Why the `FileIO` fork?

As documented [here](https://juliaio.github.io/FileIO.jl/stable/#Supporting-new-formats) it is possible, by design, to add support for new formats to `FileIO` by forking and modifying the source code. You can check what we modified at [our `FileIO` repo](https://github.com/Samuele-Colombo/FileIO.jl). This package conserves all the behaviors of the original package.

## Projects that use this package:

- [Raytracer](https://github.com/Paolo97Gll/Raytracer.jl)