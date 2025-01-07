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
        for i ∈ 1:length(cls), j ∈ i+1:length(cls)
            for ii in 1:length(cls[i]), jj in 1:length(cls[j])
                cl12 = gather2(length(variables), cls[i][ii], cls[j][jj])
                if cl12.mask == 0
                    continue
                end
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

function localsearch(cls::Vector{Vector{Clause{INT}}}, problem::AbstractProblem, variables::Vector, m::AbstractMeasure) where {INT}
    cls = copy(cls)
    size_reductions = Float64[size_reduction(problem, m, first(candidate), variables) for candidate in cls]
    γ = complexity_bv(size_reductions)
    communities = [[i] for i in 1:length(cls)]
	mincls = [cls[i][1] for i in 1:length(cls)]
    for β in 1:1:1000.0
        # fuse, or free
        for i ∈ 1:length(communities), j in 1:length(communities)
            (i == j) && continue
            # try free
            for fi in 1:length(communities[i])
                # bring communities[i][fi] to communities[j]
                reduction_i,cli = merge_community(problem, m, cls[setdiff(communities[i], communities[i][fi])], variables)
                reduction_j,clj = merge_community(problem, m, cls[communities[j] ∪ communities[i][fi]], variables)
				iszero(clj.mask) && continue
                ΔE = γ^(-reduction_i) + γ^(-reduction_j) - γ^(-size_reductions[i]) - γ^(-size_reductions[j])
                if rand() < exp(-β * ΔE)
                    push!(communities[j], communities[i][fi])
                    deleteat!(communities[i], fi)
                    size_reductions[i] = reduction_i
                    size_reductions[j] = reduction_j
                    γ = complexity_bv(size_reductions[findall(!isempty, communities)])
					mincls[i] = cli
					mincls[j] = clj
                    break
                end
            end
        end
		@show β
		@show γ
    end
	pos = findall(!isempty, communities)
    return OptimalBranchingResult(DNF(mincls[pos]), size_reductions[pos], γ)
end

function merge_community(problem::AbstractProblem, m::AbstractMeasure, cls::Vector{Vector{Clause{INT}}}, variables::Vector) where {INT}
    isempty(cls) && return Inf,Clause(zero(INT), zero(INT))
    maxclause = Clause(zero(INT), zero(INT))
    maxred = 0
	pos = [length(cls[i]) for i in 1:length(cls)]
	while true
		cl = reduce((x,y) ->gather2(length(variables), x, y), [cls[i][pos[i]] for i in 1:length(cls)])
		reduction = size_reduction(problem, m, cl, variables)
		if reduction > maxred
			maxred, maxclause = reduction, cl
		end
		posi = findfirst(x -> x > 1, pos)
		isnothing(posi) && break
		pos[posi] -= 1
	end
    return maxred, maxclause
end
