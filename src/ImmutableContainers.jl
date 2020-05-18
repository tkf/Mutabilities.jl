module ImmutableContainers

# Use README as the docstring of the module:
@doc let path = joinpath(dirname(@__DIR__), "README.md")
    include_dependency(path)
    replace(read(path, String), r"^```julia"m => "```jldoctest README")
end ImmutableContainers

export freeze,
    freezeindex,
    freezeproperties,
    freezevalue,
    melt,
    meltindex,
    meltproperties,
    meltvalue,
    move!,
    readonly

import SplittablesBase
using ConstructionBase: constructorof, setproperties
using Requires: @require

include("utils.jl")
include("interface.jl")
include("baseimpl.jl")
include("arrays.jl")
include("dicts.jl")
include("sets.jl")
include("datatypes.jl")

const AbstractReadOnlyContainers =
    Union{AbstractReadOnlyArray,AbstractReadOnlyDict,AbstractReadOnlySet}

include("splittables.jl")

function __init__()
    @require StaticArrays = "90137ffa-7385-5640-81b9-e52037218182" begin
        include("staticarrays.jl")
    end
    @require StructArrays = "09ab397b-f2b6-538f-b94a-2f83cf4a842a" begin
        include("structarrays.jl")
    end
end

end # module
