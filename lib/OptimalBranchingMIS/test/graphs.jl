using OptimalBranchingCore, OptimalBranchingMIS
using EliminateGraphs, EliminateGraphs.Graphs
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

@testset "kernelize" begin
    function kernelize(g::SimpleGraph, reducer::TensorNetworkReducer; verbose::Int = 0, vmap::Vector{Int} = collect(1:nv(g)))
        (verbose ≥ 2) && (@info "kernelizing graph: $(nv(g)) vertices, $(ne(g)) edges")
        r = 0
    
        vmap_0 = vmap
    
        while true
            res = OptimalBranchingMIS.reduce_graph(g, reducer, vmap_0 = vmap_0) # res = (g_new, r_new, vmap_new)
            vmap_0 = res[3]
            vmap = vmap[res[3]]
            r += res[2]
            if g == res[1]
                (verbose ≥ 2) && (@info "kernelized graph: $(nv(g)) vertices, $(ne(g)) edges")
                return (g, r, vmap)
            end
            g = res[1]
        end
    end

    g = random_regular_graph(100, 3)
    reducer = TensorNetworkReducer()
    gk, r, _ = kernelize(g, reducer)
    @test nv(gk) ≤ nv(g)
    @test nv(gk) == length(reducer.region_list)

    @test mis2(EliminateGraph(gk)) + r == mis2(EliminateGraph(g))
    
    reducer = TensorNetworkReducer()
    gkk, _, _ = kernelize(gk, reducer)
    @test gkk == gk
end