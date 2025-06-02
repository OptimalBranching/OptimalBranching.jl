using OptimalBranchingCore, GenericTensorNetworks, NLsolve
using Test

@testset "constructing candidate_clauses" begin
    function all_clauses_naive(n::Int, bss::AbstractVector{Vector{INT}}) where INT
        allclauses = Vector{Clause{INT}}()
        for ids in Iterators.product([0:length(bss[i]) for i in 1:length(bss)]...)
            masks = [ids...]
            cbs = [bss[i][masks[i]] for i in 1:length(bss) if masks[i] != 0]
            if length(cbs) > 0
                ccbs = cover_clause(n, cbs)
                if !(ccbs in allclauses) && (ccbs.mask != 0)
                    push!(allclauses, ccbs)
                end
            end
        end
        return allclauses
    end
    function subcovers_naive(tbl::BranchingTable{INT}) where{INT}
        n, bs = tbl.bit_length, tbl.table
        allclauses = all_clauses_naive(n, bs)
        subsets = Vector{Vector{Int}}()
        for (i, c) in enumerate(allclauses)
            ids = OptimalBranchingCore.covered_items(bs, c)
            push!(subsets, ids)
        end
        return subsets
    end

    # Return a clause that covers all the bit strings.
    function cover_clause(n::Int, bitstrings::AbstractVector{INT}) where INT
        mask = OptimalBranchingCore.bmask(INT, 1:n)
        for i in 1:length(bitstrings) - 1
            mask &= bitstrings[i] ⊻ OptimalBranchingCore.flip_all(n, bitstrings[i+1])
        end
        val = bitstrings[1] & mask
        return Clause(mask, val)
    end

    tbl = BranchingTable(5, [
        [StaticElementVector(2, [0, 0, 1, 0, 0]), StaticElementVector(2, [0, 1, 0, 0, 0])],
        [StaticElementVector(2, [1, 0, 0, 1, 0])],
        [StaticElementVector(2, [0, 0, 1, 0, 1])]
    ])
    is_valid, gamma = test_rule(tbl, DNF([Clause(2, 1)]), OptimalBranchingCore.MockProblem(rand(Bool, 5)), OptimalBranchingCore.NumOfVariables(), collect(1:5))
    @test is_valid
    @test gamma == 1.0
    clauses = OptimalBranchingCore.candidate_clauses(tbl)
    subsets = [OptimalBranchingCore.covered_items(tbl.table, c) for c in clauses]
    subsets_naive = subcovers_naive(tbl)
    @test length(subsets) == length(subsets_naive)
    for sc in subsets
        @test sc in subsets_naive
    end
end

@testset "complexity" begin
    for k=1:100
        bv = rand(1:10, 5)
        f = x -> sum(x[1]^(-i) for i in bv) - 1.0
        sol = nlsolve(f, [1.0]).zero[1]
        if sol <= 2.0   # complexity_bv may fail for sol > 2.0!
            @test OptimalBranchingCore.complexity_bv(bv) ≈ sol
        end
    end
end
