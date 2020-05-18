# Implementations for Base/stdlib functions

isfrozenindex(::Type{<:Union{Array,SubArray,Base.ReshapedArray,BitArray}}) = true
isfrozenindex(::Type{<:Vector}) = false
isfrozenindex(::Type{<:BitArray}) = false
