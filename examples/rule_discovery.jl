# # Automatic rule discovery
using OptimalBranching.OptimalBranchingMIS.Graphs, OptimalBranching, OptimalBranching.OptimalBranchingMIS
using OptimalBranching.OptimalBranchingCore, OptimalBranching.OptimalBranchingCore.BitBasis
using OptimalBranching.OptimalBranchingCore: IPSolver
using ProblemReductions

# This function generates the tree-like N3 neighborhood of g0.
function tree_like_N3_neighborhood(g0::SimpleGraph)
    g = copy(g0)
    for layer in 1:3
        for v in vertices(g)
            for _ = 1:(3-degree(g, v))
                add_vertex!(g)
                add_edge!(g, v, nv(g))
            end
        end
    end
    return g
end

function solve_opt_rule(branching_region, graph, vs)
    ## Use default solver and measure
    m = D3Measure()
    table_solver = TensorNetworkSolver(; prune_by_env=true)
    set_cover_solver = IPSolver()

    ## Pruning irrelevant entries
    ovs = OptimalBranchingMIS.open_vertices(graph, vs)
    subg, vmap = induced_subgraph(graph, vs)
    @info "solving the branching table..."
    tbl = OptimalBranchingMIS.reduced_alpha_configs(table_solver, subg, UnitWeight(nv(subg)), Int[findfirst(==(v), vs) for v in ovs])
    @info "the length of the truth_table after pruning irrelevant entries: $(length(tbl.table))"

    @info "generating candidate clauses..."
    candidate_clauses = OptimalBranchingMIS.OptimalBranchingCore.candidate_clauses(tbl)
    @info "the length of the candidate clauses: $(length(candidate_clauses))"

    @info "generating the optimal branching rule via set cover..."
    problem = MISProblem(graph)
    size_reductions = [measure(problem, m) - measure(first(OptimalBranchingCore.apply_branch(problem, candidate, vs)), m) for candidate in candidate_clauses]
    result = OptimalBranchingMIS.OptimalBranchingCore.minimize_γ(tbl, candidate_clauses, size_reductions, set_cover_solver)
    is_valid, gamma = OptimalBranchingCore.test_rule(tbl, result.optimal_rule, problem, m, vs)
    @assert is_valid "The rule is not valid"
    @assert gamma ≈ result.γ "The gamma is not correct"
    @info "the minimized gamma: $(result.γ)"

    @info "the optimal branching rule on R:"
    viz_dnf(result.optimal_rule, vs)
    return result
end

function viz_dnf(dnf::DNF{INT}, variables::Vector{T}) where {T, INT}
    for c in dnf.clauses
        println(join([iszero(readbit(c.val, i)) ? "¬$(variables[i])" : "$(variables[i])" for i = 1:bsizeof(INT) if readbit(c.mask, i) == 1], " ∧ "))
    end
end


# ## Domination rule
# Define the branching region R
vs = [1,2,3,4,5]
edges = [(1, 2), (2, 3), (1, 3), (2, 4), (3, 4), (2, 5), (4, 5)]
branching_region = SimpleGraph(Graphs.SimpleEdge.(edges)) 

graph = tree_like_N3_neighborhood(branching_region)

solve_opt_rule(branching_region, graph, vs)


# ## PH2 rule
# Define the branching region R
vs = [1,2,3,4,5,6,7,8]
edges = [(1, 2), (1, 5), (2, 3), (2, 6), (3, 4), (4, 5), (5, 8), (6, 7), (7, 8)]
branching_region = SimpleGraph(Graphs.SimpleEdge.(edges)) 

# Generate the tree-like N3 neighborhood of R
graph = tree_like_N3_neighborhood(branching_region)

solve_opt_rule(branching_region, graph, vs)


# ## Bottleneck case
# Define the branching region R
vs = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22]
edges = [(1, 2), (1, 3), (1, 4), (2, 5), (2, 6), (3, 7), (3, 8), (4, 9), (4, 10), (5, 11), (5, 12), (6, 13), (6, 14), (7, 15), (7, 16), (8, 17), (8, 18), (9, 19), (9, 20), (10, 21), (10, 22), (11, 14), (12, 13), (15, 18), (16, 17), (19, 22), (20, 21)]
branching_region = SimpleGraph(Graphs.SimpleEdge.(edges)) 

# Generate the tree-like N3 neighborhood of R
graph = tree_like_N3_neighborhood(branching_region)

solve_opt_rule(branching_region, graph, vs)


# ## Generating rules for large scale problems
# For large scale problems, we can use the greedy merge rule to generate rules, which avoids generating all candidate clauses.
function solve_greedy_rule(branching_region, graph, vs)
    ## Use default solver and measure
    m = D3Measure()
    table_solver = TensorNetworkSolver(; prune_by_env=true)

    ## Pruning irrelevant entries
    ovs = OptimalBranchingMIS.open_vertices(graph, vs)
    subg, vmap = induced_subgraph(graph, vs)
    @info "solving the branching table..."
    tbl = OptimalBranchingMIS.reduced_alpha_configs(table_solver, subg, UnitWeight(nv(subg)), Int[findfirst(==(v), vs) for v in ovs])
    @info "the length of the truth_table after pruning irrelevant entries: $(length(tbl.table))"

    @info "generating the optimal branching rule via greedy merge..."
    candidates = OptimalBranchingCore.bit_clauses(tbl)
    result = OptimalBranchingMIS.OptimalBranchingCore.greedymerge(candidates, MISProblem(graph), vs, m)
    is_valid, gamma = OptimalBranchingCore.test_rule(tbl, result.optimal_rule, MISProblem(graph), m, vs)
    @assert is_valid "The rule is not valid"
    @assert gamma ≈ result.γ "The gamma is not correct"
    @info "the greedily minimized gamma: $(result.γ)"

    @info "the branching rule on R:"
    viz_dnf(result.optimal_rule, vs)
    return result
end

result = solve_greedy_rule(branching_region, graph, vs)