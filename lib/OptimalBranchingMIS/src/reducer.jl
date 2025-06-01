"""
    MISReducer

A struct representing a reducer for the Maximum Independent Set (MIS) problem. 
This struct serves as a specific implementation of the `AbstractReducer` type.
"""
struct MISReducer <: AbstractReducer end

"""
    MWISReducer

A struct representing a reducer for the Maximum Weighted Independent Set (MWIS) problem. 
This struct serves as a specific implementation of the `AbstractReducer` type.
"""
struct MWISReducer <: AbstractReducer end

"""
    struct XiaoReducer <: AbstractReducer end

A reducer that uses Xiao's reduction rules to find reduction rules.
"""
struct XiaoReducer <: AbstractReducer end

"""
    struct TensorNetworkReducer <: AbstractReducer

A reducer that uses tensor network contraction to find reduction rules.

# Fields
- `n_max::Int = 15`: Maximum number of vertices to be included in the selected region
- `selector::Symbol = :mincut`: Strategy for selecting vertices to contract. Options are:
    - `:neighbor`: Select vertices based on neighborhood
    - `:mincut`: Select vertices based on minimum cut provided by KaHyPar !Note: KaHyPar may leads to memory leak!
- `measure::AbstractMeasure = NumOfVertices()`: Measure used for kernelization. Uses size reduction from OptimalBranchingMIS
- `intersect_strategy::Symbol = :bfs`: Strategy for intersecting clauses. Options are:
    - `:bfs`: Breadth-first search (gives the optimal result)
    - `:dfs`: Depth-first search (gives the first found non-zero intersection)
- `sub_reducer::AbstractReducer = XiaoReducer()`: Reducer applied to selected vertices before tensor network contraction, default is XiaoReducer
"""
@kwdef mutable struct TensorNetworkReducer <: AbstractReducer
    n_max::Int = 15
    selector::Symbol = :mincut # :neighbor or :mincut
    measure::AbstractMeasure = NumOfVertices() # different measures for kernelization, use the size reduction from OptimalBranchingMIS
    intersect_strategy::Symbol = :bfs # :dfs or :bfs
    sub_reducer::AbstractReducer = XiaoReducer() # sub reducer for the selected vertices
    region_list::Dict{Int, Tuple{Vector{Int}, Vector{Int}}} = Dict{Int, Tuple{Vector{Int}, Vector{Int}}}() # store the selected region and the open neighbors of the selected region for each vertex
    recheck::Bool = false # whether to recheck the vertices that have not been modified
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
    struct SubsolverReducer{TR, TS} <: AbstractReducer

After the size of the problem is smaller than the threshold, use a subsolver to find reduction rules.

# Fields
- `reducer::TR = XiaoReducer()`: The reducer used to reduce the graph.
- `subsolver::Symbol = :xiao`: subsolvers include `:mis2`, `:xiao` and `:ip`.
- `threshold::Int = 100`: The threshold for using the subsolver.
"""
@kwdef struct SubsolverReducer <: AbstractReducer
    reducer::AbstractReducer = XiaoReducer()
    subsolver::Symbol = :xiao # :mis2, :xiao or :ip
    threshold::Int = 100 # the threshold for using the subsolver
end

"""
    reduce_problem(::Type{R}, p::MISProblem, ::MISReducer) where R

Reduces the given `MISProblem` by removing vertices based on their degrees and returns a new `MISProblem` instance along with the count of removed vertices.

# Arguments
- `p::MISProblem`: The problem instance containing the graph to be reduced.
- `::MISReducer`: An instance of the `MISReducer` struct.
- `::Type{R}`: The type of the result expected.

# Returns
- A tuple containing:
  - A new `MISProblem` instance with specified vertices removed.
  - An integer representing the count of removed vertices.

