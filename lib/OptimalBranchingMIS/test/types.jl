using OptimalBranchingMIS
using OptimalBranchingMIS.EliminateGraphs.Graphs
using Test
using Random
using OptimalBranchingCore
using OptimalBranchingCore.BitBasis
using GenericTensorNetworks
using OptimalBranchingCore: size_reduction

@testset "size_reduction" begin
    g = random_regular_graph(60, 3)
    vs = collect(1:20)
    cl = Clause(bit"1111111111", bit"1011010111")
    size_reduction(MISProblem(g),D3Measure(),cl,vs)
end