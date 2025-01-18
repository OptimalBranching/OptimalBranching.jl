using OptimalBranchingCore
using Test, Documenter

@testset "algebra" begin
    include("algebra.jl")
end

@testset "bit basis" begin
    include("bitbasis.jl")
end

@testset "branching_table" begin
    include("branching_table.jl")
end

@testset "branch" begin
    include("branch.jl")
end

@testset "set covering" begin
    include("setcovering.jl")
end

@testset "greedymerge" begin
    include("greedymerge.jl")
end

@testset "mockproblem" begin
    include("mockproblem.jl")
end

Documenter.doctest(OptimalBranchingCore; manual=false)
