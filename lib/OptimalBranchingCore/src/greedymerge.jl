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
    function reduction_merge(cli, clj)
        iimax, jjmax, reductionmax = -1, -1, 0.0
        for ii = 1:length(cli), jj = 1:length(clj)
            cl12 = gather2(length(variables), cli[ii], clj[jj])
            iszero(cl12.mask) && continue
            reduction = size_reduction(problem, m, cl12, variables)
            if reduction > reductionmax
                iimax, jjmax, reductionmax = ii, jj, reduction
            end
        end
        return iimax, jjmax, reductionmax
    end
    cls = copy(cls)
    size_reductions = [size_reduction(problem, m, first(candidate), variables) for candidate in cls]
    II = zeros(Int, length(cls), length(cls))
    JJ = zeros(Int, length(cls), length(cls))
    RD = zeros(length(cls), length(cls))
    for i = 1:length(cls), j = i+1:length(cls)
        II[i, j], JJ[i, j], RD[i, j] = reduction_merge(cls[i], cls[j])
    end
    while true
        nc = length(cls)
        mask = trues(nc)
        γ = complexity_bv(size_reductions)
        queue = PriorityQueue{NTuple{2, Int}, Float64}()  # from small to large
        for i ∈ 1:nc, j ∈ i+1:nc
            dE = γ^(-RD[i, j]) - γ^(-size_reductions[i]) - γ^(-size_reductions[j])
            dE <= -1e-12 && enqueue!(queue, (i, j), dE)
        end
        isempty(queue) && return OptimalBranchingResult(DNF(first.(cls)), size_reductions, γ)
        @show "!"
        while !isempty(queue)
            @show peek(queue)
            (i, j) = dequeue!(queue)
            # remove i, j-th row
            for rowid in (i, j)
                mask[rowid] = false
                for k = 1:nc
                    if mask[k]
                        a, b = minmax(rowid, k)
                        haskey(queue, (a, b)) && delete!(queue, (a, b))
                    end
                end
            end
            # add i-th row
            mask[i] = true
            cls[i] = [gather2(length(variables), cls[i][II[i, j]], cls[j][JJ[i, j]])]
            size_reductions[i] = RD[i, j]
            for k = 1:nc
                if i !== k && mask[k]
                    a, b = minmax(i, k)
                    II[a, b], JJ[a, b], RD[a, b] = reduction_merge(cls[a], cls[b])
                    dE = γ^(-RD[a, b]) - γ^(-size_reductions[a]) - γ^(-size_reductions[b])
                    dE <= -1e-12 && enqueue!(queue, (a, b), dE)
                end
            end
        end
        cls, size_reductions, II, JJ, RD = cls[mask], size_reductions[mask], II[mask, mask], JJ[mask, mask], RD[mask, mask]
    end
end
