using OptimalBranchingCore
using Test

@testset "OptimalBranchingCore.jl" begin
    include("bitbasis.jl")
    include("subcover.jl")
    include("setcovering.jl")
end
