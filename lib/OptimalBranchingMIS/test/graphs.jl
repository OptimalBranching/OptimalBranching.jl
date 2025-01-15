using OptimalBranchingCore
using OptimalBranchingMIS, EliminateGraphs.Graphs
using Test

using OptimalBranchingMIS: neighbor_cover, reduced_alpha, reduced_alpha_configs, graph_from_tuples, collect_configs
using GenericTensorNetworks

@testset "graphs from tuple" begin
    @testset "graph_from_tuples" begin
        g = graph_from_tuples(4, [(1, 2), (2, 3), (3, 4)])
        @test nv(g) == 4
        @test ne(g) == 3
    end
end

@testset "neighbor cover" begin
    g = smallgraph(:petersen)
    @test length(neighbor_cover(g, 1, 0)[1]) == 1
    @test length(neighbor_cover(g, 1, 0)[2]) == 1
    @test length(neighbor_cover(g, 1, 1)[1]) == 4
    @test length(neighbor_cover(g, 1, 1)[2]) == 3
    @test length(neighbor_cover(g, 1, 2)[1]) == 10
    @test length(neighbor_cover(g, 1, 2)[2]) == 0
end

@testset "reduced alpha" begin
    g = graph_from_tuples(3, [(1, 2), (2, 3), (3, 1)])
    @test reduced_alpha(g, [1, 2]) == Tropical.([1 -Inf; -Inf -Inf])

    cfgs = OptimalBranchingMIS._reduced_alpha_configs(g, [1, 2], nothing)
    @test count(!iszero, cfgs) == 1
    @test collect_configs.(cfgs, Ref("abc")) == reshape([["c"], String[], String[], String[]], 2, 2)
    @test collect_configs.(cfgs) == reshape([[BitVector((0, 0, 1))], [], [], []], 2, 2)
    @test BranchingTable(cfgs) == BranchingTable(3, [[StaticElementVector(2, [0, 0, 1])]])
end

@testset "graph_product" begin
    bs = BranchingStrategy(table_solver = TensorNetworkSolver(), selector = KaHyParSelector(15), measure = D3Measure())

    c7 = cycle_graph(7)
    @test mis_size(c7) == 3

    g2 = OptimalBranchingMIS.graph_product(c7, c7)
    @test mis_size(g2) == 10

    g3 = OptimalBranchingMIS.graph_product(g2, c7)
    # @test mis_size(g3;branching_strategy=bs) == 33
end