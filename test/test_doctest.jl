module TestDoctest

import ImmutableContainers
using Documenter: doctest
using Test

@testset "doctest" begin
    if lowercase(get(ENV, "JULIA_PKGEVAL", "false")) == "true"
        @info "Skipping doctests on PkgEval."
        return
    end
    doctest(ImmutableContainers)
end

end  # module
