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

@testset "mwis" begin
    include("mwis.jl")
end

@testset "table solver" begin
    include("table_solver.jl")
end

@testset "interfaces" begin
    include("interfaces.jl")
end

@testset "types" begin
    include("types.jl")
end

@testset "selector" begin
    include("selector.jl")
end

@testset "greedymerge" begin
    include("greedymerge.jl")
end