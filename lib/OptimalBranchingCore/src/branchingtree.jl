struct BranchingTreeNode{P <: AbstractProblem}
    children::Vector{BranchingTreeNode{P}}
    problem::P
    BranchingTreeNode(problem::P) where {P <: AbstractProblem} = new{P}(BranchingTreeNode{P}[], problem)
end


AbstractTrees.children(node::BranchingTreeNode) = node.children
AbstractTrees.printnode(io::IO, node::BranchingTreeNode) = print(io, "G{$(nv(node.graph))}")
AbstractTrees.nodevalue(node::BranchingTreeNode) = node.problem

isleaf(node::BranchingTreeNode) = isempty(node.children)
Base.show(io::IO, tree::BranchingTreeNode) = print_tree(io, tree)

function add_child!(node::BranchingTreeNode, child::BranchingTreeNode)
    push!(node.children, child)
end

function add_child!(node::BranchingTreeNode, problem::P) where {P <: AbstractProblem}
    push!(node.children, BranchingTreeNode{P}(problem))
end
