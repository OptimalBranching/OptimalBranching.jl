using Test
using OptimalBranchingMIS
using OptimalBranchingCore
using OptimalBranchingCore: select_variables
using OptimalBranchingMIS: edge2vertex
using OptimalBranchingMIS.Graphs
using KaHyPar

# calculate the maximum distance between any two vertices in the subset
function max_subset_distance(g::SimpleGraph, subset::Vector{Int})
    isempty(subset) && return 0
    length(subset) == 1 && return 0
    
    max_dist = 0
    for (i, v1) in enumerate(subset)
        for v2 in subset[i+1:end]
            path_length = length(a_star(g, v1, v2)) - 1
            if path_length == -1
                return Inf
            end
            max_dist = max(max_dist, path_length)
        end
    end
    
    return max_dist
end

@testset "KaHyParSelector" begin
    g = random_regular_graph(20, 3; seed = 2134)
    mis1, count1 = mis_branch_count(g)

    bs = BranchingStrategy(table_solver = TensorNetworkSolver(), selector = KaHyParSelector(15), measure = D3Measure())
    misk, countk = mis_branch_count(g; branching_strategy = bs)
    @test mis1 == misk
end

@testset "NaiveBranch" begin
    g = random_regular_graph(20, 3; seed = 2134)
    mis1, count1 = mis_branch_count(g)

    bs = BranchingStrategy(table_solver = TensorNetworkSolver(), selector = KaHyParSelector(15), measure = D3Measure(), set_cover_solver = OptimalBranchingCore.NaiveBranch())
    miskn, countkn = mis_branch_count(g; branching_strategy = bs)
    @test mis1 == miskn
end

@testset "region selection" begin
    g = random_regular_graph(100, 3)
    for strategy in [:neighbor, :mincut]
        for i in rand(1:100, 10)
            selected_vertices = OptimalBranchingMIS.select_region(g, i, 15, strategy)
            @test length(selected_vertices) ≤ 15
            @test i ∈ selected_vertices
        end
    end
end

@testset "MinBoundarySelector" begin
    g = random_regular_graph(100, 3)
    measure = D3Measure()
    selector = MinBoundarySelector(2)
    selected_vertices = select_variables(MISProblem(g), measure, selector)
    @test max_subset_distance(g, selected_vertices) ≤ 4
end

@testset "MinBoundaryHighDegreeSelector" begin
    g = random_regular_graph(100, 3)
    measure = D3Measure()
    selector = MinBoundaryHighDegreeSelector(2, 6, 0)
    selected_vertices = select_variables(MISProblem(g), measure, selector)
    @test max_subset_distance(g, selected_vertices) ≤ 4
end

@testset "KaHyParSelector" begin
    g = random_regular_graph(100, 3)
    measure = D3Measure()
    selector = KaHyParSelector(15)
    selected_vertices = select_variables(MISProblem(g), measure, selector)
    @test length(selected_vertices) < nv(g) - length(selected_vertices)
end

@testset "edge2vertex" begin
    g = random_regular_graph(3, 2)
    res = edge2vertex(g)
    @test res[1,1] == 1.0
    @test res[1,2] == 1.0   
    @test res[1,3] == 0.0
end