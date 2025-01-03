using OptimalBranchingMIS
using OptimalBranchingMIS.EliminateGraphs.Graphs
using Test
using Random
using OptimalBranchingCore
using OptimalBranchingCore.BitBasis
using GenericTensorNetworks
using OptimalBranchingCore: size_reduction, apply_branch

@testset "size_reduction" begin
    g = random_regular_graph(60, 3)
    vs = collect(1:20)
    cl = Clause(bit"1111111111", bit"1011010111")
    p = MISProblem(g)
    m = D3Measure()
    @test size_reduction(p, m, cl, vs) == measure(p, m) - measure(first(apply_branch(p, cl, vs)), m)
end


@testset "covered_by" begin
    tbl = BranchingTable(9, [
        [[0,0,0,0,0,1,1,0,0], [0,0,0,0,0,0,1,1,0]],
        [[0,0,0,0,1,1,1,0,0]],
        [[0,0,1,1,0,0,0,0,1], [0,0,1,1,0,1,0,0,0], [0,0,1,1,0,0,0,1,0]],
        [[0,0,1,1,1,0,0,0,1], [0,0,1,1,1,1,0,0,0]],
        [[0,1,0,0,0,0,1,1,0]],
        [[0,1,0,1,1,0,0,0,1]],
        [[0,1,1,0,1,0,0,0,1]],
        [[0,1,1,1,0,0,0,0,1], [0,1,1,1,0,0,0,1,0]],
        [[0,1,1,1,1,0,0,0,1]],
        [[1,0,0,0,0,0,1,1,0]],
        [[1,0,0,1,1,0,0,0,1]],
        [[1,0,1,0,1,0,0,0,1]],
        [[1,0,1,1,0,0,0,0,1], [1,0,1,1,0,0,0,1,0]],
        [[1,0,1,1,1,0,0,0,1]],
        [[1,1,0,0,0,0,1,1,0]],
        [[1,1,0,1,1,0,0,0,1]],
        [[1,1,1,0,1,0,0,0,1]],
        [[1,1,1,1,0,0,0,0,1], [1,1,1,1,0,0,0,1,0]],
        [[1,1,1,1,1,0,0,0,1]]
    ])
    clauses = OptimalBranchingCore.candidate_clauses(tbl)
    Δρ = [count_ones(c.mask) for c in clauses]
    result_ip = OptimalBranchingCore.minimize_γ(tbl, clauses, Δρ, IPSolver(max_itr = 10, verbose = false))
    @test OptimalBranchingCore.covered_by(tbl, result_ip.optimal_rule)

    p = MISProblem(random_regular_graph(20, 3))
    cls = OptimalBranchingCore.bit_clauses(tbl)
    clsf = OptimalBranchingCore.greedymerge(cls, p, [1, 2, 3, 4, 5], D3Measure())
    @test OptimalBranchingCore.covered_by(tbl, DNF(clsf))
end