using OptimalBranching
using OptimalBranchingMIS.EliminateGraphs, OptimalBranchingMIS.EliminateGraphs.Graphs
using Test

@testset "MIS" begin
    g = random_regular_graph(40, 3)
    p = MISProblem(g)
    bs = BranchingStrategy(; table_solver=TensorNetworkSolver(; prune_by_env=true), set_cover_solver=IPSolver(), selector=MinBoundarySelector(2), measure=D3Measure())
    res = reduce_and_branch(p, bs; reducer=MISReducer(), result_type=MaxSize)
    res_xiao = reduce_and_branch(p, bs; reducer=XiaoReducer(), result_type=MaxSize)
    @test res.size == counting_mis2(EliminateGraph(g)).size
    @test res_xiao.size == counting_xiao2013(g).size
end
