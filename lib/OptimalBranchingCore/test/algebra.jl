using OptimalBranchingCore, OptimalBranchingCore.BitBasis
using OptimalBranchingCore: compare_solutions, join_solutions
using Test

@testset "algebra" begin
    INT = LongLongUInt{2}
    a = SolutionAndCount(1, zero(INT), 1)
    b = SolutionAndCount(2, zero(INT), 1)
    c = compare_solutions(a, b)
    @test c.size == 2
    @test c.count == 2
    d = join_solutions(a, b)
    @test d.size == 3
    @test d.count == 1
end