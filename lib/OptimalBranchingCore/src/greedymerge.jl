struct GreedyMerge <: AbstractSetCoverSolver end
function optimal_branching_rule(table::BranchingTable, variables::Vector, problem::AbstractProblem, m::AbstractMeasure, solver::GreedyMerge)
	candidates = bit_clauses(table)
	return greedymerge(candidates, problem, variables, m)
end

function bit_clauses(tbl::BranchingTable{INT}) where {INT}
	n, bss = tbl.bit_length, tbl.table
	temp_clauses = [[Clause(bmask(INT, 1:n), bs) for bs in bss1] for bss1 in bss]
	return temp_clauses
end

function greedymerge(cls::Vector{Vector{Clause{INT}}}, problem::AbstractProblem, variables::Vector, m::AbstractMeasure) where {INT}
	active_cls = collect(1:length(cls))
	cls = copy(cls)
	merging_pairs = [(i, j) for i in active_cls, j in active_cls if i < j]
	n = length(variables)
	size_reductions = [size_reduction(problem, m, candidate[1], variables) for candidate in cls]
	γ = complexity_bv(size_reductions)
	while !isempty(merging_pairs)
		i, j = popfirst!(merging_pairs)
		if i in active_cls && j in active_cls
			for ii in 1:length(cls[i]), jj in 1:length(cls[j])
				if bdistance(cls[i][ii], cls[j][jj]) == 1
					cl12 = gather2(n, cls[i][ii], cls[j][jj])
					if cl12.mask == 0
						continue
					end
					l12 = size_reduction(problem, m, cl12, variables)
					if γ^(-size_reductions[i]) + γ^(-size_reductions[j]) >= γ^(-l12) + 1e-8
						push!(cls, [cl12])
						k = length(cls)
						deleteat!(active_cls, findfirst(==(i), active_cls))
						deleteat!(active_cls, findfirst(==(j), active_cls))
						for ii in active_cls
							push!(merging_pairs, (ii, k))
						end
						push!(active_cls, k)
						push!(size_reductions, l12)
						γ = complexity_bv(size_reductions[active_cls])
						break
					end
				end
			end
		end
	end
	return [cl[1] for cl in cls[active_cls]]
end

function size_reduction(p::AbstractProblem, m::AbstractMeasure, cl::Clause{INT}, variables::Vector) where {INT}
	return measure(p, m) - measure(first(apply_branch(p, cl, variables)), m)
end
