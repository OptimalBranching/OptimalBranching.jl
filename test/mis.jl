using OptimalBranching
using OptimalBranchingMIS.EliminateGraphs, OptimalBranchingMIS.EliminateGraphs.Graphs
using OptimalBranchingMIS
using GenericTensorNetworks
using Test

@testset "MIS" begin
    g = random_regular_graph(40, 3)
    p = MISProblem(g)
    bs = BranchingStrategy(; table_solver=TensorNetworkSolver(; prune_by_env=true), set_cover_solver=IPSolver(), selector=MinBoundarySelector(2), measure=D3Measure())
    res = branch_and_reduce(p, bs, BasicReducer(), MaxSize)
    res_xiao = branch_and_reduce(p, bs, XiaoReducer(), MaxSize)
    res_no = branch_and_reduce(p, bs, NoReducer(), MaxSize)
    mis_size = mis2(EliminateGraph(g))
    @test res.size == mis_size
    @test res_xiao.size == counting_xiao2013(g).size
    @test res_no.size == mis_size
end

@testset "MWIS" begin
    g = random_regular_graph(40, 3)
    weights = rand(Float64, nv(g))
    p = OptimalBranchingMIS.MISProblem(g, weights)
    bs = BranchingStrategy(; table_solver=TensorNetworkSolver(; prune_by_env=true), set_cover_solver=IPSolver(), selector=MinBoundarySelector(2), measure=D3Measure())
    res = branch_and_reduce(p, bs, BasicReducer(), MaxSize)
    res_no = branch_and_reduce(p, bs, NoReducer(), MaxSize)
    problem = GenericTensorNetwork(IndependentSet(g, weights); optimizer = TreeSA())
    mwis = solve(problem, SizeMax())[1].n
    @test isapprox(res.size, mwis)
    @test isapprox(res_no.size, mwis)
end
