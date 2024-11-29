using OptimalBranchingCore, GenericTensorNetworks
using Test

@testset "setcover by JuMP - StaticBitVector type" begin
    tbl = BranchingTable(5, [
        [StaticBitVector([0, 0, 1, 0, 0]), StaticBitVector([0, 1, 0, 0, 0])],
        [StaticBitVector([1, 0, 0, 1, 0])],
        [StaticBitVector([0, 0, 1, 0, 1])]
    ])
    scs = subcovers(tbl)
    dns = [count_ones(sc.clause.mask) for sc in scs]
    opt_ip, cx_ip = cover(scs, dns, IPSolver(; max_itr = 10, verbose = false))
    opt_lp, cx_lp = cover(scs, dns, LPSolver(; max_itr = 10, verbose = false))
    @test opt_ip == opt_lp
    @test cx_ip ≈ cx_lp ≈ 1.0
end

@testset "setcover by JuMP - normal vector type" begin
    tbl = BranchingTable(5, [
        [[0, 0, 1, 0, 0], [0, 1, 0, 0, 0]],
        [[1, 0, 0, 1, 0]],
        [[0, 0, 1, 0, 1]]
    ])
    scs = subcovers(tbl)
    dns = [count_ones(sc.clause.mask) for sc in scs]
    opt_ip, cx_ip = minimum_γ(scs, dns, IPSolver(max_itr = 10, verbose = false))
    opt_lp, cx_lp = minimum_γ(scs, dns, LPSolver(max_itr = 10, verbose = false))
    @test opt_ip == opt_lp
    @test cx_ip ≈ cx_lp ≈ 1.0
end
