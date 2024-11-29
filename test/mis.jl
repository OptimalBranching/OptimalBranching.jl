using OptimalBranching
using OptimalBranchingMIS.EliminateGraphs, OptimalBranchingMIS.EliminateGraphs.Graphs
using Test

@testset "MIS" begin
    g = random_regular_graph(20, 3)
    p = MISProblem(g)
    bs = OptBranchingStrategy(TensorNetworkSolver(), IPSolver(), EnvFilter(), MinBoundarySelector(2), D3Measure())
    cfg = SolverConfig(MISReducer(), bs, Int)
    cfg_xiao = SolverConfig(XiaoReducer(), bs, Int)
    res = reduce_and_branch(p, cfg)
    res_xiao = reduce_and_branch(p, cfg_xiao)
    @test res.mis_size == mis2(EliminateGraph(g))
    @test res_xiao.mis_size == counting_xiao2013(g).mis_size
end
