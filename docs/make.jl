using Documenter
using ImmutableContainers

makedocs(
    sitename = "ImmutableContainers",
    format = Documenter.HTML(),
    modules = [ImmutableContainers],
)

deploydocs(repo = "github.com/tkf/ImmutableContainers.jl")
