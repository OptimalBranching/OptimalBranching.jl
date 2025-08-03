"""
    counting_xiao2021(g::SimpleGraph, weights::Vector{WT})

This function counts the maximum weighted independent set (MWIS) in a given simple graph with weights on vertices using the Xiao 2021 algorithm.

# Arguments
- `g::SimpleGraph`: A simple graph for which the maximum weighted independent set is to be counted.
- `weights::Vector{WT}`: The weights of the vertices.
# Returns
- `CountingMIS`: An object representing the size of the maximum weighted independent set and the count of branches.

"""
function counting_xiao2021(g::SimpleGraph, weights::Vector{WT}) where WT
    gc = copy(g)    
    return _xiao2021(gc, weights)
end

function _xiao2021(g::SimpleGraph, weights::Vector{WT}) where WT
    if nv(g) == 0
        return MISCount(0.0)
    elseif nv(g) == 1
        return MISCount(weights[1])
    elseif nv(g) == 2
        if !has_edge(g, 1, 2)
            return MISCount(weights[1] + weights[2])
        else
            return MISCount(max(weights[1], weights[2]))
        end
    else
        degrees = degree(g)
        degmin = minimum(degrees)
        vmin = findfirst(==(degmin), degrees)
        if degmin == 0
            all_zero_vertices = findall(==(0), degrees)
            g_new, vmap = remove_vertices_vmap(g, all_zero_vertices)
            return (sum(weights[all_zero_vertices])) + _xiao2021(g_new, weights[vmap])
        end

        g_new, weights_new, mwis_diff, _ = fast_heavy_vertex_vmap(g, weights)
        if g_new != g 
            return WT(mwis_diff) + _xiao2021(g_new, weights_new)
        end
        
        if degmin == 1
            g_new, weights_new, mwis_diff, _ = isolated_vertex_vmap(g, weights, vmin)
            if g_new != g 
                return WT(mwis_diff) + _xiao2021(g_new, weights_new)
            end
        end

        if degmin == 2
            g_new, weights_new, mwis_diff, _ = alternative_vertex_vmap(g, weights, vmin)
            if g_new != g 
                return WT(mwis_diff) + _xiao2021(g_new, weights_new)
            end

            g_new, weights_new, mwis_diff, _ = alternative_path_cycle_vmap(g, weights)
            if g_new != g 
                return WT(mwis_diff) + _xiao2021(g_new, weights_new)
            end

            g_new, weights_new, mwis_diff, _ = isolated_vertex_vmap(g, weights, vmin)
            if g_new != g 
                return WT(mwis_diff) + _xiao2021(g_new, weights_new)
            end
        end

        g_new, weights_new, mwis_diff, _ = module_vmap(g, weights)
        if g_new != g 
            return WT(mwis_diff) + _xiao2021(g_new, weights_new)
        end

        g_new, weights_new, mwis_diff, _ = heavy_vertex_vmap(g, weights)
        if g_new != g 
            return WT(mwis_diff) + _xiao2021(g_new, weights_new)
        end

        g_new, weights_new, mwis_diff, _ = alternative_vertex_vmap(g, weights)
        if g_new != g 
            return WT(mwis_diff) + _xiao2021(g_new, weights_new)
        end

        g_new, weights_new, mwis_diff, _ = isolated_vertex_vmap(g, weights)
        if g_new != g 
            return WT(mwis_diff) + _xiao2021(g_new, weights_new)
        end

        unconfined_vs = unconfined_vertices(g, weights)
        if length(unconfined_vs) != 0
            g_new, vmap = remove_vertices_vmap(g, [unconfined_vs[1]])
            return _xiao2021(g_new, weights[vmap])
        end

        g_new, weights_new, mwis_diff, _ = confined_pair_vmap(g, weights)
        if g_new != g 
            return WT(mwis_diff) + _xiao2021(g_new, weights_new)
        end

        critical_independent_set = find_independent_critical_set(g, weights)
        if length(critical_independent_set) != 0
            mwis_diff = sum(weights[critical_independent_set])
            g_new, vmap = remove_vertices_vmap(g, union(neighbors(g, critical_independent_set),critical_independent_set))
            return WT(mwis_diff) + _xiao2021(g_new, weights[vmap])
        end

        g_new, weights_new, mwis_diff, _ = heavy_pair_vmap(g, weights)
        if g_new != g 
            return WT(mwis_diff) + _xiao2021(g_new, weights_new)
        end

        v_maxdegree = findfirst(==(maximum(degrees)), degrees)
        S_v = confined_set(g, weights, [v_maxdegree])
        mwis_diff1 = sum(weights[S_v])
        g_new_1, vmap_1 = remove_vertices_vmap(g, closed_neighbors(g, S_v))
        mwis_diff2 = 0
        g_new_2, vmap_2 = remove_vertices_vmap(g, [v_maxdegree])
        return max(WT(mwis_diff1) + _xiao2021(g_new_1, weights[vmap_1]), WT(mwis_diff2) + _xiao2021(g_new_2, weights[vmap_2]))
    end
end