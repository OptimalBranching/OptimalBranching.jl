using OptimalBranchingCore.JuMP, OptimalBranchingCore.HiGHS

function ip_mis(g::AbstractGraph; optimizer=HiGHS.Optimizer, verbose::Bool=false)
    model = Model(optimizer)
    !verbose && set_silent(model)
    n = nv(g)
    @variable(model, 0 <= x[i = 1:n] <= 1, Int)
    @objective(model, Max, sum(x))
    for e in edges(g)
        @constraint(model, x[src(e)] + x[dst(e)] <= 1)
    end
    optimize!(model)
    @assert is_solved_and_feasible(model)
    return Int(round(sum(value.(x))))
end