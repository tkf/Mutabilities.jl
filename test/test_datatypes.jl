module TestDataTypes

using Mutabilities
using Test

@testset begin
    x = meltproperties(1 + 2im)
    @test (x.re, x.im) == (1, 2)
    x.re *= 100
    @test freezeproperties(x) === 100 + 2im

    @test sprint(show, meltproperties(1 + 2im)) == "meltproperties(1 + 2im)"
    @test sprint(show, "text/plain", meltproperties(1 + 2im)) == "mutable handle to 1 + 2im"
end

end  # module
