"""
    mis_size(g::AbstractGraph; branching_strategy::BranchingStrategy = BranchingStrategy(table_solver = TensorNetworkSolver(), selector = MinBoundaryHighDegreeSelector(2, 6, 0), measure=D3Measure()), reducer::AbstractReducer = MISReducer(), show_progress::Bool = false)

Calculate the size of the Maximum Independent Set (MIS) for a given graph.

### Arguments
- `g::AbstractGraph`: The graph for which the MIS size is to be calculated.

### Keyword Arguments
- `branching_strategy::BranchingStrategy`: (optional) The branching strategy to be used. Defaults to a strategy using `table_solver=TensorNetworkSolver`, `selector=MinBoundaryHighDegreeSelector(2, 6, 0)`, and `measure=D3Measure`.
- `reducer::AbstractReducer`: (optional) The reducer to be applied. Defaults to `MISReducer`.
- `show_progress::Bool`: (optional) Whether to show the progress of the branching and reduction process. Defaults to `false`.

### Returns
- An integer representing the size of the Maximum Independent Set for the given graph.
"""
function mis_size(g::AbstractGraph; branching_strategy::BranchingStrategy = BranchingStrategy(table_solver = TensorNetworkSolver(), selector = MinBoundaryHighDegreeSelector(2, 6, 0), measure = D3Measure()), reducer = MISReducer(), show_progress::Bool = false)
    p = MISProblem(g)
    res = branch_and_reduce(p, branching_strategy, reducer, MaxSize; show_progress)
    return res.size
end

"""
    mwis_size(g::AbstractGraph, weights::Vector; branching_strategy::BranchingStrategy = BranchingStrategy(table_solver = TensorNetworkSolver(), selector = MinBoundaryHighDegreeSelector(2, 6, 0), measure=D3Measure()), reducer::AbstractReducer = MWISReducer(), show_progress::Bool = false)

Calculate the size of the Maximum Weighted Independent Set (MWIS) for a given vertex-weighted graph.

### Arguments
- `g::AbstractGraph`: The graph for which the MWIS size is to be calculated.
- `weights::Vector`: The weights of the vertices in the graph.

### Keyword Arguments
- `branching_strategy::BranchingStrategy`: (optional) The branching strategy to be used. Defaults to a strategy using `table_solver=TensorNetworkSolver`, `selector=MinBoundaryHighDegreeSelector(2, 6, 0)`, and `measure=D3Measure`.
- `reducer::AbstractReducer`: (optional) The reducer to be applied. Defaults to `MWISReducer`.
- `show_progress::Bool`: (optional) Whether to show the progress of the branching and reduction process. Defaults to `false`.

### Returns
- An integer representing the size of the Maximum Weighted Independent Set for the given vertex-weighted graph.
"""
function mwis_size(g::AbstractGraph, weights::Vector; branching_strategy::BranchingStrategy = BranchingStrategy(table_solver = TensorNetworkSolver(), selector = MinBoundaryHighDegreeSelector(2, 6, 0), measure = D3Measure()), reducer = MWISReducer(), show_progress::Bool = false)
    p = MWISProblem(g, weights)
    res = branch_and_reduce(p, branching_strategy, reducer, MaxSize; show_progress)
    return res.size
end

"""
    mis_branch_count(g::AbstractGraph; branching_strategy::BranchingStrategy = BranchingStrategy(table_solver = TensorNetworkSolver(), selector = MinBoundaryHighDegreeSelector(2, 6, 0), measure=D3Measure()), reducer=MISReducer(), show_progress::Bool = false)

Calculate the size and the number of branches of the Maximum Independent Set (MIS) for a given graph.

### Arguments
- `g::AbstractGraph`: The graph for which the MIS size and the number of branches are to be calculated.

### Keyword Arguments
- `branching_strategy::BranchingStrategy`: (optional) The branching strategy to be used. Defaults to a strategy using `table_solver=TensorNetworkSolver`, `selector=MinBoundaryHighDegreeSelector(2, 6, 0)`, and `measure=D3Measure`.
- `reducer::AbstractReducer`: (optional) The reducer to be applied. Defaults to `MISReducer`.
- `show_progress::Bool`: (optional) Whether to show the progress of the branching and reduction process. Defaults to `false`.

### Returns
- A tuple `(size, count)` where `size` is the size of the Maximum Independent Set and `count` is the number of branches.
"""
function mis_branch_count(g::AbstractGraph; branching_strategy::BranchingStrategy = BranchingStrategy(table_solver = TensorNetworkSolver(), selector = MinBoundaryHighDegreeSelector(2, 6, 0), measure = D3Measure()), reducer = MISReducer(), show_progress::Bool = false)
    p = MISProblem(g)
    res = branch_and_reduce(p, branching_strategy, reducer, MaxSizeBranchCount; show_progress)
    return (res.size, res.count)
end

"""
    mwis_branch_count(g::AbstractGraph, weights::Vector; branching_strategy::BranchingStrategy = BranchingStrategy(table_solver = TensorNetworkSolver(), selector = MinBoundaryHighDegreeSelector(2, 6, 0), measure=D3Measure()), reducer=MWISReducer(), show_progress::Bool = false)

Calculate the size and the number of branches of the Maximum Weighted Independent Set (MWIS) for a given vertex-weighted graph.

### Arguments
- `g::AbstractGraph`: The graph for which the MWIS size and the number of branches are to be calculated.
- `weights::Vector`: The weights of the vertices in the graph.

### Keyword Arguments
- `branching_strategy::BranchingStrategy`: (optional) The branching strategy to be used. Defaults to a strategy using `table_solver=TensorNetworkSolver`, `selector=MinBoundaryHighDegreeSelector(2, 6, 0)`, and `measure=D3Measure`.
- `reducer::AbstractReducer`: (optional) The reducer to be applied. Defaults to `MWISReducer`.
- `show_progress::Bool`: (optional) Whether to show the progress of the branching and reduction process. Defaults to `false`.

### Returns
- A tuple `(size, count)` where `size` is the size of the Maximum Weighted Independent Set and `count` is the number of branches.
"""
function mwis_branch_count(g::AbstractGraph, weights::Vector; branching_strategy::BranchingStrategy = BranchingStrategy(table_solver = TensorNetworkSolver(), selector = MinBoundaryHighDegreeSelector(2, 6, 0), measure = D3Measure()), reducer = MWISReducer(), show_progress::Bool = false)
    p = MWISProblem(g, weights)
    res = branch_and_reduce(p, branching_strategy, reducer, MaxSizeBranchCount; show_progress)
    return (res.size, res.count)
end
