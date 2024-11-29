using OptimalBranchingCore, GenericTensorNetworks
using Test

@testset "constructing candidate_clauses" begin
    function all_clauses_naive(n::Int, bss::AbstractVector{Vector{INT}}) where INT
        allclauses = Vector{Clause{INT}}()
        for ids in Iterators.product([0:length(bss[i]) for i in 1:length(bss)]...)
            masks = [ids...]
            cbs = [bss[i][masks[i]] for i in 1:length(bss) if masks[i] != 0]
            if length(cbs) > 0
                ccbs = OptimalBranchingCore.cover_clause(n::Int, cbs)
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
        allcovers = Vector{CandidateClause{INT}}()
        for (i, c) in enumerate(allclauses)
            ids = OptimalBranchingCore.covered_items(bs, c)
            push!(allcovers, CandidateClause(ids, c))
        end
        return allcovers
    end

    tbl = BranchingTable(5, [
        [StaticElementVector(2, [0, 0, 1, 0, 0]), StaticElementVector(2, [0, 1, 0, 0, 0])],
        [StaticElementVector(2, [1, 0, 0, 1, 0])],
        [StaticElementVector(2, [0, 0, 1, 0, 1])]
    ])
    scs = OptimalBranchingCore.candidate_clauses(tbl)
    scs_naive = subcovers_naive(tbl)
    @test length(scs) == length(scs_naive)
    for sc in scs
        @test sc in scs_naive
    end
end