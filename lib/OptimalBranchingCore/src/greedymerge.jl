struct GreedyMerge <: AbstractSetCoverSolver end
struct NaiveBranch <: AbstractSetCoverSolver end
function optimal_branching_rule(table::BranchingTable, variables::Vector, problem::AbstractProblem, m::AbstractMeasure, solver::GreedyMerge)
    candidates = bit_clauses(table)
    return greedymerge(candidates, problem, variables, m)
end

function optimal_branching_rule(table::BranchingTable, variables::Vector, problem::AbstractProblem, m::AbstractMeasure, solver::NaiveBranch)
    candidates = bit_clauses(table)
	size_reductions = [size_reduction(problem, m, first(candidate), variables) for candidate in candidates]
	γ = complexity_bv(size_reductions)
    return OptimalBranchingResult(DNF(first.(candidates)), size_reductions, γ)
end

function bit_clauses(tbl::BranchingTable{INT}) where {INT}
    n, bss = tbl.bit_length, tbl.table
    temp_clauses = [[Clause(bmask(INT, 1:n), bs) for bs in bss1] for bss1 in bss]
    return temp_clauses
end

function greedymerge(cls::Vector{Vector{Clause{INT}}}, problem::AbstractProblem, variables::Vector, m::AbstractMeasure) where {INT}
    function min_merge(cli, clj, Δρi, Δρj, γ)
        dEmin, iimin, jjmin, reductionmin = 0.0, -1, -1, 0
        for ii = 1:length(cli), jj = 1:length(clj)
            cl12 = gather2(length(variables), cli[ii], clj[jj])
            iszero(cl12.mask) && continue
            reduction = size_reduction(problem, m, cl12, variables)
            dE = γ^(-reduction) - γ^(-Δρi) - γ^(-Δρj)
            if dE < dEmin
                dEmin, iimin, jjmin, reductionmin = dE, ii, jj, reduction
            end
        end
        return dEmin, iimin, jjmin, reductionmin
    end
    cls = copy(cls)
    size_reductions = [size_reduction(problem, m, first(candidate), variables) for candidate in cls]
    ΔE = zeros(length(cls), length(cls))
    II = zeros(Int, length(cls), length(cls))
    JJ = zeros(Int, length(cls), length(cls))
    RD = zeros(length(cls), length(cls))
    while true
        nc = length(cls)
        mask = trues(nc)
        γ = complexity_bv(size_reductions)
        for i ∈ 1:nc, j ∈ i+1:nc
            ΔE[i, j], II[i, j], JJ[i, j], RD[i, j] = min_merge(cls[i], cls[j], size_reductions[i], size_reductions[j], γ)
        end
        all(x-> x > -1e-12, ΔE) && return OptimalBranchingResult(DNF(first.(cls)), size_reductions, γ)
        while true
            minval, minidx = findmin(ΔE)
            minval > -1e-12 && break
            i, j = minidx.I
            # update i-th row
            cls[i] = [gather2(length(variables), cls[i][II[i, j]], cls[j][JJ[i, j]])]
            size_reductions[i] = RD[i, j]
            for k = i+1:nc
                mask[k] && ((ΔE[i, k], II[i, k], JJ[i, k], RD[i, k]) = min_merge(cls[i], cls[k], size_reductions[i], size_reductions[k], γ))
            end
            for k = 1:i-1
                mask[k] && ((ΔE[k, i], II[k, i], JJ[k, i], RD[k, i]) = min_merge(cls[k], cls[i], size_reductions[k], size_reductions[i], γ))
            end
            # remove j-th row
            mask[j] = false
            ΔE[j, :] .= 0.0
            ΔE[:, j] .= 0.0
        end
        cls, size_reductions = cls[mask], size_reductions[mask]
    end
end
