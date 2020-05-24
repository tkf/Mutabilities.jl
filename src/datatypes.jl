"""
    meltproperties(z) -> x
    freezeproperties(x) -> z

`meltproperties` on an immutable data type (`struct`) object creates a
mutable handle to it.  This can be unwrapped using `freezeproperties`
to obtain the "mutated" immutable object.

# Examples
```jldoctest
julia> using Mutabilities

julia> x = meltproperties(1 + 2im)
mutable handle to 1 + 2im

julia> x.re *= 100;

julia> x
mutable handle to 100 + 2im

julia> freezeproperties(x) :: Complex{Int}
100 + 2im

julia> x = meltproperties((a = 1, b = 2))
mutable handle to (a = 1, b = 2)

julia> x.a = 123;

julia> freezeproperties(x)
(a = 123, b = 2)
```
"""
(meltproperties, freezeproperties)

mutable struct MutableDataType{T}
    parent::T
end

Base.parent(x::MutableDataType) = getfield(x, :parent)

Base.getproperty(x::MutableDataType, name::Symbol) = getproperty(parent(x), name)
Base.getproperty(x::MutableDataType, field) = getproperty(parent(x), field)

function Base.setproperty!(x::MutableDataType, name::Symbol, v)
    setfield!(x, :parent, setproperties(parent(x); name => v))
    return x
end

#=
struct ReadOnlyDataType{T}
    parent::T
end

Base.parent(x::ReadOnlyDataType) = getfield(x, :parent)

Base.getproperty(x::ReadOnlyDataType, name::Symbol) = getproperty(parent(x), name)
Base.getproperty(x::ReadOnlyDataType, field) = getproperty(parent(x), field)

_ismutablestruct(::Type) = false
Base.@pure _ismutablestruct(T::DataType) = T.mutable
=#

freezeproperties(x::MutableDataType) = parent(x)
meltproperties(x) = MutableDataType(x)

#=
meltproperties(x::ReadOnlyDataType) = own(parent(x))
meltproperties(x::Moved) = meltproperties!(x.value)
meltproperties(x) = _ismutablestruct(typeof(x)) ? own(x) : MutableDataType(x)
meltproperties!(x) = _ismutablestruct(typeof(x)) ? x : MutableDataType(x)

freezeproperties(x::Moved) = freezeproperties!(x.value)
freezeproperties(x) = _ismutablestruct(typeof(x)) ? freezeproperties!(own(x)) : x
freezeproperties!(x) = _ismutablestruct(typeof(x)) ? ReadOnlyDataType(x) : x
=#

function Base.show(io::IO, ::MIME"text/plain", x::MutableDataType)
    print(io, "mutable handle to ")
    show(io, MIME"text/plain"(), parent(x))
end

function Base.show(io::IO, x::MutableDataType)
    print(io, meltproperties, '(')
    show(io, parent(x))
    print(io, ')')
end
