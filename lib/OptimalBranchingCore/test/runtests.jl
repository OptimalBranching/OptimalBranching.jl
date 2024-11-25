using OptimalBranchingCore
using Test, Documenter

@testset "bit basis" begin
    include("bitbasis.jl")
end

@testset "subcover" begin
    include("subcover.jl")
end

@testset "set covering" begin
    include("setcovering.jl")
end

Documenter.doctest(OptimalBranchingCore; manual=false)
