using EliminateGraphs, EliminateGraphs.Graphs
using Test, Random

using OptimalBranchingMIS
using OptimalBranchingMIS: find_children, find_family, unconfined_vertices, confined_set, is_line_graph, first_twin, twin_filter!, short_funnel_filter!, desk_filter!, effective_vertex, all_three_funnel, all_four_funnel, rho, optimal_four_cycle, optimal_vertex, has_fine_structure, count_o_path, closed_neighbors, is_complete_graph, twin_filter_vmap, short_funnel_filter_vmap, desk_filter_vmap

function graph_from_edges(edges)
    return SimpleGraph(Graphs.SimpleEdge.(edges))
end

@testset "find_children and find_family" begin
    g = graph_from_edges([(1,2),(2,3), (1,4), (2,5), (3,5)])
    @test find_children(g, [1]) == [2, 4]
    @test find_children(g, [1,2,3]) == [4]
    @test find_family(g, [1]) == ([2, 4], [1, 1])
    @test find_family(g, [1,2,3]) == ([4], [1])
end

@testset "find_family with weights" begin
    g = graph_from_edges([(1,4), (2,4), (2,3), (4,5)])
    weights = [1, 2, 3, 4, 5]
    @test find_family(g, [1], weights) == ([4], [[1]])
    @test find_family(g, [1,2,3], weights) == ([4], [[1,2]])
end

@testset "line graph" begin
    edges = [(1,2),(1,4),(1,5),(2,3),(2,4),(2,5),(3,4),(3,5)]
    example_g = SimpleGraph(Graphs.SimpleEdge.(edges))
    @test is_lg = is_line_graph(example_g) == true

    edges = [(1,2),(1,4),(1,5),(2,3),(2,4),(2,5),(3,4),(3,5),(4,5)]
    example_g = SimpleGraph(Graphs.SimpleEdge.(edges))
    @test is_lg = is_line_graph(example_g) == false
end

@testset "confined set and unconfined vertices" begin
    # via dominated rule
    g = graph_from_edges([(1, 2),(1,3),(1, 4), (2, 3), (2, 4), (2, 6), (3, 5), (4, 5)])
    @test unconfined_vertices(g) == [2]
    @test unconfined_vertices(g, ones(nv(g))) == [2]
    @test Set(confined_set(g, [1])) == Set([1, 5, 6])
    @test Set(confined_set(g, ones(nv(g)), [1])) == Set([1, 5, 6])
   
    # via roof
    g = graph_from_edges([(1, 2), (1, 5), (1, 6), (2, 5), (2, 3), (4, 5), (3, 4), (3, 7), (4, 7)])
    @test in(1, unconfined_vertices(g))
    @test in(1, unconfined_vertices(g, ones(nv(g))))
    @test Set(confined_set(g, [6])) == Set([6])
    @test Set(confined_set(g, ones(nv(g)), [6])) == Set([6])

    g = graph_from_edges([(1,4), (2,4), (2,3), (4,5)])
    weights = [1, 2, 3, 4, 1]
    @test unconfined_vertices(g, weights) == [1, 2, 5]
    @test Set(confined_set(g, weights, [4])) == Set([4])
end

@testset "twin" begin
    # xiao2013 fig.2(a)
    edges = [(1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5), (4, 5), (3, 6), (3, 7), (4, 8), (5, 9), (5, 10)]
    example_g = SimpleGraph(Graphs.SimpleEdge.(edges))
 
    @test first_twin(example_g) == (1, 2)
    example_g_new, vmap = twin_filter_vmap(example_g)
    @test twin_filter!(example_g)
    @test ne(example_g) == ne(example_g_new) == 0
    @test nv(example_g) == nv(example_g_new) == 5

    #xiao2013 fig.2(b)
    edges = [(1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5), (3, 6), (3, 7), (4, 8), (5, 9), (5, 10)]
    example_g = SimpleGraph(Graphs.SimpleEdge.(edges))
    @test first_twin(example_g) == (1, 2)
    example_g_new, vmap = twin_filter_vmap(example_g)
    @test twin_filter!(example_g)
    @test ne(example_g) == ne(example_g_new) == 5
    @test nv(example_g) == nv(example_g_new) == 6
end

@testset "short funnel" begin
    edges = [(1, 2), (1, 4), (1, 5), (2, 3), (2, 6), (3, 6), (4, 6)]
    example_g = SimpleGraph(Graphs.SimpleEdge.(edges))
    example_g_new, vmap = short_funnel_filter_vmap(example_g)
    @test short_funnel_filter!(example_g)
    @test ne(example_g) == ne(example_g_new) == 5
    @test nv(example_g) == nv(example_g_new) == 4

    # xiao2013 fig.2(c)
    edges = [(1, 2), (1, 3), (1, 4), (2, 5), (2, 6), (3, 4), (3, 7), (4, 5), (4, 8), (5, 10), (6, 9)]
    example_g = SimpleGraph(Graphs.SimpleEdge.(edges))
    example_g_new, vmap = short_funnel_filter_vmap(example_g)
    @test short_funnel_filter!(example_g)
    @test nv(example_g) == nv(example_g_new) == 8
    @test ne(example_g) == ne(example_g_new) == 9
end

