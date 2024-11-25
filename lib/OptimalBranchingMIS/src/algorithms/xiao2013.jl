"""
    counting_xiao2013(g::SimpleGraph)

This function counts the maximum independent set (MIS) in a given simple graph using the Xiao 2013 algorithm.

# Arguments
- `g::SimpleGraph`: A simple graph for which the maximum independent set is to be counted.

# Returns
- `CountingMIS`: An object representing the size of the maximum independent set and the count of branches.

"""
function counting_xiao2013(g::SimpleGraph)
    gc = copy(g)    
    return _xiao2013(gc)
end


function _xiao2013(g::SimpleGraph)
    if nv(g) == 0
        return MISCount(0)
    elseif nv(g) == 1
        return MISCount(1)
    elseif nv(g) == 2
        return MISCount(2 - has_edge(g, 1, 2))
    else
        degrees = degree(g)
        degmin = minimum(degrees)
        vmin = findfirst(==(degmin), degrees)

        if degmin == 0
            all_zero_vertices = findall(==(0), degrees)
            return length(all_zero_vertices) + _xiao2013(remove_vertices(g, all_zero_vertices))
        elseif degmin == 1
            return 1 + _xiao2013(remove_vertices(g, neighbors(g, vmin) ∪ vmin))
        elseif degmin == 2
            return 1 + _xiao2013(folding(g, vmin)[1])
        end

        # reduction rules

        unconfined_vs = unconfined_vertices(g)
        if length(unconfined_vs) != 0
            rem_vertices!(g, [unconfined_vs[1]])
            return _xiao2013(g)
        end

        twin_filter!(g) && return _xiao2013(g) + 2
        short_funnel_filter!(g) && return _xiao2013(g) + 1
        desk_filter!(g) && return _xiao2013(g) + 2

        # branching rules

        ev = effective_vertex(g)
        if !isnothing(ev)
            a, S_a = ev
            return max(_xiao2013(remove_vertices(g, closed_neighbors(g, S_a))) + length(S_a), _xiao2013(remove_vertices(g, [a])))
        end

        opt_funnel = optimal_funnel(g)
        if !isnothing(opt_funnel)
            a,b = opt_funnel
            S_b = confined_set(g, [b])
            return max(_xiao2013(remove_vertices(g, closed_neighbors(g, [a]))) + 1, _xiao2013(remove_vertices(g, closed_neighbors(g, S_b))) + length(S_b))
        end

        opt_quad = optimal_four_cycle(g)
        if !isnothing(opt_quad)
            a, b, c, d = opt_quad
            return max(_xiao2013(remove_vertices(g, [a,c])), _xiao2013(remove_vertices(g, [b,d])))
        end

        v = optimal_vertex(g)
        S_v = confined_set(g, [v])
        return max(_xiao2013(remove_vertices(g, closed_neighbors(g, S_v))) + length(S_v), _xiao2013(remove_vertices(g, [v])))
    end
end