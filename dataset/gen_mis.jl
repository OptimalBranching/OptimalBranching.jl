# Generate end to end dataset for MIS
using OptimalBranchingCore, OptimalBranchingMIS
using OptimalBranchingCore: IPSolver, optimal_branching_rule, BitBasis, NumOfVariables
using OptimalBranchingMIS.GenericTensorNetworks: random_diagonal_coupled_graph
using Graphs
using JSON3

function OptimalBranchingCore.size_reduction(p::AbstractProblem, m::NumOfVariables, cl::Clause{INT}, variables::Vector) where {INT}
    return count_ones(cl.mask)
end
function gen_mis(graph::SimpleGraph, output_file::String, single_column::Bool)
    problem = MISProblem(graph)
    output_data = []
    for i in 1:nv(graph)
        @info "Generating sample $i"
        variables, openvars = OptimalBranchingMIS.neighbor_cover(graph, i, 2)
        tbl = branching_table(problem, TensorNetworkSolver(; prune_by_env=true), variables)      # compute the BranchingTable
        if single_column
            for row in tbl.table
                resize!(row, 1)
            end
        end
        @show length(tbl.table)
        if length(tbl.table) > 100
            @warn "Branching table is too large: $length(tbl.table)"
            continue
        end
        # measure = D3Measure()
        measure = NumOfVariables()
        result = optimal_branching_rule(tbl, variables, problem, measure, IPSolver())        # compute the optimal branching rule

        # save the environment data (up to 4-layer neighbors)
        variables4, openvars4 = OptimalBranchingMIS.neighbor_cover(graph, i, 4)
        subgraph, vmap = induced_subgraph(graph, variables4)
        # Convert the optimal rule to a serializable format
        item = Dict(
            "input_subgraph" => subgraph2dict(subgraph, findfirst(==(i), vmap), [findfirst(==(v), vmap) for v in openvars4]),
            "input_table" => table2dict(tbl),
            "optimal_rule" => Dict(
                "rule" => [clause2dict(nv(graph), clause) for clause in result.optimal_rule.clauses],
                "gamma" => result.γ  # γ is determined by: 1 = sum_c γ^(num_literals(c)), where c is a clause in the optimal rule
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

function subgraph2dict(subgraph::SimpleGraph, center::Int, openvars::Vector{Int})
    return Dict(
        "center" => center,
        "openvars" => openvars,
        "nv" => nv(subgraph),
        "edges" => [[e.src, e.dst] for e in edges(subgraph)]
    )
end

function clause2dict(n::Int, clause::Clause)
    return [isone(BitBasis.readbit(clause.mask, i)) ? Int(BitBasis.readbit(clause.val, i)) : -1 for i in 1:n]
end

# Generate and save to file
function gen_renyi_and_save(n, p)
    output_file = joinpath(@__DIR__, "mis_result-renyi-n=$n-p=$p.json")
    # generate a Erdos-Renyi graph with n vertices and edge probability p
    graph = erdos_renyi(n, p)
    gen_mis(graph, output_file, true)
    @info("Results saved to $output_file")
    return output_file
end
function gen_ksg_and_save(L::Int)
    ksg = random_diagonal_coupled_graph(L, L, 0.8)
    output_file = joinpath(@__DIR__, "mis_result-ksg-L=$L.json")
    gen_mis(SimpleGraph(ksg), output_file, true)
    @info("Results saved to $output_file")
    return output_file
end
function gen_regular3_and_save(n::Int)
    output_file = joinpath(@__DIR__, "mis_result-regular3-n=$n.json")
    graph = random_regular_graph(n, 3)
    gen_mis(graph, output_file, true)
end
# output_file = gen_ksg_and_save(32)
# output_file = gen_renyi_and_save(1000, 0.005)
# output_file = gen_regular3_and_save(1000)