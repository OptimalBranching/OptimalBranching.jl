mutable struct ClauseTree{INT <: Integer}
    left::ClauseTree
    right::ClauseTree
    cl::Vector{Clause{INT}}
    γ::Float64
    size_re::Int # the largest size reduction in cl
    ClauseTree(::Type{INT},size_re::Int) where INT = (res = new{INT}(); res.cl = [Clause(zero(INT),zero(INT))]; res.size_re = size_re; res)
    ClauseTree(::Type{INT}) where INT = (res = new{INT}(); res.cl = [Clause(zero(INT),zero(INT))]; res.size_re = 0; res)
    ClauseTree(cl::Vector{Clause{T}}, size_re::Int,γ) where T = (res = new{T}(); res.cl = cl; res.size_re = size_re;res.γ = γ; res)
    ClauseTree(left, right, cl::Vector{Clause{T}}, γ, size_re) where T = new{T}(left, right, cl, γ, size_re)
end

function print_expr(io::IO, expr::ClauseTree)
    if isleaf(expr)
        print(io, "leaf\n")
        print(io, expr.cl)
    else
        print(io, "γ: ", expr.γ, "\n")
        print(io, expr.cl[1])
    end

end

isleaf(clt::ClauseTree) = !isdefined(clt, :left)
siblings(t::ClauseTree{T}) where T = isleaf(t) ? ClauseTree{T}[] : ClauseTree{T}[t.left, t.right]
Base.copy(t::ClauseTree) = isleaf(t) ? ClauseTree(t.cl,t.size_re,t.γ) : ClauseTree(copy(t.left), copy(t.right), copy(t.cl), t.γ, t.size_re)
Base.show(io::IO, expr::ClauseTree) = print_expr(io, expr)
Base.show(io::IO, ::MIME"text/plain", expr::ClauseTree) = show(io, expr)

Base.@kwdef struct TreeSA <: AbstractSetCoverSolver 
    βs::Vector{Float64} = collect(1:5:500)
    iter::Int = 100
    γ::Float64 = 1.1
end
function optimal_branching_rule(table::BranchingTable, variables::Vector, problem::AbstractProblem, m::AbstractMeasure, solver::TreeSA)
    candidates = bit_clauses(table)
    tree = random_clausetree(candidates, problem, m, variables)
    optimize_tree_sa!(tree, solver.βs, solver.iter, problem, m, variables)
    # return tree
    cls = Vector{typeof(candidates[1][1])}()
    reductions = Vector{Int}()
    slice_tree!(tree, solver.γ, cls, reductions)
    # return cls
    γ = complexity_bv(reductions)
    return OptimalBranchingResult(DNF((cls)), reductions, γ)
end

function random_clausetree(cls::Vector{Vector{Clause{INT}}}, p::AbstractProblem, m::AbstractMeasure, variables) where INT
    n = length(cls)
    nv = length(variables)
    if n == 1
        local max_sr = 0
        for cl0 in cls[1]
            sr = size_reduction(p, m, cl0, variables)
            if sr > max_sr
                max_sr = sr
            end
        end
        return ClauseTree(cls[1], max_sr,1.0)
    end

    mask = rand(Bool, n)

    if all(mask) || !any(mask)  # prevent invalid partition
        i = rand(1:n)
        mask[i] = ~(mask[i])
    end

    left = random_clausetree(cls[mask], p, m, variables)
    right = random_clausetree(cls[(!).(mask)], p, m, variables)
    cl, rs = gather2(nv, left.cl, right.cl, p, m, variables)
    γ = complexity_bv([left.size_re-rs, right.size_re-rs])

    return ClauseTree(left, right, [cl], γ, rs)
end

function gather2(n::Int, leftcl::Vector{Clause{INT}}, rightcl::Vector{Clause{INT}}, p::AbstractProblem, m::AbstractMeasure, variables) where INT
    local max_sr = 0
    local max_cl = Clause(zero(INT), zero(INT))
    for l in leftcl
        for r in rightcl
            cl = gather2(n, r, l)
            cl.mask == 0 && continue
            sr = size_reduction(p, m, cl, variables)
            if sr > max_sr
                max_sr = sr
                max_cl = cl
            end
        end
    end
    return max_cl, max_sr
end


# use simulated annealing to optimize a contraction tree
function optimize_tree_sa!(tree::ClauseTree, βs, niters, p::AbstractProblem, m::AbstractMeasure, variables)
    for β in βs
        for _ ∈ 1:niters
            optimize_subtree!(tree, β, p, m, variables)
        end
    end
    return tree
end

