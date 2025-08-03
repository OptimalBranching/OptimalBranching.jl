# For a subset `vertex_set` of weighted vertices, find its children and the corresponding parents.
function find_family(g::SimpleGraph, vertex_set::Vector{Int}, weights::Vector{WT}) where WT
    u_vertices = Int[]
    vs_vertices = Vector{Int}[]
    for v in open_neighbors(g, vertex_set)
        if weights[v] >= sum(weights[collect(intersect(neighbors(g, v), vertex_set))])
            push!(u_vertices, v)
            push!(vs_vertices, collect(intersect(neighbors(g, v), vertex_set)))
        end
    end
    return u_vertices, vs_vertices
end

# Delete v from the graph if it is unconfined
# Corresponding to Rule 5 in Xiao's paper.
function unconfined_vertices(g::SimpleGraph, weights::Vector{WT}) where WT
    u_vertices = Int[]
    for v in 1:nv(g)
        confinedset = confined_set(g, weights, [v])
        isempty(confinedset) && push!(u_vertices, v)
    end
    return u_vertices
end

# `Confined_set` is defined by Xiao in [https://dl.acm.org/doi/abs/10.1145/3442381.3450130]. 
# If `S` is contained in any maximum independent set of `G`, then `confined_set(G, S)` is contained in any maximum independent set of `G`.
function confined_set(g::SimpleGraph, weights::Vector{WT}, S::Vector{Int}) where WT
    N_S = closed_neighbors(g, S)
    us, vss = find_family(g, S, weights) 
    isempty(us) && return S

    ws = Vector{Int}[]
    for u_idx in 1:length(us)
        u = us[u_idx]
        vs = vss[u_idx]
        w = setdiff(neighbors(g, u), N_S)
        if isempty(w) 
            return Int[]
        elseif sum(weights[collect(w)]) + sum(weights[vs]) <= weights[u]  
            return Int[]
        elseif length(w) == 1
            push!(ws, w)
        end
    end

    (length(ws) == 0) && return S

    W = unique(vcat(ws...))
    if is_independent(g, W)
        return confined_set(g, weights,unique(S ∪ W))
    else
        return Int[]
    end
end

# `Critical_set` is defined by Xiao, which is the subset maximizing w(I) − w(N(I)).
function find_critical_set(g::SimpleGraph, weights::Vector{WT}) where WT
    model = Model(HiGHS.Optimizer)
    set_silent(model)
    @variable(model, 0 <= x[i = 1:2*nv(g)] <= 1)
    @objective(model, Max, sum(x[i] * weights[i] for i in 1:nv(g)) - sum(x[i + nv(g)] * weights[i] for i in 1:nv(g)))
    for edge in edges(g)
        @constraint(model, x[src(edge) + nv(g)] >= x[dst(edge)])
        @constraint(model, x[dst(edge) + nv(g)] >= x[src(edge)])
    end
    optimize!(model)
    xs = value.(x)
    if sum(xs) == 2*nv(g) || any(x != 0 && x != 1 for x in xs)
        return Int[]
    else
        return [i for i in 1:nv(g) if xs[i] == 1]
    end
end

# the maximum independent critical set, consists of isolated vertices in the critical set.
# Corresponding to Rule 4 in Xiao's paper.
function find_independent_critical_set(g::SimpleGraph, weights::Vector{WT}) where WT
    critical_set = find_critical_set(g, weights)
    critical_independent_set = Int[]
    for i in critical_set
        if !any(j in critical_set for j in neighbors(g, i))
            push!(critical_independent_set, i)
        end
    end
    return critical_independent_set
end

# Corresponding to Rule 1 in Xiao's paper.
function fast_heavy_vertex_vmap(g::SimpleGraph, weights::Vector{WT}) where WT
    for v in 1:nv(g)
        v_neighbors = collect(neighbors(g, v))
        mis_vneighbors = sum(weights[v_neighbors])
        if weights[v] >= mis_vneighbors
            g_new, vmap = induced_subgraph(g, setdiff(1:nv(g), [v] ∪ v_neighbors))
            return g_new, weights[vmap], weights[v], vmap
        end
    end
    return g, weights, 0, collect(1:nv(g))
end

# Corresponding to Rule 2 in Xiao's paper.
function heavy_vertex_vmap(g::SimpleGraph, weights::Vector{WT}) where WT
    for v in 1:nv(g)
        v_neighbors = collect(neighbors(g, v))
        if length(v_neighbors) <= 8
            problem_sg = GenericTensorNetwork(IndependentSet(induced_subgraph(g,v_neighbors)[1], weights[induced_subgraph(g,v_neighbors)[2]]); optimizer = GreedyMethod())
            mis_vneighbors = solve(problem_sg, SizeMax())[].n
        else
            continue
        end
        if weights[v] >= mis_vneighbors
            g_new, vmap = induced_subgraph(g, setdiff(1:nv(g), [v] ∪ v_neighbors))
            return g_new, weights[vmap], weights[v], vmap
        end
    end
    return g, weights, 0, collect(1:nv(g))
