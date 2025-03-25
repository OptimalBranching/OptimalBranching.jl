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


@testset "update region list via vmap" begin
    for g in [random_regular_graph(1000, 3), SimpleGraph(GenericTensorNetworks.random_diagonal_coupled_graph(50, 50, 0.8))]
        region_list = Dict{Int, Tuple{Vector{Int}, Vector{Int}}}()
        for i in 1:nv(g)
            n = OptimalBranchingMIS.closed_neighbors(g, [i])
            nn = OptimalBranchingMIS.open_neighbors(g, n)
            region_list[i] = (n, nn)
        end

        removed_vertices = unique!(rand(1:nv(g), 10))
        sub_g, vmap = OptimalBranchingMIS.remove_vertices_vmap(g, removed_vertices)

        mapped_region_list = OptimalBranchingMIS.update_region_list(region_list, vmap)
        
        for (v, (n, nn)) in mapped_region_list
            @test n == OptimalBranchingMIS.closed_neighbors(sub_g, [v])
            @test nn == OptimalBranchingMIS.open_neighbors(sub_g, n)
        end
    end
end