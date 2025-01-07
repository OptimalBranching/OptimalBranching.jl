using Test
using OptimalBranchingMIS
using OptimalBranchingCore
using OptimalBranchingMIS.Graphs

@testset "kahypar" begin
    edges = [(1, 4), (1, 5), (3, 4), (2, 5), (4, 5), (1, 6), (2, 7), (3, 8)]
    example_g = SimpleGraph(Graphs.SimpleEdge.(edges))

    p = MISProblem(example_g)

    OptimalBranchingCore.select_variables(p, NumOfVertices(), KaHyParSelector(2))
    # OptimalBranchingCore.select_variables(p, NumOfVertices(), MinBoundarySelector(2))
end

@testset "KaHyParSelector" begin
    g = random_regular_graph(200, 3; seed = 2134)
    mis1, count1 = mis_branch_count(g)

    bs = BranchingStrategy(table_solver = TensorNetworkSolver(), selector = KaHyParSelector(15), measure = D3Measure())
    misk, countk = mis_branch_count(g; branching_strategy = bs)
    @show mis1, count1
    @show misk, countk
    @test mis1 == mis_num
end

@testset "GreedyMerge" begin
    g = random_regular_graph(200, 3; seed = 2134)
    bs = BranchingStrategy(table_solver = TensorNetworkSolver(), selector = KaHyParSelector(15), measure = D3Measure(), set_cover_solver = OptimalBranchingCore.GreedyMerge())
    miskg, countkg = mis_branch_count(g; branching_strategy = bs)
    @show miskg, countkg
end

@testset "NaiveBranch" begin
    g = random_regular_graph(200, 3; seed = 2134)
    bs = BranchingStrategy(table_solver = TensorNetworkSolver(), selector = KaHyParSelector(15), measure = D3Measure(), set_cover_solver = OptimalBranchingCore.NaiveBranch())
    miskn, countkn = mis_branch_count(g; branching_strategy = bs)
    @show miskn, countkn
end
