using OptimalBranching
using OptimalBranchingMIS.EliminateGraphs, OptimalBranchingMIS.EliminateGraphs.Graphs
using Test

@testset "MIS" begin
    g = random_regular_graph(40, 3)
    p = MISProblem(g)
    bs = BranchingStrategy(; table_solver=TensorNetworkSolver(; prune_by_env=true), set_cover_solver=IPSolver(), selector=MinBoundarySelector(2), measure=D3Measure())
    res = reduce_and_branch(p, bs, MISReducer(), MaxSize)
    res_xiao = reduce_and_branch(p, bs, XiaoReducer(), MaxSize)
    res_no = reduce_and_branch(p, bs, NoReducer(), MaxSize)
    mis_size = mis2(EliminateGraph(g))
    @test res.size == mis_size
    @test res_xiao.size == counting_xiao2013(g).size
    @test res_no.size == mis_size
end
