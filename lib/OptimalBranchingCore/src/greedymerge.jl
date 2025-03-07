struct GreedyMerge <: AbstractSetCoverSolver end
struct NaiveBranch <: AbstractSetCoverSolver end
function optimal_branching_rule(table::BranchingTable, variables::Vector, problem::AbstractProblem, m::AbstractMeasure, solver::GreedyMerge)
    candidates = bit_clauses(table)
    return greedymerge(candidates, problem, variables, m)
end

function optimal_branching_rule(table::BranchingTable, variables::Vector, problem::AbstractProblem, m::AbstractMeasure, solver::NaiveBranch)
    candidates = bit_clauses(table)
	size_reductions = [Float64(size_reduction(problem, m, first(candidate), variables)) for candidate in candidates]
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
        clmax, iimax, jjmax, reductionmax = Clause(zero(INT), zero(INT)), -1, -1, 0.0
        @inbounds for ii = 1:length(cli), jj = 1:length(clj)
            cl12 = gather2(length(variables), cli[ii], clj[jj])
            iszero(cl12.mask) && continue
            reduction = Float64(size_reduction(problem, m, cl12, variables))
            if reduction > reductionmax
                clmax, iimax, jjmax, reductionmax = cl12, ii, jj, reduction
            end
        end
        return clmax, iimax, jjmax, reductionmax
    end
    cls = copy(cls)
    size_reductions = [Float64(size_reduction(problem, m, first(candidate), variables)) for candidate in cls]
    @inbounds while true
        nc = length(cls)
        mask = trues(nc)
        γ = complexity_bv(size_reductions)
        weights = map(s -> γ^(-s), size_reductions)
        queue = PriorityQueue{NTuple{2, Int}, Float64}()  # from small to large
        for i ∈ 1:nc, j ∈ i+1:nc
            _, _, _, reduction = reduction_merge(cls[i], cls[j])
            dE = γ^(-reduction) - weights[i] - weights[j]
            dE <= -1e-12 && enqueue!(queue, (i, j), dE)
        end
        isempty(queue) && return OptimalBranchingResult(DNF(first.(cls)), size_reductions, γ)
        while !isempty(queue)
            (i, j) = dequeue!(queue)
            # remove i, j-th row
            for rowid in (i, j)
                mask[rowid] = false
                for l = 1:nc
                    if mask[l]
                        a, b = minmax(rowid, l)
                        haskey(queue, (a, b)) && delete!(queue, (a, b))
                    end
                end
            end
            # add i-th row
            mask[i] = true
            clij, _, _, size_reductions[i] = reduction_merge(cls[i], cls[j])
            cls[i] = [clij]
            weights[i] = γ^(-size_reductions[i])
            for l = 1:nc
                if i !== l && mask[l]
                    a, b = minmax(i, l)
                    _, _, _, reduction = reduction_merge(cls[a], cls[b])
                    dE = γ^(-reduction) - weights[a] - weights[b]
                    
                    dE <= -1e-12 && enqueue!(queue, (a, b), dE)
                end
            end
        end
        cls, size_reductions = cls[mask], size_reductions[mask]
    end
end
