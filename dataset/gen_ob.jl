using OptimalBranchingCore
using OptimalBranchingCore: NumOfVariables, MockProblem, MockTableSolver, IPSolver, optimal_branching_rule, BitBasis
using JSON3

function gen_ob(n::Int, nstrings::Int, output_file::String, solver, nsample::Int)
    output_data = []
    for i in 1:nsample
        @info "Generating sample $i"
        p = MockProblem(rand(Bool, n))
        table_solver = MockTableSolver(nstrings, 0.2)
        tbl = branching_table(p, table_solver, 1:n)
        r1 = optimal_branching_rule(tbl, collect(1:n), p, NumOfVariables(), solver)
        # Convert the optimal rule to a serializable format
        item = Dict(
            "input_table" => table2dict(tbl),
            "optimal_rule" => Dict(
                "rule" => [clause2dict(n, clause) for clause in r1.optimal_rule.clauses],
                "gamma" => r1.γ  # γ is determined by: 1 = sum_c γ^(num_literals(c)), where c is a clause in the optimal rule
            ),
        )
        push!(output_data, item)
    end
   # Write to JSON file
    open(output_file, "w") do io
        JSON3.write(io, output_data)
    end
end

function table2dict(tbl::BranchingTable)
    n = tbl.bit_length
    return Dict(
        "bit_length" => n,
        "rows" => [[[Int(BitBasis.readbit(bs, i)) for i in 1:n] for bs in row] for row in tbl.table]
    )
end

function clause2dict(n::Int, clause::Clause)
    return [isone(BitBasis.readbit(clause.mask, i)) ? Int(BitBasis.readbit(clause.val, i)) : -1 for i in 1:n]
end

# Generate and save to file
function gen_ob_and_save(n, nstrings, nsample)
    output_file = joinpath(@__DIR__, "optimal_branching_result-n=$n-nstrings=$nstrings.json")
    gen_ob(n, nstrings, output_file, IPSolver(), nsample)
    @info("Results saved to $output_file")
    return output_file
end

n, nstrings = 15, 40
output_file = gen_ob_and_save(n, nstrings, 1000)

function load_ob(input_file::String)
    # Read the JSON file
    data = open(input_file, "r") do io
        JSON3.read(io)
    end
    return data
end

data = load_ob(output_file)
println(data)