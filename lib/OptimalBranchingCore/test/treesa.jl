using Test
using OptimalBranchingCore
using OptimalBranchingCore: ClauseTree,random_clausetree,bit_clauses
using GenericTensorNetworks


# @testset "random_clausetree" begin
#     tbl = BranchingTable(5, [
#         [StaticElementVector(2, [0, 0, 0, 0, 1]), StaticElementVector(2, [0, 0, 0, 1, 0])],
#         [StaticElementVector(2, [0, 0, 1, 0, 1])],
#         [StaticElementVector(2, [0, 1, 0, 1, 0])],
#         [StaticElementVector(2, [1, 1, 1, 0, 0])],
#     ])
# 	cls = bit_clauses(tbl)
#     tree = random_clausetree(5,cls)
#     @test length(tree.cl) == 0
#     @test tree isa ClauseTree
# end