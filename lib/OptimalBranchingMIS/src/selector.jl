"""
    struct MinBoundarySelector <: AbstractVertexSelector

The `MinBoundarySelector` struct represents a strategy for selecting a subgraph with the minimum number of open vertices by k-layers of neighbors.

# Fields
- `k::Int`: The number of layers of neighbors to consider when selecting the subgraph.

"""
struct MinBoundarySelector <: AbstractSelector
    k::Int # select the subgraph with minimum open vertices by k-layers of neighbors
end

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