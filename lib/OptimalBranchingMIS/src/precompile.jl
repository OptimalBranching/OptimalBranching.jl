# Compile the default MIS entry points on a small, deterministic cubic graph.
# Workload setup and execution happen during package precompilation only.
@setup_workload begin
    graph = Graphs.random_regular_graph(60, 3; seed=2134)
    @compile_workload begin
        mis_size(graph)
        mis_branch_count(graph)
    end
end
