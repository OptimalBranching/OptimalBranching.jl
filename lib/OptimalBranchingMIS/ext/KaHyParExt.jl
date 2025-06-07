module KaHyParExt

using KaHyPar, OptimalBranchingMIS
using OptimalBranchingMIS.OptimalBranchingCore
using OptimalBranchingMIS.Graphs

function OptimalBranchingCore.select_variables(p::MISProblem, m::M, selector::KaHyParSelector) where {M <: AbstractMeasure}
    nv(p.g) <= selector.app_domain_size && return collect(1:nv(p.g))
    h = KaHyPar.HyperGraph(OptimalBranchingMIS.edge2vertex(p))
    imbalance = 1-2*selector.app_domain_size/nv(p.g)
    
    parts = KaHyPar.partition(h, 2; configuration = pkgdir(@__MODULE__, "src/ini", "cut_kKaHyPar_sea20.ini"), imbalance)

    zero_num = count(x-> x ≈ 0,parts)
    one_num = length(parts)-zero_num
    @debug "Selecting vertices by KaHyPar, sizes: $(zero_num), $(one_num)"
    
    return abs(zero_num-selector.app_domain_size) < abs(one_num-selector.app_domain_size) ? findall(iszero,parts) : findall(!iszero,parts)
end

# region selectors, max size is n_max and a vertex i is required to be in the region
function OptimalBranchingMIS.select_region_mincut(g::AbstractGraph, i::Int, n_max::Int)
    nv(g) <= n_max && return collect(1:nv(g))
    h = KaHyPar.HyperGraph(OptimalBranchingMIS.edge2vertex(g))
    
    fix_vs = [j == i ? 1 : -1 for j in 1:nv(g)]
    KaHyPar.fix_vertices(h, 2, fix_vs)
    KaHyPar.set_target_block_weights(h, [nv(g) - n_max, n_max])
    parts = KaHyPar.partition(h, 2; configuration = pkgdir(@__MODULE__, "src/ini", "cut_kKaHyPar_sea20.ini"))
    
    return findall(!iszero,parts)
end

end