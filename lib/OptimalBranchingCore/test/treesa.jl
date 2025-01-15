using Test
using OptimalBranchingCore
using OptimalBranchingCore: ClauseTree,ruleset,update_tree!
using GenericTensorNetworks

@testset "rules" begin
    ClauseTree(Int)
    t1 = ClauseTree(ClauseTree(Int,1), ClauseTree(ClauseTree(Int,2), ClauseTree(Int,3),[Clause(0,0)], 10,10), [Clause(0,0)], 10,10)
    t2 = ClauseTree(ClauseTree(ClauseTree(Int,1), ClauseTree(Int,2),[Clause(0,0)], 10,10), ClauseTree(Int,3), [Clause(0,0)], 10,10)
    t3 = ClauseTree(ClauseTree(Int), ClauseTree(Int), [Clause(0,0)], 1,1)
    t4 = ClauseTree(ClauseTree(ClauseTree(Int,1), ClauseTree(Int,2),[Clause(0,0)], 1,1), ClauseTree(ClauseTree(Int,3), ClauseTree(Int,4),[Clause(0,0)], 1,1), [Clause(0,0)], 1,1)
    @test ruleset(t1) == 3:4
    @test ruleset(t2) == 1:2
    @test ruleset(t3) == 1:0
    @test ruleset(t4) == 1:4

    t11 = update_tree!(copy(t1), 3, 1, 2, 2, Clause(0,0))
    @test t11.left.size_re == 2
    @test t11.right.right.size_re == 3
    @test t11.right.left.size_re == 1

    t11_ = update_tree!(copy(t1), 4, 1, 2, 2, Clause(0,0))
    @test t11_.left.size_re == 3
    @test t11_.right.right.size_re == 1
    @test t11_.right.left.size_re == 2

    t22 = update_tree!(copy(t2), 1, 1, 2, 2, Clause(0,0))
    @test t22.left.left.size_re == 1
    @test t22.left.right.size_re == 3
    @test t22.right.size_re == 2

    t22_ = update_tree!(copy(t2), 2, 1, 2, 2, Clause(0,0))
    @test t22_.left.left.size_re == 3
    @test t22_.left.right.size_re == 2
    @test t22_.right.size_re == 1

    t44 = update_tree!(copy(t4), 1, 1, 2, 2, Clause(0,0))
    @test t44.left.left.size_re == 1
    @test t44.left.right.left.size_re == 3
    @test t44.left.right.right.size_re == 4
    @test t44.right.size_re == 2
end
