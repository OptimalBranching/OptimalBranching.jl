"""
    MISReducer

An abstract type representing a reducer for the Maximum (Weighted) Independent Set (M(W)IS) problem.
"""
abstract type MISReducer <: AbstractReducer end

"""
    BasicReducer

A basic reducer for the Maximum (Weighted) Independent Set (M(W)IS) problem.
This struct implements the basic reduction rules.
"""
struct BasicReducer <: MISReducer end

"""
    XiaoReducer <: MISReducer

A reducer that uses Xiao's reduction rules to find reduction rules.
"""
struct XiaoReducer <: MISReducer end

"""
    struct TensorNetworkReducer <: MISReducer

A reducer that uses tensor network contraction to find reduction rules.

# Fields
- `n_max::Int = 15`: Maximum number of vertices to be included in the selected region
- `selector::Symbol = :mincut`: Strategy for selecting vertices to contract. Options are:
    - `:neighbor`: Select vertices based on neighborhood
    - `:mincut`: Select vertices based on minimum cut provided by `KaHyPar` (as extension, requires `using KaHyPar`)
      !Note: `KaHyPar` may leads to memory leak!
- `measure::AbstractMeasure = NumOfVertices()`: Measure used for kernelization
- `intersect_strategy::Symbol = :bfs`: Strategy for intersecting clauses. Options are:
    - `:bfs`: Breadth-first search (gives the optimal result)
    - `:dfs`: Depth-first search (gives the first found non-zero intersection)
- `sub_reducer::MISReducer = BasicReducer()`: Reducer applied to selected vertices before tensor network contraction
- `region_list::Dict{Int, Tuple{Vector{Int}, Vector{Int}}}`: Store the selected region
- `recheck::Bool = false`: Whether to recheck the vertices that have not been modified
- `folding::Bool = false`: Whether to fold the vertices
"""
@kwdef mutable struct TensorNetworkReducer <: MISReducer
    n_max::Int = 15
    selector::Symbol = :neighbor # :neighbor or :mincut
    measure::AbstractMeasure = NumOfVertices() # different measures for kernelization
    intersect_strategy::Symbol = :bfs # :dfs or :bfs
    sub_reducer::AbstractReducer = BasicReducer() # sub reducer for the selected vertices
    region_list::Dict{Int, Tuple{Vector{Int}, Vector{Int}}} = Dict{Int, Tuple{Vector{Int}, Vector{Int}}}() # store the selected region
    recheck::Bool = false # whether to recheck the vertices that have not been modified
    folding::Bool = false # whether to fold the vertices
end


Base.show(io::IO, reducer::TensorNetworkReducer) = print(io,
    """
    TensorNetworkReducer
        ├── n_max - $(reducer.n_max)
        ├── selector - $(reducer.selector)
        ├── measure - $(reducer.measure)
        ├── intersect_strategy - $(reducer.intersect_strategy)
        ├── sub_reducer - $(reducer.sub_reducer)
        └── recheck - $(reducer.recheck)
    """)

"""
    struct SubsolverReducer{TR, TS} <: MISReducer

After the size of the problem is smaller than the threshold, use a subsolver to find reduction rules.

# Fields
- `reducer::TR = XiaoReducer()`: The reducer used to reduce the graph.
- `subsolver::Symbol = :xiao`: subsolvers include `:mis2`, `:xiao` and `:ip`.
- `threshold::Int = 100`: The threshold for using the subsolver.
"""
@kwdef struct SubsolverReducer <: MISReducer
    reducer::MISReducer = XiaoReducer()
    subsolver::Symbol = :xiao # :mis2, :xiao or :ip
    threshold::Int = 100 # the threshold for using the subsolver
end

