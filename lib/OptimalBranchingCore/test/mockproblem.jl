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
    @test branch_and_reduce(p, config, NoReducer(), MaxSize; show_progress=true).size == 100
end
