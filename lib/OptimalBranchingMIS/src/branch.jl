function OptimalBranchingCore.apply_branch(p::MISProblem, clause::Clause{INT}, vertices::Vector{T}) where {INT<:Integer, T<:Integer}
    vertices_removed = removed_vertices(vertices, p.g, clause)
    return MISProblem(remove_vertices(p.g, vertices_removed)), count_ones(clause.val)
end

function OptimalBranchingCore.apply_branch(p::MWISProblem, clause::Clause{INT}, vertices::Vector{T}) where {INT<:Integer, T<:Integer}
    vertices_removed = removed_vertices(vertices, p.g, clause)
    g_new, vmap = induced_subgraph(p.g, setdiff(1:nv(p.g), vertices_removed))
    return MWISProblem(g_new, p.weights[vmap]), clause_weighted_size(p.weights,clause.val,vertices)
end