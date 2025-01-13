using Test
using OptimalBranchingCore
using OptimalBranchingCore: ClauseTree,random_clausetree,bit_clauses,optimize_tree_sa!,slice_tree!
using OptimalBranchingMIS
using OptimalBranchingMIS.EliminateGraphs.Graphs
using GenericTensorNetworks
@testset "random_clausetree" begin
    edges = [(1, 4), (1, 5), (3, 4), (2, 5), (4, 5), (1, 6), (2, 7), (3, 8)]
    example_g = SimpleGraph(Graphs.SimpleEdge.(edges))
    p = MISProblem(example_g)
    tbl = BranchingTable(5, [
        [StaticElementVector(2, [0, 0, 0, 0, 1]), StaticElementVector(2, [0, 0, 0, 1, 0])],
        [StaticElementVector(2, [0, 0, 1, 0, 1])],
        [StaticElementVector(2, [0, 1, 0, 1, 0])],
        [StaticElementVector(2, [1, 1, 1, 0, 0])],
    ])
    cls = bit_clauses(tbl)
    tree = random_clausetree(cls,p,NumOfVertices(),[1, 2, 3, 4, 5])
    @test tree.size_re == 0
    @test tree.γ > 1
end

@testset "optimize_tree_sa!" begin
    edges = [(1, 4), (1, 5), (3, 4), (2, 5), (4, 5), (1, 6), (2, 7), (3, 8)]
    example_g = SimpleGraph(Graphs.SimpleEdge.(edges))
    p = MISProblem(example_g)
    tbl = BranchingTable(5, [
        [StaticElementVector(2, [0, 0, 0, 0, 1]), StaticElementVector(2, [0, 0, 0, 1, 0])],
        [StaticElementVector(2, [0, 0, 1, 0, 1])],
        [StaticElementVector(2, [0, 1, 0, 1, 0])],
        [StaticElementVector(2, [1, 1, 1, 0, 0])],
    ])
    cls = bit_clauses(tbl)
    tree = random_clausetree(cls,p,NumOfVertices(),[1, 2, 3, 4, 5])
    optimize_tree_sa!(tree,collect(0.01:0.05:15), 100, p, NumOfVertices(), [1, 2, 3, 4, 5])
    cls_f = Vector{typeof(cls[1][1])}()
    slice_tree!(tree, 1.08,cls_f)
end
# function optimize_tree_sa!(tree::ClauseTree, βs, niters, p::AbstractProblem, m::AbstractMeasure, variables)