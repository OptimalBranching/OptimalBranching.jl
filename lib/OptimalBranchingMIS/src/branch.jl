function OptimalBranchingCore.apply_branch(p::MISProblem, clause::Clause{INT}, vertices::Vector{T}) where {INT<:Integer, T<:Integer}
    vertices_removed = removed_vertices(vertices, p.g, clause)
    return MISProblem(remove_vertices(p.g, vertices_removed))
end

function OptimalBranchingCore.apply_branch_gain(::Type{R}, p::MISProblem, clause::Clause{INT}, vertices::Vector{T}) where {R, INT<:Integer, T<:Integer}
    return apply_branch(p, clause, vertices), R(count_ones(clause.val))
end