"""
    reduce_problem(::Type{R}, p::MISProblem, ::MISReducer) where R

Reduces the given `MISProblem` by removing vertices based on their degrees and returns a new `MISProblem` instance along with the count of removed vertices.

# Arguments
- `p::MISProblem`: The problem instance containing the graph to be reduced.
- `::MISReducer`: An implementation of the `MISReducer` abstract type.
- `::Type{R}`: The type of the result expected.

# Returns
- A tuple containing:
  - A new `MISProblem` instance with specified vertices removed.
  - An integer representing the count of removed vertices.

# Description
The function checks the number of vertices in the graph:
- If there are no vertices, it returns an empty instance and a count of 0.
- If there is one vertex, it returns an empty instance and a count of 1 or weight of the vertex.
- If there are two vertices, it returns an empty instance and a count based on the presence of an edge between them.
- For graphs with more than two vertices, it calculates the degrees of the vertices and identifies the vertex with the minimum degree to determine which vertices to remove.
"""
function OptimalBranchingCore.reduce_problem(::Type{R}, p::MISProblem, reducer::MISReducer) where R
    res = reduce_graph(p.g, p.weights, reducer)
    if (nv(res.g) == nv(p.g)) && iszero(res.r)
        return p, R(0)
    else
        return MISProblem(res.g, res.weights), R(res.r)
    end
end

"""
    struct ReductionResult{VT<:AbstractVector, WT}

A struct to store the result of the reduction.

# Fields
- `g::SimpleGraph{Int}`: The reduced graph.
- `weights::VT`: The weights of the reduced graph.
- `r::WT`: The reduction value (MIS difference).
- `vmap::Vector{Int}`: The vertex map from the vertices in the reduced graph to the vertices in the original graph.
"""
struct ReductionResult{VT<:AbstractVector, WT}
    g::SimpleGraph{Int}
    weights::VT
    r::WT
    vmap::Vector{Int}
end

function ReductionResult(g::SimpleGraph{Int}, r::Int, vmap::Vector{Int})
    ReductionResult(g, UnitWeight(nv(g)), r, vmap)
end

"""
    reduce_graph(g::SimpleGraph, weights::AbstractVector, ::NoReducer)

Reduce the graph into a simplified one by reduction rules.
Actually does nothing, only for comparison with other reducers.

# Arguments
- `g::SimpleGraph`: The input graph.
- `weights::AbstractVector`: The weights of the vertices.
- `::NoReducer`: The reducer to be applied.

# Returns
- A `ReductionResult` instance containing the reduced graph, weights, mis difference, and vertex map.

"""
function reduce_graph(g::SimpleGraph{Int}, weights::AbstractVector{WT}, ::NoReducer) where WT
    return ReductionResult(g, weights, 0, collect(1:nv(g)))
end

"""
    reduce_graph(g::SimpleGraph, weights::UnitWeight, ::BasicReducer)

Reduce the graph into a simplified one by basic reduction rules used in classical algorithms like mis2.

# Arguments
- `g::SimpleGraph`: The input graph.
- `weights::UnitWeight`: The weights of the vertices.
- `::BasicReducer`: The reducer to be applied.

# Returns
- A `ReductionResult` instance containing the reduced graph, weights, mis difference, and vertex map.

"""
function reduce_graph(g::SimpleGraph{Int}, ::UnitWeight, ::BasicReducer)
    if nv(g) == 0
        return ReductionResult(SimpleGraph(0), 0, Int[])
    elseif nv(g) == 1
        return ReductionResult(SimpleGraph(0), 1, Int[]) 
    elseif nv(g) == 2
        return ReductionResult(SimpleGraph(0), 2 - has_edge(g, 1, 2), Int[])
    else
        degrees = degree(g)
        degmin = minimum(degrees)
        vmin = findfirst(==(degmin), degrees)

        if degmin == 0
            all_zero_vertices = findall(==(0), degrees)
            g_new, vmap = remove_vertices_vmap(g, all_zero_vertices)
            return ReductionResult(g_new, length(all_zero_vertices), vmap)
        elseif degmin == 1
            g_new, vmap = remove_vertices_vmap(g, neighbors(g, vmin) ∪ vmin)
            return ReductionResult(g_new, 1, vmap)
        elseif degmin == 2
            return ReductionResult(folding_vmap(g, vmin)...)
        end
    end
    return ReductionResult(g, 0, collect(1:nv(g)))
