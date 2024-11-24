using EliminateGraphs: adjacent45

function counting_mis2(eg::EliminateGraph)
    if nv(eg) == 0
        #@show "0" # CHECKED
        return MISCount(0)
    elseif nv(eg) == 1
        return MISCount(1)
    elseif nv(eg) == 2
        return MISCount(2 - (@inbounds isconnected(eg, eg.vertices[end-1], eg.vertices[end])))
    elseif nv(eg) == 3
        @inbounds a, b, c = eg.vertices[end-2:end]
        nedge = isconnected(eg, a, b) + isconnected(eg, a, c) + isconnected(eg, b, c)
        if nedge == 0
            return MISCount(3)
        elseif nedge == 3
            return MISCount(1)
        else
            return MISCount(2)
        end
    else
        #@show "1" # CHECKED
        vmin, degmin = mindegree_vertex(eg)
        if degmin == 0  # DONE
            #@show "1.1(1)" # CHECKED
            return 1 + eliminate(counting_mis2, eg, vmin)
        elseif degmin == 1  # DONE
            #@show "1.1(2)" # CHECKED
            return 1 + eliminate(counting_mis2, eg, NeighborCover(vmin))
        elseif degmin == 2
            #@show "1.2" # CHECKED
            a, b = neighbors(eg, vmin)
            if isconnected(eg, a, b)
                #@show "1.2.1" # CHECKED
                return 1 + eliminate(counting_mis2, eg, NeighborCover(vmin))
            else
                #@show "1.2.2" # CHECKED
                sn = neighbors2(eg, vmin)
                # NOTE: there is no degree one vertex!
                if length(sn) == 1
                    #@show "1.2.2.1" # CHECKED
                    w = sn[1]
                    #return max(2+eliminate(counting_mis2, eg, NeighborCover(w) ∪ Neighbors{CLOSED,2}(vmin)),
                                #2+eliminate(counting_mis2, eg, Neighbors{CLOSED,2}(vmin)),
                    # Note: it seems it must choose the latter. Gurantted if one removes one vertex, the MIS is non-increasing.
                    return 2+eliminate(counting_mis2, eg, (vmin, w, a, b)
                    )
                else
                    #@show "1.2.2.2" # CHECKED
                    return max(1+eliminate(counting_mis2, eg, NeighborCover(vmin)),
                                eliminate(counting_mis2, eg, MirrorCover(vmin)))
                end
            end
        elseif degmin == 3 # DONE
            #@show "1.3" #CHECKED
            a, b, c = neighbors(eg, vmin)
            nedge = isconnected(eg, a, b) + isconnected(eg, a, c) + isconnected(eg, b, c)
            if nedge == 0
                #@show "1.3.1" #CHECKED
                ms = mirrorcover(eg, vmin)
                if length(ms) > 1
                    #@show "1.3.1.1" # CHECKED
                    return max(1+eliminate(counting_mis2, eg, NeighborCover(vmin)),
                                eliminate(counting_mis2, eg, ms))
                else
                    #@show "1.3.1.2" # CHECKED
                    return max(1+eliminate(counting_mis2, eg, NeighborCover(vmin)),
                                2 + eliminate(counting_mis2, eg, NeighborCover(a) ∪ NeighborCover(b)),
                                2 + eliminate(counting_mis2, eg, NeighborCover(a) ∪ NeighborCover(c) ∪ Vertex(b)),
                                2 + eliminate(counting_mis2, eg, NeighborCover(b) ∪ NeighborCover(c) ∪ Vertex(a)),
                                )
                end
            elseif nedge == 3
                #@show "1.3.2" # CHECKED
                return 1 + eliminate(counting_mis2, eg, NeighborCover(vmin))
            else
                #@show "1.3.3" # CHECKED
                return max(1 + eliminate(counting_mis2, eg, NeighborCover(vmin)),
                            eliminate(counting_mis2, eg, MirrorCover(vmin)))
            end
        else # DONE
            #@show "1.4" # CHECKED
            vmax, degmax = maxdegree_vertex(eg)
            if degmax >= 6 # DONE
                #@show "1.4.1"
                return max(1+eliminate(counting_mis2, eg, NeighborCover(vmax)),
                            eliminate(counting_mis2, eg, vmax))
            elseif !isconnected(eg) # DONE
                #@show "1.4.2" # CHECKED
                cluster = find_cluster(eg, vmax)
                A = subgraph(eg, cluster)
                B = subgraph(eg, setdiff(vertices(eg), cluster))
                return counting_mis2(A) + counting_mis2(B)
            elseif degmin == degmax  # DONE
                #@show "1.4.3" # CHECKED
                return max(1+eliminate(counting_mis2, eg, NeighborCover(vmax)),
                            eliminate(counting_mis2, eg, MirrorCover(vmax)))
            else
                #@show "1.4.4" # CHECKED
                v4, v5 = adjacent45(eg)
                return max(1+eliminate(counting_mis2, eg, NeighborCover(v5)),
                            1+eliminate(counting_mis2, eg, MirrorCover(v5) ∪ NeighborCover(v4)),
                            eliminate(counting_mis2, eg, MirrorCover(v5) ∪ Vertex(v4))
                            )
            end
        end
    end
end

"""
    counting_mis2(g::SimpleGraph)

Calculates the size of the maximum independent set and the count of branches for a given `SimpleGraph`.
"""
counting_mis2(g::SimpleGraph) = counting_mis2(EliminateGraph(g))