function slice_tree!(tree::ClauseTree{T}, min_γ::Float64, cls::Vector{Clause{T}},reductions::Vector{Int}) where T
    if isleaf(tree)
        push!(cls, tree.cl[1])
        push!(reductions, tree.size_re)
        return true
    end
    if tree.γ < min_γ
        return false
    end
    if slice_tree!(tree.left, min_γ, cls,reductions) && slice_tree!(tree.right, min_γ, cls,reductions)
        return true
    else
        push!(cls, tree.cl[1])
        push!(reductions, tree.size_re)
        return true
    end
end

function optimize_subtree!(tree, β, p, m, variables)
    # find appliable local rules, at most 4 rules can be applied.
    # Sometimes, not all rules are applicable because either left or right sibling do not have siblings.
    rst = ruleset(tree)
    if !isempty(rst)
        rule = rand(rst)
        γac, γacb, rs, cl, γab_old, γabc_old = tcsc_diff(tree, rule, p, m, variables)

        ΔE = γac + γacb - γab_old - γabc_old
        # @show weight_sum(tree,2.0)
        if rand() < exp(-β * ΔE)  # ACCEPT
            update_tree!(tree, rule, γac, γacb, rs, cl)
        end
        for subtree in siblings(tree)  # RECURSE
            optimize_subtree!(subtree, β, p, m, variables)
        end
    end
end

function weight_sum(tree,γ)
    if isleaf(tree)
        return γ^ (- tree.size_re)
    else
        return γ^ (- tree.size_re) + weight_sum(tree.left,γ) + weight_sum(tree.right,γ)
    end
end

@inline function ruleset(tree::ClauseTree)
    if isleaf(tree) || (isleaf(tree.left) && isleaf(tree.right))
        return 1:0
    elseif isleaf(tree.right)
        return 1:2
    elseif isleaf(tree.left)
        return 3:4
    else
        return 1:4
    end
end

function update_tree!(tree::ClauseTree, rule::Int, γac, γacb, rs, cl)
    if rule == 1 # (a,b), c -> (a,c),b
        b, c = tree.left.right, tree.right
        tree.left.right = c
        tree.right = b
        tree.left.γ = γac
        tree.γ = γacb
        tree.left.size_re = rs
        tree.left.cl = [cl]
    elseif rule == 2 # (a,b), c -> (c,b),a
        a, c = tree.left.left, tree.right
        tree.left.left = c
        tree.right = a
        tree.left.γ = γac
        tree.γ = γacb
        tree.left.size_re = rs
        tree.left.cl = [cl]
    elseif rule == 3 # a,(b,c) -> b,(a,c)
        a, b = tree.left, tree.right.left
        tree.left = b
        tree.right.left = a
        tree.right.γ = γac
        tree.γ = γacb
        tree.right.size_re = rs
        tree.right.cl = [cl]
    else  # a,(b,c) -> c,(b,a)
        a, c = tree.left, tree.right.right
        tree.left = c
        tree.right.right = a
        tree.right.γ = γac
        tree.γ = γacb
        tree.right.size_re = rs
        tree.right.cl = [cl]
    end
    return tree
end

function tcsc_diff(tree::ClauseTree, rule, p::AbstractProblem, m::AbstractMeasure, variables)
    if rule == 1 # (a,b), c -> (a,c),b
        return abcacb(tree.left.left.cl, tree.right.cl, p, m, variables, tree.left.left.size_re, tree.left.right.size_re, tree.right.size_re,tree.size_re)..., tree.left.γ, tree.γ
    elseif rule == 2 # (a,b), c -> (c,b),a
        return abcacb(tree.left.right.cl, tree.right.cl, p, m, variables, tree.left.right.size_re, tree.left.left.size_re, tree.right.size_re,tree.size_re)..., tree.left.γ, tree.γ
    elseif rule == 3 # a,(b,c) -> b,(a,c)
        return abcacb(tree.right.right.cl, tree.left.cl, p, m, variables, tree.right.right.size_re, tree.right.left.size_re, tree.left.size_re,tree.size_re)..., tree.right.γ, tree.γ
    else  # a,(b,c) -> c,(b,a)
        return abcacb(tree.right.left.cl, tree.left.cl, p, m, variables, tree.right.left.size_re, tree.right.right.size_re, tree.left.size_re,tree.size_re)..., tree.right.γ, tree.γ
    end
end
# compute the gamma and size reduction for the contraction update rule "((a,b),c) -> ((a,c),b)"
function abcacb(a, b, p, m, variables, ra, rb, rc,rabc_old)
    cl, rs = gather2(length(variables), a, b, p, m, variables)

    γac = complexity_bv([ra-rs, rc-rs])
    γacb = complexity_bv([rs-rabc_old, rb-rabc_old])
    return γac, γacb, rs, cl
end