end

"""
    reduce_graph(g::SimpleGraph, weights::Vector{WT}, ::BasicReducer)

Reduce the graph into a simplified one by basic weighted_version reduction rules.

# Arguments
- `g::SimpleGraph`: The input graph.
- `weights::Vector{WT}`: The weights of the vertices.
- `::BasicReducer`: The reducer to be applied.

# Returns
- A `ReductionResult` instance containing the reduced graph, weights, mis difference, and vertex map.

"""
function reduce_graph(g::SimpleGraph{Int}, weights::Vector{WT}, ::BasicReducer) where WT
    if nv(g) == 0
        return ReductionResult(SimpleGraph(0), WT[], 0, Int[])
    elseif nv(g) == 1
        return ReductionResult(SimpleGraph(0), WT[], weights[1], Int[]) 
    elseif nv(g) == 2
        if !has_edge(g, 1, 2)
            return ReductionResult(SimpleGraph(0), WT[], weights[1] + weights[2], Int[])
        else
            return ReductionResult(SimpleGraph(0), WT[], max(weights[1], weights[2]), Int[])
        end
    else
        degrees = degree(g)
        degmin = minimum(degrees)
        vmin = findfirst(==(degmin), degrees)

        if degmin == 0
            all_zero_vertices = findall(==(0), degrees)
            g_new, vmap = remove_vertices_vmap(g, all_zero_vertices)
            return ReductionResult(g_new, weights[vmap], sum(weights[all_zero_vertices]), vmap)
        elseif degmin == 1
            vmin_neighbor = neighbors(g, vmin)[1]
            if weights[vmin] >= weights[vmin_neighbor]
                g_new, vmap = remove_vertices_vmap(g, neighbors(g, vmin) ∪ vmin)
                return ReductionResult(g_new, weights[vmap], weights[vmin], vmap)
            end
        end

        unconfined_vs = unconfined_vertices(g, weights)
        if length(unconfined_vs) != 0
            g_new, vmap = remove_vertices_vmap(g, [unconfined_vs[1]])
            return ReductionResult(g_new, weights[vmap], 0, vmap)
        end

        for vi in 1:nv(g)
            g_new, weights_new, mis_addition, vmap = folding_vmap(g, weights, vi)
            
            if g_new != g
                return ReductionResult(g_new, weights_new, mis_addition, vmap)
            end
        end
    end
    return ReductionResult(g, weights, 0, collect(1:nv(g)))
end

