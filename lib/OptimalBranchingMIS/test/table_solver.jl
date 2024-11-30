using OptimalBranchingMIS, OptimalBranchingMIS.OptimalBranchingCore, OptimalBranchingMIS.Graphs
using Test

@testset "pruner PH2" begin
    function tree_like_N3_neighborhood(g::SimpleGraph)
        for layer in 1:3
            for v in vertices(g)
                for _ = 1:(3-degree(g, v))
                    add_vertex!(g)
                    add_edge!(g, v, nv(g))
                end
            end
        end
        return g
    end

    
    vs = [1,2,3,4,5,6,7,8]
    measure = D3Measure()
    table_solver = TensorNetworkSolver(true)
    set_cover_solver = IPSolver()
    edges = [(1, 2), (1, 5), (2, 3), (2, 6), (3, 4), (4, 5), (5, 8), (6, 7), (7, 8)]
    branching_region = SimpleGraph(Graphs.SimpleEdge.(edges))
    graph = tree_like_N3_neighborhood(copy(branching_region))

    ovs = OptimalBranchingMIS.open_vertices(graph, vs)
    subg, vmap = induced_subgraph(graph, vs)
    tbl = OptimalBranchingMIS.reduced_alpha_configs(table_solver, subg, Int[findfirst(==(v), vs) for v in ovs])
    @test length(tbl.table) == 9

    problem = MISProblem(graph)
    pruned_tbl = OptimalBranchingMIS.prune_by_env(tbl, problem, vs)
    @test length(pruned_tbl.table) == 5
end