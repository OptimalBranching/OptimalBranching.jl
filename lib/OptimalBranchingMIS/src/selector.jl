"""
    struct MinBoundarySelector <: AbstractVertexSelector

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
    boundary_neighbor = selector.kb
    high_degree_threshold = selector.hd
    high_degree_neighbor = selector.kd

    local vs_min
    # if exists a vertex with degree geq 6, then select it and it 1st-order neighbors.
    for v in 1:nv(g)
        if degree(g, v) ≥ high_degree_threshold
            vs_min = neighbor_cover(g, v, high_degree_neighbor)[1]
            @debug "Selecting vertices $(vs_min) by high degree, degree $(degree(g, v))"
            return vs_min
        end
    end
    
    novs_min = nv(g)
    for v in 1:nv(g)
        vs, ovs = neighbor_cover(g, v, boundary_neighbor)
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

function OptimalBranchingCore.select_variables(p::MISProblem, m::M, selector::KaHyParSelector) where {M <: AbstractMeasure}
    nv(p.g) <= selector.app_domain_size && return collect(1:nv(p.g))
    h = KaHyPar.HyperGraph(edge2vertex(p))
    imbalance = 1-2*selector.app_domain_size/nv(p.g)
    
    parts = KaHyPar.partition(h, 2; configuration = pkgdir(@__MODULE__, "src", "cut_kKaHyPar_sea20.ini"), imbalance)

    zero_num = count(x-> x ≈ 0,parts)
    one_num = length(parts)-zero_num
    @info "Selecting vertices by KaHyPar, sizes: $(zero_num), $(one_num)"

    return abs(zero_num-selector.app_domain_size) < abs(one_num-selector.app_domain_size) ? findall(iszero,parts) : findall(!iszero,parts)
end

function edge2vertex(p::MISProblem)
    I = Int[]
    J = Int[]
    edgecount = 0
    for i in 1:nv(p.g)-1
        for j in p.g.fadjlist[i]
            if j >i
                edgecount += 1
                push!(I,i)
                push!(I,j)
                push!(J, edgecount)
                push!(J, edgecount)
            end
        end
    end
    return sparse(I, J, ones(length(I)))
end