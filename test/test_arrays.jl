module TestCore

using Mutabilities
using Test

@testset "readonly" begin
    @testset for x in Any[[1, 2], [1 2; 3 4]]
        @test parent(readonly(x)) === x  # (no copy)
        @test parent(readonly(move!(x))) === x  # (no copy)
        @test readonly(x) == x
        @test_throws Exception readonly(x)[1] = 1
        @test_throws Exception push!(readonly(x), 1)

        z = readonly(x)
        x[1] = 111
        @test z[1] == 111

        if ndims(x) == 1
            push!(x, 333)
            @test z[end] == 333
        end
    end
end

@testset "freeze" begin
    @testset for x in Any[[1, 2], [1 2; 3 4]]
        @test parent(freeze(x)) !== x  # (copy)
        @test parent(freeze(move!(x))) === x  # (no copy)
        @test freeze(x) == x
        @test_throws Exception freeze(x)[1] = 1
        @test_throws Exception push!(freeze(x), 1)

        z = freeze(x)
        x[1] = 111
        @test z[1] != 111

        if ndims(x) == 1
            push!(x, 333)
            @test z[end] != 333
        end
    end
end

@testset "freezevalue" begin
    @testset for x in Any[[1, 2], [1 2; 3 4]]
        @test parent(freezevalue(x)) !== x  # (copy)
        @test parent(freezevalue(move!(x))) === x  # (no copy)
        @test freezevalue(x) == x
        @test_throws Exception freezevalue(x)[1] = 1
        if ndims(x) == 1
            @test push!(freezevalue(x), 333) == vcat(x, [333])
        end

        z = freezevalue(x)
        x[1] = 111
        @test z[1] != 111

        if ndims(x) == 1
            push!(x, 333)
            @test z[end] != 333
        end
    end
end

@testset "freezeindex" begin
    @testset for x in Any[[1, 2], [1 2; 3 4]]
        if x isa Matrix
            @test freezeindex(x) === x
        else
            @test parent(freezeindex(x)) !== x  # (copy)
        end
        @test parent(freezeindex(move!(x))) === x  # (no copy)
        @test freezeindex(x) == x
        @test_throws Exception push!(freezeindex(x), 333)

        x0 = copy(x)
        z = freezeindex(x)
        z[1] = 111
        @test z[1] == 111
        @test z != x0
    end
end

@testset "melt" begin
    @testset for freezer in [readonly, freeze, freezeindex, freezevalue]
        @testset for x in Any[[1, 2], [1 2; 3 4]]
            z = freezer(x)

            @test melt(z) !== x
            @test melt(move!(z)) === parent(z)
            if freezer === readonly || (freezer == freezeindex && x isa Matrix)
                @test melt(move!(z)) === x
            else
                @test melt(move!(z)) !== x
            end

            a = melt(z)
            a[1] = 123
            @test z[1] != 123

            b = melt(move!(z))
            b[1] = 123
            @test z[1] == 123
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
