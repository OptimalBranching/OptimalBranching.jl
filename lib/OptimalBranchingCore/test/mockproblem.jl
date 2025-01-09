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

@testset "greedymerge" begin
    n = 1000    # total number of variables
    p = MockProblem(n)

    nvars = 18  # number of variables to be selected
    variables = [1:nvars...]

    # get the branching table
    table_solver = MockTableSolver(1000)
    tbl = branching_table(p, table_solver, variables)
    candidates = OptimalBranchingCore.bit_clauses(tbl)

    m = NumOfVariables()
    # the bottleneck is the call to the `findmin` function in the `greedymerge` function
    result = OptimalBranchingCore.greedymerge(candidates, p, variables, m)
    @test length(tbl.table)^(1/nvars) > result.γ
end