end

# Corresponding to Rule 3 in Xiao's paper.
function heavy_pair_vmap(g::SimpleGraph, weights::Vector{WT}) where WT
    for v in 1:nv(g)
        for inter_v in neighbors(g, v)
            for u in neighbors(g, inter_v)
                if u > v && !has_edge(g, u, v)
                    vu_neighbors = collect(neighbors(g, v)) ∪ collect(neighbors(g, u))
                    only_v_neighbors = setdiff(collect(neighbors(g, v)), collect(neighbors(g, u)))
                    only_u_neighbors = setdiff(collect(neighbors(g, u)), collect(neighbors(g, v)))
                    if length(vu_neighbors) <= 8
                        problem_sg = GenericTensorNetwork(IndependentSet(induced_subgraph(g,only_v_neighbors)[1], weights[induced_subgraph(g,only_v_neighbors)[2]]); optimizer = GreedyMethod())
                        mis_only_v_neighbors = solve(problem_sg, SizeMax())[].n
                        if mis_only_v_neighbors > weights[v]
                            continue
                        end
                        problem_sg = GenericTensorNetwork(IndependentSet(induced_subgraph(g,only_u_neighbors)[1], weights[induced_subgraph(g,only_u_neighbors)[2]]); optimizer = GreedyMethod())
                        mis_only_u_neighbors = solve(problem_sg, SizeMax())[].n
                        if mis_only_u_neighbors > weights[u]
                            continue
                        end
                        problem_sg = GenericTensorNetwork(IndependentSet(induced_subgraph(g,vu_neighbors)[1], weights[induced_subgraph(g,vu_neighbors)[2]]); optimizer = GreedyMethod())
                        mis_vu_neighbors = solve(problem_sg, SizeMax())[].n
                        if mis_vu_neighbors <= weights[v] + weights[u]
                            g_new, vmap = induced_subgraph(g, setdiff(1:nv(g), [v, u] ∪ vu_neighbors))
                            return g_new, weights[vmap], weights[v] + weights[u], vmap
                        end
                    else
                        mis_vuneighbors = sum(weights[vu_neighbors])
                        if mis_vuneighbors <= weights[v] + weights[u]
                            g_new, vmap = induced_subgraph(g, setdiff(1:nv(g), [v, u] ∪ vu_neighbors))
                            return g_new, weights[vmap], weights[v] + weights[u], vmap
                        end
                    end
                end 
            end
        end
    end
    return g, weights, 0, collect(1:nv(g))
end

# Corresponding to Rule 7 in Xiao's paper.
function module_vmap(g::SimpleGraph, weights::Vector{WT}) where WT
    neigh_map = Dict{Vector{Int}, Vector{Int}}()
    for v in 1:nv(g)
        v_neighbors = collect(neighbors(g, v))
        if haskey(neigh_map, v_neighbors)
            push!(neigh_map[v_neighbors], v)
        else
            neigh_map[v_neighbors] = [v]
        end
    end
    for (neigh, group) in neigh_map
        if length(group) >= 2 && is_independent(g, group)
            for n in neigh
                add_edge!(g, group[1], n)
            end
            weights[group[1]] = sum(weights[group])
            g_new, vmap = induced_subgraph(g, setdiff(1:nv(g), group[2:end]))
            return g_new, weights[vmap], 0, vmap
        end
    end
    return g, weights, 0, collect(1:nv(g))
end

# Corresponding to Rule 8 in Xiao's paper.
function confined_pair_vmap(g::SimpleGraph, weights::Vector{WT}) where WT
    confinedsets = Vector{Int}[]
    for v in 1:nv(g)
        confinedset = confined_set(g, weights, [v])
        push!(confinedsets, confinedset)
    end
    for v in 1:nv(g)
        for u in v+1:nv(g)
            if u in confinedsets[v] && v in confinedsets[u]
                #delete v and merge v to u
                for n in neighbors(g, v)
                    add_edge!(g, u, n)
                end
                weights[u] = weights[u] + weights[v]
                g_new, vmap = induced_subgraph(g, setdiff(1:nv(g), [v]))
                return g_new, weights[vmap], 0, vmap
            end
        end
    end
    return g, weights, 0, collect(1:nv(g))
end

