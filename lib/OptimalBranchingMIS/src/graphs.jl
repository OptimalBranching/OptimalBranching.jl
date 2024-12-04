function graph_from_tuples(n::Int, edgs)
    g = SimpleGraph(n)
    for (i, j) in edgs
        add_edge!(g, i, j)
    end
    g
end

"""
    removed_vertices(vertices::Vector{Int}, g::SimpleGraph, clause::Clause{N}) where N

Given a list of vertices, a graph, and a clause, this function returns a list of removed vertices. 

The `vertices` argument is a vector of integers representing the vertices to consider. 
The `g` argument is a `SimpleGraph` object representing the graph.
The `clause` argument is a `Clause` object representing a clause.

The function iterates over the `vertices` and checks if the corresponding bit in the `clause.mask` is 1. 
If it is, the vertex is added to the list of removed vertices (`rvs`). 
If the corresponding bit in the `clause.val` is also 1, the neighbors of the vertex are also added to `rvs`.

The function returns the list of removed vertices with duplicates removed.
"""
function removed_vertices(vertices::Vector{Int}, g::SimpleGraph, clause::Clause{N}) where N
    rvs = Int[]
    for (k, v) in enumerate(vertices)
        if readbit(clause.mask, k) == 1
            push!(rvs, v)
            if readbit(clause.val, k) == 1
                append!(rvs, neighbors(g, v))
            end
        end
    end
    return unique!(rvs)
end

function remove_vertices(g, v)
    g, vs = induced_subgraph(g, setdiff(vertices(g), v))
    return g
end

"""
    open_vertices(g::SimpleGraph, vertices::Vector{Int})

Remove vertices from the given vector that are connected to all other vertices in the graph.

# Arguments
- `g::SimpleGraph`: The graph object.
- `vertices::Vector{Int}`: The vector of vertices.

# Returns
- `Vector{Int}`: The open vertices.

"""
function open_vertices(g::SimpleGraph, vertices::Vector{Int})
    return unique!([v for v in vertices if !all(x->x ∈ vertices, neighbors(g, v))])
end

"""
    open_neighbors(g::SimpleGraph, vertices::Vector{Int})

Returns a vector of vertices in the graph `g`, which are neighbors of the given vertices and not in the given vertices.

# Arguments
- `g::SimpleGraph`: The graph in which to find the open neighbors.
- `vertices::Vector{Int}`: The vertices for which to find the open neighbors.

# Returns
A vector of open neighbors of the given vertices.

"""
function open_neighbors(g::SimpleGraph, vertices::Vector{Int})
    ov = Vector{Int}()
    for v in vertices
        for n in neighbors(g, v)
            push!(ov, n)
        end
    end
    return unique!(setdiff(ov, vertices))
end

"""
    closed_neighbors(g::SimpleGraph, vertices::Vector{Int})

Returns a set of vertices that includes the input `vertices` as well as their open neighbors.

# Arguments
- `g::SimpleGraph`: The input graph.
- `vertices::Vector{Int}`: The vertices for which closed neighbors are to be computed.

# Returns
A set of vertices that includes the input `vertices` as well as their open neighbors.

"""
function closed_neighbors(g::SimpleGraph, vertices::Vector{Int})
    return vertices ∪ open_neighbors(g, vertices)
end

"""
    neighbor_cover(g::SimpleGraph, v::Int, k::Int)

Compute the neighbor cover of a vertex in a graph.

# Arguments
- `g::SimpleGraph`: The input graph.
- `v::Int`: The vertex for which to compute the neighbor cover.
- `k::Int`: The number of iterations to perform.

# Returns
- `vertices`: An array containing the vertices in the neighbor cover.
- `openvertices`: An array containing the open vertices in the neighbor cover.

"""
function neighbor_cover(g::SimpleGraph, v::Int, k::Int)
    @assert k >= 0
    vertices = [v]
    for _ = 1:k
        vertices = union(vertices, (neighbors(g, w) for w in vertices)...)
    end
    openvertices = open_vertices(g, vertices)
    return vertices, openvertices
end

"""
    neighbors_2nd(g::SimpleGraph, v::Int)

Return the second-order neighbors of a vertex `v` in a simple graph `g`.

# Arguments
- `g::SimpleGraph`: The simple graph.
- `v::Int`: The vertex.

# Returns
- `Array{Int}`: An array of second-order neighbors of `v`.

"""
function neighbors_2nd(g::SimpleGraph, v::Int)
    return open_neighbors(g, v ∪ neighbors(g, v))
end

# vs a subgraph, return N(vs)
function Graphs.neighbors(g::SimpleGraph, vs::Vector{Int})
    set_vs = Set(vs)
    set_neighbors = Set{Int}()
    for v in vs
        neighbors_v = neighbors(g, v)
        for n in neighbors_v
            if n ∉ set_vs
                push!(set_neighbors, n)
            end
        end
    end
    return set_neighbors
end

function folding(g::SimpleGraph, v::Int)
    @debug "Folding vertex" v
    @assert degree(g, v) == 2
    a, b = neighbors(g, v)
    if has_edge(g, a, b)
        return (induced_subgraph(g, setdiff(1:nv(g), [v, a, b]))[1], 1)
    else
        # apply the graph rewrite rule
        g = copy(g)
        add_vertex!(g)
        nn = open_neighbors(g, [v, a, b])
        for n in nn
            add_edge!(g, nv(g), n)
        end
        return (induced_subgraph(g, setdiff(1:nv(g), [v, a, b]))[1], 1)
    end
end