"""
    reduce_graph(g::SimpleGraph, weights::AbstractVector{WT}, ::XiaoReducer)

Reduce the graph into a simplified one by Xiao's reduction rules.

# Arguments
- `g::SimpleGraph`: The input graph.
- `weights::AbstractVector{WT}`: The weights of the vertices.
- `::XiaoReducer`: The reducer to be applied.

# Returns
- A `ReductionResult` instance containing the reduced graph, weights, mis difference, and vertex map.

"""
function reduce_graph(g::SimpleGraph{Int}, weights::Vector{WT}, ::XiaoReducer) where WT
    if nv(g) == 0
        return ReductionResult(SimpleGraph(0), WT[], 0, Int[])
    elseif nv(g) == 1
        return ReductionResult(SimpleGraph(0), WT[], weights[1], Int[]) 
    elseif nv(g) == 2
        if !has_edge(g, 1, 2)
            return ReductionResult(SimpleGraph(0), WT[], weights[1] + weights[2], Int[])
        else
            return ReductionResult(SimpleGraph(0), WT[], max(weights[1], weights[2]), Int[])
        end
    else
        degrees = degree(g)
        degmin = minimum(degrees)
        vmin = findfirst(==(degmin), degrees)
        if degmin == 0
            all_zero_vertices = findall(==(0), degrees)
            g_new, vmap = remove_vertices_vmap(g, all_zero_vertices)
            return ReductionResult(g_new, weights[vmap], sum(weights[all_zero_vertices]), vmap) 
        end

        g_new, weights_new, mwis_diff, vmap = fast_heavy_vertex_vmap(g, weights)
        if g_new != g 
            return ReductionResult(g_new, weights_new, mwis_diff, vmap)
        end
        
        if degmin == 1
            g_new, weights_new, mwis_diff, vmap = isolated_vertex_vmap(g, weights, vmin)
            if g_new != g 
                return ReductionResult(g_new, weights_new, mwis_diff, vmap)
            end
        end

        if degmin == 2
            g_new, weights_new, mwis_diff, vmap = alternative_vertex_vmap(g, weights, vmin)
            if g_new != g 
                return ReductionResult(g_new, weights_new, mwis_diff, vmap)
            end

            g_new, weights_new, mwis_diff, vmap = alternative_path_cycle_vmap(g, weights)
            if g_new != g 
                return ReductionResult(g_new, weights_new, mwis_diff, vmap)
            end

            g_new, weights_new, mwis_diff, vmap = isolated_vertex_vmap(g, weights, vmin)
            if g_new != g 
                return ReductionResult(g_new, weights_new, mwis_diff, vmap)
            end
        end

        g_new, weights_new, mwis_diff, vmap = module_vmap(g, weights)
        if g_new != g 
            return ReductionResult(g_new, weights_new, mwis_diff, vmap)
        end


        g_new, weights_new, mwis_diff, vmap = heavy_vertex_vmap(g, weights)
        if g_new != g 
            return ReductionResult(g_new, weights_new, mwis_diff, vmap)
        end

        g_new, weights_new, mwis_diff, vmap = alternative_vertex_vmap(g, weights)
        if g_new != g 
            return ReductionResult(g_new, weights_new, mwis_diff, vmap)
        end

        g_new, weights_new, mwis_diff, vmap = isolated_vertex_vmap(g, weights)
        if g_new != g 
            return ReductionResult(g_new, weights_new, mwis_diff, vmap)
        end

        unconfined_vs = unconfined_vertices(g, weights)
        if length(unconfined_vs) != 0
            g_new, vmap = remove_vertices_vmap(g, [unconfined_vs[1]])
            return ReductionResult(g_new, weights[vmap], 0, vmap)
        end

        g_new, weights_new, mwis_diff, vmap = confined_pair_vmap(g, weights)
        if g_new != g 
            return ReductionResult(g_new, weights_new, mwis_diff, vmap)
        end

        critical_independent_set = find_independent_critical_set(g, weights)
        if length(critical_independent_set) != 0
            mwis_diff = sum(weights[critical_independent_set])
            g_new, vmap = remove_vertices_vmap(g, union(neighbors(g, critical_independent_set),critical_independent_set))
            return ReductionResult(g_new, weights[vmap], mwis_diff, vmap)
        end

        g_new, weights_new, mwis_diff, vmap = heavy_pair_vmap(g, weights)
        if g_new != g 
            return ReductionResult(g_new, weights_new, mwis_diff, vmap)
        end
    end
    return ReductionResult(g, weights, 0, collect(1:nv(g)))
end


