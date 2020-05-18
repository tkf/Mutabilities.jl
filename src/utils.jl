_tall(_, ::Type{Tuple{}}) = true
_tall(f, ::Type{Tuple{T}}) where {T} = f(T)
_tall(f, ::Type{T}) where {T<:Tuple} =
    f(Base.tuple_type_head(T)) && _tall(f, Base.tuple_type_tail(T))

_map(f, a::Tuple) = map(f, a)
_map(f, a::NamedTuple{names}) where {names} = NamedTuple{names}(_map(f, Tuple(a)))

_map(f, (x,)::Tuple{Any}, (y,)::Tuple{Any}) = (f(x, y),)
_map(f, a::Tuple, b::Tuple) = (f(a[1], b[1]), _map(f, Base.tail(a), Base.tail(b))...)
_map(f, a::NamedTuple{names}, b::NamedTuple{names}) where {names} =
    NamedTuple{names}(_map(f, Tuple(a), Tuple(b)))

struct DisallowedOperation <: Exception
    f
    x
end

function Base.showerror(io::IO, err::DisallowedOperation)
    print(io, "$(err.f) on ")
    Base.showarg(io, err.x, false)
    print(io, " not allowed")
end
