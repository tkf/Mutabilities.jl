module TestDoctest

import Mutabilities
using Documenter: doctest
using Test

@testset "doctest" begin
    if lowercase(get(ENV, "JULIA_PKGEVAL", "false")) == "true"
        @info "Skipping doctests on PkgEval."
        return
    end
    doctest(Mutabilities)
end

end  # module
