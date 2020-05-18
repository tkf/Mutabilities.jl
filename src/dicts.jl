abstract type AbstractReadOnlyDict{K,V,P} <: AbstractDict{K,V} end

Base.parent(x::AbstractReadOnlyDict) = getfield(x, :parent)

isfrozenvalue(::Type{<:AbstractReadOnlyDict}) = true
isfrozenindex(::Type{<:AbstractReadOnlyDict}) = true

meltvalue!(x::AbstractReadOnlyDict) = parent(x)
meltindex!(x::AbstractReadOnlyDict) = parent(x)

# Workaround: `Base.copymutable(::AbstractDict)` returns an array
ownmutablevalue(x::AbstractDict) = Dict(x)
ownmutableindex(x::AbstractDict) = Dict(x)

Base.IteratorSize(::Type{<:AbstractReadOnlyDict{K,V,P}}) where {K,V,P} =
    Base.IteratorSize(P)
Base.IteratorEltype(::Type{<:AbstractReadOnlyDict{K,V,P}}) where {K,V,P} =
    Base.IteratorEltype(P)
Base.eltype(::Type{<:AbstractReadOnlyDict{K,V,P}}) where {K,V,P} = eltype(P)
Base.@propagate_inbounds Base.getindex(x::AbstractReadOnlyDict, I...) =
    getindex(parent(x), I...)
Base.iterate(x::AbstractReadOnlyDict, args...) = iterate(parent(x), args...)
Base.length(x::AbstractReadOnlyDict) = length(parent(x))
Base.get(x::AbstractReadOnlyDict, k, default) = get(parent(x), k, default)

Base.copy(x::AbstractReadOnlyDict) = copy(parent(x))
Base.copymutable(x::AbstractReadOnlyDict) = Base.copymutable(parent(x))

Base.getproperty(x::AbstractReadOnlyDict, name::Symbol) =
    constructorof(typeof(x))(getproperty(parent(x), name))
Base.getproperty(x::AbstractReadOnlyDict, field) =
    constructorof(typeof(x))(getproperty(parent(x), field))

Base.broadcastable(x::AbstractReadOnlyDict) = Base.broadcastable(parent(x))

struct ReadOnlyDict{K,V,P<:AbstractDict{K,V}} <: AbstractReadOnlyDict{K,V,P}
    parent::P
end

isimmutablevalue(::Type{<:ReadOnlyDict}) = true
isimmutableindex(::Type{<:ReadOnlyDict}) = true
isfrozenvalue(::Type{<:ReadOnlyDict}) = false
isfrozenindex(::Type{<:ReadOnlyDict}) = false
readonly_impl(x::AbstractDict) = ReadOnlyDict(x)

struct ImmutableDict{K,V,P<:AbstractDict{K,V}} <: AbstractReadOnlyDict{K,V,P}
    parent::P
end

freeze!(x::AbstractDict) = ImmutableDict(x)

struct ImmutableIndexDict{K,V,P<:AbstractDict{K,V}} <: AbstractReadOnlyDict{K,V,P}
    parent::P
end

isfrozenvalue(::Type{<:ImmutableIndexDict}) = false
function Base.setindex!(x::ImmutableIndexDict, v, k)
    haskey(x, k) || throw(KeyError(k))
    setindex!(parent(x), v, k)
    return x
end

freezeindex!(x::AbstractDict) = ImmutableIndexDict(x)

struct AppendOnlyDict{K,V,P<:AbstractDict{K,V}} <: AbstractReadOnlyDict{K,V,P}
    parent::P
end

isfrozenindex(::Type{<:AppendOnlyDict}) = false
function Base.setindex!(x::AppendOnlyDict, v, k)
    haskey(x, k) && throw(ArgumentError("key already exist"))
    setindex!(parent(x), v, k)
    return x
end

freezevalue!(x::AbstractDict) = AppendOnlyDict(x)

factoryof(::ReadOnlyDict) = readonly
factoryof(::ImmutableDict) = freeze
factoryof(::ImmutableIndexDict) = freezeindex
factoryof(::AppendOnlyDict) = freezevalue

function Base.showarg(io::IO, x::AbstractReadOnlyDict, toplevel::Bool)
    print(io, nameof(factoryof(x)), '(')
    Base.showarg(io, parent(x), false)
    print(io, ')')
end
