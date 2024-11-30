using OptimalBranching
using OptimalBranchingMIS.EliminateGraphs, OptimalBranchingMIS.EliminateGraphs.Graphs
using Test

@testset "MIS" begin
    g = random_regular_graph(20, 3)
    p = MISProblem(g)
    bs = BranchingStrategy(; table_solver=TensorNetworkSolver(; prune_by_env=true), set_cover_solver=IPSolver(), selector=MinBoundarySelector(2), measure=D3Measure())
    res = reduce_and_branch(p, bs; reducer=MISReducer(), result_type=Int)
    res_xiao = reduce_and_branch(p, bs; reducer=XiaoReducer(), result_type=Int)
    @test res == counting_mis2(EliminateGraph(g)).mis_size
    @test res_xiao == counting_xiao2013(g).mis_size
end