"""
    reduce_graph(g::SimpleGraph, weights::UnitWeight, ::XiaoReducer)

Reduce the graph into a simplified one by Xiao's reduction rules.

# Arguments
- `g::SimpleGraph`: The input graph.
- `weights::UnitWeight`: The weights of the vertices.
- `::XiaoReducer`: The reducer to be applied.

# Returns
- A `ReductionResult` instance containing the reduced graph, weights, mis difference, and vertex map.

"""
function reduce_graph(g::SimpleGraph{Int}, weights::UnitWeight, ::XiaoReducer)
    nv(g) == 0 && return ReductionResult(SimpleGraph(0), 0, Int[])

    res = reduce_graph(g, weights, BasicReducer())
    (res.g != g) && return res

    unconfined_vs = unconfined_vertices(g)
    if length(unconfined_vs) != 0
        @debug "Removing unconfined vertex $(unconfined_vs[1])"
        g_new, vmap = remove_vertices_vmap(g, [unconfined_vs[1]])
        return ReductionResult(g_new, 0, vmap)
    end

    twin_res = twin_filter_vmap(g)
    !isnothing(twin_res) && return ReductionResult(twin_res[1], 2, twin_res[2])
    short_funnel_res = short_funnel_filter_vmap(g)
    !isnothing(short_funnel_res) && return ReductionResult(short_funnel_res[1], 1, short_funnel_res[2])
    desk_res = desk_filter_vmap(g)
    !isnothing(desk_res) && return ReductionResult(desk_res[1], 2, desk_res[2])
    return ReductionResult(g, 0, collect(1:nv(g)))
end

function select_region(g::AbstractGraph, i::Int, n_max::Int, strategy::Symbol)
    if strategy == :neighbor
        return select_region_neighbor(g, i, n_max)
    elseif strategy == :mincut
        return select_region_mincut(g, i, n_max)
    else
        error("Invalid strategy: $strategy")
    end
end

function select_region_neighbor(g::AbstractGraph, i::Int, n_max::Int)
    n_max = min(n_max, nv(g))
    vs = [i]
    while length(vs) < n_max 
        nbrs = OptimalBranchingMIS.open_neighbors(g, vs)
        (length(vs) + length(nbrs) > n_max) && break
        (isempty(nbrs)) && break
        append!(vs, nbrs)
    end
    return vs
end

function select_region_mincut(args...)
    error("Region selection requires `using KaHyPar`, since it is an extension function.")
end

"""
    reduce_graph(g::SimpleGraph, weights::AbstractVector{WT}, ::TensorNetworkReducer)

Reduce the graph into a simplified one by tensor-network-generated reduction rules.
Apply sub-reducer first, then select region to on-the-fly generate reduction rules.

# Arguments
- `g::SimpleGraph`: The input graph.
- `weights::AbstractVector{WT}`: The weights of the vertices.
- `::TensorNetworkReducer`: The reducer to be applied.

# Returns
- A `ReductionResult` instance containing the reduced graph, weights, mis difference, and vertex map.

"""
# in this function, vmap_0 is from the late step to the current step, the out put vmap is from the current step to next step, which means it is not coupled with the vmap_0
function reduce_graph(g::SimpleGraph{Int}, weights::AbstractVector{WT}, tnreducer::TensorNetworkReducer; vmap_0::Union{Nothing, Vector{Int}} = nothing) where WT
    nv(g) == 0 && return ReductionResult(SimpleGraph(0), weights, 0, Int[])


    # if the vmap_0 is not specified, the region_list will not be updated, otherwise udpate the region_list
    !isnothing(vmap_0) && (tnreducer.region_list = update_region_list(tnreducer.region_list, vmap_0))

    # use the sub_reducer to reduce the graph first
    res = reduce_graph(g, weights, tnreducer.sub_reducer)
    (res.g != g) && return res

    p = MISProblem(g, weights)

    # first consider the vertices with region removed (not a key in region_list)
    is = collect(1:nv(p.g))
    is = sort(is, by=i -> degree(p.g, i), rev=true)
    for i in is
        haskey(tnreducer.region_list, i) && continue
        selected_vertices = select_region(p.g, i, tnreducer.n_max, tnreducer.selector)
        if tnreducer.folding
            res = tn_reduce_rewrite_graph(p.g, p.weights, tnreducer, selected_vertices)
        else
            res = tn_reduce_graph(p.g, p.weights, tnreducer, selected_vertices)
        end
        if isnothing(res)
            # if the region selected by i can not be reduced, add it to the region_list
            tnreducer.region_list[i] = (selected_vertices, open_neighbors(p.g, selected_vertices))
        else
            return res
        end
    end

    # if all the vertices that have been modified can not be reduced, try other vertices
    if tnreducer.recheck
        is = keys(tnreducer.region_list)
        is = sort(collect(is), by=i -> degree(p.g, i), rev=true)
        for i in is
            selected_vertices, nn = tnreducer.region_list[i]
            reselected_vertices = select_region(p.g, i, tnreducer.n_max, tnreducer.selector)
            reselected_nn = open_neighbors(p.g, reselected_vertices)
            if (sort!(selected_vertices) == sort!(reselected_vertices)) && (sort!(nn) == sort!(reselected_nn))
                continue
            else
                if tnreducer.folding
                    res = tn_reduce_rewrite_graph(p.g, p.weights, tnreducer, reselected_vertices) 
                else
                    res = tn_reduce_graph(p.g, p.weights, tnreducer, reselected_vertices) 
                end
                if isnothing(res)
                    tnreducer.region_list[i] = (reselected_vertices, reselected_nn)
                else
                    return res
                end
            end
        end
    end
    
    return ReductionResult(g, weights, 0, collect(1:nv(g)))

