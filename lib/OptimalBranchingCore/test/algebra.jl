using OptimalBranchingCore
using Test

@testset "algebra" begin
    @test MaxSize(1) + MaxSize(2) == MaxSize(2)
    @test MaxSize(1) * MaxSize(2) == MaxSize(3)
    @test zero(MaxSize) == MaxSize(0)

    @test MaxSizeBranchCount(1) + MaxSizeBranchCount(2) == MaxSizeBranchCount(2, 2)
    @test MaxSizeBranchCount(1) * MaxSizeBranchCount(2) == MaxSizeBranchCount(3, 1)
    @test zero(MaxSizeBranchCount) == MaxSizeBranchCount(0, 1)
end