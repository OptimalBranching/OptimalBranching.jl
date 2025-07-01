using OptimalBranchingCore, OptimalBranchingMIS
using EliminateGraphs, EliminateGraphs.Graphs
using Test
using ProblemReductions
using OptimalBranchingMIS: neighbor_cover, reduced_alpha, reduced_alpha_configs, graph_from_tuples, collect_configs, best_folding
using GenericTensorNetworks
using Random

@testset "graph_from_tuples" begin
    g = graph_from_tuples(4, [(1, 2), (2, 3), (3, 4)])
    @test nv(g) == 4
    @test ne(g) == 3
end


@testset "neighbor cover" begin
    g = smallgraph(:petersen)
    @test length(neighbor_cover(g, 1, 0)[1]) == 1
    @test length(neighbor_cover(g, 1, 0)[2]) == 1
    @test length(neighbor_cover(g, 1, 1)[1]) == 4
    @test length(neighbor_cover(g, 1, 1)[2]) == 3
    @test length(neighbor_cover(g, 1, 2)[1]) == 10
    @test length(neighbor_cover(g, 1, 2)[2]) == 0
end

@testset "reduced alpha" begin
    g = graph_from_tuples(3, [(1, 2), (2, 3), (3, 1)])
    @test reduced_alpha(g, UnitWeight(nv(g)), [1, 2]) == Tropical.([1 -Inf; -Inf -Inf])

    cfgs = OptimalBranchingMIS._reduced_alpha_configs(g, UnitWeight(nv(g)), [1, 2], nothing)
    @test count(!iszero, cfgs) == 1
    @test collect_configs.(cfgs, Ref("abc")) == reshape([["c"], String[], String[], String[]], 2, 2)
    @test collect_configs.(cfgs) == reshape([[BitVector((0, 0, 1))], [], [], []], 2, 2)
    @test BranchingTable(cfgs) == BranchingTable(3, [[StaticElementVector(2, [0, 0, 1])]])
end

@testset "update region list via vmap" begin
    for g in [random_regular_graph(1000, 3), SimpleGraph(GenericTensorNetworks.random_diagonal_coupled_graph(50, 50, 0.8))]
        region_list = Dict{Int, Tuple{Vector{Int}, Vector{Int}}}()
        for i in 1:nv(g)
            n = OptimalBranchingMIS.closed_neighbors(g, [i])
            nn = OptimalBranchingMIS.open_neighbors(g, n)
            region_list[i] = (n, nn)
        end

        removed_vertices = unique!(rand(1:nv(g), 10))
        sub_g, vmap = OptimalBranchingMIS.remove_vertices_vmap(g, removed_vertices)

        mapped_region_list = OptimalBranchingMIS.update_region_list(region_list, vmap)
        
        for (v, (n, nn)) in mapped_region_list
            @test n == OptimalBranchingMIS.closed_neighbors(sub_g, [v])
            @test nn == OptimalBranchingMIS.open_neighbors(sub_g, n)
        end
    end
end

@testset "folding for mwis" begin
    g = graph_from_tuples(5, [(1, 2), (2, 3), (3, 4), (4, 5)])
    weights = ones(Float64, nv(g))
    
    weights[3] = 2.5
    res = OptimalBranchingMIS.folding_vmap(g, weights, 3)
    @test nv(res[1]) == length(res[2]) == 2
    @test res[3] == 2.5
   
    weights[3] = 1.5
    res = OptimalBranchingMIS.folding_vmap(g, weights, 3)
    @test nv(res[1]) == length(res[2]) == 3
    @test res[3] == 1.5
end

@testset "best folding" begin
    g = graph_from_tuples(5, [(1, 2), (2, 3), (3, 4), (4, 5)])
    weights = ones(Float64, nv(g))
    tbl = BranchingTable(5, [
        [[0, 0, 0, 0, 1], [0, 0, 1, 0, 1]],
        [[1, 1, 0, 1, 0]]
    ])
    problem = MISProblem(g, weights)
    cl = best_folding(problem, tbl, :bfs)
    @test count_ones(cl.mask) == 5
    @test count_ones(cl.val) == 2
end

@testset "general folding" begin
    g = graph_from_tuples(5, [(1, 2), (2, 3), (3, 4), (4, 5)])
    weights = ones(Float64, nv(g))
    g_new, weights_new, vmap = OptimalBranchingMIS.folding_one_node(g, weights, [1, 2])
    @test nv(g_new) == length(vmap) == 4
    @test weights_new[1] == 2
   
    g_new, weights_new, vmap = OptimalBranchingMIS.folding_two_nodes(g, weights, [1, 2], [3, 4])
    @test nv(g_new) == length(vmap) == 3
    @test weights_new[1] == 2
    @test weights_new[2] == 2
end