# Corresponding to Lemmas 3.11 in Rule 9 in Xiao's paper.
function alternative_vertex_vmap(g::SimpleGraph, weights::Vector{WT}) where WT
    for v in 1:nv(g)
        v_neighbors = collect(neighbors(g, v))
        if is_independent(g, v_neighbors)
            if weights[v] < sum(weights[v_neighbors]) && weights[v] >= sum(weights[v_neighbors]) - minimum(weights[v_neighbors])
                for n in v_neighbors
                    for nn in neighbors(g, n)
                        if nn != v
                            add_edge!(g, v, nn)
                        end
                    end
                end
                mwis_diff = weights[v]
                weights[v] = sum(weights[v_neighbors]) - weights[v]
                g_new, vmap = induced_subgraph(g, setdiff(1:nv(g), v_neighbors))
                return g_new, weights[vmap], mwis_diff, vmap
            end
        end
    end
    return g, weights, 0, collect(1:nv(g))
end

# Corresponding to Lemmas 3.11 in Rule 9 for a given vertex in Xiao's paper.
function alternative_vertex_vmap(g::SimpleGraph, weights::Vector{WT}, v::Int) where WT
    v_neighbors = collect(neighbors(g, v))
    if is_independent(g, v_neighbors)
        if weights[v] < sum(weights[v_neighbors]) && weights[v] >= sum(weights[v_neighbors]) - minimum(weights[v_neighbors])
            for n in v_neighbors
                for nn in neighbors(g, n)
                    if nn != v
                        add_edge!(g, v, nn)
                    end
                end
            end
            mwis_diff = weights[v]
            weights[v] = sum(weights[v_neighbors]) - weights[v]
            g_new, vmap = induced_subgraph(g, setdiff(1:nv(g), v_neighbors))
            return g_new, weights[vmap], mwis_diff, vmap
        end
    end
    return g, weights, 0, collect(1:nv(g))
end

# Corresponding to Lemmas 3.12 and 3.13 in Rule 9 in Xiao's paper.
function alternative_path_cycle_vmap(g::SimpleGraph, weights::Vector{WT}) where WT
    for v2 in 1:nv(g)
        if degree(g, v2) == 2
            for v3 in neighbors(g, v2)
                if degree(g, v3) == 2
                    v4 = setdiff(neighbors(g, v3), [v2])[1]
                    v1 = setdiff(neighbors(g, v2), [v3])[1]
                    if v1 == v4
                        continue
                    end
                    if !has_edge(g, v1, v4)
                        if weights[v1] >= weights[v2] && weights[v2] >= weights[v3] && weights[v3] >= weights[v4]
                            for n in union(neighbors(g, v1), [v4])
                                if n != v2
                                    add_edge!(g, v2, n)
                                end
                            end
                            mwis_diff = weights[v2] 
                            weights[v2] = weights[v1] + weights[v3] - weights[v2]
                            g_new, vmap = induced_subgraph(g, setdiff(1:nv(g), [v1, v3]))
                            return g_new, weights[vmap], mwis_diff, vmap
                        end
                    else
                        if weights[v1] >= weights[v2] && weights[v2] >= weights[v3]
                            for n in union(neighbors(g, v1), [v4])
                                if n != v2
                                    add_edge!(g, v2, n)
                                end
                            end
                            mwis_diff = weights[v2] 
                            weights[v2] = weights[v1] + weights[v3] - weights[v2]
                            g_new, vmap = induced_subgraph(g, setdiff(1:nv(g), [v1, v3]))
                            return g_new, weights[vmap], mwis_diff, vmap
                        end
                    end
                end
            end
        end
    end
    return g, weights, 0, collect(1:nv(g))
end

# Corresponding to Rule 10 in Xiao's paper.
function isolated_vertex_vmap(g::SimpleGraph, weights::Vector{WT}) where WT
    for v in 1:nv(g)
        if is_complete_graph(g, neighbors(g, v))
            light_neighbors = Int[]
            for n in neighbors(g, v)
                if weights[n] <= weights[v]
                    push!(light_neighbors, n)
                else
                    weights[n] = weights[n] - weights[v]
                end
            end
            mwis_diff = weights[v] 
            g_new, vmap = induced_subgraph(g, setdiff(1:nv(g), union([v], light_neighbors)))
            return g_new, weights[vmap], mwis_diff, vmap
        end
    end
    return g, weights, 0, collect(1:nv(g))
end

# Corresponding to Rule 10 for a given vertex in Xiao's paper.
function isolated_vertex_vmap(g::SimpleGraph, weights::Vector{WT}, v::Int) where WT
    if is_complete_graph(g, neighbors(g, v))
        light_neighbors = Int[]
        for n in neighbors(g, v)
            if weights[n] <= weights[v]
                push!(light_neighbors, n)
            else
                weights[n] = weights[n] - weights[v]
            end
        end
        mwis_diff = weights[v] 
        g_new, vmap = induced_subgraph(g, setdiff(1:nv(g), union([v], light_neighbors)))
        return g_new, weights[vmap], mwis_diff, vmap
    end
    return g, weights, 0, collect(1:nv(g))
end