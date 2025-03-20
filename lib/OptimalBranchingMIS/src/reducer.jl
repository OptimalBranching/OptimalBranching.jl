"""
    MISReducer

A struct representing a reducer for the Maximum Independent Set (MIS) problem. 
This struct serves as a specific implementation of the `AbstractReducer` type.
"""
struct MISReducer <: AbstractReducer end

"""
    struct XiaoReducer <: AbstractReducer end

A reducer that uses Xiao's reduction rules to find reduction rules.
"""
struct XiaoReducer <: AbstractReducer end

"""
    struct TensorNetworkReducer <: AbstractReducer

A reducer that uses tensor network contraction to find reduction rules.

# Fields
- `n_max::Int = 15`: Maximum number of vertices to be included in the selected region
- `selector::Symbol = :mincut`: Strategy for selecting vertices to contract. Options are:
    - `:neighbor`: Select vertices based on neighborhood
    - `:mincut`: Select vertices based on minimum cut provided by KaHyPar !Note: KaHyPar may leads to memory leak!
- `measure::AbstractMeasure = NumOfVertices()`: Measure used for kernelization. Uses size reduction from OptimalBranchingMIS
- `intersect_strategy::Symbol = :bfs`: Strategy for intersecting clauses. Options are:
    - `:bfs`: Breadth-first search (gives the optimal result)
    - `:dfs`: Depth-first search (gives the first found non-zero intersection)
- `sub_reducer::AbstractReducer = XiaoReducer()`: Reducer applied to selected vertices before tensor network contraction, default is XiaoReducer
"""
@kwdef struct TensorNetworkReducer <: AbstractReducer
    n_max::Int = 15
    selector::Symbol = :mincut # :neighbor or :mincut
    measure::AbstractMeasure = NumOfVertices() # different measures for kernelization, use the size reduction from OptimalBranchingMIS
    intersect_strategy::Symbol = :bfs # :dfs or :bfs
    sub_reducer::AbstractReducer = XiaoReducer() # sub reducer for the selected vertices
end
Base.show(io::IO, reducer::TensorNetworkReducer) = print(io,
    """
    TensorNetworkReducer
        ├── n_max - $(reducer.n_max)
        ├── selector - $(reducer.selector)
        ├── measure - $(reducer.measure)
        ├── intersect_strategy - $(reducer.intersect_strategy)
        └── sub_reducer - $(reducer.sub_reducer)
    """)

"""
    reduce_problem(::Type{R}, p::MISProblem, ::MISReducer) where R

Reduces the given `MISProblem` by removing vertices based on their degrees and returns a new `MISProblem` instance along with the count of removed vertices.

# Arguments
- `p::MISProblem`: The problem instance containing the graph to be reduced.
- `::MISReducer`: An instance of the `MISReducer` struct.
- `::Type{R}`: The type of the result expected.

# Returns
- A tuple containing:
  - A new `MISProblem` instance with specified vertices removed.
  - An integer representing the count of removed vertices.

# Description
The function checks the number of vertices in the graph:
- If there are no vertices, it returns an empty instance and a count of 0.
- If there is one vertex, it returns an empty instance and a count of 1.
- If there are two vertices, it returns an empty instance and a count based on the presence of an edge between them.
- For graphs with more than two vertices, it calculates the degrees of the vertices and identifies the vertex with the minimum degree to determine which vertices to remove.
"""
function OptimalBranchingCore.reduce_problem(::Type{R}, p::MISProblem, reducer::Union{MISReducer, XiaoReducer, TensorNetworkReducer}) where R
    p_new, r, _ = reduce_problem_vmap(R, p, reducer)
    return p_new, r
end

function reduce_problem_vmap(::Type{R}, p::MISProblem, MISReducer) where R
    g = p.g
    if nv(g) == 0
        return MISProblem(SimpleGraph(0)), R(0), Int[]
    elseif nv(g) == 1
        return MISProblem(SimpleGraph(0)), R(1), Int[]
    elseif nv(g) == 2
        return MISProblem(SimpleGraph(0)), R(2 - has_edge(g, 1, 2)), Int[]
    else
        degrees = degree(g)
        degmin = minimum(degrees)
        vmin = findfirst(==(degmin), degrees)

        if degmin == 0
            all_zero_vertices = findall(==(0), degrees)
            g_new, vmap = remove_vertices_vmap(g, all_zero_vertices)
            return MISProblem(g_new), R(length(all_zero_vertices)), vmap
        elseif degmin == 1
            g_new, vmap = remove_vertices_vmap(g, neighbors(g, vmin) ∪ vmin)
            return MISProblem(g_new), R(1), vmap
        elseif degmin == 2
            g_new, n, vmap = folding_vmap(g, vmin)
            return MISProblem(g_new), R(n), vmap
        end
    end
    return p, R(0), collect(1:nv(g))
