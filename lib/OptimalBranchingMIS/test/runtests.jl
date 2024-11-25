using OptimalBranchingMIS
using Test

@testset "branch" begin
    include("branch.jl")
end

@testset "graphs" begin
    include("graphs.jl")
end
