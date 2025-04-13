using JSON3
using OptimalBranchingCore
using DelimitedFiles
using PrettyTables

function load_ob(input_file::String)
    # Read the JSON file
    data = open(input_file, "r") do io
        JSON3.read(io)
    end
    return data
end

function check_validity(data::JSON3.Object)
    input_table_string = data[:input_table][433:end]
    tbl_matrix = DelimitedFiles.readdlm_string(input_table_string, ',', Int, ';', true, Dict())
    table = BranchingTable(size(tbl_matrix, 2), [[tbl_matrix[i, :]] for i in 1:size(tbl_matrix, 1)])
    predicted = read_rule(data[:prediction][7:end])
    optimal = read_rule(data[:real_optimal_value][7:end])
    (is_valid, gamma) = checkrule(table, predicted)
    (is_valid_opt, gamma_opt) = checkrule(table, optimal)
    @assert is_valid_opt
    @assert !is_valid || gamma_opt <= gamma + eps(1.0) "gamma_opt = $gamma_opt, gamma = $gamma"
    @show table predicted optimal
    return is_valid, gamma, gamma_opt, optimal == predicted, predicted, optimal
end

function checkrule(table::BranchingTable, predicted::DNF)
    @show table.table[1]
    @show [any(bs->OptimalBranchingCore.covered_by(bs, predicted), row) for row in table.table]
    is_valid = OptimalBranchingCore.covered_by(table, predicted)
    @show is_valid
    size_reductions = [length(clause) for clause in predicted.clauses]
    gamma = OptimalBranchingCore.complexity_bv(size_reductions)
    return is_valid, gamma
end

function read_rule(rule_string::String)
    return DNF([read_clause(cstring) for cstring in split(rule_string, " OR ")])
end

function read_clause(cstring::AbstractString)
    tokens = split(cstring, ",")
    INT = OptimalBranchingCore.BitBasis.longinttype(length(tokens), 2)
    mask = INT(0)
    val = INT(0)
    for (i, token) in enumerate(tokens)
        if token != "X"
            mask += INT(1) << (i - 1)
            if token == "1"
                val += INT(1) << (i - 1)
            end
        end
    end
    return OptimalBranchingCore.Clause(mask, val)
end

datafile = joinpath(@__DIR__, "evaluation_1.json")
data = load_ob(datafile)
checkres = check_validity.(data)

using PrettyTables
# Create a summary table with validation results
function print_summary_results(checkres)
    # list the non-trivial, and non-optimal rules, and compare with the optimal rule
    badcount = 0
    for (i, x) in enumerate(checkres)
        x[1] || continue
        if x[2] <= 2 && !x[4]
            println("Rule $i: $(x[2]) $(x[3])")
        elseif x[2] > 2
            badcount += 1
        end
    end
    summary_data = [count(x -> x[1], checkres) length(checkres) count(x -> x[4], checkres) badcount]
    pretty_table(summary_data, header=["Valid Rules", "Total Rules", "Optimal Rules", "Bad Rules"], 
                 tf=tf_unicode_rounded)
end

print_summary_results(checkres)

function print_detailed_results(checkres)
    # Create a detailed table with validation results for each rule
    detailed_data = Matrix{Any}(undef, length(data), 5)
    for (i, (is_valid, gamma, gamma_opt, is_optimal)) in enumerate(checkres)
        detailed_data[i, 1] = i
        detailed_data[i, 2] = is_valid ? "✓" : "✗"
        detailed_data[i, 3] = gamma
        detailed_data[i, 4] = gamma_opt
        detailed_data[i, 5] = is_optimal ? "✓" : "✗"
    end

    # Define highlighters for the detailed table
    hl_invalid = Highlighter((data, i, j) -> j == 2 && data[i, j] == "✗", crayon"red bold")
    hl_optimal = Highlighter((data, i, j) -> j == 5 && data[i, j] == "✓", crayon"green bold")
    hl_suboptimal = Highlighter((data, i, j) -> j == 5 && data[i, j] == "✗", crayon"yellow")

    # Print the detailed table
    println("\nDetailed Results:")
    pretty_table(
        detailed_data,
        header=["Rule #", "Valid", "Complexity", "Optimal Complexity", "Is Optimal"],
        highlighters=(hl_invalid, hl_optimal, hl_suboptimal),
        tf=tf_unicode_rounded
    )
end

print_detailed_results(checkres)
