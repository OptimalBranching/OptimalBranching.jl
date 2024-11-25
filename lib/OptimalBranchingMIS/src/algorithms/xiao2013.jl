# the algorithm in Confining sets and avoiding bottleneck cases: A simple maximum independent set algorithm in degree-3 graphs
export mis_xiao2013, count_xiao2013


"""
    mis_xiao2013(g::SimpleGraph)

# Arguments
- `g::SimpleGraph`: The input graph for which the maximum independent set is to be calculated.

# Returns
- `CountingMIS.mis`: The size of the MIS of a graph `g`.
"""
function mis_xiao2013(g::SimpleGraph)
    gc = copy(g)    
    return _xiao2013(gc).mis
end


"""
    count_xiao2013(g::SimpleGraph)

Uses the branch and bound algorithm in xiao2013 to search for the size of the MIS of a graph `g`. 

# Arguments
- `g::SimpleGraph`: The input graph for which the maximum independent set is to be calculated.

# Returns
- `CountingMIS.count`: The number of branches generated during the entire process.
"""
function count_xiao2013(g::SimpleGraph)
    gc = copy(g)
    return _xiao2013(gc).count
end


function _xiao2013(g::SimpleGraph)
    if nv(g) == 0
        return CountingMIS(0)
    elseif nv(g) == 1
        return CountingMIS(1)
    elseif nv(g) == 2
        return CountingMIS(2 - has_edge(g, 1, 2))
    else
        degrees = degree(g)
        degmin = minimum(degrees)
        vmin = findfirst(==(degmin), degrees)

        if degmin == 0
            all_zero_vertices = findall(==(0), degrees)
            return length(all_zero_vertices) + _xiao2013(remove_vertex(g, all_zero_vertices))
        elseif degmin == 1
            return 1 + _xiao2013(remove_vertex(g, neighbors(g, vmin) ∪ vmin))
        elseif degmin == 2
            return 1 + _xiao2013(folding(g, vmin))
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