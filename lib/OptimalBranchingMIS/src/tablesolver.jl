function alpha(g::SimpleGraph, openvertices::Vector{Int})
	problem = GenericTensorNetwork(IndependentSet(g); openvertices, optimizer = GreedyMethod(nrepeat=1))
	alpha_tensor = solve(problem, SizeMax())
    return alpha_tensor
end

function alpha(g::SimpleGraph, weights::Vector, openvertices::Vector{Int})
	problem = GenericTensorNetwork(IndependentSet(g, weights); openvertices, optimizer = GreedyMethod(nrepeat=1))
	alpha_tensor = solve(problem, SizeMax())
    return alpha_tensor
end

# Let us create a function for finding reduced ``\alpha``-tensors."
function reduced_alpha(g::SimpleGraph, openvertices::Vector{Int})
	problem = GenericTensorNetwork(IndependentSet(g); openvertices, optimizer = GreedyMethod(nrepeat=1))
	alpha_tensor = solve(problem, SizeMax())
	return mis_compactify!(alpha_tensor)
end

function reduced_alpha(g::SimpleGraph, weights::Vector, openvertices::Vector{Int})
	problem = GenericTensorNetwork(IndependentSet(g, weights); openvertices, optimizer = GreedyMethod(nrepeat=1))
	alpha_tensor = solve(problem, SizeMax())
	return mis_compactify!(alpha_tensor)
end

function _reduced_alpha_configs(g::SimpleGraph, openvertices::Vector{Int}, potential)
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

function _reduced_alpha_configs(g::SimpleGraph, weights::Vector; openvertices::Vector{Int})
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

function reduced_alpha_configs(::TensorNetworkSolver, graph::SimpleGraph, openvertices::Vector{Int}, potentials=nothing)
	configs = _reduced_alpha_configs(graph, openvertices, potentials)
    return BranchingTable(configs)
end

function reduced_alpha_configs(::TensorNetworkSolver, graph::SimpleGraph, weights::Vector; openvertices::Vector{Int})
	configs = _reduced_alpha_configs(graph, weights; openvertices)
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

function OptimalBranchingCore.branching_table(p::MISProblem, solver::TensorNetworkSolver, vs::Vector{Int})
    ovs = open_vertices(p.g, vs)
    subg, vmap = induced_subgraph(p.g, vs)
	potential = [length(setdiff(neighbors(p.g, v), vs)) for v in ovs]
    tbl = reduced_alpha_configs(solver, subg, Int[findfirst(==(v), vs) for v in ovs], potential)
    if solver.prune_by_env
        tbl = prune_by_env(tbl, p, vs)
    end
    return tbl
end

function OptimalBranchingCore.branching_table(p::MWISProblem, solver::TensorNetworkSolver, vs::Vector{Int})
    ovs = open_vertices(p.g, vs)
    subg, vmap = induced_subgraph(p.g, vs)
	tbl = reduced_alpha_configs(solver, subg, p.weights[vmap], openvertices=Int[findfirst(==(v), vs) for v in ovs])
    if solver.prune_by_env
        tbl = prune_by_env(tbl, p, vs)
    end
    return tbl
end

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
                mis_pink = mis2(EliminateGraph(sg_pink))
                if (count_ones(tbl.table[i][1]) + mis_pink ≤ count_ones(tbl.table[j][1])) && (!iszero(mis_pink))
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

function clause_weighted_size(weights::Vector,bit_config,vertices::Vector)
    weighted_size = 0.0
    for bit_pos in 1:length(vertices)
        if readbit(bit_config,bit_pos) == 1
            weighted_size += weights[vertices[bit_pos]]
        end
    end
    return weighted_size
end

function prune_by_env(tbl::BranchingTable{INT}, p::MWISProblem, vertices) where{INT<:Integer}
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
                problem_sg_pink = GenericTensorNetwork(IndependentSet(sg_pink, p.weights[collect(pink_block)]); optimizer = GreedyMethod(nrepeat=1))
                mis_pink = solve(problem_sg_pink, SizeMax())[].n
                if (clause_weighted_size(p.weights, tbl.table[i][1], vertices) + mis_pink ≤ clause_weighted_size(p.weights, tbl.table[j][1], vertices)) && (!iszero(mis_pink))
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