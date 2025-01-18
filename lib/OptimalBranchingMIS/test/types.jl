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

    edges = [(1, 4), (1, 5), (3, 4), (2, 5), (4, 5), (1, 6), (2, 7), (3, 8)]
    example_g = SimpleGraph(Graphs.SimpleEdge.(edges))
    p = MISProblem(example_g)
    cl = Clause(bit"11111", bit"10000")
    vs = collect(1:5)
    m = D3Measure()
    @test size_reduction(p, m, cl, vs) == measure(p, m) - measure(first(apply_branch(p, cl, vs)), m)
end
