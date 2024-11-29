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

"""
    result(p::MISProblem, clause::Clause{INT}, vertices::Vector{T}, TR::Type{R}) where {INT<:Integer, R<:AbstractResult, T<:Integer}

Calculates the result of applying the given clause to the specified vertices in the MISProblem.

# Arguments
- `p::MISProblem`: The problem instance containing the graph.
- `clause::Clause{INT}`: The clause whose value is to be counted.
- `vertices::Vector{T}`: A vector of vertices to be considered (not used in the calculation).
- `TR::Type{R}`: The type of the result expected.

# Returns
- `Int`: The count of ones in the clause's value.

"""
function OptimalBranchingCore.result(p::MISProblem, clause::Clause{INT}, vertices::Vector{T}, TR::Type{R}) where {INT<:Integer, R<:AbstractResult, T<:Integer}
    return count_ones(clause.val)
end