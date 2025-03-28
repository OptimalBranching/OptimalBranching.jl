using OptimalBranchingCore
using OptimalBranchingCore: NumOfVariables, MockProblem, MockTableSolver, IPSolver, optimal_branching_rule, GreedyMerge, NaiveBranch, BitBasis
using JSON3

function gen_ob(n::Int, nstrings::Int, output_file::String, solver, nsample::Int)
    output_data = []
    for i in 1:nsample
        p = MockProblem(rand(Bool, n))
        table_solver = MockTableSolver(nstrings, 0.2)
        tbl = branching_table(p, table_solver, 1:n)
        r1 = optimal_branching_rule(tbl, collect(1:n), p, NumOfVariables(), solver)
        # Convert the optimal rule to a serializable format
        item = Dict(
            "input_table" => table2dict(tbl),
            "optimal_rule" => Dict(
                "rule" => [clause2dict(clause) for clause in r1.optimal_rule],
                "gamma" => r1.γ
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

function clause2dict(clause::Clause)
    return Dict(
        "mask" => BitArray(bitstring(clause.mask)[end-tbl.bit_length+1:end] .== '1'),
        "val" => BitArray(bitstring(clause.val)[end-tbl.bit_length+1:end] .== '1')
    )
end

# Generate and save to file
output_file = "optimal_branching_result.json"
gen_ob(15, 40, output_file, IPSolver(), 1)
println("Results saved to $output_file")

function load_ob(input_file::String)
    # Read the JSON file
    data = open(input_file, "r") do io
        JSON3.read(io)
    end
    
    # Extract the bit length
    bit_length = data.bit_length
    
    # Convert the table data back to BranchingTable format
    table = Vector{Vector{UInt}}()
    for row in data.table
        table_row = Vector{UInt}()
        for bs in row
            # Convert BitArray back to UInt
            int_val = UInt(0)
            for (i, bit) in enumerate(bs)
                if bit
                    int_val |= UInt(1) << (i-1)
                end
            end
            push!(table_row, int_val)
        end
        push!(table, table_row)
    end
    
    # Create the BranchingTable
    branching_table = BranchingTable(bit_length, table)
    
    # Convert the rule data back to DNF format
    clauses = Vector{Clause{UInt}}()
    for clause_data in data.optimal_rule
        mask = UInt(0)
        val = UInt(0)
        
        for (i, bit) in enumerate(clause_data.mask)
            if bit
                mask |= UInt(1) << (i-1)
            end
        end
        
        for (i, bit) in enumerate(clause_data.val)
            if bit
                val |= UInt(1) << (i-1)
            end
        end
        
        push!(clauses, Clause(mask, val))
    end
    
    # Create the DNF
    optimal_rule = DNF(clauses)
    
    # Return the loaded data
    return (
        branching_table = branching_table,
        optimal_rule = optimal_rule,
        gamma = data.gamma
    )
end

# Example usage:
# result = load_ob("optimal_branching_result.json")
# println("Loaded branching table: ", result.branching_table)
# println("Loaded optimal rule: ", result.optimal_rule)
# println("Gamma value: ", result.gamma)
