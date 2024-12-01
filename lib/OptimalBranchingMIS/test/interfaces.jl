using OptimalBranchingMIS
using EliminateGraphs, EliminateGraphs.Graphs
using Test
using Random
Random.seed!(1234)

@testset "mis_size" begin
    g = random_regular_graph(60, 3)
    @test mis_size(g) == mis2(EliminateGraph(g))
    @test mis_branch_count(g)[1] == mis2(EliminateGraph(g))
end
