"""
    apply(p::MISProblem, clause::Clause{INT}, vertices::Vector{T}) where {INT<:Integer, T<:Integer}

Applies the given clause to the specified vertices of the MISProblem, removing the vertices that are affected by the clause.

# Arguments
- `p::MISProblem`: The problem instance containing the graph.
- `clause::Clause{INT}`: The clause to be applied, which may affect the vertices.
- `vertices::Vector{T}`: A vector of vertices to be considered for removal.

# Returns
- `MISProblem`: A new instance of `MISProblem` with the specified vertices removed from the graph.

"""
function OptimalBranchingCore.apply_branch(p::MISProblem, clause::Clause{INT}, vertices::Vector{T}) where {INT<:Integer, T<:Integer}
    vertices_removed = removed_vertices(vertices, p.g, clause)
    return MISProblem(remove_vertices(p.g, vertices_removed)), count_ones(clause.val)
end