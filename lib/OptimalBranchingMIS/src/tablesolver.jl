function alpha(g::SimpleGraph, weights::UnitWeight, openvertices::Vector{Int})
	problem = GenericTensorNetwork(IndependentSet(g); openvertices, optimizer = GreedyMethod(nrepeat=1))
	alpha_tensor = solve(problem, SizeMax())
    return alpha_tensor
end

function alpha(g::SimpleGraph, weights::Vector{WT}, openvertices::Vector{Int}) where WT
	problem = GenericTensorNetwork(IndependentSet(g, weights); openvertices, optimizer = GreedyMethod(nrepeat=1))
	alpha_tensor = solve(problem, SizeMax())
    return alpha_tensor
end

# Let us create a function for finding reduced ``\alpha``-tensors."
function reduced_alpha(g::SimpleGraph, weights::UnitWeight, openvertices::Vector{Int})
	problem = GenericTensorNetwork(IndependentSet(g); openvertices, optimizer = GreedyMethod(nrepeat=1))
	alpha_tensor = solve(problem, SizeMax())
	return mis_compactify!(alpha_tensor)
end

function reduced_alpha(g::SimpleGraph, weights::Vector{WT}, openvertices::Vector{Int}) where WT
	problem = GenericTensorNetwork(IndependentSet(g, weights); openvertices, optimizer = GreedyMethod(nrepeat=1))
	alpha_tensor = solve(problem, SizeMax())
	return mis_compactify!(alpha_tensor)
end

function _reduced_alpha_configs(g::SimpleGraph, weights::UnitWeight, openvertices::Vector{Int}, potential::Vector{Int})
	problem = GenericTensorNetwork(IndependentSet(g); openvertices, optimizer = GreedyMethod(nrepeat=1))
	alpha_tensor = solve(problem, SizeMax())
	alpha_configs = solve(problem, ConfigsMax(; bounded=false))
	reduced_alpha_tensor = mis_compactify!(alpha_tensor; potential)
	# set the corresponding entries to 0.
	alpha_configs[map(iszero, reduced_alpha_tensor)] .= Ref(zero(eltype(alpha_configs)))
	# post processing
	configs = alpha_configs
	return configs
end

function _reduced_alpha_configs(g::SimpleGraph, weights::Vector{WT}, openvertices::Vector{Int}, potential::Vector{Int}) where WT
	problem = GenericTensorNetwork(IndependentSet(g, weights); openvertices, optimizer = GreedyMethod(nrepeat=1))
	alpha_tensor = solve(problem, SizeMax())
	alpha_configs = solve(problem, ConfigsMax(; bounded=false))
	reduced_alpha_tensor = mis_compactify!(alpha_tensor)
	# set the corresponding entries to 0.
	alpha_configs[map(iszero, reduced_alpha_tensor)] .= Ref(zero(eltype(alpha_configs)))
	# post processing
	configs = alpha_configs
	return configs
end

function reduced_alpha_configs(::TensorNetworkSolver, graph::SimpleGraph, weights::Union{UnitWeight, Vector{WT}}, openvertices::Vector{Int}, potential::Vector{Int}) where WT
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
	potential = [length(setdiff(neighbors(p.g, v), vs)) for v in ovs]
    tbl = reduced_alpha_configs(solver, subg, p.weights[vmap]; openvertices=Int[findfirst(==(v), vs) for v in ovs], potential)
    if solver.prune_by_env
        tbl = prune_by_env(tbl, p, vs)
    end
    return tbl
end

function clause_size(weights::Vector{WT}, bit_config::Int, vertices::Vector) where WT
    weighted_size = zero(WT)
    for bit_pos in 1:length(vertices)
        if readbit(bit_config, bit_pos) == 1
            weighted_size += weights[vertices[bit_pos]]
        end
    end
    return weighted_size
end
clause_size(::UnitWeight, bit_config::Int, vertices::Vector) = count_ones(bit_config)

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
                mis_pink = exact_mis_size(sg_pink, p.weights[collect(pink_block)])
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

function exact_mis_size(g::SimpleGraph{Int}, weights::Vector{WT}) where WT
    problem = GenericTensorNetwork(IndependentSet(g, weights); optimizer = GreedyMethod(nrepeat=1))
    return solve(problem, SizeMax())[].n
end

function exact_mis_size(g::SimpleGraph{Int}, weights::UnitWeight)
    return mis2(EliminateGraph(g))
end