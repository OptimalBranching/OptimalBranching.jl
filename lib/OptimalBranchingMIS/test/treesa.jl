using Test
using OptimalBranchingCore
using OptimalBranchingCore: ClauseTree,random_clausetree,bit_clauses,optimize_tree_sa!,slice_tree!
using OptimalBranchingMIS
using OptimalBranchingMIS.EliminateGraphs.Graphs
using GenericTensorNetworks
using Random
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

@testset "tcsc_diff and update_tree!" begin
    Random.seed!(1234)
    edges = [(1, 4), (1, 5), (3, 4), (2, 5), (4, 5), (1, 6), (2, 7), (3, 8)]
    example_g = SimpleGraph(Graphs.SimpleEdge.(edges))
    p = MISProblem(example_g)
    m = NumOfVertices()
    deciding_variables = [1, 2, 3, 4, 5]
    tbl = BranchingTable(5, [
        [StaticElementVector(2, [0, 0, 0, 0, 1]), StaticElementVector(2, [0, 0, 0, 1, 0])],
        [StaticElementVector(2, [0, 0, 1, 0, 1])],
        [StaticElementVector(2, [0, 1, 0, 1, 0])],
        [StaticElementVector(2, [1, 1, 1, 0, 0])],
    ])
    cls = bit_clauses(tbl)
    tree = random_clausetree(cls,p,m,deciding_variables)

    rule = 4
    γac, γacb, rs, cl, γab_old, γabc_old = OptimalBranchingCore.tcsc_diff(tree, rule, p, m, deciding_variables)

    tree2 = copy(tree)
    OptimalBranchingCore.update_tree!(tree, rule, γac, γacb, rs, cl)
end

@testset "optimize_tree_sa!" begin
    Random.seed!(1234)
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
    optimize_tree_sa!(tree,collect(1:5:500), 1000, p, NumOfVertices(), [1, 2, 3, 4, 5])
    cls_f = Vector{typeof(cls[1][1])}()
    reductions = Vector{Int}()
    slice_tree!(tree,1.1, cls_f, reductions)
end

@testset "optimal_branching_rule" begin
    edges = [(1, 4), (1, 5), (3, 4), (2, 5), (4, 5), (1, 6), (2, 7), (3, 8)]
    example_g = SimpleGraph(Graphs.SimpleEdge.(edges))
    p = MISProblem(example_g)
    tbl = BranchingTable(5, [
        [StaticElementVector(2, [0, 0, 0, 0, 1]), StaticElementVector(2, [0, 0, 0, 1, 0])],
        [StaticElementVector(2, [0, 0, 1, 0, 1])],
        [StaticElementVector(2, [0, 1, 0, 1, 0])],
        [StaticElementVector(2, [1, 1, 1, 0, 0])],
    ])
    ans = optimal_branching_rule(tbl, [1, 2, 3, 4, 5], p, NumOfVertices(), OptimalBranchingCore.TreeSA())
    @show ans
end