# Description
The function checks the number of vertices in the graph:
- If there are no vertices, it returns an empty instance and a count of 0.
- If there is one vertex, it returns an empty instance and a count of 1.
- If there are two vertices, it returns an empty instance and a count based on the presence of an edge between them.
- For graphs with more than two vertices, it calculates the degrees of the vertices and identifies the vertex with the minimum degree to determine which vertices to remove.
"""
function OptimalBranchingCore.reduce_problem(::Type{R}, p::MISProblem, reducer::Union{MISReducer, XiaoReducer, TensorNetworkReducer, SubsolverReducer}) where R
    g_new, r, _ = reduce_graph(p.g, reducer)
    if (nv(g_new) == nv(p.g)) && iszero(r)
        return p, R(0)
    else
        return MISProblem(g_new), R(r)
    end
end

function reduce_graph(g::SimpleGraph{Int}, ::MISReducer)
    if nv(g) == 0
        return SimpleGraph(0), 0, Int[]
    elseif nv(g) == 1
        return SimpleGraph(0), 1, Int[] 
    elseif nv(g) == 2
        return SimpleGraph(0), 2 - has_edge(g, 1, 2), Int[]
    else
        degrees = degree(g)
        degmin = minimum(degrees)
        vmin = findfirst(==(degmin), degrees)

        if degmin == 0
            all_zero_vertices = findall(==(0), degrees)
            g_new, vmap = remove_vertices_vmap(g, all_zero_vertices)
            return g_new, length(all_zero_vertices), vmap
        elseif degmin == 1
            g_new, vmap = remove_vertices_vmap(g, neighbors(g, vmin) ∪ vmin)
            return g_new, 1, vmap
        elseif degmin == 2
            return folding_vmap(g, vmin)
        end
    end
    return g, 0, collect(1:nv(g))
end

function OptimalBranchingCore.reduce_problem(::Type{R}, p::MWISProblem, reducer::Union{MISReducer, MWISReducer, XiaoReducer, TensorNetworkReducer, SubsolverReducer}) where R
    g_new, weights_new, r, _ = reduce_graph(p.g, p.weights, reducer)
    if (nv(g_new) == nv(p.g)) && iszero(r)
        return p, R(0)
    else
        return MWISProblem(g_new, weights_new), R(r)
    end
end

function reduce_graph(g::SimpleGraph{Int}, weights::Vector, ::MWISReducer)
    if nv(g) == 0
        return SimpleGraph(0), [], 0, Int[]
    elseif nv(g) == 1
        return SimpleGraph(0), [], weights[1], Int[] 
    elseif nv(g) == 2
        if !has_edge(g, 1, 2)
            return SimpleGraph(0), [], weights[1] + weights[2], Int[]
        else
            return SimpleGraph(0), [], max(weights[1], weights[2]), Int[]
        end
    else
        degrees = degree(g)
        degmin = minimum(degrees)
        vmin = findfirst(==(degmin), degrees)

        if degmin == 0
            all_zero_vertices = findall(==(0), degrees)
            g_new, vmap = remove_vertices_vmap(g, all_zero_vertices)
            return g_new, weights[vmap], sum(weights[all_zero_vertices]), vmap
        elseif degmin == 1
            vmin_neighbor = neighbors(g, vmin)[1]
            if weights[vmin] >= weights[vmin_neighbor]
                g_new, vmap = remove_vertices_vmap(g, neighbors(g, vmin) ∪ vmin)
                return g_new, weights[vmap], weights[vmin], vmap
            end
        end

        unconfined_vs = unconfined_vertices(g, weights)
        if length(unconfined_vs) != 0
            g_new, vmap = remove_vertices_vmap(g, [unconfined_vs[1]])
            return g_new, weights[vmap], 0, vmap
        end

        for vi in 1:nv(g)
            g_new, weights_new, mis_addition, vmap = folding_vmap(g, weights, vi)
            
            if g_new != g
                return g_new, weights_new, mis_addition, vmap
            end
        end
    end
    return g, weights, 0, collect(1:nv(g))
end

function reduce_graph(g::SimpleGraph{Int}, ::XiaoReducer)
    nv(g) == 0 && return SimpleGraph(0), 0, Int[]

    g_new, r, vmap = reduce_graph(g, MISReducer())
    (g_new != g) && return g_new, r, vmap

    unconfined_vs = unconfined_vertices(g)
    if length(unconfined_vs) != 0
        @debug "Removing unconfined vertex $(unconfined_vs[1])"
        g_new, vmap = remove_vertices_vmap(g, [unconfined_vs[1]])
        return g_new, 0, vmap
    end

    twin_res = twin_filter_vmap(g)
    !isnothing(twin_res) && return twin_res[1], 2, twin_res[2]
    
    short_funnel_res = short_funnel_filter_vmap(g)
    !isnothing(short_funnel_res) && return short_funnel_res[1], 1, short_funnel_res[2]

    desk_res = desk_filter_vmap(g)
    !isnothing(desk_res) && return desk_res[1], 2, desk_res[2]

    return g, 0, collect(1:nv(g))
end

# in this function, vmap_0 is from the late step to the current step, the out put vmap is from the current step to next step, which means it is not coupled with the vmap_0
function reduce_graph(g::SimpleGraph{Int}, tnreducer::TensorNetworkReducer; vmap_0::Union{Nothing, Vector{Int}} = nothing)
    nv(g) == 0 && return SimpleGraph(0), 0, Int[]

    # if the vmap_0 is not specified, the region_list will not be updated, otherwise udpate the region_list
    !isnothing(vmap_0) && (tnreducer.region_list = update_region_list(tnreducer.region_list, vmap_0))

    # use the sub_reducer to reduce the graph first
    g_new, r, vmap = reduce_graph(g, tnreducer.sub_reducer)
    (g_new != g) && return g_new, r, vmap

    p = MISProblem(g)

    # first consider the vertices with region removed (not a key in region_list)
    for i in 1:nv(p.g)
        haskey(tnreducer.region_list, i) && continue 
        selected_vertices = select_region(p.g, i, tnreducer.n_max, tnreducer.selector)
        res = tn_reduce_graph(p, tnreducer, selected_vertices)

        if isnothing(res)
            # if the region selected by i can not be reduced, add it to the region_list
            tnreducer.region_list[i] = (selected_vertices, open_neighbors(p.g, selected_vertices))
        else
            return res 
        end
    end

    # if all the vertices that have been modified can not be reduced, try other vertices
    if tnreducer.recheck
        for (i, value) in tnreducer.region_list
            selected_vertices, nn = value
            reselected_vertices = select_region(p.g, i, tnreducer.n_max, tnreducer.selector)
            reselected_nn = open_neighbors(p.g, reselected_vertices)
            if (sort!(selected_vertices) == sort!(reselected_vertices)) && (sort!(nn) == sort!(reselected_nn))
                continue
            else
                res = tn_reduce_graph(p, tnreducer, selected_vertices) 
                if isnothing(res)
                    tnreducer.region_list[i] = (reselected_vertices, reselected_nn)
                else
                    return res
                end
            end
        end
    end

    return g, 0, collect(1:nv(g))
end

# in this function, vmap_0 is from the late step to the current step, the out put vmap is from the current step to next step, which means it is not coupled with the vmap_0
function reduce_graph(g::SimpleGraph{Int}, weights::Vector, tnreducer::TensorNetworkReducer; vmap_0::Union{Nothing, Vector{Int}} = nothing)
    nv(g) == 0 && return SimpleGraph(0), [], 0, Int[]

    # if the vmap_0 is not specified, the region_list will not be updated, otherwise udpate the region_list
    !isnothing(vmap_0) && (tnreducer.region_list = update_region_list(tnreducer.region_list, vmap_0))

    # use the sub_reducer to reduce the graph first
    g_new, weights_new, r, vmap = reduce_graph(g, weights, MWISReducer())
    (g_new != g) && return g_new, weights_new, r, vmap

    p = MWISProblem(g, weights)

    # first consider the vertices with region removed (not a key in region_list)
    for i in 1:nv(p.g)
        haskey(tnreducer.region_list, i) && continue 
        selected_vertices = select_region(p.g, i, tnreducer.n_max, tnreducer.selector)
        res = tn_reduce_graph(p, tnreducer, selected_vertices)

        if isnothing(res)
            # if the region selected by i can not be reduced, add it to the region_list
            tnreducer.region_list[i] = (selected_vertices, open_neighbors(p.g, selected_vertices))
        else
            return res 
        end
    end

    # if all the vertices that have been modified can not be reduced, try other vertices
    if tnreducer.recheck
        for (i, value) in tnreducer.region_list
            selected_vertices, nn = value
            reselected_vertices = select_region(p.g, i, tnreducer.n_max, tnreducer.selector)
            reselected_nn = open_neighbors(p.g, reselected_vertices)
            if (sort!(selected_vertices) == sort!(reselected_vertices)) && (sort!(nn) == sort!(reselected_nn))
                continue
            else
                res = tn_reduce_graph(p, tnreducer, selected_vertices) 
                if isnothing(res)
                    tnreducer.region_list[i] = (reselected_vertices, reselected_nn)
                else
                    return res
                end
            end
        end
    end

    return g, weights, 0, collect(1:nv(g))
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

function tn_reduce_graph(p::MISProblem, tnreducer::TensorNetworkReducer, selected_vertices::Vector{Int})
    truth_table = branching_table(p, TensorNetworkSolver(), selected_vertices)
    bc = best_intersect(p, truth_table, tnreducer.measure, tnreducer.intersect_strategy, 
    selected_vertices)
    if !isnothing(bc)
        vertices_removed = removed_vertices(selected_vertices, p.g, bc)
        g_new, vmap = remove_vertices_vmap(p.g, vertices_removed)
        reducedvalue = count_ones(bc.val)
        return g_new, reducedvalue, vmap
    end
    return nothing
end

function tn_reduce_graph(p::MWISProblem, tnreducer::TensorNetworkReducer, selected_vertices::Vector{Int})
    truth_table = branching_table(p, TensorNetworkSolver(), selected_vertices)
    bc = best_intersect(p, truth_table, tnreducer.measure, tnreducer.intersect_strategy, 
    selected_vertices)
    if !isnothing(bc)
        vertices_removed = removed_vertices(selected_vertices, p.g, bc)
        g_new, vmap = remove_vertices_vmap(p.g, vertices_removed)
        reducedvalue = clause_weighted_size(p.weights, bc.val, selected_vertices)
        return g_new, p.weights[vmap], reducedvalue, vmap
    end
    return nothing
end

function best_intersect(p::Union{MISProblem, MWISProblem}, tbl::BranchingTable, measure::AbstractMeasure, intersect_strategy::Symbol, variables::Vector{T}) where {T}
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
            if loss < best_loss
                best_loss = loss
                best_cl = c
            end
        end
        return best_cl
    end
end

function reduce_graph(g::SimpleGraph{Int}, reducer::SubsolverReducer)
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
        return SimpleGraph(0), res, Int[]
    else
        return reduce_graph(g, reducer.reducer)
    end
end