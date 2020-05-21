module TestStaticArrays

using Mutabilities
using Mutabilities: isfrozen, isfrozenindex, isfrozenvalue
using StaticArrays
using Test

@testset "isfrozen" begin
    @test isfrozen(SVector(1))
    @test isfrozenindex(SVector(1))
    @test isfrozenvalue(SVector(1))

    @test !isfrozen(MVector(1))
    @test isfrozenindex(MVector(1))
    @test !isfrozenvalue(MVector(1))
end

@testset "melt" begin
    @test typeof(melt(SVector(1))) <: Vector{Int}
    @test typeof(melt(MVector(1))) <: Vector{Int}
    @test typeof(melt(SMatrix{1,1}(1))) <: MMatrix
    @test typeof(melt(MMatrix{1,1}(1))) <: MMatrix
end

@testset "meltvalue" begin
    @test typeof(meltvalue(SVector(1))) <: MVector
    @test typeof(meltvalue(MVector(1))) <: MVector
    @test typeof(meltvalue(SMatrix{1,1}(1))) <: MMatrix
    @test typeof(meltvalue(MMatrix{1,1}(1))) <: MMatrix
end

@testset "meltindex" begin
    @test typeof(meltindex(SVector(1))) <: Vector{Int}
    @test typeof(meltindex(MVector(1))) <: Vector{Int}
    @test typeof(meltindex(SMatrix{1,1}(1))) <: MMatrix
    @test typeof(meltindex(MMatrix{1,1}(1))) <: MMatrix
end

end  # module
