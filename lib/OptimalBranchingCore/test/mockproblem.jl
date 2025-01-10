using OptimalBranchingCore, Test
using OptimalBranchingCore: NumOfVariables, MockProblem, MockTableSolver

@testset "mockproblem" begin
    n = 10
    p = MockProblem(n)
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