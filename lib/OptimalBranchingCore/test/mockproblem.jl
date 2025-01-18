using OptimalBranchingCore, Test
using OptimalBranchingCore: NumOfVariables, MockProblem, MockTableSolver, RandomSelector

@testset "mockproblem" begin
    n = 10
    p = MockProblem(rand(Bool, n))
    m = NumOfVariables()
    @test measure(p, m) == n
    nb = 5
    nsample = 9
    table_solver = MockTableSolver(nsample)
    tbl = branching_table(p, table_solver, 1:nb)
    @test tbl.bit_length == nb
    @test length(tbl.table) <= nsample
    @test all(length.(tbl.table) .== 1)

    table_solver = MockTableSolver(nsample, 1.0)
    tbl = branching_table(p, table_solver, 1:nb)
    @test tbl.bit_length == nb
    @test length(tbl.table) <= nsample
    @test all(length.(tbl.table) .> 10)
end

@testset "branch_and_reduce" begin
    n = 100
    nsample = 3
    p = MockProblem(rand(Bool, n))
    config = BranchingStrategy(table_solver=MockTableSolver(nsample), measure=NumOfVariables(), selector=RandomSelector(16))
    res1 = branch_and_reduce(p, config; show_progress=true)
    @test res1.size == 100
    @test read_solution(n, res1) == p.optimal

    config = BranchingStrategy(table_solver=MockTableSolver(nsample),  measure=NumOfVariables(), selector=RandomSelector(16), set_cover_solver=NaiveBranch())
    res2 = branch_and_reduce(p, config; show_progress=true)
    @test read_solution(n, res2) == p.optimal
    @test res1.count < res2.count

    config = BranchingStrategy(table_solver=MockTableSolver(nsample),  measure=NumOfVariables(), selector=RandomSelector(16), set_cover_solver=GreedyMerge())
    res3 = branch_and_reduce(p, config; show_progress=true)
    @test read_solution(n, res3) == p.optimal
    @test res2.count > res3.count

    @show res1.count, res2.count, res3.count
end