@testset "desk" begin
    edges = [(1, 2), (1, 4), (1, 8), (2, 3), (2, 7), (3, 8), (5, 7), (6, 8), (7, 8)]
    example_g = SimpleGraph(Graphs.SimpleEdge.(edges))
    example_g_new, vmap = desk_filter_vmap(example_g)
    @test desk_filter!(example_g)
    @test ne(example_g) == ne(example_g_new) == 4
    @test nv(example_g) == nv(example_g_new) == 4

    #xiao2013 fig.2(d)
    edges = [(1, 2), (1, 4), (1, 5), (2, 3), (2, 6), (3, 4), (3, 5), (3, 7), (4, 8), (5, 9), (6, 10), (7, 11), (8, 12)]
    example_g = SimpleGraph(Graphs.SimpleEdge.(edges))
    example_g_new, vmap = desk_filter_vmap(example_g)
    @test desk_filter!(example_g)
    @test nv(example_g) == nv(example_g_new) == 8
    @test ne(example_g) == ne(example_g_new) == 8
end

@testset "effective vertex" begin
    function is_effective_vertex(g::SimpleGraph, a::Int, S_a::Vector{Int})
        g_copy = copy(g)
        rem_vertices!(g_copy, closed_neighbors(g, S_a))
        degree(g,a) == 3 && all(degree(g,n) == 3 for n in neighbors(g,a)) && rho(g) - rho(g_copy) >= 20
    end
    Random.seed!(2)
    g = random_regular_graph(1000, 3)
    a, S_a = effective_vertex(g)
    @test is_effective_vertex(g, a, S_a)
end

@testset "funnel" begin
    function is_n_funnel(g::SimpleGraph, n::Int, a::Int, b::Int)
        degree(g,a) == n && is_complete_graph(g, setdiff(neighbors(g,a), [b]))
    end

    edges = [(1, 2), (1, 3), (1, 4), (3, 4)]
    g = SimpleGraph(Graphs.SimpleEdge.(edges))
    three_funnels = all_three_funnel(g)
    @test three_funnels == [(1, 2)]
    @test is_n_funnel(g, 3, 1, 2)

    edges = [(1, 2), (1, 3), (1, 4), (1, 5), (3, 4), (3, 5), (4, 5)]
    g = SimpleGraph(Graphs.SimpleEdge.(edges))
    four_funnels = all_four_funnel(g)
    @test four_funnels == [(1, 2)]
    @test is_n_funnel(g, 4, 1, 2)
end

@testset "o_path" begin
    edges = [(1, 2), (2, 3), (3, 4), (1, 5), (1, 6), (3, 7)]
    example_g = SimpleGraph(Graphs.SimpleEdge.(edges))
    o_path_num = count_o_path(example_g)
    @test o_path_num == 1

    edges = [(1, 2), (2, 3), (3, 4), (1, 5), (1, 6), (4, 7), (4, 8)]
    example_g = SimpleGraph(Graphs.SimpleEdge.(edges))
    o_path_num = count_o_path(example_g)
    @test o_path_num == 0
end

@testset "fine_structure" begin
    edges = [(1, 2), (2, 3), (3, 4), (1, 5), (1, 6), (3, 7)]
    example_g = SimpleGraph(Graphs.SimpleEdge.(edges))
    @test has_fine_structure(example_g) == true

    edges = [(1, 2), (1, 3), (1, 4), (2, 3), (2, 7), (3, 8), (4, 5), (4, 6)]
    example_g = SimpleGraph(Graphs.SimpleEdge.(edges))
    @test has_fine_structure(example_g) == true

    edges = [(1, 2), (2, 3), (3, 4), (1, 5), (1, 6), (4, 7), (4, 8)]
    example_g = SimpleGraph(Graphs.SimpleEdge.(edges))
    @test has_fine_structure(example_g) == false
end

@testset "four_cycle" begin
    edges = [(1, 2), (2, 3), (3, 4), (4, 1), (1, 5)]
    example_g = SimpleGraph(Graphs.SimpleEdge.(edges))
    opt_quad = optimal_four_cycle(example_g)
    @test opt_quad == [1, 2, 3, 4]

    edges = [(1, 2), (2, 3), (3, 4), (4, 1), (3, 5), (4, 6), (5, 6), (1, 7)]
    example_g = SimpleGraph(Graphs.SimpleEdge.(edges))
    opt_quad = optimal_four_cycle(example_g)
    @test opt_quad == [1, 2, 3, 4]
end

@testset "optimal vertex" begin
    edges = [(1, 2), (2, 6), (1, 3), (3, 7), (1, 4), (4, 8), (1, 5), (5, 9)]
    example_g = SimpleGraph(Graphs.SimpleEdge.(edges))
    v = optimal_vertex(example_g)
    @test v == 1
end

@testset "mis_algorithm" begin
    for seed in 10:10:60
        g = random_regular_graph(seed, 3)
        eg = EliminateGraph(g)
        mis_size_standard = mis2(eg)
        mis_size_mis1 = counting_mis1(g).size
        mis_size_mis2 = counting_mis2(g).size
        mis_size_xiao = counting_xiao2013(g).size
        mis_size_ip = ip_mis(g)
        @test mis_size_standard == mis_size_mis1 == mis_size_mis2 == mis_size_xiao == mis_size_ip
    end
end