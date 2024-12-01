using OptimalBranchingCore, GenericTensorNetworks
using OptimalBranchingCore: booleans, covered_by, ¬, ∧
using BitBasis
using Test

@testset "clause and dnf" begin
    c1 = Clause(bit"1110", bit"0000")
    c2 = Clause(bit"1110", bit"0001")
    c3 = Clause(bit"1110", bit"0010")
    c4 = Clause(bit"1100", bit"0001")
    @test c1 == c2
    @test c1 !== c3
    @test c1 !== c4

    dnf_1 = DNF(c1, c2, c3)
    dnf_2 = DNF(c1, c2, c4)
    dnf_3 = DNF(c1, c3, c2)
    @test !(dnf_1 == dnf_2)
    @test dnf_1 == dnf_3
    @test length(dnf_1) == 3

    cstr = bit"0011"
    @test bdistance(c2, c3) == 1
    @test bdistance(c2, cstr) == 1

    viz_dnf(dnf_1, [1, 2, 3, 4])
    viz_dnf(dnf_1, ['i', 'j', 'k', 'l'])
end

@testset "gather2" begin
    INT = LongLongUInt{1}
    mask = bmask(INT, 1:5)
    v1 = LongLongUInt{1}((0b00010,))
    v2 = LongLongUInt{1}((0b01001,))
    c1 = Clause(mask, v1)
    c2 = Clause(mask, v2)
    c3 = OptimalBranchingCore.gather2(5, c1, c2)
    @test c3 == Clause(LongLongUInt{1}((0b10100,)), LongLongUInt{1}((0b0,)))
end

@testset "satellite" begin
    tbl = BranchingTable(5, [
        [StaticElementVector(2, [0, 0, 1, 0, 0]), StaticElementVector(2, [0, 1, 0, 0, 0])],
        [StaticElementVector(2, [1, 0, 0, 1, 0])],
        [StaticElementVector(2, [0, 0, 1, 0, 1])]
    ])
    a, b, c, d, e = booleans(5)
    @test !covered_by(tbl, DNF(a ∧ ¬b))
    @test covered_by(tbl, DNF(a ∧ ¬b ∧ d ∧ ¬e, ∧(¬a, ¬b, c, ¬d)))
    @test covered_by(tbl, DNF(a ∧ ¬b ∧ d ∧ ¬e, ∧(¬a, ¬b, c, ¬d)))
    @test !covered_by(tbl, DNF(a ∧ ¬b ∧ d ∧ ¬e, ∧(¬a, ¬b, c, ¬d, e)))
    @test covered_by(tbl, DNF(a ∧ ¬b ∧ d ∧ ¬e, ∧(¬a, ¬b, c, ¬d, e), ∧(¬a, b, ¬c, ¬d, ¬e)))
end