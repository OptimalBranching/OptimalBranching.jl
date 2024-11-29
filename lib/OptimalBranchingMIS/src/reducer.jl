"""
    MISReducer

A struct representing a reducer for the Maximum Independent Set (MIS) problem. 
This struct serves as a specific implementation of the `AbstractReducer` type.
"""
struct MISReducer <: AbstractReducer end

"""
    reduce_problem(p::MISProblem, ::MISReducer, ::Type{R}) where R<:AbstractResult

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
function OptimalBranchingCore.reduce_problem(p::MISProblem, ::MISReducer, ::Type{R}) where R <: AbstractResult
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
        degmax = maximum(degrees)
        vmin = findfirst(==(degmin), degrees)
        vmax = findfirst(==(degmax), degrees)

        if degmin == 0
            all_zero_vertices = findall(==(0), degrees)
            return MISProblem(remove_vertices(g, all_zero_vertices)), R(length(all_zero_vertices))
        elseif degmin == 1
            return MISProblem(remove_vertices(g, neighbors(g, vmin) ∪ vmin)), R(1)
        elseif degmin == 2
            g_new, n = folding(g, vmin)
            return MISProblem(g_new), R(n)
        elseif degmax ≥ 6   # Q: No, This is branching!!!!!!!!!
            error("!!!")
            return (MISProblem(remove_vertices(g, closed_neighbors(g, [vmax]))), 1), (MISProblem(remove_vertices(g, [vmax])), 0)
        end
    end

    return p, 0
end

struct XiaoReducer <: AbstractReducer end

function OptimalBranchingCore.reduce_problem(p::MISProblem, ::XiaoReducer, ::Type{R}) where R <:AbstractResult
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
        degmax = maximum(degrees)
        vmin = findfirst(==(degmin), degrees)
        vmax = findfirst(==(degmax), degrees)

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
            rem_vertices!(g, [unconfined_vs[1]])
            return MISProblem(g), R(0)
        end

        twin_filter!(g) && return MISProblem(g), R(2)
        short_funnel_filter!(g) && return MISProblem(g), R(1)
        desk_filter!(g) && return MISProblem(g), R(2)

    end

    return p, R(0)
end