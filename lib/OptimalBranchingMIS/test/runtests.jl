using OptimalBranchingMIS
using Test

@testset "branch" begin
    include("branch.jl")
end

@testset "graphs" begin
    include("graphs.jl")
end

@testset "mis" begin
    include("mis.jl")
end

@testset "pruner" begin
    include("pruner.jl")
end
