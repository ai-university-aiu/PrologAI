% objcomp.pl - Layer 167: Object Connectivity and Component Analysis (oc_* prefix).
% Provides adjacency (4-touching) queries and connected-component analysis over
% collections of obj(Color, Cells) terms. Two objects "touch" when any cell of
% the first is 4-adjacent (Manhattan distance 1) to any cell of the second.
% Component queries use BFS through the touching relation. All predicates treat
% the input Objs list as the universe and produce results within that universe.
:- module(objcomp, [
    oc_touches/2,
    oc_touching_pairs/2,
    oc_adj_list/2,
    oc_degree/3,
    oc_isolated/2,
    oc_connected/3,
    oc_components/2,
    oc_num_components/2,
    oc_largest_component/2,
    oc_smallest_component/2,
    oc_singleton_components/2,
    oc_shared_components/2,
    oc_max_degree/2,
    oc_sort_by_degree/2
]).
% member/2, nth0/3, last/2, append/3, subtract/3, max_list/2 from library(lists).
:- use_module(library(lists), [member/2, nth0/3, last/2, append/3, subtract/3, max_list/2]).

% oc_touches(+Obj1, +Obj2): true if any cell of Obj1 is 4-adjacent to any cell
% of Obj2. Two distinct obj terms are touching if they share a cell boundary.
% Succeeds on the first found adjacent cell pair (cut in helper prevents backtracking).
oc_touches(obj(_, Cells1), obj(_, Cells2)) :-
% Check every cell-pair; cut on first success for efficiency.
    member(r(R1,C1), Cells1),
    member(r(R2,C2), Cells2),
    (R1 =:= R2, D is abs(C1-C2), D =:= 1 ;
     C1 =:= C2, D is abs(R1-R2), D =:= 1), !.

% oc_touching_pairs(+Objs, -Pairs): list of O1-O2 pairs where O1 and O2 are
% distinct elements of Objs and oc_touches(O1, O2) is true.
% Each unordered pair appears once: O1 has a lower index than O2 in Objs.
oc_touching_pairs(Objs, Pairs) :-
% Use nth0 indices to enforce I < J so each pair appears exactly once.
    findall(O1-O2,
            (nth0(I, Objs, O1),
             nth0(J, Objs, O2),
             I < J,
             oc_touches(O1, O2)),
            Pairs).

% oc_adj_list(+Objs, -AdjList): Obj-[Neighbors] pairs for every Obj in Objs.
% Neighbors are all other elements of Objs that touch Obj.
oc_adj_list(Objs, AdjList) :-
    findall(Obj-Nbrs,
            (member(Obj, Objs),
             findall(N, (member(N, Objs), N \== Obj, oc_touches(Obj, N)), Nbrs)),
            AdjList).

% oc_degree(+Obj, +Objs, -N): count of objects in Objs (excluding Obj itself)
% that 4-touch Obj.
oc_degree(Obj, Objs, N) :-
    findall(N_, (member(N_, Objs), N_ \== Obj, oc_touches(Obj, N_)), Touching),
    length(Touching, N).

% oc_isolated(+Objs, -Isolated): objects in Objs that do not touch any other
% object in Objs (degree = 0).
oc_isolated(Objs, Isolated) :-
    findall(Obj,
            (member(Obj, Objs),
             \+ (member(Other, Objs), Other \== Obj, oc_touches(Obj, Other))),
            Isolated).

% oc_connected(+Obj, +Objs, -Component): sorted list of objects reachable from
% Obj through the touching relation within Objs, including Obj itself.
% Uses BFS: expand the frontier one step at a time.
oc_connected(Obj, Objs, Component) :-
    oc_bfs_([Obj], Objs, [], Visited),
    sort(Visited, Component).

% oc_bfs_(+Queue, +Objs, +Visited, -AllVisited): BFS accumulator.
oc_bfs_([], _, Visited, Visited) :- !.
% Skip objects already visited.
oc_bfs_([H|T], Objs, Visited, AllVisited) :-
    (memberchk(H, Visited)
     -> oc_bfs_(T, Objs, Visited, AllVisited)
     ;  findall(N, (member(N, Objs), N \== H,
                    \+ memberchk(N, Visited),
                    oc_touches(H, N)),
                Neighbors),
        append(T, Neighbors, Queue),
        oc_bfs_(Queue, Objs, [H|Visited], AllVisited)).

% oc_components(+Objs, -Components): list of all touching-connected components.
% Each component is a sorted list of obj terms. Components are unordered.
oc_components(Objs, Components) :-
    oc_partition_(Objs, Components).

% oc_partition_/2: partition the list by extracting one component at a time.
oc_partition_([], []) :- !.
oc_partition_([H|T], [Comp|Rest]) :-
% Find the full component of H (within [H|T]).
    oc_connected(H, [H|T], Comp),
% Remove all component members from the remaining list.
    subtract([H|T], Comp, Remaining),
    oc_partition_(Remaining, Rest).

% oc_num_components(+Objs, -N): number of touching-connected components.
oc_num_components(Objs, N) :-
    oc_components(Objs, Components),
    length(Components, N).

% oc_largest_component(+Objs, -Component): the component with the most objects.
% When two components have equal size, the one that appears first in oc_components
% output is returned.
oc_largest_component(Objs, Component) :-
    oc_components(Objs, Components),
% Pair each component with its length.
    findall(N-C, (member(C, Components), length(C, N)), Pairs),
% Sort ascending; last pair has maximum length.
    msort(Pairs, Sorted),
    last(Sorted, _-Component).

% oc_smallest_component(+Objs, -Component): the component with the fewest objects.
oc_smallest_component(Objs, Component) :-
    oc_components(Objs, Components),
    findall(N-C, (member(C, Components), length(C, N)), Pairs),
    msort(Pairs, [_-Component|_]).

% oc_singleton_components(+Objs, -Singles): components containing exactly one object.
oc_singleton_components(Objs, Singles) :-
    oc_components(Objs, Components),
    findall(Comp, (member(Comp, Components), length(Comp, 1)), Singles).

% oc_shared_components(+Objs, -Groups): components containing two or more objects.
oc_shared_components(Objs, Groups) :-
    oc_components(Objs, Components),
    findall(Comp, (member(Comp, Components), length(Comp, N), N > 1), Groups).

% oc_max_degree(+Objs, -MaxDeg): the maximum touch degree of any object in Objs.
% Fails if Objs is empty.
oc_max_degree(Objs, MaxDeg) :-
    findall(D, (member(Obj, Objs), oc_degree(Obj, Objs, D)), Degs),
    Degs \= [],
    max_list(Degs, MaxDeg).

% oc_sort_by_degree(+Objs, -Sorted): Objs sorted in ascending order of touch degree.
% Equal-degree objects retain their original relative order (stable keysort).
oc_sort_by_degree(Objs, Sorted) :-
    findall(D-Obj, (member(Obj, Objs), oc_degree(Obj, Objs, D)), Pairs),
    keysort(Pairs, SortedPairs),
    findall(Obj, member(_-Obj, SortedPairs), Sorted).
