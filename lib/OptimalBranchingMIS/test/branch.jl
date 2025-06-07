using OptimalBranchingMIS, EliminateGraphs, EliminateGraphs.Graphs
using OptimalBranchingMIS: graph_from_tuples, reduce_graph
using KaHyPar
using OptimalBranchingCore
using Test, Random, GenericTensorNetworks

@testset "branch_and_reduce" begin
    @info "branch_and_reduce"
    Random.seed!(1234)
    g_rrg = random_regular_graph(30, 3)
    g_ksg = SimpleGraph(GenericTensorNetworks.random_diagonal_coupled_graph(6, 6, 0.8))
    for g in [g_rrg, g_ksg]
        mis_exact = mis2(EliminateGraph(g))
        mis_xiao = counting_xiao2013(g).size
        p = MISProblem(g)

        for set_cover_solver in [IPSolver(max_itr = 10, verbose = false), LPSolver(max_itr = 10, verbose = false)], measure in [D3Measure(), NumOfVertices()], reducer in [NoReducer(), BasicReducer(), XiaoReducer(), TensorNetworkReducer(sub_reducer=NoReducer()), TensorNetworkReducer()], prune_by_env in [true, false], selector in [MinBoundarySelector(2), MinBoundaryHighDegreeSelector(2, 6, 0), MinBoundaryHighDegreeSelector(2, 6, 1)]
            @info "set_cover_solver = $set_cover_solver, measure = $measure, reducer = $reducer, prune_by_env = $prune_by_env, selector = $selector"
            branching_strategy = BranchingStrategy(; set_cover_solver, table_solver=TensorNetworkSolver(; prune_by_env), selector=selector, measure)
            res = branch_and_reduce(p, branching_strategy, reducer, MaxSize)
            res_count = branch_and_reduce(p, branching_strategy, reducer, MaxSizeBranchCount)

            @test res.size == res_count.size == mis_exact == mis_xiao
        end
    end
end

@testset "branch_and_reduce for subsolver" begin
    @info "branch_and_reduce for subsolver"
    Random.seed!(1234)
    g = random_regular_graph(30, 3)

    mis_exact = mis2(EliminateGraph(g))
    mis_xiao = counting_xiao2013(g).size
    p = MISProblem(g)

    for subsolver in [:mis2, :xiao, :ip]
        @info "subsolver = $subsolver"
        branching_strategy = BranchingStrategy(; set_cover_solver=IPSolver(max_itr = 10, verbose = false), table_solver=TensorNetworkSolver(), selector=MinBoundaryHighDegreeSelector(2, 6, 0), measure=D3Measure())
        res = branch_and_reduce(p, branching_strategy, SubsolverReducer(; subsolver), MaxSize)
        res_count = branch_and_reduce(p, branching_strategy, SubsolverReducer(; subsolver), MaxSizeBranchCount)

        @test res.size == res_count.size == mis_exact == mis_xiao
    end
end

