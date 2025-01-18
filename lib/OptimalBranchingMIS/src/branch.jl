function OptimalBranchingCore.apply_branch(p::MISProblem, clause::Clause{INT}, variables::Vector{T}) where {INT<:Integer, T<:Integer}
    vertices_removed = removed_vertices(variables, p.g, clause)
    rem = setdiff(vertices(p.g), vertices_removed)
    g, _ = induced_subgraph(p.g, rem)
    return MISProblem(g), rem, SolutionAndCount(count_ones(clause.val), clause.val , 1)
end