function alpha(g::SimpleGraph, openvertices::Vector{Int})
	problem = GenericTensorNetwork(IndependentSet(g); openvertices, optimizer = GreedyMethod(nrepeat=1))
	alpha_tensor = solve(problem, SizeMax())
    return alpha_tensor
end

# Let us create a function for finding reduced ``\alpha``-tensors."
function reduced_alpha(g::SimpleGraph, openvertices::Vector{Int})
	problem = GenericTensorNetwork(IndependentSet(g); openvertices, optimizer = GreedyMethod(nrepeat=1))
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

function reduced_alpha_configs(::TensorNetworkSolver, graph::SimpleGraph, openvertices::Vector{Int}, potentials=nothing)
	configs = _reduced_alpha_configs(graph, openvertices, potentials)
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

function OptimalBranchingCore.solve_table(p::MISProblem, solver::TensorNetworkSolver, vs::Vector{Int})
    ovs = open_vertices(p.g, vs)
    subg, vmap = induced_subgraph(p.g, vs)
	return reduced_alpha_configs(solver, subg, Int[findfirst(==(v), vs) for v in ovs])
end