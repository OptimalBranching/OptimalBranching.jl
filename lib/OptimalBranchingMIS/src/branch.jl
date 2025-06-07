"""
    apply_branch(p::MISProblem{INTP, <:UnitWeight}, clause::Clause{INT}, vertices::Vector{T}) where {INTP<:Integer, INT<:Integer, T<:Integer}

Applies a clause to the given `MISProblem` and returns a new `MISProblem` with the left graph.

# Arguments
- `p::MISProblem{INTP, <:UnitWeight}`: The original problem.
- `clause::Clause{INT}`: The clause to be applied.
- `vertices::Vector{T}`: The vertices included in the clause.

# Returns
- A new `MISProblem` with the left graph.
"""
function OptimalBranchingCore.apply_branch(p::MISProblem{INTP, <:UnitWeight}, clause::Clause{INT}, vertices::Vector{T}) where {INTP<:Integer, INT<:Integer, T<:Integer}
    vertices_removed = removed_vertices(vertices, p.g, clause)
    return MISProblem(remove_vertices(p.g, vertices_removed)), count_ones(clause.val)
end

"""
    apply_branch(p::MISProblem{INTP, <:Vector}, clause::Clause{INT}, vertices::Vector{T}) where {INTP<:Integer, INT<:Integer, T<:Integer}

Applies a clause to the given weighted `MISProblem` and returns a new weighted `MISProblem` with the left graph.

# Arguments
- `p::MISProblem{INTP, <:Vector}`: The original problem.
- `clause::Clause{INT}`: The clause to be applied.
- `vertices::Vector{T}`: The vertices included in the clause.

# Returns
- A new weighted `MISProblem` with the left graph.
"""
function OptimalBranchingCore.apply_branch(p::MISProblem{INTP, <:Vector}, clause::Clause{INT}, vertices::Vector{T}) where {INTP<:Integer, INT<:Integer, T<:Integer}
    vertices_removed = removed_vertices(vertices, p.g, clause)
    g_new, vmap = induced_subgraph(p.g, setdiff(1:nv(p.g), vertices_removed))
    return MISProblem(g_new, p.weights[vmap]), clause_size(p.weights,clause.val,vertices)
end