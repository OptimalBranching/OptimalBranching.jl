function counting_mis1(eg::EliminateGraph)
    N = nv(eg)
    if N == 0
        return MISCount(0)
    else
        vmin, dmin = mindegree_vertex(eg)
        return 1 + neighborcover_mapreduce(y->eliminate(counting_mis1, eg, NeighborCover(y)), max, eg, vmin)
    end
end

counting_mis1(g::SimpleGraph) = counting_mis1(EliminateGraph(g))