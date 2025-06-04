using OptimalBranchingMIS, OptimalBranchingCore, OptimalBranchingMIS.Graphs
using KaHyPar
using OptimalBranchingCore: IPSolver
using OptimalBranchingMIS: clause_size, alpha, reduced_alpha
using ProblemReductions
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
    tbl = OptimalBranchingMIS.reduced_alpha_configs(table_solver, subg, UnitWeight(nv(subg)), Int[findfirst(==(v), vs) for v in ovs])
    @test length(tbl.table) == 9

    problem = MISProblem(graph)
    pruned_tbl = OptimalBranchingMIS.prune_by_env(tbl, problem, vs)
    @test length(pruned_tbl.table) == 5
end

@testset "clause_size" begin
    weights = [1.0, 2.0, 3.0, 4.0, 5.0]
    clause = 0b10100
    vertices = [1, 2, 3, 4, 5]
    @test clause_size(weights, clause, vertices) == 8.0
end

@testset "alpha tensor" begin
    g = SimpleGraph(Graphs.SimpleEdge.([(1,2), (2,3)])) 
    weights = ones(Float64, nv(g))
    openvertices = [1,3]
    alpha_tensor = alpha(g, weights, openvertices)
    @test alpha_tensor[1,2].n == 1

    alpha_tensor = alpha(g, UnitWeight(nv(g)), openvertices)
    @test alpha_tensor[1,2].n == 1

    reduced_alpha_tensor = reduced_alpha(g, weights, openvertices)
    @test reduced_alpha_tensor[1,2].n == -Inf

    reduced_alpha_tensor = reduced_alpha(g, UnitWeight(nv(g)), openvertices)
    @test reduced_alpha_tensor[1,2].n == -Inf
end

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
    weights = [1.1 for i in 1:nv(graph)]

    ovs = OptimalBranchingMIS.open_vertices(graph, vs)
    subg, vmap = induced_subgraph(graph, vs)
    tbl = OptimalBranchingMIS.reduced_alpha_configs(table_solver, subg, weights, Int[findfirst(==(v), vs) for v in ovs])
    @test length(tbl.table) == 9

    problem = MISProblem(graph, weights)
    pruned_tbl = OptimalBranchingMIS.prune_by_env(tbl, problem, vs)
    @test length(pruned_tbl.table) == 5
end

@testset "folding and refuction for degree-2" begin
    edges = [(1, 2), (1, 3), (2, 4), (3, 5)]
    graph = SimpleGraph(Graphs.SimpleEdge.(edges))
    measure = D3Measure()
    table_solver = TensorNetworkSolver(true)
    set_cover_solver = IPSolver()
    vs = [1,2,3]
    ovs = OptimalBranchingMIS.open_vertices(graph, vs)
    subg, vmap = induced_subgraph(graph, vs)

    weights = [1,1,1,0.2,0.3]
    tbl = OptimalBranchingMIS.reduced_alpha_configs(table_solver, subg, weights, Int[findfirst(==(v), vs) for v in ovs])
    @test length(tbl.table) == 2

    problem = MISProblem(graph, weights)
    pruned_tbl = OptimalBranchingMIS.prune_by_env(tbl, problem, vs)
    @test length(pruned_tbl.table) == 1

    weights = [1,0.7,0.7,0.2,0.3]
    tbl = OptimalBranchingMIS.reduced_alpha_configs(table_solver, subg, weights, Int[findfirst(==(v), vs) for v in ovs])
    @test length(tbl.table) == 2

    problem = MISProblem(graph, weights)
    pruned_tbl = OptimalBranchingMIS.prune_by_env(tbl, problem, vs)
    @test length(pruned_tbl.table) == 2
end