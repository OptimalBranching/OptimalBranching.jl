using Test
using OptimalBranchingCore
using OptimalBranchingCore: bit_clauses
using OptimalBranchingCore.BitBasis
using GenericTensorNetworks
using OptimalBranchingCore: NumOfVariables, MockProblem, MockTableSolver

@testset "bit_clauses" begin
	tbl = BranchingTable(5, [
		[StaticElementVector(2, [0, 0, 1, 0, 0]), StaticElementVector(2, [0, 1, 0, 0, 0])],
		[StaticElementVector(2, [1, 0, 0, 1, 0])],
		[StaticElementVector(2, [0, 0, 1, 0, 1])],
	])

	bc = bit_clauses(tbl)
	@test bc[1][1].mask == 31
	@test bc[1][1].val == 4

	@test length(bc) == 3
	@test length(bc[1]) == 2
end

@testset "greedymerge large scale" begin
    n = 1000    # total number of variables
    p = MockProblem(rand(Bool, n))

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
