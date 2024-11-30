using OptimalBranchingCore, GenericTensorNetworks
using Test

@testset "setcover by JuMP - StaticBitVector type" begin
    tbl = BranchingTable(5, [
        [StaticBitVector([0, 0, 1, 0, 0]), StaticBitVector([0, 1, 0, 0, 0])],
        [StaticBitVector([1, 0, 0, 1, 0])],
        [StaticBitVector([0, 0, 1, 0, 1])]
    ])
    scs = OptimalBranchingCore.candidate_clauses(tbl)
    dns = [count_ones(sc.clause.mask) for sc in scs]
    opt_ip, cx_ip = OptimalBranchingCore.minimize_γ(3, scs, dns, IPSolver(; max_itr = 10, verbose = false))
    opt_lp, cx_lp = OptimalBranchingCore.minimize_γ(3, scs, dns, LPSolver(; max_itr = 10, verbose = false))
    @test opt_ip == opt_lp
    @test cx_ip ≈ cx_lp ≈ 1.0
end

@testset "setcover by JuMP - normal vector type" begin
    tbl = BranchingTable(5, [
        [[0, 0, 1, 0, 0], [0, 1, 0, 0, 0]],
        [[1, 0, 0, 1, 0]],
        [[0, 0, 1, 0, 1]]
    ])
    scs = OptimalBranchingCore.candidate_clauses(tbl)
    dns = [count_ones(sc.clause.mask) for sc in scs]
    opt_ip, cx_ip = OptimalBranchingCore.minimize_γ(3, scs, dns, IPSolver(max_itr = 10, verbose = false))
    opt_lp, cx_lp = OptimalBranchingCore.minimize_γ(3, scs, dns, LPSolver(max_itr = 10, verbose = false))
    @test opt_ip == opt_lp
    @test OptimalBranchingCore.covered_by(tbl, DNF(getfield.(scs[opt_ip], :clause)))
    @test OptimalBranchingCore.covered_by(tbl, DNF(getfield.(scs[opt_lp], :clause)))
    @test cx_ip ≈ cx_lp ≈ 1.0
end