end

function reduce_problem_vmap(::Type{R}, p::MISProblem, ::XiaoReducer) where R
    g = p.g
    if nv(g) == 0
        # NOTE: using NoProblem can be slower due to type instability.
        return MISProblem(SimpleGraph(0)), R(0), Int[]
    elseif nv(g) == 1
        return MISProblem(SimpleGraph(0)), R(1), Int[]
    elseif nv(g) == 2
        return MISProblem(SimpleGraph(0)), R(2 - has_edge(g, 1, 2)), Int[]
    else
        degrees = degree(g)
        degmin = minimum(degrees)
        vmin = findfirst(==(degmin), degrees)

        if degmin == 0
            all_zero_vertices = findall(==(0), degrees)
            g_new, vmap = remove_vertices_vmap(g, all_zero_vertices)
            return MISProblem(g_new), R(length(all_zero_vertices)), vmap
        elseif degmin == 1
            g_new, vmap = remove_vertices_vmap(g, neighbors(g, vmin) ∪ vmin)
            return MISProblem(g_new), R(1), vmap
        elseif degmin == 2
            g_new, n, vmap = folding_vmap(g, vmin)
            return MISProblem(g_new), R(n), vmap
        end

        g = copy(p.g)

        unconfined_vs = unconfined_vertices(g)
        if length(unconfined_vs) != 0
            @debug "Removing unconfined vertex $(unconfined_vs[1])"
            g_new, vmap = remove_vertices_vmap(g, [unconfined_vs[1]])
            return MISProblem(g_new), R(0), vmap
        end

        twin_res = twin_filter_vmap(g)
        !isnothing(twin_res) && return MISProblem(twin_res[1]), R(2), twin_res[2]
        
        short_funnel_res = short_funnel_filter_vmap(g)
        !isnothing(short_funnel_res) && return MISProblem(short_funnel_res[1]), R(1), short_funnel_res[2]

        desk_res = desk_filter_vmap(g)
        !isnothing(desk_res) && return MISProblem(desk_res[1]), R(2), desk_res[2]
    end

    return p, R(0), collect(1:nv(g))
end

function reduce_problem_vmap(::Type{R}, p::MISProblem, tnreducer::TensorNetworkReducer) where R
    rp, reducedvalue, vmap = reduce_problem_vmap(R, p, tnreducer.sub_reducer)
    (rp.g != p.g) && return rp, reducedvalue, vmap

    # TODO: consider better strategy for selecting
    for i in 1:nv(p.g)
        selected_vertices = select_region(p.g, i, tnreducer.n_max, tnreducer.selector)
        truth_table = branching_table(p, TensorNetworkSolver(), selected_vertices)
        bc = best_intersect(p, truth_table, tnreducer.measure, tnreducer.intersect_strategy, 
        selected_vertices)
        if !isnothing(bc)
            # rp, reducedvalue = OptimalBranchingCore.apply_branch(p, bc, selected_vertices)
            vertices_removed = removed_vertices(selected_vertices, p.g, bc)
            g_new, vmap = remove_vertices_vmap(p.g, vertices_removed)
            reducedvalue = count_ones(bc.val)
            return MISProblem(g_new), R(reducedvalue), vmap
        end
    end

    return p, R(0), collect(1:nv(p.g))
end

function best_intersect(p::MISProblem, tbl::BranchingTable, measure::AbstractMeasure, intersect_strategy::Symbol, variables::Vector{T}) where {T}
    cl = OptimalBranchingCore.intersect_clauses(tbl, intersect_strategy)
    if isempty(cl)
        return nothing
    elseif length(cl) == 1
        return cl[1]
    else
        best_loss = OptimalBranchingCore.size_reduction(p, measure, cl[1], variables)
        best_cl = cl[1]
        for c in cl[2:end]
            loss = OptimalBranchingCore.size_reduction(p, measure, c, variables)
            if loss < best_loss
                best_loss = loss
                best_cl = c
            end
        end
        return best_cl
    end
end