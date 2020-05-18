_fieldtypes(::Type{<:StructArrays.StructArray{<:Any,<:Any,C}}) where {C<:Tuple} = C
_fieldtypes(
    ::Type{<:StructArrays.StructArray{<:Any,<:Any,<:NamedTuple{<:Any,C}}},
) where {C<:Tuple} = C

isimmutableindex(::Type{T}) where {T<:StructArrays.StructArray} =
    _tall(isimmutableindex, _fieldtypes(T))
isimmutablevalue(::Type{T}) where {T<:StructArrays.StructArray} =
    _tall(isimmutablevalue, _fieldtypes(T))
isfrozenindex(::Type{T}) where {T<:StructArrays.StructArray} =
    _tall(isfrozenindex, _fieldtypes(T))
isfrozenvalue(::Type{T}) where {T<:StructArrays.StructArray} =
    _tall(isfrozenvalue, _fieldtypes(T))

ownmutableindex(x::StructArrays.StructArray{T,N}) where {T,N} =
    StructArrays.StructArray{T,N}(_map(ownmutableindex, StructArrays.fieldarrays(x)))
