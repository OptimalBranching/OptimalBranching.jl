struct Path
    vertices::Vector{Int}
end

add_left(path::Path, v::Int) = Path([v; path.vertices])
add_right(path::Path, v::Int) = Path([path.vertices; v])
left_boundary(path::Path) = path.vertices[1]
right_boundary(path::Path) = path.vertices[end]
left_neighbors(path::Path, g::SimpleGraph) = setdiff(neighbors(g, left_boundary(path)), path.vertices)
right_neighbors(path::Path, g::SimpleGraph) = setdiff(neighbors(g, right_boundary(path)), path.vertices)
Base.length(path::Path) = length(path.vertices)
is_o_path(path::Path) = isodd(length(path.vertices))

function is_path(g::SimpleGraph, path::Path)
    for i in 2:length(path.vertices) - 1
        degree(g, path.vertices[i]) != 2 && return false
        Set(neighbors(g, path.vertices[i])) == Set([path.vertices[i-1], path.vertices[i+1]]) || return false
    end
    return true
end


const Beineke_graphs = [
    SimpleGraph(Graphs.SimpleEdge.([(1, 2), (1, 3), (1, 4)])),
    SimpleGraph(Graphs.SimpleEdge.([(1, 2), (1, 3), (1, 4), (2, 3), (2, 5), (3, 5), (4, 5)])),
    SimpleGraph(Graphs.SimpleEdge.([(1, 2), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5), (3, 4), (3, 5), (4, 5)])),
    SimpleGraph(Graphs.SimpleEdge.([(1, 2), (2, 3), (2, 4), (3, 4), (3, 5), (4, 5), (5, 6)])),
    SimpleGraph(Graphs.SimpleEdge.([(1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (2, 5), (3, 4), (4, 5), (5, 6)])),
    SimpleGraph(Graphs.SimpleEdge.([(1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4), (3, 5), (3, 6), (4, 5), (4, 6), (5, 6)])),
    SimpleGraph(Graphs.SimpleEdge.([(1, 2), (1, 3), (1, 4), (2, 3), (2, 5), (3, 4), (4, 6), (5, 6)])),
    SimpleGraph(Graphs.SimpleEdge.([(1, 2), (1, 3), (2, 3), (2, 4), (3, 4), (3, 5), (4, 5), (4, 6), (5, 6)])),
    SimpleGraph(Graphs.SimpleEdge.([(1, 2), (1, 3), (1, 4), (2, 3), (2, 5), (3, 4), (3, 5), (3, 6), (4, 6), (5, 6)])),
]

function is_line_graph(g::SimpleGraph)
    for check_graph in Beineke_graphs
        if Graphs.Experimental.has_induced_subgraphisomorph(g,check_graph)
            return false
        end
    end
    return true
end

# For a subset `vertex_set` of vertices, find its children, who has only one neighbor in the subset.
function find_children(g::SimpleGraph, vertex_set::Vector{Int})
    u_vertices = Int[]
    for v in open_neighbors(g, vertex_set)
        length(intersect(neighbors(g, v), vertex_set)) == 1 && push!(u_vertices, v)
    end
    return u_vertices
end

# For a subset `vertex_set` of vertices, find its children and the corresponding parent.
function find_family(g::SimpleGraph, vertex_set::Vector{Int})
    u_vertices = Int[]
    v_vertices = Int[]
    for v in open_neighbors(g, vertex_set)
        if length(intersect(neighbors(g, v), vertex_set)) == 1
            push!(u_vertices, v)
            push!(v_vertices, intersect(neighbors(g, v), vertex_set)[1])
        end
    end
    return u_vertices, v_vertices
end

function is_independent(g::SimpleGraph, vertex_set::Vector{Int})
    for i in 1:length(vertex_set), j in i+1:length(vertex_set)
        has_edge(g, vertex_set[i], vertex_set[j]) && return false
    end
    return true
end

function unconfined_vertices(g::SimpleGraph)
    u_vertices = Int[]
    for v in 1:nv(g)
        isempty(confined_set(g, [v])) && push!(u_vertices, v)
    end
    return u_vertices
end

