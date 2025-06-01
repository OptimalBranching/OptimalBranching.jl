using OptimalBranchingMIS
using EliminateGraphs, EliminateGraphs.Graphs
using Test
using Random
using GenericTensorNetworks
Random.seed!(1234)

@testset "mis_size" begin
    g = random_regular_graph(60, 3)
    @test mis_size(g) == mis2(EliminateGraph(g))
    @test mis_branch_count(g)[1] == mis2(EliminateGraph(g))
end

@testset "mwis_size" begin
    g = random_regular_graph(60, 3)
    weights = rand(Float64, nv(g))
    problem = GenericTensorNetwork(IndependentSet(g, weights); optimizer = TreeSA())
    mwis = solve(problem, SizeMax())[1].n
    @test abs(mwis_size(g, weights) - mwis) < 1e-12
    @test abs(mwis_branch_count(g, weights)[1] - mwis) < 1e-12

    weights = ones(Int64, nv(g))
    problem = GenericTensorNetwork(IndependentSet(g, weights); optimizer = TreeSA())
    mwis = solve(problem, SizeMax())[1].n
    @test mwis_size(g, weights) == mwis
    @test mwis_branch_count(g, weights)[1] == mwis
end
