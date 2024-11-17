mutable struct BranchingNode{P}
    children::Vector{BranchingNode{P}}
    problem::P
    BranchingNode(graph::SimpleGraph{Int}; children::Vector{BranchingNode} = Vector{BranchingNode}(), removed::Vector{Vector{Int}} = Vector{Vector{Int}}()) = new(children, graph, removed)
end

AbstractTrees.children(node::BranchingNode) = node.children
AbstractTrees.printnode(io::IO, node::BranchingNode) = print(io, "G{$(nv(node.graph))}")
AbstractTrees.nodevalue(node::BranchingNode) = node.graph

isleaf(node::BranchingNode) = isempty(node.children)
Base.show(io::IO, tree::BranchingNode) = print_tree(io, tree)

function add_child!(node::BranchingNode, child::BranchingNode)
    push!(node.children, child)
    return node
end