# Mutabilities: a type-level tool for ownership-by-convention

[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://tkf.github.io/Mutabilities.jl/dev)
[![GitHub Actions](https://github.com/tkf/Mutabilities.jl/workflows/Run%20tests/badge.svg)](https://github.com/tkf/Mutabilities.jl/actions?query=workflow%3A%22Run+tests%22)

Mutabilities.jl is a type-level tool for describing
mutabilities and ownership of objects in a composable manner.

See more in the
[documentation](https://tkf.github.io/Mutabilities.jl/dev).

## Summary

* `readonly`: create read-only view
* `freeze`, `freezevalue`, `freezeindex`, `freezeproperties`: create
  immutable copies
* `melt`, `meltvalue`, `meltindex`, `meltproperties`: create mutable copies
* `move!`: manually elides copies with freeze/melt APIs.

## High-level interface

### Read-only view

The most easy-to-use interface is `readonly(x)` which creates a
read-only "view" to `x`:

```julia
julia> using Mutabilities

julia> x = [1, 2, 3];

julia> z = readonly(x)
3-element readonly(::Array{Int64,1}) with eltype Int64:
 1
 2
 3

julia> z[1] = 111
ERROR: setindex! not defined for Mutabilities.ReadOnlyArray{Int64,1,Array{Int64,1}}
```

Note that changes in `x` would still be reflected to `z`:

```julia
julia> x[1] = 111;

julia> z
3-element readonly(::Array{Int64,1}) with eltype Int64:
 111
   2
   3
```

### Freeze/melt

Use `freeze(x)` to get an independent immutable (shallow) _copy_ of
`x`:

```julia
julia> x = [1, 2, 3];

julia> z = freeze(x)
3-element freeze(::Array{Int64,1}) with eltype Int64:
 1
 2
 3

julia> x[1] = 111;

julia> z
3-element freeze(::Array{Int64,1}) with eltype Int64:
 1
 2
 3
```

`freeze` can be reverted by `melt`:

```julia
julia> y = melt(z)
3-element Array{Int64,1}:
 1
 2
 3
```

It returns an independent mutable (shallow) _copy_ of `y`.  Thus, `y`
can be safely mutated:

```julia
julia> y[1] = 111;

julia> z
3-element freeze(::Array{Int64,1}) with eltype Int64:
 1
 2
 3
```

### Example usage

Julia's `view` is dangerous to use if the indices can be mutated after
creating it:

```JULIA
idx = [1, 1, 1]
x = view([1], idx)
x[1]  # OK
idx[1] = 10_000_000_000
x[1]  # segfault
```

This can be avoided by freezing the index array:

```JULIA
view([1], freeze(idx))
```

Note that `readonly` is not enough.

### Variants

`freeze` and `melt` work both on _indices (keys) and values_.  It is
possible to create an append-only vector by freezing the values:

```julia
julia> append_only = freezevalue([1, 2, 3]);

julia> push!(append_only, 4)
4-element freezevalue(::Array{Int64,1}) with eltype Int64:
 1
 2
 3
 4

julia> append_only[1] = 1
ERROR: setindex! not defined for Mutabilities.AppendOnlyVector{Int64,Array{Int64,1}}
```

It is possible to create a shape-frozen vector by freezing the indices:

```julia
julia> shape_frozen = freezeindex([1, 2, 3])
3-element freezeindex(::Array{Int64,1}) with eltype Int64:
 1
 2
 3

julia> shape_frozen .*= 10
3-element freezeindex(::Array{Int64,1}) with eltype Int64:
 10
 20
 30

julia> push!(shape_frozen, 4)
ERROR: push! on freezeindex(::Array{Int64,1}) not allowed
```

## Low-level interface

Using `freeze` and `melt` at API boundaries is a good way to ensure
correctness of the programs.  However,
[until the `julia` compiler gets a borrow checker](https://github.com/JuliaLang/julia/pull/31630)
and automatically elides such copies, it may be very expensive to use
them in some situations.  Until then, Mutabilities.jl provides
an "escape hatch"; i.e., an API to let the programmer declare that
there is no sharing of the given object:

```julia
julia> z = freeze(move!([1, 2, 3]))  # no copy
3-element freeze(::Array{Int64,1}) with eltype Int64:
 1
 2
 3

julia> melt(move!(z))  # no copy
3-element Array{Int64,1}:
 1
 2
 3
```

This allows Julia programs to compose well, without defining immutable
`f` and mutable `f!` variants of the API and without documenting the
particular memory ownership for each function.

For example, `melt` is simply defined as

```JULIA
melt(x) = meltvalue(move!(meltindex(x)))
```

`move!` can be useful when, e.g., input values can be re-used for
output values:

```julia
julia> function add(x, y)
           out = melt(x)
           out .+= y
           return freeze(out)
       end;

julia> add(move!(ones(3)), ones(3))  # allocates two arrays, not three
3-element freeze(::Array{Float64,1}) with eltype Float64:
 2.0
 2.0
 2.0
```

## Supported collections and types

* `AbstractArray`
* `AbstractDict`
* `AbstractSet`
* [Data types](https://juliadata.github.io/StructTypes.jl/stable/#DataTypes-1)
  ("plain `struct`")

## Interop

### StaticArrays

Static arrays are converted to appropriate types instead of the
wrapper arrays:

```julia
julia> using StaticArrays

julia> a = SA[1, 2, 3]
3-element SArray{Tuple{3},Int64,1,3} with indices SOneTo(3):
 1
 2
 3

julia> melt(a)
3-element Array{Int64,1}:
 1
 2
 3

julia> meltvalue(a)
3-element MArray{Tuple{3},Int64,1,3} with indices SOneTo(3):
 1
 2
 3

julia> freeze(MVector(1, 2, 3))  # or freezevalue
3-element SArray{Tuple{3},Int64,1,3} with indices SOneTo(3):
 1
 2
 3
```

### StructArrays

Mutabilities.jl is aware of mutability of each field arrays
wrapped in struct arrays:

```julia
julia> using StructArrays

julia> x = StructArray(a = 1:3);  # x.a is not mutable

julia> y = melt(x)
3-element StructArray(::Array{Int64,1}) with eltype NamedTuple{(:a,),Tuple{Int64}}:
 (a = 1,)
 (a = 2,)
 (a = 3,)

julia> y.a
3-element Array{Int64,1}:
 1
 2
 3

julia> z = freeze(StructArray(a = [1, 2, 3]))
3-element freeze(StructArray(::Array{Int64,1})) with eltype NamedTuple{(:a,),Tuple{Int64}}:
 (a = 1,)
 (a = 2,)
 (a = 3,)

julia> z.a
3-element freeze(::Array{Int64,1}) with eltype Int64:
 1
 2
 3
```

## Related packages

* https://github.com/andyferris/Freeze.jl
* https://github.com/bkamins/ReadOnlyArrays.jl
