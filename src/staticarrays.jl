isfrozenindex(::Type{<:StaticArrays.StaticArray}) = true
isfrozenvalue(::Type{<:StaticArrays.SArray}) = true
ownmutableindex(x::StaticArrays.StaticVector) = collect(x)

freeze(x::StaticArrays.MArray) = StaticArrays.SArray(x)
freezevalue(x::StaticArrays.MArray) = StaticArrays.SArray(x)
