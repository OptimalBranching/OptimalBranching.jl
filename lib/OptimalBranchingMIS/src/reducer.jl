struct MISReducer <: AbstractReducer end

function OptimalBranchingCore.reduce(p::MISProblem, ::MISReducer, TR::Type{R}) where R<:AbstractResult
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