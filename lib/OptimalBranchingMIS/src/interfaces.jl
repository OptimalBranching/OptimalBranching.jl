"""
    mis_size(g::AbstractGraph; weights::AbstractVector = UnitWeight(nv(g)), branching_strategy::BranchingStrategy = BranchingStrategy(table_solver = TensorNetworkSolver(), selector = MinBoundaryHighDegreeSelector(2, 6, 0), measure=D3Measure()), reducer::AbstractReducer = BasicReducer(), show_progress::Bool = false)

Calculate the size of the Maximum (Weighted) Independent Set (M(W)IS) for a given (vertex-weighted) graph.

### Arguments
- `g::AbstractGraph`: The graph for which the M(W)IS size is to be calculated.
- `weights::Vector`: (optional) The weights of the vertices in the graph. It's set to be UnitWeight if the graph is not weighted. Defaults to `UnitWeight(nv(g))`.

### Keyword Arguments
- `branching_strategy::BranchingStrategy`: (optional) The branching strategy to be used. Defaults to a strategy using `table_solver=TensorNetworkSolver`, `selector=MinBoundaryHighDegreeSelector(2, 6, 0)`, and `measure=D3Measure`.
- `reducer::AbstractReducer`: (optional) The reducer to be applied. Defaults to `BasicReducer`.
- `show_progress::Bool`: (optional) Whether to show the progress of the branching and reduction process. Defaults to `false`.

### Returns
- An integer representing the size of the Maximum (Weighted) Independent Set for the given (vertex-weighted) graph.
"""
function mis_size(g::AbstractGraph; weights::AbstractVector = UnitWeight(nv(g)), branching_strategy::BranchingStrategy = BranchingStrategy(table_solver = TensorNetworkSolver(), selector = MinBoundaryHighDegreeSelector(2, 6, 0), measure = D3Measure()), reducer = BasicReducer(), show_progress::Bool = false)
    p = MISProblem(g, weights)
    res = branch_and_reduce(p, branching_strategy, reducer, MaxSize; show_progress)
    return res.size
end

"""
    mis_branch_count(g::AbstractGraph; weights::AbstractVector = UnitWeight(nv(g)), branching_strategy::BranchingStrategy = BranchingStrategy(table_solver = TensorNetworkSolver(), selector = MinBoundaryHighDegreeSelector(2, 6, 0), measure=D3Measure()), reducer=BasicReducer(), show_progress::Bool = false)

Calculate the size and the number of branches of the Maximum (Weighted) Independent Set (M(W)IS) for a given (vertex-weighted) graph.

### Arguments
- `g::AbstractGraph`: The graph for which the M(W)IS size and the number of branches are to be calculated.
- `weights::Vector`: (optional) The weights of the vertices in the graph. It's set to be UnitWeight if the graph is not weighted. Defaults to `UnitWeight(nv(g))`.

### Keyword Arguments
- `branching_strategy::BranchingStrategy`: (optional) The branching strategy to be used. Defaults to a strategy using `table_solver=TensorNetworkSolver`, `selector=MinBoundaryHighDegreeSelector(2, 6, 0)`, and `measure=D3Measure`.
- `reducer::AbstractReducer`: (optional) The reducer to be applied. Defaults to `BasicReducer`.
- `show_progress::Bool`: (optional) Whether to show the progress of the branching and reduction process. Defaults to `false`.

### Returns
- A tuple `(size, count)` where `size` is the size of the Maximum (Weighted) Independent Set and `count` is the number of branches.
"""
function mis_branch_count(g::AbstractGraph; weights::AbstractVector = UnitWeight(nv(g)), branching_strategy::BranchingStrategy = BranchingStrategy(table_solver = TensorNetworkSolver(), selector = MinBoundaryHighDegreeSelector(2, 6, 0), measure = D3Measure()), reducer = BasicReducer(), show_progress::Bool = false)
    p = MISProblem(g, weights)
    res = branch_and_reduce(p, branching_strategy, reducer, MaxSizeBranchCount; show_progress)
    return (res.size, res.count)
end