# `Confined_set` is defined by Xiao in [https://www.sciencedirect.com/science/article/pii/S0304397512008729]. 
# If `S` is contained in any maximum independent set of `G`, then `confined_set(G, S)` is contained in any maximum independent set of `G`.
function confined_set(g::SimpleGraph, S::Vector{Int})
    N_S = closed_neighbors(g, S)
    us = find_children(g, S)
    isempty(us) && return S

    ws = []
    for u in us
        w = setdiff(neighbors(g, u), N_S)
        isempty(w) && return Int[]
        push!(ws, w)
    end

    (minimum(length.(ws)) ≥ 2) && return S

    # all length(w) = 1
    W = [w[1] for w in ws if length(w) == 1]
    if is_independent(g, W)
        return confined_set(g, unique(S ∪ W))
    else
        return Int[]
    end
end
function twin_filter!(g::SimpleGraph)
    twin_pair = first_twin(g)
    isnothing(twin_pair) && return false

    neighbor = copy(neighbors(g, twin_pair[1]))
    if is_independent(g,neighbor)
        add_vertex!(g)
        for left_neighbor in unique(vcat([neighbors(g, neighbori) for neighbori in neighbor]...))
            add_edge!(g,nv(g),left_neighbor)  
        end
    end
    @debug "Removing twin vertices, $(twin_pair[1]) $(twin_pair[2])"
    rem_vertices!(g, vcat([twin_pair[1],twin_pair[2]],neighbor))

    return true
end

function twin_filter_vmap(g::SimpleGraph{Int})
    g = copy(g)
    twin_pair = first_twin(g)
    isnothing(twin_pair) && return nothing
    neighbor = copy(neighbors(g, twin_pair[1]))
    if is_independent(g,neighbor)
        for left_neighbor in unique(vcat([neighbors(g, neighbori) for neighbori in neighbor]...))
            (twin_pair[1] != left_neighbor) && add_edge!(g, twin_pair[1], left_neighbor)  
        end
        return remove_vertices_vmap(g, vcat(twin_pair[2], neighbor))
    else
        return remove_vertices_vmap(g, vcat(twin_pair[1], twin_pair[2], neighbor))
    end
end

function first_twin(g::SimpleGraph)
    vertices_with_degree_3 = [v for v in vertices(g) if degree(g, v) == 3]
    for (v1, v2) in combinations(vertices_with_degree_3, 2)
        (Set(neighbors(g, v1)) == Set(neighbors(g, v2))) && return (v1,v2)
    end
    return nothing
end

function is_complete_graph(g::SimpleGraph, vertices::Vector)
    (length(vertices) <= 1) && return false
    for (u, v) in combinations(vertices, 2)
        (!has_edge(g, u, v)) && return false
    end
    return true
end

function short_funnel_filter!(g::SimpleGraph)
    funnel_pair = first_short_funnel(g)
    isnothing(funnel_pair) && return false

    a,b = funnel_pair
    @debug "Removing short funnel vertices, $(a) $(b)"
    N_a = neighbors(g, a)
    N_b = neighbors(g, b)
    for u in setdiff(N_a,vcat(N_b,[b])), v in setdiff(N_b,vcat(N_a,[a]))
        (!has_edge(g,u,v)) && add_edge!(g,u,v)
    end
    rem_vertices!(g, [a,b])

    return true
end

function short_funnel_filter_vmap(g::SimpleGraph{Int})
    g = copy(g)
    funnel_pair = first_short_funnel(g)
    isnothing(funnel_pair) && return nothing

    a,b = funnel_pair
    @debug "Removing short funnel vertices, $(a) $(b)"
    N_a = neighbors(g, a)
    N_b = neighbors(g, b)
    for u in setdiff(N_a,vcat(N_b,[b])), v in setdiff(N_b,vcat(N_a,[a]))
        (!has_edge(g,u,v)) && add_edge!(g,u,v)
    end
    return remove_vertices_vmap(g, [a,b]) 
end

function first_short_funnel(g::SimpleGraph)
    for a in vertices(g)
        neighbors_a = neighbors(g, a)
        for b in neighbors_a
            neighbors_a_minus_b = setdiff(neighbors_a, [b])
            if is_complete_graph(g, neighbors_a_minus_b)
                neighbors_b_minus_a = setdiff(neighbors(g, b), [a])
                num_nonadjacent_vertices = count(!has_edge(g, v1, v2) for v1 in neighbors_a_minus_b for v2 in neighbors_b_minus_a)
                if length(intersect(neighbors(g, b),neighbors(g, a))) == 0 && num_nonadjacent_vertices <= degree(g, b)
                    return (a,b)
                end
            end
        end
    end
    return nothing
