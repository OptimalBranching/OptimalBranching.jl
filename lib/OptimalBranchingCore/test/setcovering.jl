using OptimalBranchingCore, GenericTensorNetworks
using Test

@testset "bisect_solve" begin
    f(x) = x^2 - 2
    @test OptimalBranchingCore.bisect_solve(f, 1.0, f(1.0), 2.0, f(2.0)) ≈ sqrt(2)
end

@testset "intersection of clauses" begin
    tbl = BranchingTable(5, [
        [[0, 1, 0, 1, 0], [0, 1, 1, 0, 0]],
        [[1, 1, 0, 1, 0]],
        [[0, 0, 1, 0, 1]]
    ])
    ct_dfs = OptimalBranchingCore.intersect_clauses(tbl, :dfs)
    ct_bfs = OptimalBranchingCore.intersect_clauses(tbl, :bfs)
    @test isempty(ct_dfs)
    @test isempty(ct_bfs)

    tbl = BranchingTable(5, [
        [[0, 1, 0, 1, 0], [0, 1, 1, 0, 0], [0, 0, 1, 0, 0]],
        [[1, 1, 0, 1, 0]],
        [[0, 0, 1, 0, 1], [0, 1, 1, 0, 1]]
    ])
    ct_dfs = OptimalBranchingCore.intersect_clauses(tbl, :dfs)
    ct_bfs = OptimalBranchingCore.intersect_clauses(tbl, :bfs)
    @test count_ones(ct_dfs[1].mask) == 1
    @test count_ones(ct_bfs[1].mask) == 1
end

@testset "setcover by JuMP - StaticBitVector type" begin
    tbl = BranchingTable(5, [
        [StaticBitVector([0, 0, 1, 0, 0]), StaticBitVector([0, 1, 0, 0, 0])],
        [StaticBitVector([1, 0, 0, 1, 0])],
        [StaticBitVector([0, 0, 1, 0, 1])]
    ])
    clauses = OptimalBranchingCore.candidate_clauses(tbl)
    Δρ = [count_ones(c.mask) for c in clauses]
    result_ip = OptimalBranchingCore.minimize_γ(tbl, clauses, Δρ, IPSolver(; max_itr = 10, verbose = false))
    result_lp = OptimalBranchingCore.minimize_γ(tbl, clauses, Δρ, LPSolver(; max_itr = 10, verbose = false))
    @test result_ip.branching_vector ≈ result_lp.branching_vector
    @test result_ip.γ ≈ result_lp.γ ≈ 1.0

    tbl = BranchingTable(5, [
        [StaticBitVector([0, 1, 0, 1, 0]), StaticBitVector([0, 1, 1, 0, 0])],
        [StaticBitVector([1, 1, 0, 1, 0])],
        [StaticBitVector([0, 0, 1, 0, 1])]
    ])
    clauses = OptimalBranchingCore.candidate_clauses(tbl)
    Δρ = [count_ones(c.mask) for c in clauses]
    result_ip = OptimalBranchingCore.minimize_γ(tbl, clauses, Δρ, IPSolver(; max_itr = 10, verbose = false))
    result_lp = OptimalBranchingCore.minimize_γ(tbl, clauses, Δρ, LPSolver(; max_itr = 10, verbose = false))
    @test result_ip.branching_vector ≈ result_lp.branching_vector
    @test result_ip.γ ≈ result_lp.γ ≈ 1.1673039782614185

    println(result_ip)
    println(result_lp)
end

@testset "setcover by JuMP - normal vector type" begin
    tbl = BranchingTable(5, [
        [[0, 1, 0, 1, 0], [0, 1, 1, 0, 0]],
        [[1, 1, 0, 1, 0]],
        [[0, 0, 1, 0, 1]]
    ])
    clauses = OptimalBranchingCore.candidate_clauses(tbl)
    Δρ = [count_ones(c.mask) for c in clauses]
    result_ip = OptimalBranchingCore.minimize_γ(tbl, clauses, Δρ, IPSolver(max_itr = 10, verbose = false))
    result_lp = OptimalBranchingCore.minimize_γ(tbl, clauses, Δρ, LPSolver(max_itr = 10, verbose = false))
    @test result_ip.branching_vector ≈ result_lp.branching_vector
    @test OptimalBranchingCore.covered_by(tbl, result_ip.optimal_rule)
    @test OptimalBranchingCore.covered_by(tbl, result_lp.optimal_rule)
    @test result_ip.γ ≈ result_lp.γ ≈ 1.1673039782614185
end

@testset "setcover - the corner case (exist a clause that covers all items)" begin
    tbl = BranchingTable(5, [
        [[0, 1, 0, 1, 0], [0, 1, 1, 0, 0]],
        [[1, 1, 0, 1, 0]],
        [[0, 0, 1, 1, 1]]
    ])
    clauses = OptimalBranchingCore.candidate_clauses(tbl)
    Δρ = [count_ones(c.mask) for c in clauses]
    result_ip = OptimalBranchingCore.minimize_γ(tbl, clauses, Δρ, IPSolver(max_itr = 10, verbose = false))
    @test OptimalBranchingCore.covered_by(tbl, result_ip.optimal_rule)
    @test result_ip.γ ≈ 1.0
end

@testset "weighted minimum signed exact cover" begin
    subsets = [[1], [2], [3], [4], [1, 2], [2, 3], [3, 4], [4, 5]]
    weights = collect(1:8.0)
    num_items = 5
    result_ip = OptimalBranchingCore.weighted_minimum_signed_exact_cover(IPSolver(max_itr = 10, verbose = false), weights, subsets, num_items, 10.0)
    @test result_ip ≈ [1.0, 1.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0]

    subsets = [[1, 2], [2], [2,3,4,5], [4], [2, 3], [3, 4], [4, 5]]
    weights = collect(1:7.0)
    num_items = 5
    result_ip = OptimalBranchingCore.weighted_minimum_signed_exact_cover(IPSolver(max_itr = 10, verbose = false), weights, subsets, num_items, 10.0)
    @test result_ip ≈ [1.0, -1.0, 1.0, 0.0, 0.0, 0.0, 0.0]
end