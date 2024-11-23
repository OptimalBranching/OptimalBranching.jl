function OptimalBranchingCore.apply(p::MISProblem, clause::Clause{INT}, vertices::Vector{T}) where {INT<:Integer, T<:Integer}
    g = p.g
    vertices_removed = removed_vertices(vertices, g, clause)
    return MISProblem(remove_vertices(g, vertices_removed))
end

function OptimalBranchingCore.result(p::MISProblem, clause::Clause{INT}, vertices::Vector{T}, TR::Type{R}) where {INT<:Integer, R<:AbstractResult, T<:Integer}
    return count_ones(clause.val)
end