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

function OptimalBranchingCore.select_variables(p::MISProblem, m::M, selector::KaHyParSelector) where {M <: AbstractMeasure}
    nv(p.g) <= selector.app_domain_size && return collect(1:nv(p.g))
    h = KaHyPar.HyperGraph(edge2vertex(p))
    imbalance = 1-2*selector.app_domain_size/nv(p.g)
    
    parts = KaHyPar.partition(h, 2; configuration = pkgdir(@__MODULE__, "src/ini", "cut_kKaHyPar_sea20.ini"), imbalance)

    zero_num = count(x-> x ≈ 0,parts)
    one_num = length(parts)-zero_num
    @debug "Selecting vertices by KaHyPar, sizes: $(zero_num), $(one_num)"

    return abs(zero_num-selector.app_domain_size) < abs(one_num-selector.app_domain_size) ? findall(iszero,parts) : findall(!iszero,parts)
end

edge2vertex(p::MISProblem) = edge2vertex(p.g)
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

# region selectors, max size is n_max and a vertex i is required to be in the region
function select_region(g::AbstractGraph, i::Int, n_max::Int, strategy::Symbol)
    if strategy == :neighbor
        vs = [i]
        while length(vs) < n_max
            nbrs = open_neighbors(g, vs)
            (length(vs) + length(nbrs) > n_max) && break
            append!(vs, nbrs)
        end
        return vs
    elseif strategy == :mincut
        nv(g) <= n_max && return collect(1:nv(g))

        fix_vs = fill(-1, nv(g)) 
        fix_vs[i] = 0  

        h = KaHyPar.HyperGraph(edge2vertex(g))
        KaHyPar.fix_vertices(h, nv(g)-1, fix_vs)
        KaHyPar.set_target_block_weights(h, [n_max,nv(g) - n_max])
        parts = KaHyPar.partition(h, 2; configuration = pkgdir(@__MODULE__, "src/ini", "cut_kKaHyPar_sea20.ini"))
        
        return findall(iszero,parts)
    else
        error("Invalid strategy: $strategy, must be :neighbor or :mincut")
    end
end
