"""
    struct MinBoundarySelector <: AbstractSelector

The `MinBoundarySelector` struct represents a strategy for selecting a subgraph with the minimum number of open vertices by k-layers of neighbors.

# Fields
- `k::Int`: The number of layers of neighbors to consider when selecting the subgraph.

"""
struct MinBoundarySelector <: AbstractSelector
    k::Int # select the subgraph with minimum open vertices by k-layers of neighbors
end

function OptimalBranchingCore.select_variables(p::MISProblem, m::M, selector::MinBoundarySelector) where{M<:AbstractMeasure}
    g = p.g
    @assert nv(g) > 0
    kneighbor = selector.k

    local vs_min
    
    novs_min = nv(g)
    for v in 1:nv(g)
        vs, ovs = neighbor_cover(g, v, kneighbor)
        if length(ovs) < novs_min
            vs_min = vs
            novs_min = length(ovs)
        end
    end
    @debug "Selecting vertices $(vs_min) by boundary"
    return vs_min
end

"""
    struct MinBoundaryHighDegreeSelector <: AbstractVertexSelector

The `MinBoundaryHighDegreeSelector` struct represents a strategy:
    - if exists a vertex with degree geq high_degree_threshold, then select it and its k-degree neighbors.
    - otherwise, select a subgraph with the minimum number of open vertices by k-layers of neighbors.

# Fields
- `kb::Int`: The number of layers of neighbors to consider when selecting the subgraph.
- `hd::Int`: The threshold of degree for a vertex to be selected.
- `kd::Int`: The number of layers of neighbors to consider when selecting the subgraph.

"""
struct MinBoundaryHighDegreeSelector <: AbstractSelector
    kb::Int # k-boundary
    hd::Int # high-degree threshold
    kd::Int # k-degree
end

function OptimalBranchingCore.select_variables(p::MISProblem, m::M, selector::MinBoundaryHighDegreeSelector) where{M<:AbstractMeasure}
    g = p.g
    @assert nv(g) > 0
    local vs_min
    # if exists a vertex with degree geq 6, then select it and it 1st-order neighbors.
    maxdegree, vmax = findmax(degree(g))
    if maxdegree >= selector.hd
        vs_min = neighbor_cover(g, vmax, selector.kd)[1]
        @debug "Selecting vertices $(vs_min) by high degree, degree $(degree(g, vmax))"
        return vs_min
    end
    
    novs_min = nv(g)
    for v in 1:nv(g)
        vs, ovs = neighbor_cover(g, v, selector.kb)
        if length(ovs) < novs_min
            vs_min = vs
            novs_min = length(ovs)
        end
    end
    @debug "Selecting vertices $(vs_min) by boundary"
    return vs_min
end

struct KaHyParSelector <: AbstractSelector 
    app_domain_size::Int
end

edge2vertex(p::MISProblem) = edge2vertex(p.g)

"""
    edge2vertex(g::SimpleGraph)

Connectivity between edges and vertices.

# Arguments
- `g::SimpleGraph`: The input graph.

# Returns
- A sparse matrix where the i-th row and j-th column is 1.0 if there is edge j had an end at vertex i.

"""
function edge2vertex(g::SimpleGraph)
    I = Int[]
    J = Int[]
    edgecount = 0
    @inbounds for i in 1:nv(g)-1, j in g.fadjlist[i]
        if j >i
            edgecount += 1
            push!(I,i)
            push!(I,j)
            push!(J, edgecount)
            push!(J, edgecount)
        end
    end
    return sparse(I, J, ones(length(I)))
end