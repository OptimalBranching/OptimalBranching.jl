using OptimalBranchingCore, GenericTensorNetworks
using OptimalBranchingCore: subcovers_naive
using Test

@testset "constructing subcovers" begin
    tbl = BranchingTable(5, [
        [StaticElementVector(2, [0, 0, 1, 0, 0]), StaticElementVector(2, [0, 1, 0, 0, 0])],
        [StaticElementVector(2, [1, 0, 0, 1, 0])],
        [StaticElementVector(2, [0, 0, 1, 0, 1])]
    ])
    scs = subcovers(tbl)
    scs_naive = subcovers_naive(tbl)
    @test length(scs) == length(scs_naive)
    for sc in scs
        @test sc in scs_naive
    end
end