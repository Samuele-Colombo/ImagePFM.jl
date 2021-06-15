# Changelog ImagePFM.jl

## v2.0.0

### ⚠⚠⚠ BREAKING CHANGES ⚠⚠⚠

- Only `RGB{Float32}` is supported. Any other eltype of `RGB` will throw an `InvalidRGBEltype` exception.

### Bug fix

- Fix a bug that cause an anomalous `using` behaviour.

## v1.0.0

- First release of the code.
