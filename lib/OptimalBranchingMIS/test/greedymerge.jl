using OptimalBranchingMIS
using OptimalBranchingMIS.EliminateGraphs.Graphs
using Test
using Random
using OptimalBranchingCore
using OptimalBranchingCore.BitBasis
using GenericTensorNetworks
using OptimalBranchingCore: bit_clauses
using OptimalBranchingCore: size_reduction, apply_branch
Random.seed!(1234)

# Example from arXiv:2412.07685 Fig. 1
@testset "GreedyMerge" begin
    edges = [(1, 4), (1, 5), (3, 4), (2, 5), (4, 5), (1, 6), (2, 7), (3, 8)]
    example_g = SimpleGraph(Graphs.SimpleEdge.(edges))
    p = MISProblem(example_g)
    tbl = BranchingTable(5, [
        [StaticElementVector(2, [0, 0, 0, 0, 1]), StaticElementVector(2, [0, 0, 0, 1, 0])],
        [StaticElementVector(2, [0, 0, 1, 0, 1])],
        [StaticElementVector(2, [0, 1, 0, 1, 0])],
        [StaticElementVector(2, [1, 1, 1, 0, 0])],
    ])
    cls = bit_clauses(tbl)
    res = OptimalBranchingCore.greedymerge(cls, p, [1, 2, 3, 4, 5], NumOfVertices())
    clsf = res.optimal_rule.clauses
    @test clsf[1].mask == cls[3][1].mask
    @test clsf[1].val == cls[3][1].val
    @test clsf[2].mask == cls[4][1].mask
    @test clsf[2].val == cls[4][1].val
    @test clsf[3].mask == 27
    @test clsf[3].val == 16
end

@testset "GreedyMerge" begin
    g = random_regular_graph(20, 3)
    mis_num, count2 = mis_branch_count(g)
    for reducer in [NoReducer(), MISReducer()]
        for measure in [D3Measure(), NumOfVertices()]
            bs = BranchingStrategy(table_solver = TensorNetworkSolver(), selector = MinBoundaryHighDegreeSelector(2, 6, 0), measure = measure, set_cover_solver = OptimalBranchingCore.GreedyMerge())
            mis1, count1 = mis_branch_count(g; branching_strategy = bs, reducer)
            @test mis1 == mis_num
        end
    end
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
    res = OptimalBranchingCore.greedymerge(cls, p, [1, 2, 3, 4, 5], D3Measure())
    @test OptimalBranchingCore.covered_by(tbl, res.optimal_rule)
end