end

#update the region_list accroding to the region list
function update_region_list(region_list::Dict{Int, Tuple{Vector{Int}, Vector{Int}}}, vmap::Vector{Int})
    v_max = maximum(vmap)
    v_removed = Set(setdiff(collect(1:v_max), vmap))
    ivmap = Dict(vmap[i] => i for i in 1:length(vmap))

    mapped_region_list = Dict{Int, Tuple{Vector{Int}, Vector{Int}}}()
    for (v, value) in region_list
        region, open_neighbors = value
        (isempty(region) || isempty(open_neighbors)) && continue
        ((v in v_removed) || maximum(region) > v_max || maximum(open_neighbors) > v_max || !isempty(intersect(region, v_removed)) || !isempty(intersect(open_neighbors, v_removed))) && continue
        mapped_region_list[ivmap[v]] = ([ivmap[u] for u in region], [ivmap[u] for u in open_neighbors])
    end
    
    return mapped_region_list
end

function tn_reduce_rewrite_graph(g::SimpleGraph{Int}, weights::Vector{WT}, tnreducer::TensorNetworkReducer, selected_vertices::Vector{Int}) where WT
    truth_table = branching_table(MISProblem(g, weights), TensorNetworkSolver(), selected_vertices)
    bc = best_intersect(MISProblem(g, weights), truth_table, tnreducer.measure, tnreducer.intersect_strategy, selected_vertices)
    if !isnothing(bc)
        vertices_removed = removed_vertices(selected_vertices, g, bc)
        g_new, vmap = remove_vertices_vmap(g, vertices_removed)
        reducedvalue = clause_size(weights, bc.val, selected_vertices)
        return ReductionResult(g_new, weights[vmap], reducedvalue, vmap)
    end

    bc = best_folding(MISProblem(g, weights), truth_table, tnreducer.intersect_strategy)
    group1 = Int[]
    group2 = Int[]
    if !isnothing(bc)
        for bit_pos in 1:length(selected_vertices)
            if readbit(bc.mask, bit_pos) == 1 && readbit(bc.val, bit_pos) == 1
                push!(group1, selected_vertices[bit_pos])
            elseif readbit(bc.mask, bit_pos) == 1 && readbit(bc.val, bit_pos) == 0
                push!(group2, selected_vertices[bit_pos])
            end
        end
        if length(group2) <= 1
            g_new, weights_new, vmap = folding_one_node(g, weights, group1)
        else
            g_new, weights_new, vmap = folding_two_nodes(g, weights, group1, group2)
        end
        return ReductionResult(g_new, weights_new, 0, vmap)
    end
    return nothing
end

