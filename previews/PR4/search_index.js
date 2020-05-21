var documenterSearchIndex = {"docs":
[{"location":"#Mutabilities.jl-1","page":"Mutabilities.jl","title":"Mutabilities.jl","text":"","category":"section"},{"location":"#","page":"Mutabilities.jl","title":"Mutabilities.jl","text":"","category":"page"},{"location":"#","page":"Mutabilities.jl","title":"Mutabilities.jl","text":"Mutabilities\nMutabilities.readonly\nMutabilities.freeze\nMutabilities.move!\nMutabilities.meltproperties","category":"page"},{"location":"#Mutabilities","page":"Mutabilities.jl","title":"Mutabilities","text":"Mutabilities: a type-level tool for ownership-by-convention\n\n(Image: Dev) (Image: GitHub Actions)\n\nMutabilities.jl is a type-level tool for describing mutabilities and ownership of objects in a composable manner.\n\nSee more in the documentation.\n\nSummary\n\nreadonly: create read-only view\nfreeze, freezevalue, freezeindex, freezeproperties: create immutable copies\nmelt, meltvalue, meltindex, meltproperties: create mutable copies\nmove!: manually elides copies with freeze/melt APIs.\n\nHigh-level interface\n\nRead-only view\n\nThe most easy-to-use interface is readonly(x) which creates a read-only \"view\" to x:\n\njulia> using Mutabilities\n\njulia> x = [1, 2, 3];\n\njulia> z = readonly(x)\n3-element readonly(::Array{Int64,1}) with eltype Int64:\n 1\n 2\n 3\n\njulia> z[1] = 111\nERROR: setindex! not defined for Mutabilities.ReadOnlyArray{Int64,1,Array{Int64,1}}\n\nNote that changes in x would still be reflected to z:\n\njulia> x[1] = 111;\n\njulia> z\n3-element readonly(::Array{Int64,1}) with eltype Int64:\n 111\n   2\n   3\n\nFreeze/melt\n\nUse freeze(x) to get an independent immutable (shallow) copy of x:\n\njulia> x = [1, 2, 3];\n\njulia> z = freeze(x)\n3-element freeze(::Array{Int64,1}) with eltype Int64:\n 1\n 2\n 3\n\njulia> x[1] = 111;\n\njulia> z\n3-element freeze(::Array{Int64,1}) with eltype Int64:\n 1\n 2\n 3\n\nfreeze can be reverted by melt:\n\njulia> y = melt(z)\n3-element Array{Int64,1}:\n 1\n 2\n 3\n\nIt returns an independent mutable (shallow) copy of y.  Thus, y can be safely mutated:\n\njulia> y[1] = 111;\n\njulia> z\n3-element freeze(::Array{Int64,1}) with eltype Int64:\n 1\n 2\n 3\n\nExample usage\n\nJulia's view is dangerous to use if the indices can be mutated after creating it:\n\nidx = [1, 1, 1]\nx = view([1], idx)\nx[1]  # OK\nidx[1] = 10_000_000_000\nx[1]  # segfault\n\nThis can be avoided by freezing the index array:\n\nview([1], freeze(idx))\n\nNote that readonly is not enough.\n\nVariants\n\nfreeze and melt work both on indices (keys) and values.  It is possible to create an append-only vector by freezing the values:\n\njulia> append_only = freezevalue([1, 2, 3]);\n\njulia> push!(append_only, 4)\n4-element freezevalue(::Array{Int64,1}) with eltype Int64:\n 1\n 2\n 3\n 4\n\njulia> append_only[1] = 1\nERROR: setindex! not defined for Mutabilities.AppendOnlyVector{Int64,Array{Int64,1}}\n\nIt is possible to create a shape-frozen vector by freezing the indices:\n\njulia> shape_frozen = freezeindex([1, 2, 3])\n3-element freezeindex(::Array{Int64,1}) with eltype Int64:\n 1\n 2\n 3\n\njulia> shape_frozen .*= 10\n3-element freezeindex(::Array{Int64,1}) with eltype Int64:\n 10\n 20\n 30\n\njulia> push!(shape_frozen, 4)\nERROR: push! on freezeindex(::Array{Int64,1}) not allowed\n\nLow-level interface\n\nUsing freeze and melt at API boundaries is a good way to ensure correctness of the programs.  However, until the julia compiler gets a borrow checker and automatically elides such copies, it may be very expensive to use them in some situations.  Until then, Mutabilities.jl provides an \"escape hatch\"; i.e., an API to let the programmer declare that there is no sharing of the given object:\n\njulia> z = freeze(move!([1, 2, 3]))  # no copy\n3-element freeze(::Array{Int64,1}) with eltype Int64:\n 1\n 2\n 3\n\njulia> melt(move!(z))  # no copy\n3-element Array{Int64,1}:\n 1\n 2\n 3\n\nThis allows Julia programs to compose well, without defining immutable f and mutable f! variants of the API and without documenting the particular memory ownership for each function.\n\nFor example, melt is simply defined as\n\nmelt(x) = meltvalue(move!(meltindex(x)))\n\nmove! can be useful when, e.g., input values can be re-used for output values:\n\njulia> function add(x, y)\n           out = melt(x)\n           out .+= y\n           return freeze(out)\n       end;\n\njulia> add(move!(ones(3)), ones(3))  # allocates two arrays, not three\n3-element freeze(::Array{Float64,1}) with eltype Float64:\n 2.0\n 2.0\n 2.0\n\nSupported collections and types\n\nAbstractArray\nAbstractDict\nAbstractSet\nData types (\"plain struct\")\n\nInterop\n\nStaticArrays\n\nStatic arrays are converted to appropriate types instead of the wrapper arrays:\n\njulia> using StaticArrays\n\njulia> a = SA[1, 2, 3]\n3-element SArray{Tuple{3},Int64,1,3} with indices SOneTo(3):\n 1\n 2\n 3\n\njulia> melt(a)\n3-element Array{Int64,1}:\n 1\n 2\n 3\n\njulia> meltvalue(a)\n3-element MArray{Tuple{3},Int64,1,3} with indices SOneTo(3):\n 1\n 2\n 3\n\njulia> freeze(MVector(1, 2, 3))  # or freezevalue\n3-element SArray{Tuple{3},Int64,1,3} with indices SOneTo(3):\n 1\n 2\n 3\n\nStructArrays\n\nMutabilities.jl is aware of mutability of each field arrays wrapped in struct arrays:\n\njulia> using StructArrays\n\njulia> x = StructArray(a = 1:3);  # x.a is not mutable\n\njulia> y = melt(x)\n3-element StructArray(::Array{Int64,1}) with eltype NamedTuple{(:a,),Tuple{Int64}}:\n (a = 1,)\n (a = 2,)\n (a = 3,)\n\njulia> y.a\n3-element Array{Int64,1}:\n 1\n 2\n 3\n\njulia> z = freeze(StructArray(a = [1, 2, 3]))\n3-element freeze(StructArray(::Array{Int64,1})) with eltype NamedTuple{(:a,),Tuple{Int64}}:\n (a = 1,)\n (a = 2,)\n (a = 3,)\n\njulia> z.a\n3-element freeze(::Array{Int64,1}) with eltype Int64:\n 1\n 2\n 3\n\nRelated packages\n\nhttps://github.com/andyferris/Freeze.jl\nhttps://github.com/bkamins/ReadOnlyArrays.jl\n\n\n\n\n\n","category":"module"},{"location":"#Mutabilities.readonly","page":"Mutabilities.jl","title":"Mutabilities.readonly","text":"readonly(x) -> z\n\nCreate a read-only view of x.  Mutations on x are reflected to z.\n\n\n\n\n\n","category":"function"},{"location":"#Mutabilities.freeze","page":"Mutabilities.jl","title":"Mutabilities.freeze","text":"melt(z) -> x\nmeltvalue(z) -> x\nmeltindex(z) -> x\nfreeze(x) -> z\nfreezevalue(x) -> z\nfreezeindex(x) -> z\n\nmelt and meltvalue create a mutable copy of x.  freeze, freezevalue, and freezeindex create an immutable copy of x.\n\nThe result of melt(::AbstractVector) is appendable. The result of meltvalue(::AbstractVector) may not be appendable.  meltindex undoes freezeindex.\n\nfreezevalue only freezes the existing values and it is still possible to append the new items to z.  freezeindex only freezes the indices and it is still possible to mutate the values.\n\nUse, e.g., freeze(move!(x)) and melt(move!(z)) to freeze or melt the values without creating a copy (see also move!).\n\nreadonly can also be used to create a read-only view without creating a copy and without asserting strict absence of ownership.\n\nExamples\n\njulia> using Mutabilities\n\njulia> z = freeze([1, 2, 3])\n3-element freeze(::Array{Int64,1}) with eltype Int64:\n 1\n 2\n 3\n\njulia> z[1] = 111\nERROR: setindex! not defined for Mutabilities.ImmutableArray{Int64,1,Array{Int64,1}}\n\njulia> y = melt(z)\n3-element Array{Int64,1}:\n 1\n 2\n 3\n\n\n\n\n\n","category":"function"},{"location":"#Mutabilities.move!","page":"Mutabilities.jl","title":"Mutabilities.move!","text":"move!(x)\n\nManually declare that the object x has no other owners and the object x is not going to be used by the caller.\n\nExamples\n\njulia> using Mutabilities\n\njulia> x = [];\n\njulia> melt(move!(freeze(move!(x)))) === x\ntrue\n\njulia> melt(move!(freeze(x))) === x\nfalse\n\njulia> melt(freeze(move!(x))) === x\nfalse\n\nnote: Note\nAbove examples intentionally violate the rule for using move! to show how it works.  When x is passed to move! on the left hand side, it is not allowed to use x on the right hand side of ===.\n\n\n\n\n\n","category":"function"},{"location":"#Mutabilities.meltproperties","page":"Mutabilities.jl","title":"Mutabilities.meltproperties","text":"meltproperties(z) -> x\nfreezeproperties(x) -> z\n\nmeltproperties on an immutable data type (struct) object creates a mutable handle z to it.  This can be unwrapped using freezeproperties to obtain the \"mutated\" immutable object.\n\nExamples\n\njulia> using Mutabilities\n\njulia> x = meltproperties(1 + 2im)\nmutable handle to 1 + 2im\n\njulia> x.re *= 100;\n\njulia> x\nmutable handle to 100 + 2im\n\njulia> freezeproperties(x) :: Complex{Int}\n100 + 2im\n\njulia> x = meltproperties((a = 1, b = 2))\nmutable handle to (a = 1, b = 2)\n\njulia> x.a = 123;\n\njulia> freezeproperties(x)\n(a = 123, b = 2)\n\n\n\n\n\n","category":"function"}]
}
