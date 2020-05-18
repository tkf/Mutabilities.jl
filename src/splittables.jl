function SplittablesBase.halve(x::AbstractReadOnlyContainers)
    left, right = halve(parent(x))
    return (constructorof(typeof(x))(left), constructorof(typeof(x))(right))
end

SplittablesBase.amount(x::AbstractReadOnlyContainers) = amount(parent(x))