function tn_reduce_graph(g::SimpleGraph{Int}, weights::AbstractVector{WT}, tnreducer::TensorNetworkReducer, selected_vertices::Vector{Int}) where WT
    truth_table = branching_table(MISProblem(g, weights), TensorNetworkSolver(), selected_vertices)
    bc = best_intersect(MISProblem(g, weights), truth_table, tnreducer.measure, tnreducer.intersect_strategy, selected_vertices)
    if !isnothing(bc)
        vertices_removed = removed_vertices(selected_vertices, g, bc)
        g_new, vmap = remove_vertices_vmap(g, vertices_removed)
        reducedvalue = clause_size(weights, bc.val, selected_vertices)
        return ReductionResult(g_new, weights[vmap], reducedvalue, vmap)
    end
    return nothing
end

# fold the vertices in group1 into one vertex, and weights[new_vertex] = sum(weights[group1])
function folding_one_node(g::SimpleGraph{Int}, weights::Vector{WT}, group1::Vector{Int}) where WT
    for n in neighbors(g, group1)
        add_edge!(g, group1[1], n)
    end
    weights_new = copy(weights)
    weights_new[group1[1]] = sum(weights[group1])
    g_new, vmap = induced_subgraph(g, setdiff(1:nv(g), group1[2:end]))
    return g_new, weights_new[vmap], vmap
end

# fold the vertices in group1 and group2 into two vertices, and weights[new_vertex1] = sum(weights[group1]), weights[new_vertex2] = sum(weights[group2])
# add an edge between the two new vertices
function folding_two_nodes(g::SimpleGraph{Int}, weights::Vector{WT}, group1::Vector{Int}, group2::Vector{Int}) where WT
    for n in neighbors(g, group1)
        add_edge!(g, group1[1], n)
    end
    weights_new = copy(weights)
    weights_new[group1[1]] = sum(weights[group1])
    for n in neighbors(g, group2)
        add_edge!(g, group2[1], n)
    end 
    weights_new[group2[1]] = sum(weights[group2])
    g_new, vmap = induced_subgraph(g, setdiff(1:nv(g), union(group1[2:end], group2[2:end])))
    return g_new, weights_new[vmap], vmap
end

function best_intersect(p::MISProblem, tbl::BranchingTable, measure::AbstractMeasure, intersect_strategy::Symbol, variables::Vector{Int})
    cl = OptimalBranchingCore.intersect_clauses(tbl, intersect_strategy)
    if isempty(cl)
        return nothing
    elseif length(cl) == 1
        return cl[1]
    else
        best_loss = OptimalBranchingCore.size_reduction(p, measure, cl[1], variables)
        best_cl = cl[1]
        for c in cl[2:end]
            loss = OptimalBranchingCore.size_reduction(p, measure, c, variables)
            if loss > best_loss
                best_loss = loss
                best_cl = c
            end
        end
        return best_cl
    end
end

function best_folding(p::MISProblem, tbl::BranchingTable, intersect_strategy::Symbol)
    cl = OptimalBranchingCore.folding_clauses(tbl, intersect_strategy)
    if isempty(cl)
        return nothing
    elseif length(cl) == 1
        return cl[1]
    else
        best_loss = count_ones(cl[1].mask) - (count_ones(cl[1].mask) == count_ones(cl[1].val) ? 1.0 : 2.1)
        best_cl = cl[1]
        for c in cl[2:end]
            loss = count_ones(c.mask) - (count_ones(c.mask) == count_ones(c.val) ? 1.0 : 2.1)
            if loss > best_loss
                best_loss = loss
                best_cl = c
            end
        end
        return best_cl
    end
end

function reduce_graph(g::SimpleGraph{Int}, weights::UnitWeight, reducer::SubsolverReducer)
    if nv(g) <= reducer.threshold
        # use the subsolver the directly solve the problem
        if reducer.subsolver == :mis2
            res = mis2(EliminateGraph(g))
        elseif reducer.subsolver == :xiao
            res = counting_xiao2013(g).size
        elseif reducer.subsolver == :ip
            res = ip_mis(g)
        else
            error("Subsolver $(reducer.subsolver) not supported, please choose from :mis2, :xiao or :ip")
        end
        return ReductionResult(SimpleGraph(0), res, Int[])
    else
        return reduce_graph(g, weights, reducer.reducer)
    end
end