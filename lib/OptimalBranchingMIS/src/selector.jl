"""
    struct MinBoundarySelector <: AbstractVertexSelector

The `MinBoundarySelector` struct represents a strategy for selecting a subgraph with the minimum number of open vertices by k-layers of neighbors.

# Fields
- `k::Int`: The number of layers of neighbors to consider when selecting the subgraph.

"""
struct MinBoundarySelector <: AbstractSelector
    k::Int # select the subgraph with minimum open vertices by k-layers of neighbors
end

"""
    select(p::MISProblem, m::M, selector::MinBoundarySelector)

Selects a subgraph from the given `MISProblem` based on the minimum number of open vertices within k-layers of neighbors.

# Arguments
- `p::MISProblem`: The problem instance containing the graph from which to select vertices.
- `m::M`: An instance of a measure associated with the problem (not used in this function).
- `selector::MinBoundarySelector`: The selector strategy that defines the number of neighbor layers to consider.

# Returns
- `Vector{Int}`: A vector of vertices representing the selected subgraph with the minimum number of open vertices.

# Description
This function iterates through each vertex in the graph, computes the neighbor cover for each vertex up to `k` layers, and selects the vertex that results in the minimum number of open vertices. The selected vertices are returned as a vector.
"""
function OptimalBranchingCore.select(p::MISProblem, m::M, selector::MinBoundarySelector) where{M<:AbstractMeasure}
    g = p.g
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
    return vs_min
end