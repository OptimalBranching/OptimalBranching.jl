"""
    struct SolutionAndCount{INT <: Integer}

The maximum solution size, solution and the number of branches, which is the return value of a branching algorithm.

### Fields
- `size::Float64`: The solution size, the larger the better.
- `solution::INT`: The optimal solution stored in an integer.
- `count::Int`: The number of branches of that size.
"""
struct SolutionAndCount{INT <: Integer}
    size::Float64
    solution::INT
    count::Int
    SolutionAndCount(size::Real, solution::INT, count::Integer) where INT <: Integer = new{INT}(Float64(size), solution, Int(count))
end

function compare_solutions(a::SolutionAndCount, b::SolutionAndCount)
    cc = a.count + b.count
    a.size >= b.size ? SolutionAndCount(a.size, a.solution, cc) : SolutionAndCount(b.size, b.solution, cc)
end
function join_solutions(a::SolutionAndCount, b::SolutionAndCount)
    SolutionAndCount(a.size + b.size, a.solution | b.solution, a.count * b.count)
end

"""
    read_solution(n::Int, sol::SolutionAndCount)

Reads the solution from the [`SolutionAndCount`](@ref) object.

### Arguments
- `n::Int`: The number of variables.
- `sol::SolutionAndCount`: The solution object.
"""
read_solution(n::Int, sol::SolutionAndCount) = [Int(readbit(sol.solution, i)) for i in 1:n]