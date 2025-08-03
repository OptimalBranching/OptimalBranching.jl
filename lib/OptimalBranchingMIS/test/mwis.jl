using GenericTensorNetworks
using Test, Random

using OptimalBranchingMIS
using OptimalBranchingMIS: find_critical_set, find_independent_critical_set, heavy_vertex_vmap, heavy_pair_vmap, module_vmap, confined_pair_vmap, alternative_vertex_vmap, alternative_path_cycle_vmap, isolated_vertex_vmap, counting_xiao2021

function graph_from_edges(edges)
    return SimpleGraph(Graphs.SimpleEdge.(edges))
end

@testset "find_critical_set" begin
    g = graph_from_edges([(1,2),(1,3),(2,3),(2,4),(3,4),(3,5),(4,5)])
    weights = [1,1,1,1,1]
    critical_set = find_critical_set(g, weights)
    @test length(critical_set) == 0

    weights = [5,1,1,4,3]
    critical_set = find_critical_set(g, weights)
    @test critical_set == [1,4]
end

@testset "find_independent_critical_set" begin
    g = graph_from_edges([(1,2),(1,3),(2,3),(2,4),(3,4),(3,5),(4,5)])
    weights = [1,1,1,1,1]
    critical_independent_set = find_independent_critical_set(g, weights)
    @test length(critical_independent_set) == 0

    weights = [5,1,1,4,3]
    critical_independent_set = find_independent_critical_set(g, weights)
    @test critical_independent_set == [1,4]
end

@testset "heavy_vertex_vmap" begin
    g = graph_from_edges([(1,2),(1,3),(2,3),(2,4),(3,4),(3,5),(4,5)])
    weights = [1,1,1,1,1]
    g_new, weights_new, vmap = heavy_vertex_vmap(g, weights)
    @test length(weights_new) == 2
end

@testset "heavy_pair_vmap" begin    
    g = graph_from_edges([(1,2),(2,3),(3,4),(3,5),(1,6),(1,7),(4,8)])
    weights = [2,1,3,1,1,1,1,1]
    g_new, weights_new, vmap = heavy_pair_vmap(g, weights)
    @test length(weights_new) == 1
end

@testset "module_vmap" begin    
    g = graph_from_edges([(1,4),(1,5),(2,4),(2,5),(3,4),(3,5),(1,6)])
    weights = [1,1,1,1,1,1]
    g_new, weights_new, vmap = module_vmap(g, weights)
    @test length(weights_new) == 5
    @test weights_new[4] == 2
end

@testset "confined_pair_vmap" begin
    g = graph_from_edges([(1,2),(2,3)])
    weights = [1,1,1]
    g_new, weights_new, vmap = confined_pair_vmap(g, weights)
    @test length(weights_new) == 2
    @test weights_new[2] == 2
end

@testset "alternative_vertex_vmap" begin
    g = graph_from_edges([(1,2),(1,3),(1,4),(1,5)])
    weights = [9,2,3,4,1]
    g_new, weights_new, vmap = alternative_vertex_vmap(g, weights)
    @test length(weights_new) == 1
    @test weights_new[1] == 1

    g = graph_from_edges([(1,2),(1,3),(1,4),(1,5)])
    weights = [9,2,3,4,1]
    g_new, weights_new, vmap = alternative_vertex_vmap(g, weights, 1)
    @test length(weights_new) == 1
    @test weights_new[1] == 1
end

@testset "alternative_path_cycle_vmap" begin
    g = graph_from_edges([(1,2),(2,3),(3,4),(1,5),(1,6),(4,7),(4,8)])
    weights = [4,3,2,1,1,1,1,1]
    g_new, weights_new, vmap = alternative_path_cycle_vmap(g, weights)
    @test length(weights_new) == 6
    @test weights_new[1] == 3
    @test has_edge(g_new, 1, 2)
    @test has_edge(g_new, 1, 3)
    @test has_edge(g_new, 1, 4)
  
    g = graph_from_edges([(1,2),(2,3),(3,4),(1,5),(1,6),(4,7),(4,8),(1,4)])
    weights = [4,3,2,0.5,1,1,1,1]
    g_new, weights_new, vmap = alternative_path_cycle_vmap(g, weights)
    @test length(weights_new) == 6
    @test weights_new[1] == 3
    @test has_edge(g_new, 1, 2)
    @test has_edge(g_new, 1, 3)
    @test has_edge(g_new, 1, 4)
end

@testset "isolated_vertex_vmap" begin
    g = graph_from_edges([(1,2),(1,3),(1,4),(1,5),(2,3),(2,4),(2,5),(3,4),(3,5),(4,5)])
    weights = [3,1,2,4,5]
    g_new, weights_new, vmap = isolated_vertex_vmap(g, weights)
    @test length(weights_new) == 2
    @test weights_new[1] == 1
    @test weights_new[2] == 2

    g = graph_from_edges([(1,2),(1,3),(1,4),(1,5),(2,3),(2,4),(2,5),(3,4),(3,5),(4,5)])
    weights = [3,1,2,4,5]
    g_new, weights_new, vmap = isolated_vertex_vmap(g, weights, 2)
    @test length(weights_new) == 4
    @test weights_new[1] == 2
    @test weights_new[2] == 1
    @test weights_new[3] == 3
    @test weights_new[4] == 4
end

@testset "mwis_algorithm" begin
    for seed in 10:10:60
        g = random_regular_graph(seed, 3)
        weights = rand(nv(g))
        problem = GenericTensorNetwork(IndependentSet(g, weights); optimizer = GreedyMethod())
        mwis_size_tn = solve(problem, SizeMax())[].n
        mwis_size_xiao = counting_xiao2021(g, weights).size
        @test isapprox(mwis_size_tn, mwis_size_xiao)

        g = random_regular_graph(seed, 3)
        weights = ones(nv(g))
        problem = GenericTensorNetwork(IndependentSet(g, weights); optimizer = GreedyMethod())
        mwis_size_tn = solve(problem, SizeMax())[].n
        mwis_size_xiao = counting_xiao2021(g, weights).size
        @test isapprox(mwis_size_tn, mwis_size_xiao)
    end
end

@testset "mwis_algorithm at branching leaves" begin
    g = graph_from_edges([(1,2)])
    weights =  [1,1]
    problem = GenericTensorNetwork(IndependentSet(g, weights); optimizer = GreedyMethod())
    mwis_size_tn = solve(problem, SizeMax())[].n
    mwis_size_xiao = counting_xiao2021(g, weights).size
    @test isapprox(mwis_size_tn, mwis_size_xiao)

    g = SimpleGraph(2)
    weights = [1,1]
    problem = GenericTensorNetwork(IndependentSet(g, weights); optimizer = GreedyMethod())
    mwis_size_tn = solve(problem, SizeMax())[].n
    mwis_size_xiao = counting_xiao2021(g, weights).size
    @test isapprox(mwis_size_tn, mwis_size_xiao)
end