@testset "branch_and_reduce for mwis" begin
    Random.seed!(1234)
    g_rrg = random_regular_graph(30, 3)
    g_ksg = SimpleGraph(GenericTensorNetworks.random_diagonal_coupled_graph(6, 6, 0.8))
    for g in [g_rrg, g_ksg]
        @info "branch_and_reduce, weights = ones"
        weights = ones(Float64, nv(g))
        problem = GenericTensorNetwork(IndependentSet(g, weights); optimizer = TreeSA())
        mwis_exact = solve(problem, SizeMax())[1].n
        p = MISProblem(g, weights)

        for set_cover_solver in [IPSolver(max_itr = 10, verbose = false), LPSolver(max_itr = 10, verbose = false)], measure in [D3Measure(), NumOfVertices()], reducer in [NoReducer(), BasicReducer(), TensorNetworkReducer(sub_reducer=NoReducer()), TensorNetworkReducer()], prune_by_env in [true, false], selector in [MinBoundarySelector(2), MinBoundaryHighDegreeSelector(2, 6, 0), MinBoundaryHighDegreeSelector(2, 6, 1)]
            @info "set_cover_solver = $set_cover_solver, measure = $measure, reducer = $reducer, prune_by_env = $prune_by_env, selector = $selector"
            branching_strategy = BranchingStrategy(; set_cover_solver, table_solver=TensorNetworkSolver(; prune_by_env), selector=selector, measure)
            res = branch_and_reduce(p, branching_strategy, reducer, MaxSize)
            res_count = branch_and_reduce(p, branching_strategy, reducer, MaxSizeBranchCount)

            @test isapprox(res.size, mwis_exact)
            @test isapprox(res_count.size, mwis_exact)
        end

        @info "branch_and_reduce, weights = random"
        weights = rand(Float64, nv(g))
        problem = GenericTensorNetwork(IndependentSet(g, weights); optimizer = TreeSA())
        mwis_exact = solve(problem, SizeMax())[1].n
        p = MISProblem(g, weights)

        for set_cover_solver in [IPSolver(max_itr = 10, verbose = false), LPSolver(max_itr = 10, verbose = false)], measure in [D3Measure(), NumOfVertices()], reducer in [NoReducer(), BasicReducer(), TensorNetworkReducer(sub_reducer=NoReducer()), TensorNetworkReducer()], prune_by_env in [true, false], selector in [MinBoundarySelector(2), MinBoundaryHighDegreeSelector(2, 6, 0), MinBoundaryHighDegreeSelector(2, 6, 1)]
            @info "set_cover_solver = $set_cover_solver, measure = $measure, reducer = $reducer, prune_by_env = $prune_by_env, selector = $selector"
            branching_strategy = BranchingStrategy(; set_cover_solver, table_solver=TensorNetworkSolver(; prune_by_env), selector=selector, measure)
            res = branch_and_reduce(p, branching_strategy, reducer, MaxSize)
            res_count = branch_and_reduce(p, branching_strategy, reducer, MaxSizeBranchCount)

            @test isapprox(res.size, mwis_exact)
            @test isapprox(res_count.size, mwis_exact)
        end
    end
end

@testset "leaves of the branching tree" begin
    g0 = graph_from_tuples(0, [])
    g1 = graph_from_tuples(1, [])
    g2 = graph_from_tuples(2, [(1, 2)])
    branching_strategy = BranchingStrategy(; set_cover_solver=IPSolver(max_itr = 10, verbose = false), table_solver=TensorNetworkSolver(), selector=MinBoundaryHighDegreeSelector(2, 6, 0), measure=D3Measure())
    
    for g in [g0, g1, g2]
        problem = GenericTensorNetwork(IndependentSet(g); optimizer = TreeSA())
        mis_exact = solve(problem, SizeMax())[1].n
        p = MISProblem(g)
        res = branch_and_reduce(p, branching_strategy, BasicReducer(), MaxSize)
        res_count = branch_and_reduce(p, branching_strategy, BasicReducer(), MaxSizeBranchCount)
        res_reduction = reduce_graph(p.g, p.weights, BasicReducer())
        @test res.size == res_count.size == mis_exact
        @test res_reduction.r == mis_exact

        weights = rand(Float64, nv(g))
        problem = GenericTensorNetwork(IndependentSet(g, weights); optimizer = TreeSA())
        mwis_exact = solve(problem, SizeMax())[1].n
        p = MISProblem(g, weights)
        res = branch_and_reduce(p, branching_strategy, BasicReducer(), MaxSize)
        res_count = branch_and_reduce(p, branching_strategy, BasicReducer(), MaxSizeBranchCount)
        res_reduction = reduce_graph(p.g, p.weights, BasicReducer())
        @test res.size == res_count.size == mwis_exact
        @test res_reduction.r == mwis_exact
    end   
end