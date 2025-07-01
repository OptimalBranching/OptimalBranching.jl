"""
    alpha(g::SimpleGraph, weights::AbstractVector{WT}, openvertices::Vector{Int}) where WT      

Compute the alpha tensor for a given weighted sub-graph.

# Arguments
- `g::SimpleGraph`: The input sub-graph.
- `weights::AbstractVector{WT}`: The weights of the sub-graph.
- `openvertices::Vector{Int}`: The open vertices of the sub-graph.

# Returns
- The alpha tensor.
"""
function alpha(g::SimpleGraph, weights::AbstractVector{WT}, openvertices::Vector{Int}) where WT
	problem = GenericTensorNetwork(IndependentSet(g, weights); openvertices, optimizer = GreedyMethod(nrepeat=1))
	alpha_tensor = solve(problem, SizeMax())
    return alpha_tensor
end

"""
    reduced_alpha(g::SimpleGraph, weights::AbstractVector{WT}, openvertices::Vector{Int}) where WT      

Compute the reduced alpha tensor for a given weighted sub-graph.

# Arguments
- `g::SimpleGraph`: The input sub-graph.
- `weights::AbstractVector{WT}`: The weights of the sub-graph.
- `openvertices::Vector{Int}`: The open vertices of the sub-graph.

# Returns
- The reduced alpha tensor.
"""
function reduced_alpha(g::SimpleGraph, weights::AbstractVector{WT}, openvertices::Vector{Int}) where WT
	problem = GenericTensorNetwork(IndependentSet(g, weights); openvertices, optimizer = GreedyMethod(nrepeat=1))
	alpha_tensor = solve(problem, SizeMax())
	return mis_compactify!(alpha_tensor)
end

function _reduced_alpha_configs(g::SimpleGraph, weights::AbstractVector{WT}, openvertices::Vector{Int}, potential) where WT
	problem = GenericTensorNetwork(IndependentSet(g, weights); openvertices, optimizer = GreedyMethod(nrepeat=1))
	alpha_tensor = solve(problem, SizeMax())
	alpha_configs = solve(problem, ConfigsMax(; bounded=false))
	reduced_alpha_tensor = mis_compactify!(alpha_tensor; potential)
	# set the corresponding entries to 0.
	alpha_configs[map(iszero, reduced_alpha_tensor)] .= Ref(zero(eltype(alpha_configs)))
	# post processing
	configs = alpha_configs
	return configs
end

"""
    reduced_alpha_configs(solver::TensorNetworkSolver, graph::SimpleGraph, weights::AbstractVector{WT}, openvertices::Vector{Int}, potential=nothing) where WT

Compute the truth table according to the non-zero entries of the reduced alpha tensor for a given weighted sub-graph.

# Arguments
- `solver::TensorNetworkSolver`: The solver to use.
- `graph::SimpleGraph`: The input sub-graph.
- `weights::AbstractVector{WT}`: The weights of the sub-graph.
- `openvertices::Vector{Int}`: The open vertices of the sub-graph.
- `potential::Union{Nothing, Vector{WT}}`: The potential of the open vertices, defined as the sum of the weights of the nearestneighbors of the open vertices.

# Returns
- The truth table.
"""
function reduced_alpha_configs(::TensorNetworkSolver, graph::SimpleGraph, weights::AbstractVector{WT}, openvertices::Vector{Int}, potential=nothing) where WT
    configs = _reduced_alpha_configs(graph, weights, openvertices, potential)
    return BranchingTable(configs)
end

function OptimalBranchingCore.BranchingTable(arr::AbstractArray{<:CountingTropical{<:Real, <:ConfigEnumerator{N}}}) where N
    return BranchingTable(N, filter(!isempty, vec(map(collect_configs, arr))))
end

# Now we collect these configurations into a vector.
function collect_configs(cfg::CountingTropical{<:Real, <:ConfigEnumerator}, symbols::Union{Nothing, String}=nothing)
    cs = cfg.c.data
    symbols === nothing ? cs : [String([symbols[i] for (i, v) in enumerate(x) if v == 1]) for x in cs]
end

function OptimalBranchingCore.branching_table(p::MISProblem, solver::TensorNetworkSolver, vs::Vector{Int}) where INT<:Integer
    ovs = open_vertices(p.g, vs)
    subg, vmap = induced_subgraph(p.g, vs)
	potential = [sum(p.weights[collect(setdiff(neighbors(p.g, v), vs))]) for v in ovs]
    tbl = reduced_alpha_configs(solver, subg, p.weights[vmap], Int[findfirst(==(v), vs) for v in ovs], potential)
    if solver.prune_by_env
        tbl = prune_by_env(tbl, p, vs)
    end
    return tbl
end

"""
    clause_size(weights::Vector{WT}, bit_config, vertices::Vector) where WT

Compute the MIS size difference brought by the application of a clause for a given weighted graph.

# Arguments
- `weights::Vector{WT}`: The weights of the graph.
- `bit_config::Int`: The bit configuration of the clause.
- `vertices::Vector{Int}`: The vertices included in the clause.

# Returns
- The MIS size difference brought by the application of the clause.
"""
function clause_size(weights::Vector{WT}, bit_config, vertices::Vector) where WT
    weighted_size = zero(WT)
    for bit_pos in 1:length(vertices)
        if readbit(bit_config, bit_pos) == 1
            weighted_size += weights[vertices[bit_pos]]
        end
    end
    return weighted_size
end
clause_size(::UnitWeight, bit_config, vertices::Vector) = count_ones(bit_config)

# consider two different branching rule (A, and B) applied on the same set of vertices, with open vertices ovs.
# the neighbors of 1 vertices in A is label as NA1, and the neighbors of 1 vertices in B is label as NB1, and the pink_block is the set of vertices that are not in NB1 but in NA1.
# once mis(A) + mis(pink_block) ≤ mis(B), then A is not a good branching rule, and should be removed.
function prune_by_env(tbl::BranchingTable{INT}, p::MISProblem, vertices) where{INT<:Integer}
    g = p.g
    openvertices = open_vertices(g, vertices)
    ns = neighbors(g, vertices)
    so = Set(openvertices)

    new_table = Vector{Vector{INT}}()

    open_vertices_1 = [Int[] for i in 1:length(tbl.table)]
    neibs_0 = Set{Int}[]
    for i in 1:length(tbl.table)
        row = tbl.table[i]
        x = row[1]
        for n in 1:tbl.bit_length
            xn = (x >> (n-1)) & 1
            if (xn == 1) && (vertices[n] ∈ so)
                push!(open_vertices_1[i], vertices[n])
            end
        end
        push!(neibs_0, setdiff(ns, neighbors(g, open_vertices_1[i]) ∩ ns))
    end

    for i in 1:length(tbl.table)
        flag = true
        for j in 1:length(tbl.table)
            if i != j
                pink_block = setdiff(neibs_0[i], neibs_0[j])
                sg_pink, sg_vec = induced_subgraph(g, collect(pink_block))
                problem_pink = GenericTensorNetwork(IndependentSet(sg_pink, p.weights[collect(pink_block)]); optimizer = GreedyMethod(nrepeat=1))
                mis_pink = solve(problem_pink, SizeMax())[].n
                if (clause_size(p.weights, tbl.table[i][1], vertices) + mis_pink ≤ clause_size(p.weights, tbl.table[j][1], vertices)) && (!iszero(mis_pink))
                    flag = false
                    break
                end
            end
        end
        if flag
            push!(new_table, tbl.table[i])
        end
    end
    return BranchingTable(OptimalBranchingCore.nbits(tbl), new_table)
end
