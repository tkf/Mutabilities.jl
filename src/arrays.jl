abstract type AbstractReadOnlyArray{T,N,P} <: AbstractArray{T,N} end

Base.parent(x::AbstractReadOnlyArray) = getfield(x, :parent)

isfrozenvalue(::Type{<:AbstractReadOnlyArray}) = true
isfrozenindex(::Type{<:AbstractReadOnlyArray}) = true

meltvalue!(x::AbstractReadOnlyArray) = parent(x)
meltindex!(x::AbstractReadOnlyArray) = parent(x)

Base.IteratorSize(::Type{<:AbstractReadOnlyArray{T,N,P}}) where {T,N,P} =
    Base.IteratorSize(P)
Base.IteratorEltype(::Type{<:AbstractReadOnlyArray{T,N,P}}) where {T,N,P} =
    Base.IteratorEltype(P)
Base.eltype(::Type{<:AbstractReadOnlyArray{T,N,P}}) where {T,N,P} = eltype(P)
Base.size(x::AbstractReadOnlyArray, args...) = size(parent(x), args...)
Base.@propagate_inbounds Base.getindex(x::AbstractReadOnlyArray, I...) =
    getindex(parent(x), I...)
Base.firstindex(x::AbstractReadOnlyArray) = firstindex(parent(x))
Base.lastindex(x::AbstractReadOnlyArray) = lastindex(parent(x))
Base.IndexStyle(::Type{<:AbstractReadOnlyArray{T,N,P}}) where {T,N,P} = IndexStyle(P)
Base.iterate(x::AbstractReadOnlyArray, args...) = iterate(parent(x), args...)
Base.length(x::AbstractReadOnlyArray) = length(parent(x))

Base.axes(x::AbstractReadOnlyArray) = axes(parent(x))
Base.strides(x::AbstractReadOnlyArray) = strides(parent(x))
Base.unsafe_convert(p::Type{Ptr{T}}, x::AbstractReadOnlyArray) where {T} =
    Base.unsafe_convert(p, parent(x))
Base.stride(x::AbstractReadOnlyArray, i::Int) = stride(parent(x), i)

Base.copy(x::AbstractReadOnlyArray) = copy(parent(x))
Base.copymutable(x::AbstractReadOnlyArray) = Base.copymutable(parent(x))

Base.push!(x::AbstractReadOnlyArray, _...) = throw(DisallowedOperation(push!, x))
Base.append!(x::AbstractReadOnlyArray, _...) = throw(DisallowedOperation(append!, x))

# For StructArrays:
Base.getproperty(x::AbstractReadOnlyArray, name::Symbol) =
    constructorof(typeof(x))(getproperty(parent(x), name))
Base.getproperty(x::AbstractReadOnlyArray, field) =
    constructorof(typeof(x))(getproperty(parent(x), field))

Base.broadcastable(x::AbstractReadOnlyArray) = Base.broadcastable(parent(x))

struct ReadOnlyArray{T,N,P<:AbstractArray{T,N}} <: AbstractReadOnlyArray{T,N,P}
    parent::P
end

isimmutablevalue(::Type{<:ReadOnlyArray}) = true
isimmutableindex(::Type{<:ReadOnlyArray}) = true
isfrozenvalue(::Type{<:ReadOnlyArray}) = false
isfrozenindex(::Type{<:ReadOnlyArray}) = false
readonly_impl(x::AbstractArray) = ReadOnlyArray(x)

struct ImmutableArray{T,N,P<:AbstractArray{T,N}} <: AbstractReadOnlyArray{T,N,P}
    parent::P
end

freeze!(x::AbstractArray) = ImmutableArray(x)

struct ImmutableIndexArray{T,N,P<:AbstractArray{T,N}} <: AbstractReadOnlyArray{T,N,P}
    parent::P
end

isfrozenvalue(::Type{<:ImmutableIndexArray}) = false
Base.setindex!(x::ImmutableIndexArray, args...) = setindex!(parent(x), args...)

freezeindex!(x::AbstractArray) = ImmutableIndexArray(x)

struct AppendOnlyVector{T,P<:AbstractVector{T}} <: AbstractReadOnlyArray{T,1,P}
    parent::P
end

isfrozenindex(::Type{<:AppendOnlyVector}) = false
Base.push!(x::AppendOnlyVector, args...) = (push!(parent(x), args...); x)
Base.append!(x::AppendOnlyVector, args...) = (append!(parent(x), args...); x)

freezevalue!(x::AbstractVector) = AppendOnlyVector(x)
freezevalue!(x::AbstractArray) = ImmutableArray(x)

factoryof(::ReadOnlyArray) = readonly
factoryof(::ImmutableArray) = freeze
factoryof(::ImmutableIndexArray) = freezeindex
factoryof(::AppendOnlyVector) = freezevalue

function Base.showarg(io::IO, x::AbstractReadOnlyArray, toplevel::Bool)
    print(io, nameof(factoryof(x)), '(')
    Base.showarg(io, parent(x), false)
    print(io, ')')
    toplevel && print(io, " with eltype ", eltype(x))
end
