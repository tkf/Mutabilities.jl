module TestStructArrays

using ImmutableContainers
using ImmutableContainers: isfrozen, isfrozenindex, isfrozenvalue
using StructArrays
using StaticArrays
using Test

@testset "isfrozen" begin
    @test !isfrozen(StructArray(a = [1]))
    @test !isfrozenindex(StructArray(a = [1]))
    @test !isfrozenvalue(StructArray(a = [1]))

    @test isfrozen(StructArray(a = 1:1))
    @test isfrozenindex(StructArray(a = 1:1))
    @test isfrozenvalue(StructArray(a = 1:1))

    @test !isfrozen(StructArray(a = [1 2]))
    @test isfrozenindex(StructArray(a = [1 2]))
    @test !isfrozenvalue(StructArray(a = [1 2]))
end

@testset "melt" begin
    @test melt(StructArray(a = 1:3)).a isa Vector{Int}
    @test melt(StructArray(a = SA[1, 2])).a isa Vector{Int}
    @test meltvalue(StructArray(a = SA[1, 2])).a isa MArray
    @test meltvalue(StructArray(a = MVector(1, 2))).a isa MArray
    @test meltindex(StructArray(a = SA[1, 2])).a isa Vector{Int}
    @test meltindex(StructArray(a = MVector(1, 2))).a isa Vector{Int}

    x = StructArray{Complex{Int}}(re = SA[1, 2], im = SA[3, 4])
    @test meltindex(x) isa StructArray{Complex{Int}}
    @test meltindex(x).re isa Vector{Int}
    @test meltvalue(x) isa StructArray{Complex{Int}}
    @test meltvalue(x).re isa MArray
    @test typeof(melt(x)) == typeof(meltindex(x))
end

@testset "freeze" begin
    @test freeze(StructArray(a = [1:3;])).a == 1:3
    @test isfrozen(freeze(StructArray(a = [1:3;])).a)
    @test freeze(StructArray(a = SA[1, 2])) === StructArray(a = SA[1, 2])
end

end  # module
