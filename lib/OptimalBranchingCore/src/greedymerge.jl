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
    cls = copy(cls)
	size_reductions = [size_reduction(problem, m, first(candidate), variables) for candidate in cls]
    local γ
    while true
        γ = complexity_bv(size_reductions)
        minval = zero(γ)
        minidx = (-1, -1, -1, -1)
        local minclause
        local minred
        for i = 1:length(cls), j = i+1:length(cls)
            for ii in 1:length(cls[i]), jj in 1:length(cls[j])
                cl12 = gather2(length(variables), cls[i][ii], cls[j][jj])
                reduction = size_reduction(problem, m, cl12, variables)
                val = γ^(-reduction) - γ^(-size_reductions[i]) - γ^(-size_reductions[j])
                if val < minval
                    minval, minidx, minclause, minred = val, (i, j, ii, jj), cl12, reduction
                end
            end
        end
        minidx == (-1, -1, -1, -1) && break  # no more merging
        deleteat!(cls, minidx[1:2])
        deleteat!(size_reductions, minidx[1:2])
        push!(cls, [minclause])
        push!(size_reductions, minred)
    end
    return OptimalBranchingResult(DNF([cl[1] for cl in cls]), size_reductions, γ)
end