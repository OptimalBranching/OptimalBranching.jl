using OptimalBranchingCore
using Test, Documenter

@testset "bit basis" begin
    include("bitbasis.jl")
end

@testset "branch" begin
    include("branch.jl")
end

@testset "set covering" begin
    include("setcovering.jl")
end

Documenter.doctest(OptimalBranchingCore; manual=false)
