using Test
using OptimalBranchingMIS
using OptimalBranchingCore
using OptimalBranchingMIS.Graphs

@testset "KaHyParSelector" begin
    g = random_regular_graph(20, 3; seed = 2134)
    mis1, count1 = mis_branch_count(g)

    bs = BranchingStrategy(table_solver = TensorNetworkSolver(), selector = KaHyParSelector(15), measure = D3Measure())
    misk, countk = mis_branch_count(g; branching_strategy = bs)
    @test mis1 == misk
end

@testset "NaiveBranch" begin
    g = random_regular_graph(20, 3; seed = 2134)
    mis1, count1 = mis_branch_count(g)

    bs = BranchingStrategy(table_solver = TensorNetworkSolver(), selector = KaHyParSelector(15), measure = D3Measure(), set_cover_solver = OptimalBranchingCore.NaiveBranch())
    miskn, countkn = mis_branch_count(g; branching_strategy = bs)
    @test mis1 == miskn
end