@testset "kernelize" begin
    function kernelize(g::SimpleGraph, reducer::TensorNetworkReducer; verbose::Int = 0, vmap::Vector{Int} = collect(1:nv(g)))
        (verbose ≥ 2) && (@info "kernelizing graph: $(nv(g)) vertices, $(ne(g)) edges")
        r = 0
    
        vmap_0 = vmap
    
        while true
            res = OptimalBranchingMIS.reduce_graph(g, UnitWeight(nv(g)), reducer, vmap_0 = vmap_0) # res = (g_new, r_new, vmap_new)
            vmap_0 = res.vmap
            vmap = vmap[res.vmap]
            r += res.r
            if g == res.g
                (verbose ≥ 2) && (@info "kernelized graph: $(nv(g)) vertices, $(ne(g)) edges")
                return (g, r, vmap)
            end
            g = res.g
        end
    end

    g = random_regular_graph(100, 3)
    reducer = TensorNetworkReducer(recheck = true)
    gk, r, _ = kernelize(g, reducer)
    @test nv(gk) ≤ nv(g)
    @test nv(gk) == length(reducer.region_list)

    @test mis2(EliminateGraph(gk)) + r == mis2(EliminateGraph(g))
    
    reducer = TensorNetworkReducer()
    gkk, _, _ = kernelize(gk, reducer)
    @test gkk == gk
end

@testset "kernelize for mwis with XiaoReducer" begin
    function kernelize(g::SimpleGraph, weights::Vector{WT}, reducer::XiaoReducer; verbose::Int = 0, vmap::Vector{Int} = collect(1:nv(g))) where WT
        (verbose ≥ 2) && (@info "kernelizing graph: $(nv(g)) vertices, $(ne(g)) edges")
        r = 0
    
        vmap_0 = vmap
    
        while true
            res = OptimalBranchingMIS.reduce_graph(g, weights, reducer) 
            vmap_0 = res.vmap
            vmap = vmap[res.vmap]
            r += res.r
            if g == res.g
                (verbose ≥ 2) && (@info "kernelized graph: $(nv(g)) vertices, $(ne(g)) edges")
                return (g, weights, r, vmap)
            end
            g = res.g
            weights = res.weights
        end
    end
    
    @testset "random graph" begin
        g = random_regular_graph(100, 3)
        weights = rand(Float64, nv(g))
        reducer = XiaoReducer()
        gk, weightsk, r, _ = kernelize(g, weights, reducer)
        @test nv(gk) ≤ nv(g)

        problem = GenericTensorNetwork(IndependentSet(g, weights); optimizer = TreeSA())
        mwis = solve(problem, SizeMax())[1].n
        problemk = GenericTensorNetwork(IndependentSet(gk, weightsk); optimizer = TreeSA())
        mwisk = solve(problemk, SizeMax())[1].n
        @test isapprox(mwisk + r, mwis)
    
        reducer = XiaoReducer()
        gkk, weightskk, _, _ = kernelize(gk, weightsk, reducer)
        @test gkk == gk
        @test weightskk == weightsk

        g = GenericTensorNetworks.random_diagonal_coupled_graph(30, 30, 0.8)
        g = SimpleGraph(g)
        weights = ones(Float64, nv(g))
        reducer = XiaoReducer()
        gk, weightsk, r, _ = kernelize(g, weights, reducer)
        @test nv(gk) ≤ nv(g)

        problem = GenericTensorNetwork(IndependentSet(g, weights); optimizer = TreeSA())
        mwis = solve(problem, SizeMax())[1].n
        problemk = GenericTensorNetwork(IndependentSet(gk, weightsk); optimizer = TreeSA())
        mwisk = solve(problemk, SizeMax())[1].n
        @test isapprox(mwisk + r, mwis)
    
        reducer = XiaoReducer()
        gkk, weightskk, _, _ = kernelize(gk, weightsk, reducer)
        @test gkk == gk
        @test weightskk == weightsk
    end

    @testset "example graphs" begin
        reducer = XiaoReducer()

        g0 = graph_from_tuples(5, [(1,2),(1,3),(2,3),(2,4),(3,4),(3,5),(4,5)])
        weights0 = [1,1,1,1,1]
        g = copy(g0)
        weights = copy(weights0)
        gk, weightsk, r, _ = kernelize(g, weights, reducer)
        @test counting_xiao2021(gk, weightsk).size + r == counting_xiao2021(g0, weights0).size
        
        g = graph_from_tuples(5, [(1,2),(1,3),(2,3),(2,4),(3,4),(3,5),(4,5)])
        weights = [5,1,1,4,3]
        g = copy(g0)
        weights = copy(weights0)
        gk, weightsk, r, _ = kernelize(g, weights, reducer)
        @test counting_xiao2021(gk, weightsk).size + r == counting_xiao2021(g0, weights0).size

        g = graph_from_tuples(8, [(1,2),(2,3),(3,4),(3,5),(1,6),(1,7),(4,8)])
        weights = [2,1,3,1,1,1,1,1]
        g = copy(g0)
        weights = copy(weights0)
        gk, weightsk, r, _ = kernelize(g, weights, reducer)
        @test counting_xiao2021(gk, weightsk).size + r == counting_xiao2021(g0, weights0).size

        g = graph_from_tuples(6, [(1,4),(1,5),(2,4),(2,5),(3,4),(3,5),(1,6)])
        weights = [1,1,1,1,1,1]
        g = copy(g0)
        weights = copy(weights0)
        gk, weightsk, r, _ = kernelize(g, weights, reducer)
        @test counting_xiao2021(gk, weightsk).size + r == counting_xiao2021(g0, weights0).size

        g = graph_from_tuples(3, [(1,2),(2,3)])
        weights = [1,1,1]
        g = copy(g0)
        weights = copy(weights0)
        gk, weightsk, r, _ = kernelize(g, weights, reducer)
        @test counting_xiao2021(gk, weightsk).size + r == counting_xiao2021(g0, weights0).size

        g = graph_from_tuples(5, [(1,2),(1,3),(1,4),(1,5)])
        weights = [9,2,3,4,1]
        g = copy(g0)
        weights = copy(weights0)
        gk, weightsk, r, _ = kernelize(g, weights, reducer)
        @test counting_xiao2021(gk, weightsk).size + r == counting_xiao2021(g0, weights0).size

        g = graph_from_tuples(8, [(1,2),(2,3),(3,4),(1,5),(1,6),(4,7),(4,8)])
        weights = [4,3,2,1,1,1,1,1]
        g = copy(g0)
        weights = copy(weights0)
        gk, weightsk, r, _ = kernelize(g, weights, reducer)
        @test counting_xiao2021(gk, weightsk).size + r == counting_xiao2021(g0, weights0).size
        
        g = graph_from_tuples(8, [(1,2),(2,3),(3,4),(1,5),(1,6),(4,7),(4,8),(1,4)])
        weights = [4,3,2,0.5,1,1,1,1]
        g = copy(g0)
        weights = copy(weights0)
        gk, weightsk, r, _ = kernelize(g, weights, reducer)
        @test counting_xiao2021(gk, weightsk).size + r == counting_xiao2021(g0, weights0).size

        g = graph_from_tuples(5, [(1,2),(1,3),(1,4),(1,5),(2,3),(2,4),(2,5),(3,4),(3,5),(4,5)])
        weights = [3,1,2,4,5]
        g = copy(g0)
        weights = copy(weights0)
        gk, weightsk, r, _ = kernelize(g, weights, reducer)
        @test counting_xiao2021(gk, weightsk).size + r == counting_xiao2021(g0, weights0).size
    end
