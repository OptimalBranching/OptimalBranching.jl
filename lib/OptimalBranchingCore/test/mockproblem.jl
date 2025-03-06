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
    @test length(tbl.table) <= nsample + 1
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
    config = BranchingStrategy(table_solver=MockTableSolver(nsample),  measure=NumOfVariables(), selector=RandomSelector(16), set_cover_solver=NaiveBranch())
    res0 = branch_and_reduce(p, config, NoReducer(), MaxSizeBranchCount; show_progress=false)
    @test res0.size == 100

    config = BranchingStrategy(table_solver=MockTableSolver(nsample), measure=NumOfVariables(), selector=RandomSelector(16), set_cover_solver=IPSolver())
    @test branch_and_reduce(p, config, NoReducer(), MaxSize).size == 100
    res1 = branch_and_reduce(p, config, NoReducer(), MaxSizeBranchCount; show_progress=true)
    @test res1.size == 100
    @test res1.count < res0.count

    config = BranchingStrategy(table_solver=MockTableSolver(nsample),  measure=NumOfVariables(), selector=RandomSelector(16), set_cover_solver=LPSolver())
    res2 = branch_and_reduce(p, config, NoReducer(), MaxSizeBranchCount; show_progress=false)
    @test res2.size == 100
    @test res2.count < res0.count

    config = BranchingStrategy(table_solver=MockTableSolver(nsample),  measure=NumOfVariables(), selector=RandomSelector(16), set_cover_solver=GreedyMerge())
    res3 = branch_and_reduce(p, config, NoReducer(), MaxSizeBranchCount; show_progress=false)
    @test res3.size == 100
    @test res3.count < res0.count

    # gamma informed, let γ0 be 1.05
    config = BranchingStrategy(table_solver=MockTableSolver(nsample), measure=NumOfVariables(), selector=RandomSelector(16), set_cover_solver=IPSolver(max_itr=1, γ0=1.05))
    res4 = branch_and_reduce(p, config, NoReducer(), MaxSizeBranchCount; show_progress=false)
    @test res4.size == 100
    @test res4.count < res0.count

    @show res0.count, res1.count, res2.count, res3.count, res4.count
end