end


function desk_filter!(g::SimpleGraph)
    desk_group = first_desk(g)
    isnothing(desk_group) && return false

    a,b,c,d = desk_group
    @debug "Removing desk vertices, $(a) $(b) $(c) $(d)"
    for u in setdiff(open_neighbors(g, [a,c]), closed_neighbors(g, [b,d])) # N(a, c) - N[b, d]
        for v in setdiff(open_neighbors(g, [b,d]), closed_neighbors(g, [a,c])) # N(b, d) - N[a, c]
            !has_edge(g,u,v) && add_edge!(g,u,v)
        end
    end
    rem_vertices!(g, [a,b,c,d])

    return true
end

function desk_filter_vmap(g::SimpleGraph{Int})
    g = copy(g)
    desk_group = first_desk(g)
    isnothing(desk_group) && return nothing

    a,b,c,d = desk_group
    @debug "Removing desk vertices, $(a) $(b) $(c) $(d)"
    for u in setdiff(open_neighbors(g, [a,c]), closed_neighbors(g, [b,d])) # N(a, c) - N[b, d]
        for v in setdiff(open_neighbors(g, [b,d]), closed_neighbors(g, [a,c])) # N(b, d) - N[a, c]
            !has_edge(g,u,v) && add_edge!(g,u,v)
        end
    end
    return remove_vertices_vmap(g, [a,b,c,d])
end

function first_desk(g::SimpleGraph)
    all_cycles = simplecycles_limited_length(g, 4)
    cycles_of_length_4 = filter(c -> (length(c) == 4 && c[end] > c[2]), all_cycles)
    for quad in cycles_of_length_4
        a, b, c, d = quad
        if all(i -> degree(g, i) ≥ 3, quad)
            if !(has_edge(g, c, a) || has_edge(g, d, b))
                neighbor_A = open_neighbors(g, [a,c])
                neighbor_B = open_neighbors(g, [b,d])
                if isempty(intersect(neighbor_A,neighbor_B)) && length(setdiff(neighbor_A,[b,d])) <= 2 && length(setdiff(neighbor_B,[a,c])) <= 2
                    return (a,b,c,d)
                end
            end
        end
    end
    return nothing
end

function all_n_funnel(g::SimpleGraph, n::Int)
    n_funnels = []
    for a in filter(v -> degree(g,v) == n, vertices(g))
        neighbors_a = neighbors(g, a)
        for b in neighbors_a
            neighbors_a_minus_b = setdiff(neighbors_a, [b])
            is_complete_graph(g, neighbors_a_minus_b) && push!(n_funnels,(a,b))
        end
    end
    return n_funnels
end

all_three_funnel(g::SimpleGraph) = all_n_funnel(g, 3)
all_four_funnel(g::SimpleGraph) = all_n_funnel(g, 4)

function rho(g::SimpleGraph) 
    nv(g) == 0 && return 0
    return sum(max(degree(g,v) - 2, 0) for v in 1:nv(g))
end

function effective_vertex(g::SimpleGraph)
    for funnel_pair in all_three_funnel(g)
        a,b = funnel_pair
        N_a = neighbors(g,a)
        !all(degree(g,n) == 3 for n in N_a) && continue
        S_a = confined_set(g,[a])
        isempty(S_a) && continue
        g_left = copy(g)
        rem_vertices!(g_left, closed_neighbors(g, S_a))
        (rho(g) - rho(g_left)) >= 20 && return (a, S_a)
    end

    return nothing
end

function in_triangle(g::SimpleGraph, b::Int)
    neighbor = neighbors(g, b)
    for nb1 in 1:length(neighbor), nb2 in nb1+1:length(neighbor)
        has_edge(g, neighbor[nb1], neighbor[nb2]) && return true
    end
    return false
end

