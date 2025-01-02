using Test
using OptimalBranchingCore
using OptimalBranchingCore: bit_clauses
using OptimalBranchingCore.BitBasis
using GenericTensorNetworks

@testset "bit_clauses" begin
	tbl = BranchingTable(5, [
		[StaticElementVector(2, [0, 0, 1, 0, 0]), StaticElementVector(2, [0, 1, 0, 0, 0])],
		[StaticElementVector(2, [1, 0, 0, 1, 0])],
		[StaticElementVector(2, [0, 0, 1, 0, 1])],
	])

	bc = bit_clauses(tbl)
end