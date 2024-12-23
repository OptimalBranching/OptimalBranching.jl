using Test
using OptimalBranchingSTN, OMEinsum, Yao
using OptimalBranchingSTN: branch_naive

@testset "branch naive" begin
    code = optein"ijkl, i, j, k, l -> "
    tensors = [zeros(Float64, 2, 2, 2, 2), rand(2), rand(2), rand(2), rand(2)]
    tensors[1][1, 1, 1, 1] = 0.1
    tensors[1][2, 2, 2, 2] = 0.2
    tn = TensorNetwork(code, tensors)
    branches = branch_naive(tn, 1)
    @test length(branches) == 2
    @test sum(dense_contract(branch)[] for branch in branches) == dense_contract(tn)[]
end
