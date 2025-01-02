using OptimalBranchingCore, GenericTensorNetworks
using OptimalBranchingCore.BitBasis
using Test

@testset "branching table" begin
    tbl_1 = BranchingTable(5, [
        [StaticElementVector(2, [0, 0, 1, 0, 0]), StaticElementVector(2, [0, 1, 0, 0, 0])],
        [StaticElementVector(2, [1, 0, 0, 1, 0])],
        [StaticElementVector(2, [0, 0, 1, 0, 1])]
    ])

    tbl_2 = BranchingTable(5, [
        [StaticElementVector(2, [0, 1, 0, 0, 0]), StaticElementVector(2, [0, 0, 1, 0, 0])],
        [StaticElementVector(2, [1, 0, 0, 1, 0])],
        [StaticElementVector(2, [0, 0, 1, 0, 1])]
    ])
    @test tbl_1 == tbl_2

    println(tbl_1)
end