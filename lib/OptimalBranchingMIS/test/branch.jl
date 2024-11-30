using OptimalBranchingMIS, EliminateGraphs, EliminateGraphs.Graphs
using OptimalBranchingCore
using Test, Random

@testset "mis" begin
    Random.seed!(1234)
    for n in [40]
        for d in [3,4]
            g = random_regular_graph(n, d)

            mis_exact = mis2(EliminateGraph(g))
            p = MISProblem(g)

            for set_cover_solver in [IPSolver(10, false), LPSolver(10, false)], measure in [D3Measure(), NumOfVertices()], reducer in [MISReducer(), XiaoReducer()], prune_by_env in [true, false]
                branching_strategy = BranchingStrategy(; set_cover_solver, table_solver=TensorNetworkSolver(; prune_by_env), selector=MinBoundarySelector(2), measure)
                res = reduce_and_branch(p, branching_strategy; reducer, result_type=MaxSize)
                res_count = reduce_and_branch(p, branching_strategy; reducer, result_type=MaxSizeBranchCount)

                @test res.size == res_count.size == mis_exact
            end
        end
    end
end