end

@testset "kernelize for mwis with TNReducer" begin
    function kernelize(g::SimpleGraph, weights::Vector{WT}, reducer::TensorNetworkReducer; verbose::Int = 0, vmap::Vector{Int} = collect(1:nv(g))) where WT
        (verbose ≥ 2) && (@info "kernelizing graph: $(nv(g)) vertices, $(ne(g)) edges")
        r = 0
    
        vmap_0 = vmap
    
        while true
            res = OptimalBranchingMIS.reduce_graph(g, weights, reducer, vmap_0 = vmap_0) # res = (g_new, weights_new, r_new, vmap_new)
            vmap_0 = res.vmap
            vmap = vmap[res.vmap]
            r += res.r
            if g == res.g
                (verbose ≥ 2) && (@info "kernelized graph: $(nv(g)) vertices, $(ne(g)) edges")
                return (g, weights, r, vmap)
            end
            g = res.g
            weights = res.weights
        end
    end

    g = random_regular_graph(60, 3)
    weights = rand(10:40, nv(g))
    reducer = TensorNetworkReducer(recheck = true, folding = true)
    gk, weightsk, r, _ = kernelize(g, weights, reducer)
    @test nv(gk) ≤ nv(g)
    @test nv(gk) == length(reducer.region_list)

    problem = GenericTensorNetwork(IndependentSet(g, weights); optimizer = TreeSA())
    mwis = solve(problem, SizeMax())[1].n
    problemk = GenericTensorNetwork(IndependentSet(gk, weightsk); optimizer = TreeSA())
    mwisk = solve(problemk, SizeMax())[1].n
    @test isapprox(mwisk + r, mwis)
    
    reducer = TensorNetworkReducer(recheck = true, folding = true)
    gkk, weightskk, _, _ = kernelize(gk, weightsk, reducer)
    @test gkk == gk
    @test weightskk == weightsk

    g = GenericTensorNetworks.random_diagonal_coupled_graph(30, 30, 0.8)
    g = SimpleGraph(g)
    weights = ones(Float64, nv(g))
    reducer = TensorNetworkReducer(recheck = true, folding = true)
    gk, weightsk, r, _ = kernelize(g, weights, reducer)
    @test nv(gk) ≤ nv(g)
    @test nv(gk) == length(reducer.region_list)

    problem = GenericTensorNetwork(IndependentSet(g, weights); optimizer = TreeSA())
    mwis = solve(problem, SizeMax())[1].n
    problemk = GenericTensorNetwork(IndependentSet(gk, weightsk); optimizer = TreeSA())
    mwisk = solve(problemk, SizeMax())[1].n
    @test isapprox(mwisk + r, mwis)
    
    reducer = TensorNetworkReducer(recheck = true, folding = true)
    gkk, weightskk, _, _ = kernelize(gk, weightsk, reducer)
    @test gkk == gk
    @test weightskk == weightsk
end