abstract type AbstractReadOnlySet{T,P} <: AbstractSet{T} end

Base.parent(x::AbstractReadOnlySet) = getfield(x, :parent)

# isfrozenvalue(::Type{<:AbstractReadOnlySet}) = true
isfrozenindex(::Type{<:AbstractReadOnlySet}) = true

# meltvalue!(x::AbstractReadOnlySet) = parent(x)
meltindex!(x::AbstractReadOnlySet) = parent(x)

# Workaround: `Base.copymutable(::AbstractSet)` returns an array
ownmutablevalue(x::AbstractSet) = Set(x)
ownmutableindex(x::AbstractSet) = Set(x)

Base.IteratorSize(::Type{<:AbstractReadOnlySet{T,P}}) where {T,P} =
    Base.IteratorSize(P)
Base.IteratorEltype(::Type{<:AbstractReadOnlySet{T,P}}) where {T,P} =
    Base.IteratorEltype(P)
Base.eltype(::Type{<:AbstractReadOnlySet{T,P}}) where {T,P} = eltype(P)
Base.iterate(x::AbstractReadOnlySet, args...) = iterate(parent(x), args...)
Base.length(x::AbstractReadOnlySet) = length(parent(x))

Base.copy(x::AbstractReadOnlySet) = copy(parent(x))
Base.copymutable(x::AbstractReadOnlySet) = Base.copymutable(parent(x))

Base.getproperty(x::AbstractReadOnlySet, name::Symbol) =
    constructorof(typeof(x))(getproperty(parent(x), name))
Base.getproperty(x::AbstractReadOnlySet, field) =
    constructorof(typeof(x))(getproperty(parent(x), field))

Base.broadcastable(x::AbstractReadOnlySet) = Base.broadcastable(parent(x))

struct ReadOnlySet{T,P<:AbstractSet{T}} <: AbstractReadOnlySet{T,P}
    parent::P
end

# isimmutablevalue(::Type{<:ReadOnlySet}) = true
isimmutableindex(::Type{<:ReadOnlySet}) = true
# isfrozenvalue(::Type{<:ReadOnlySet}) = false
isfrozenindex(::Type{<:ReadOnlySet}) = false
readonly_impl(x::AbstractSet) = ReadOnlySet(x)

struct ImmutableSet{T,P<:AbstractSet{T}} <: AbstractReadOnlySet{T,P}
    parent::P
end

freeze!(x::AbstractSet) = ImmutableSet(x)

struct AppendOnlySet{T,P<:AbstractSet{T}} <: AbstractReadOnlySet{T,P}
    parent::P
end

isfrozenindex(::Type{<:AppendOnlySet}) = false
Base.push!(x::AppendOnlySet, args...) = (push!(parent(x), args...); x)

freezevalue!(x::AbstractSet) = AppendOnlySet(x)

factoryof(::ReadOnlySet) = readonly
factoryof(::ImmutableSet) = freeze
factoryof(::AppendOnlySet) = freezevalue

function Base.showarg(io::IO, x::AbstractReadOnlySet, toplevel::Bool)
    print(io, nameof(factoryof(x)), '(')
    Base.showarg(io, parent(x), false)
    print(io, ')')
end
