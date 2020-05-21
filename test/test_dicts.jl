module TestDicts

using Mutabilities
using Test

@testset "readonly" begin
    @testset for x in Any[Dict(:a => 1, :b => 2)]
        @test parent(readonly(x)) === x  # (no copy)
        @test parent(readonly(move!(x))) === x  # (no copy)
        @test readonly(x) == x
        @test_throws Exception readonly(x)[:a] = 1
        @test_throws Exception push!(readonly(x), :a => 1)

        z = readonly(x)
        x[:a] = 111
        @test z[:a] == 111
    end
end

@testset "freeze" begin
    @testset for x in Any[Dict(:a => 1, :b => 2)]
        @test parent(freeze(x)) !== x  # (copy)
        @test parent(freeze(move!(x))) === x  # (no copy)
        @test freeze(x) == x
        @test_throws Exception freeze(x)[:a] = 1
        @test_throws Exception push!(freeze(x), :a => 1)

        z = freeze(x)
        x[:a] = 111
        @test z[:a] != 111
    end
end

@testset "freezevalue" begin
    @testset for x in Any[Dict(:a => 1, :b => 2)]
        @test parent(freezevalue(x)) !== x  # (copy)
        @test parent(freezevalue(move!(x))) === x  # (no copy)
        @test freezevalue(x) == x
        @test_throws Exception freezevalue(x)[:a] = 1

        z = freezevalue(x)
        x[:a] = 111
        @test z[:a] != 111

        @test push!(z, :c => 3) === z
        @test z[:c] == 3
    end
end

@testset "freezeindex" begin
    @testset for x in Any[Dict(:a => 1, :b => 2)]
        @test parent(freezeindex(x)) !== x  # (copy)
        @test parent(freezeindex(move!(x))) === x  # (no copy)
        @test freezeindex(x) == x
        @test_throws Exception push!(freezeindex(x), :c => 3)

        x0 = copy(x)
        z = freezeindex(x)
        z[:a] = 111
        @test z[:a] == 111
        @test z != x0
    end
end

@testset "melt" begin
    @testset for freezer in [readonly, freeze, freezeindex, freezevalue]
        @testset for x in Any[Dict(:a => 1, :b => 2)]
            z = freezer(x)

            @test melt(z) !== x
            @test melt(move!(z)) === parent(z)
            if freezer === readonly
                @test melt(move!(z)) === x
            else
                @test melt(move!(z)) !== x
            end

            a = melt(z)
            a[:a] = 123
            @test z[:a] != 123

            b = melt(move!(z))
            b[:a] = 123
            @test z[:a] == 123
        end
    end
end

@testset "immutable input" begin
    @testset for x in Any[1:2, (1, 2), (a = (1, 2), c = 3)]
        @test readonly(x) === x
        @test freeze(x) === x
        @test freezevalue(x) === x
        @test freezeindex(x) === x
        @test readonly(move!(x)) === x
        @test freeze(move!(x)) === x
        @test freezevalue(move!(x)) === x
        @test freezeindex(move!(x)) === x
    end
end

@testset "showarg" begin
    @testset for freezer in [readonly, freeze, freezeindex, freezevalue]
        z = freezer(Symbol[])
        msg0 = sprint(Base.showarg, z, false)
        msg1 = sprint(Base.showarg, z, true)
        @test startswith(msg0, "$freezer(")
        @test startswith(msg1, "$freezer(")
        @test startswith(msg1, msg0)
        @test endswith(msg1, " with eltype Symbol")
    end
end

end  # module
