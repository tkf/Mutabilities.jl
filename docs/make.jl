using Documenter
using Mutabilities

makedocs(
    sitename = "Mutabilities",
    format = Documenter.HTML(),
    modules = [Mutabilities],
)

deploydocs(repo = "github.com/tkf/Mutabilities.jl", push_preview = true)
