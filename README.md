# ImageIO.jl

![status][status] ![package-version][package-version]

[status]: https://img.shields.io/badge/project_status-stable-389826?style=flat
[package-version]: https://img.shields.io/badge/package_version-1.0-blue?style=flat

FileIO.jl integration for image files. Provides load/save functionalities from [pfm files](http://www.pauldebevec.com/Research/HDR/PFM/).

## Installation

The package depends on [this custom fork](https://github.com/Samuele-Colombo/FileIO.jl) of the FileIO package. Note that if FileIO is already present (e.g. the original package), it will be overwritten by this custom version.

```julia
julia> # Press ']' to enter the Pkg REPL mode
pkg> add https://github.com/Samuele-Colombo/FileIO.jl
pkg> add https://github.com/Samuele-Colombo/ImagePFM.jl
```

## Usage

This module is not intended to be used directly, it only extends the capabilities of the `FileIO` package including the `pfm` format load/save.

```julia
julia> using FileIO
julia> import ColorTypes: RGB # `ColorTypes` must be in current project
julia> save("test.pfm", rand(RGB, 100, 100))
julia> load("test.pfm")
```

The `save` function will take `::AbstractMatrix{<:RGB}` arguments, but elements will be implicitly converted to `RGB{Float32}`. The `load` function only returns objects of type `Matrix{RGB{Float32}}`.

## Why the `FileIO` fork?

As documented [here](https://juliaio.github.io/FileIO.jl/stable/#Supporting-new-formats) it is possible, by design, to add support for new formats to `FileIO` by forking and modifying the source code. You can check what we modified at [our `FileIO` repo](https://github.com/Samuele-Colombo/FileIO.jl). This package conserves all the behaviors of the original package.

## Projects that use this package

- [Raytracer](https://github.com/Paolo97Gll/Raytracer.jl)
