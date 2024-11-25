using OptimalBranchingMIS, EliminateGraphs, EliminateGraphs.Graphs
using OptimalBranchingCore
using Test

@testset "mis" begin
    for n in [20, 30, 40]
        for d in [3,4]
            g = random_regular_graph(n, d)

            mis_exact = mis2(EliminateGraph(g))
            p = MISProblem(g)

            for solver in [IPSolver(10), LPSolver(10)], measure in [D3Measure(), NumOfVertices()], pruner in [EnvFilter(), NoPruner()]
                bs = OptBranchingStrategy(TensorNetworkSolver(), solver, pruner, MinBoundarySelector(2), measure)

                cfg = SolverConfig(MISReducer(), bs, MISSize)

                cfg_count = SolverConfig(MISReducer(), bs, MISCount)

                res = branch(p, cfg)
                res_count = branch(p, cfg_count)

                @test res.mis_size == res_count.mis_size == mis_exact
            end
        end
    end
end