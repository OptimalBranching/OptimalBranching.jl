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

    # literals
    lts1 = literals(c1)
    @test length(lts1) == 3 && is_true_literal.(lts1) == [false, false, false]
    @test length(lts1) == 3 && is_false_literal.(lts1) == [true, true, true]
    lts2 = literals(c2)
    @test length(lts2) == 3 && is_true_literal.(lts2) == [false, false, false]
    @test length(lts2) == 3 && is_false_literal.(lts2) == [true, true, true]
    lts3 = literals(c3)
    @test length(lts3) == 3 && is_true_literal.(lts3) == [true, false, false]
    @test length(lts3) == 3 && is_false_literal.(lts3) == [false, true, true]
    lts4 = literals(c4)
    @test length(lts4) == 2 && is_true_literal.(lts4) == [false, false]
    @test length(lts4) == 2 && is_false_literal.(lts4) == [true, true]
    @test !is_true_literal(c1) && !is_false_literal(c1)

    dnf_1 = DNF(c1, c2, c3)
    dnf_2 = DNF(c1, c2, c4)
    dnf_3 = DNF(c1, c3, c2)
    @test !(dnf_1 == dnf_2)
    @test dnf_1 == dnf_3
    @test length(dnf_1) == 3

    cstr = bit"0011"
    @test bdistance(c2, c3) == 1
    @test bdistance(c2, cstr) == 1
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
    @test length(c3) == 2
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