function optimal_funnel(g::SimpleGraph)
    # i) select four-funnel
    four_funnels = all_four_funnel(g)
    !isempty(four_funnels) && return four_funnels[1]

    three_funnels = all_three_funnel(g)
    isempty(three_funnels) && return nothing

    # ii) select three-funnel with degree(b) >= 4
    for funnel_pair in three_funnels
        a,b = funnel_pair
        degree(g,b) >= 4 && return funnel_pair
    end

    # iii) select three-funnel with b in triangle
    for funnel_pair in three_funnels
        a,b = funnel_pair
        in_triangle(g,b) && return funnel_pair
    end

    # iv) select three-funnel with degree(nab) >= 4
    for funnel_pair in three_funnels
        a,b = funnel_pair
        for nab in open_neighbors(g, [a,b])
            degree(g,nab) >= 4 && return funnel_pair
        end
    end

    # v) select three-funnel leads to a fine instance
    for funnel_pair in three_funnels
        a,b = funnel_pair
        g_left = remove_vertices(g, closed_neighbors(g, [b]))
        has_fine_structure(g_left) && return funnel_pair
    end

    # @error "No optimal funnel found"
    return nothing
end

function has_fine_structure(g::SimpleGraph)
    any(degree(g) .>= 4) && return true

    primitive_cycles = Graphs.cycle_basis(g)
    for cycle in primitive_cycles
        big_degree_vertices_num = count(x -> x >= 3, [degree(g,v) for v in cycle])
        if big_degree_vertices_num <= 4 && big_degree_vertices_num >= 1
            return true 
        end
    end

    !iszero(count_o_path(g)) && return true

    return false
end

function count_o_path(g::SimpleGraph)
    o_paths = all_o_path(g)
    return length(o_paths)
end

function all_o_path(g::SimpleGraph)
    o_paths = Vector{Vector{Int}}()
    d2v = filter(v -> degree(g,v) == 2, vertices(g))
    while !isempty(d2v)
        v = pop!(d2v)
        is_path, path = find_path(g, Path([v]))
        d2v = setdiff(d2v, path.vertices)
        (is_path && is_o_path(path)) && push!(o_paths, path.vertices)
    end
    return o_paths
end

function find_path(g::SimpleGraph, path::Path)
    l, r = left_boundary(path), right_boundary(path)
    if degree(g, l) == 2
        lneighbors = left_neighbors(path, g)
        isempty(lneighbors) && return (false, path)
        path = add_left(path, lneighbors[1])
        return find_path(g, path)
    elseif degree(g, r) == 2
        rneighbors = right_neighbors(path, g)
        isempty(rneighbors) && return (false, path)
        path = add_right(path, rneighbors[1])
        return find_path(g, path)
    else
        return (true, path)
    end
end

function optimal_four_cycle(g::SimpleGraph)
    all_cycles = simplecycles_limited_length(g, 4)
    cycles_of_length_4 = filter(c -> (length(c) == 4 && c[end] > c[2]), all_cycles)

    isempty(cycles_of_length_4) && return nothing

    for quad in cycles_of_length_4
        a, b, c, d = quad
        if (degree(g,a) == 3 && degree(g,c) == 3) || (degree(g,b) == 3 && degree(g,d) == 3)
            return quad
        end
    end

    counts = [count(v -> degree(g, v) == 3, quad) for quad in cycles_of_length_4]
    i = findfirst(x -> x == maximum(counts), counts)
    return cycles_of_length_4[i]
end

function N2v(g::SimpleGraph, v::Int)
    return closed_neighbors(g, closed_neighbors(g, [v]))
end

function optimal_vertex(g::SimpleGraph)
    degrees = degree(g)
    vs = filter(v -> degrees[v] == maximum(degrees), vertices(g))

    if maximum(degrees) > 3
        vsgeq3 = filter(v -> degrees[v] >= 3, vs)
        size_n2v = [length(N2v(g, v)) for v in vsgeq3]
        return vsgeq3[findfirst(x -> x == maximum(size_n2v), size_n2v)]
    end

    if maximum(degrees) == 3
        num_o_path = [count_o_path(remove_vertices(g, closed_neighbors(g, [v]))) for v in vs]
        return vs[findfirst(x -> x == maximum(num_o_path), num_o_path)]
    end

    @error "No optimal vertex found"
end