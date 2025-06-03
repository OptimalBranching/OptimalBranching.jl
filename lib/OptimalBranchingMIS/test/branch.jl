using OptimalBranchingMIS, EliminateGraphs, EliminateGraphs.Graphs
using KaHyPar
using OptimalBranchingCore
using Test, Random, GenericTensorNetworks

@testset "branch_and_reduce" begin
    @info "branch_and_reduce"
    Random.seed!(1234)
    g = random_regular_graph(30, 3)

    mis_exact = mis2(EliminateGraph(g))
    mis_xiao = counting_xiao2013(g).size
    p = MISProblem(g)

    for set_cover_solver in [IPSolver(max_itr = 10, verbose = false), LPSolver(max_itr = 10, verbose = false)], measure in [D3Measure(), NumOfVertices()], reducer in [NoReducer(), MISReducer(), XiaoReducer(), TensorNetworkReducer(), SubsolverReducer()], prune_by_env in [true, false], selector in [MinBoundarySelector(2), MinBoundaryHighDegreeSelector(2, 6, 0), MinBoundaryHighDegreeSelector(2, 6, 1)]
        @info "set_cover_solver = $set_cover_solver, measure = $measure, reducer = $reducer, prune_by_env = $prune_by_env, selector = $selector"
        branching_strategy = BranchingStrategy(; set_cover_solver, table_solver=TensorNetworkSolver(; prune_by_env), selector=selector, measure)
        res = branch_and_reduce(p, branching_strategy, reducer, MaxSize)
        res_count = branch_and_reduce(p, branching_strategy, reducer, MaxSizeBranchCount)

        @test res.size == res_count.size == mis_exact == mis_xiao
    end
end

@testset "branch_and_reduce for mwis" begin
    @info "branch_and_reduce"
    Random.seed!(1234)
    g = random_regular_graph(30, 3)
    weights = rand(Float64, nv(g))
    problem = GenericTensorNetwork(IndependentSet(g, weights); optimizer = TreeSA())
    mwis_exact = solve(problem, SizeMax())[1].n
    p = MISProblem(g, weights)

    for set_cover_solver in [IPSolver(max_itr = 10, verbose = false), LPSolver(max_itr = 10, verbose = false)], measure in [D3Measure(), NumOfVertices()], reducer in [NoReducer(), MWISReducer(), TensorNetworkReducer()], prune_by_env in [true, false], selector in [MinBoundarySelector(2), MinBoundaryHighDegreeSelector(2, 6, 0), MinBoundaryHighDegreeSelector(2, 6, 1)]
        @info "set_cover_solver = $set_cover_solver, measure = $measure, reducer = $reducer, prune_by_env = $prune_by_env, selector = $selector"
        branching_strategy = BranchingStrategy(; set_cover_solver, table_solver=TensorNetworkSolver(; prune_by_env), selector=selector, measure)
        res = branch_and_reduce(p, branching_strategy, reducer, MaxSize)
        res_count = branch_and_reduce(p, branching_strategy, reducer, MaxSizeBranchCount)

        @test isapprox(res.size, mwis_exact)
        @test isapprox(res_count.size, mwis_exact)
    end
end