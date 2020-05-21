isfrozenvalue(x) = isfrozenvalue(typeof(x))
isfrozenindex(x) = isfrozenindex(typeof(x))
isfrozen(x) = isfrozen(typeof(x))

isfrozenvalue(::Type{T}) where {T} = isbitstype(T)
isfrozenindex(::Type{T}) where {T} = isbitstype(T)
isfrozen(::Type{T}) where {T} = isfrozenvalue(T) && isfrozenindex(T)

isimmutablevalue(x) = isimmutablevalue(typeof(x))
isimmutableindex(x) = isimmutableindex(typeof(x))

isimmutablevalue(::Type{T}) where {T} = isfrozenvalue(T)
isimmutableindex(::Type{T}) where {T} = isfrozenindex(T)

"""
    readonly(x) -> z

Create a read-only view of `x`.  Mutations on `x` are reflected to `z`.
"""
readonly

"""
    melt(z) -> x
    meltvalue(z) -> x
    meltindex(z) -> x
    freeze(x) -> z
    freezevalue(x) -> z
    freezeindex(x) -> z

`melt` and `meltvalue` create a mutable *copy* of `x`.  `freeze`,
`freezevalue`, and `freezeindex` create an immutable *copy* of `x`.

The result of `melt(::AbstractVector)` is appendable. The result of
`meltvalue(::AbstractVector)` may not be appendable.  `meltindex`
undoes `freezeindex`.

`freezevalue` only freezes the existing values and it is still
possible to append the new items to `z`.  `freezeindex` only freezes
the indices and it is still possible to mutate the values.

Use, e.g., `freeze(move!(x))` and `melt(move!(z))` to freeze or melt the
values without creating a copy (see also [`move!`](@ref)).

[`readonly`](@ref) can also be used to create a read-only view without
creating a copy and without asserting strict absence of ownership.

# Examples
```jldoctest
julia> using Mutabilities

julia> z = freeze([1, 2, 3])
3-element freeze(::Array{Int64,1}) with eltype Int64:
 1
 2
 3

julia> z[1] = 111
ERROR: setindex! not defined for Mutabilities.ImmutableArray{Int64,1,Array{Int64,1}}

julia> y = melt(z)
3-element Array{Int64,1}:
 1
 2
 3
```
"""
(melt, meltvalue, meltindex, freeze, freezevalue, freezeindex)
# TODO: `melt(::Matrix)` can make a matrix appendable. What to do with it?
# Maybe only allow maximum mutability supported by its abstract type
# interface? (current implementation)

readonly(x) = isimmutablevalue(x) && isimmutableindex(x) ? x : readonly_impl(x)
# maybe just?: readonly(x) = freeze(move!(x))

melt(x) = meltvalue(move!(meltindex(x)))
meltvalue(x) = isimmutablevalue(x) ? ownmutablevalue(x) : own(x)
meltindex(x) = isimmutableindex(x) ? ownmutableindex(x) : own(x)

freeze(x) = isfrozen(x) ? unmoved(x) : freeze!(own(x))
freezevalue(x) = isfrozenvalue(x) ? unmoved(x) : freezevalue!(own(x))
freezeindex(x) = isfrozenindex(x) ? unmoved(x) : freezeindex!(own(x))

function freeze! end
function freezevalue! end
function freezeindex! end

meltvalue!(x) = x
meltindex!(x) = x

# `f!(x)` is the version of `f(x)` where the caller asserts that `x`
# is not going to be used by anyone else. i.e., the caller "allows"
# any future mutations of `x`.

own(x) = copy(x)
# own(x) = deepcopy(x)

ownmutablevalue(x) = Base.copymutable(x)
ownmutableindex(x) = Base.copymutable(x)

struct Moved{T}
    value::T
end

own(x::Moved) = x.value
ownmutablevalue(x::Moved) = meltvalue!(x.value)
ownmutableindex(x::Moved) = meltindex!(x.value)

unmoved(x::Moved) = x.value
unmoved(x) = x

isimmutablevalue(::Type{Moved{T}}) where {T} = isimmutablevalue(T)
isimmutableindex(::Type{Moved{T}}) where {T} = isimmutableindex(T)
isfrozenvalue(::Type{Moved{T}}) where {T} = isfrozenvalue(T)
isfrozenindex(::Type{Moved{T}}) where {T} = isfrozenindex(T)

readonly(x::Moved) = readonly(x.value)  # ignore "move!"

"""
    move!(x)

Manually declare that the object `x` has no other owners and the
object `x` is not going to be used by the caller.

# Examples
```jldoctest
julia> using Mutabilities

julia> x = [];

julia> melt(move!(freeze(move!(x)))) === x
true

julia> melt(move!(freeze(x))) === x
false

julia> melt(freeze(move!(x))) === x
false
```

!!! note

    Above examples intentionally violate the rule for using `move!` to
    show how it works.  When `x` is passed to `move!` on the left hand
    side, it is not allowed to use `x` on the right hand side of `===`.
"""
move!(x) = Moved(x)
move!(x::Moved) = x
