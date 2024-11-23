using OptimalBranchingCore, GenericTensorNetworks
using Test

@testset "setcover by JuMP" begin
    tbl = BranchingTable(5, [
        [StaticElementVector(2, [0, 0, 1, 0, 0]), StaticElementVector(2, [0, 1, 0, 0, 0])],
        [StaticElementVector(2, [1, 0, 0, 1, 0])],
        [StaticElementVector(2, [0, 0, 1, 0, 1])]
    ])
    scs = subcovers(tbl)
    dns = [count_ones(sc.clause.mask) for sc in scs]
    opt_ip, cx_ip = cover(scs, dns, IPSolver(10), verbose = false)
    opt_lp, cx_lp = cover(scs, dns, LPSolver(10), verbose = false)
    @test opt_ip == opt_lp
    @test cx_ip ≈ cx_lp ≈ 1.0
end
