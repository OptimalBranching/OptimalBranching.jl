"""
    MISReducer

A struct representing a reducer for the Maximum Independent Set (MIS) problem. 
This struct serves as a specific implementation of the `AbstractReducer` type.
"""
struct MISReducer <: AbstractReducer end

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
function OptimalBranchingCore.reduce_problem(::Type{R}, p::MISProblem, ::MISReducer) where R
    g = p.g
    if nv(g) == 0
        return MISProblem(SimpleGraph(0)), R(0)
    elseif nv(g) == 1
        return MISProblem(SimpleGraph(0)), R(1)
    elseif nv(g) == 2
        return MISProblem(SimpleGraph(0)), R(2 - has_edge(g, 1, 2))
    else
        degrees = degree(g)
        degmin = minimum(degrees)
        vmin = findfirst(==(degmin), degrees)

        if degmin == 0
            all_zero_vertices = findall(==(0), degrees)
            return MISProblem(remove_vertices(g, all_zero_vertices)), R(length(all_zero_vertices))
        elseif degmin == 1
            return MISProblem(remove_vertices(g, neighbors(g, vmin) ∪ vmin)), R(1)
        elseif degmin == 2
            g_new, n = folding(g, vmin)
            return MISProblem(g_new), R(n)
        end
    end
    return p, R(0)
end

struct XiaoReducer <: AbstractReducer end

function OptimalBranchingCore.reduce_problem(::Type{R}, p::MISProblem, ::XiaoReducer, ) where R
    g = p.g
    if nv(g) == 0
        # NOTE: using NoProblem can be slower due to type instability.
        return MISProblem(SimpleGraph(0)), R(0)
    elseif nv(g) == 1
        return MISProblem(SimpleGraph(0)), R(1)
    elseif nv(g) == 2
        return MISProblem(SimpleGraph(0)), R(2 - has_edge(g, 1, 2))
    else
        degrees = degree(g)
        degmin = minimum(degrees)
        vmin = findfirst(==(degmin), degrees)

        if degmin == 0
            all_zero_vertices = findall(==(0), degrees)
            return MISProblem(remove_vertices(g, all_zero_vertices)), R(length(all_zero_vertices))
        elseif degmin == 1
            return MISProblem(remove_vertices(g, neighbors(g, vmin) ∪ vmin)), R(1)
        elseif degmin == 2
            g_new, n = folding(g, vmin)
            return MISProblem(g_new), R(n)
        end

        g = copy(p.g)

        unconfined_vs = unconfined_vertices(g)
        if length(unconfined_vs) != 0
            @debug "Removing unconfined vertex $(unconfined_vs[1])"
            rem_vertices!(g, [unconfined_vs[1]])
            return MISProblem(g), R(0)
        end

        twin_filter!(g) && return MISProblem(g), R(2)
        short_funnel_filter!(g) && return MISProblem(g), R(1)
        desk_filter!(g) && return MISProblem(g), R(2)
    end

    return p, R(0)
end

"""
    struct TensorNetworkReducer <: AbstractReducer

A reducer that uses tensor network contraction to find reduction rules.

# Fields
- `n_max::Int = 15`: Maximum number of vertices to be included in the selected region
- `selector::Symbol = :neighbor`: Strategy for selecting vertices to contract. Options are:
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
    selector::Symbol = :neighbor # :neighbor or :mincut
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

function OptimalBranchingCore.reduce_problem(result_type::Type{R}, p::MISProblem, tnreducer::TensorNetworkReducer) where R
    rp, reducedvalue = reduce_problem(result_type, p, tnreducer.sub_reducer)
    (rp.g != p.g) && return rp, reducedvalue

    for i in 1:nv(p.g)
        selected_vertices = select_region(p.g, i, tnreducer.n_max, tnreducer.selector)
        truth_table = branching_table(p, TensorNetworkSolver(), selected_vertices)
        bc = best_intersect(p, truth_table, tnreducer.measure, tnreducer.intersect_strategy, 
        selected_vertices)
        if !isnothing(bc)
            rp, reducedvalue = OptimalBranchingCore.apply_branch(p, bc, selected_vertices)
            return rp, R(reducedvalue)
        end
    end

    return p, R(0)
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