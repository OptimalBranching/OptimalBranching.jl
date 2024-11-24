"""
    MISReducer

A struct representing a reducer for the Maximum Independent Set (MIS) problem. 
This struct serves as a specific implementation of the `AbstractReducer` type.
"""
struct MISReducer <: AbstractReducer end

"""
    problem_reduce(p::MISProblem, ::MISReducer, TR::Type{R}) where R<:AbstractResult

Reduces the given `MISProblem` by removing vertices based on their degrees and returns a new `MISProblem` instance along with the count of removed vertices.

# Arguments
- `p::MISProblem`: The problem instance containing the graph to be reduced.
- `::MISReducer`: An instance of the `MISReducer` struct.
- `TR::Type{R}`: The type of the result expected.

# Returns
- A tuple containing:
  - A new `MISProblem` instance with specified vertices removed.
  - An integer representing the count of removed vertices.

# Description
The function checks the number of vertices in the graph:
- If there are no vertices, it returns a `NoProblem` instance and a count of 0.
- If there is one vertex, it returns a `NoProblem` instance and a count of 1.
- If there are two vertices, it returns a `NoProblem` instance and a count based on the presence of an edge between them.
- For graphs with more than two vertices, it calculates the degrees of the vertices and identifies the vertex with the minimum degree to determine which vertices to remove.
"""
function OptimalBranchingCore.problem_reduce(p::MISProblem, ::MISReducer, TR::Type{R}) where R<:AbstractResult
    g = p.g
    if nv(g) == 0
        return (NoProblem(), 0)
    elseif nv(g) == 1
        return (NoProblem(), 1)
    elseif nv(g) == 2
        return (NoProblem(), (2 - has_edge(g, 1, 2)))
    else
        degrees = degree(g)
        degmin = minimum(degrees)
        vmin = findfirst(==(degmin), degrees)

        if degmin == 0
            all_zero_vertices = findall(==(0), degrees)
            return (MISProblem(remove_vertices(g, all_zero_vertices)), (length(all_zero_vertices)))
        elseif degmin == 1
            return (MISProblem(remove_vertices(g, neighbors(g, vmin) ∪ vmin)), (1))
        elseif degmin == 2
            g_new, n = folding(g, vmin)
            return (MISProblem(g_new), (n))
        end
    end

    return nothing
end