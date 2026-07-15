% topology.pl - Layer 130: Grid Topology and Connected Component Analysis (tp_* prefix).
% General-purpose predicates for flood fill, connected components,
% enclosed region detection, and topological classification of grid regions.
:- module(topology, [
    topology_component/4, topology_all_components/3,
    topology_component_count/3, topology_component_size/4,
    topology_largest_component/3, topology_reachable/5,
    topology_enclosed/4, topology_has_hole/4,
    topology_hole_count/4, topology_fill_holes/4,
    topology_border_components/3, topology_interior_components/3,
    topology_label_components/3, topology_same_component/5
]).
% Import list utilities for BFS queue and component set management.
:- use_module(library(lists), [member/2, memberchk/2, nth0/3, max_list/2,
                                append/3, subtract/3]).

% topology_component(+Grid, +Val, +Seed, -Cells): find all cells of value Val
% 4-connected to Seed. Returns sorted R-C pairs.
topology_component(Grid, Val, Seed, Cells) :-
% BFS flood fill from Seed; only step through cells with value Val.
    Seed = RS-CS,
    nth0(RS, Grid, SRow), nth0(CS, SRow, Val),
    topology_grow_(Grid, Val, [Seed], [], Acc),
    sort(Acc, Cells).

% topology_all_components(+Grid, +Val, -Components): all 4-connected components
% of Val in Grid. Returns a list of sorted R-C pair lists.
topology_all_components(Grid, Val, Components) :-
% Collect all Val cells then partition into connected components.
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(R-C, (
        between(0, H1, R), between(0, W1, C),
        nth0(R, Grid, Row), nth0(C, Row, Val)
    ), AllCells),
    sort(AllCells, Sorted),
    topology_split_cells_(Grid, Val, Sorted, Components).

% topology_component_count(+Grid, +Val, -N): count of 4-connected components.
topology_component_count(Grid, Val, N) :-
% Count components by measuring the resulting list.
    topology_all_components(Grid, Val, Comps),
    length(Comps, N).

% topology_component_size(+Grid, +Val, +Seed, -N): cell count of the 4-connected
% component of Val containing Seed.
topology_component_size(Grid, Val, Seed, N) :-
% Flood fill from Seed and count the result.
    topology_component(Grid, Val, Seed, Cells),
    length(Cells, N).

% topology_largest_component(+Grid, +Val, -Cells): cells of the largest
% 4-connected component of Val by cell count. On ties, returns the first.
topology_largest_component(Grid, Val, Cells) :-
% Tag each component with its size; pick the maximum.
    topology_all_components(Grid, Val, Comps),
    Comps \= [],
    findall(N-C, (member(C, Comps), length(C, N)), Tagged),
    topology_max_key_(Tagged, _-Cells).

% topology_reachable(+Grid, +Val, +Src, +Dst, -Bool): Bool=1 iff there exists a
% 4-connected path of Val cells from Src to Dst; Bool=0 otherwise.
topology_reachable(Grid, Val, Src, Dst, Bool) :-
% Flood fill from Src then test if Dst is in the visited set.
    Src = RS-CS,
    nth0(RS, Grid, SRow), nth0(CS, SRow, Val),
    topology_grow_(Grid, Val, [Src], [], Acc),
    (memberchk(Dst, Acc) -> Bool = 1 ; Bool = 0).

% topology_enclosed(+Grid, +_Val, +Bg, -Cells): Bg cells that are completely
% enclosed (cannot reach the grid border via 4-connected Bg cells).
% Val is the enclosing color; it is accepted but not needed for the BFS.
topology_enclosed(Grid, _Val, Bg, Enclosed) :-
% Flood fill from all border Bg cells through Bg; enclosed = unreachable Bg.
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(R-C, (
        between(0, H1, R), between(0, W1, C),
        (R =:= 0 ; R =:= H1 ; C =:= 0 ; C =:= W1),
        nth0(R, Grid, Row), nth0(C, Row, Bg)
    ), BorderBg),
    topology_grow_(Grid, Bg, BorderBg, [], Reachable),
    findall(R-C, (
        between(0, H1, R), between(0, W1, C),
        nth0(R, Grid, Row), nth0(C, Row, Bg),
        \+ memberchk(R-C, Reachable)
    ), Unsorted),
    sort(Unsorted, Enclosed).

% topology_has_hole(+Grid, +Val, +Bg, -Bool): Bool=1 iff Val encloses at least
% one Bg region; Bool=0 otherwise. Val is passed through to topology_enclosed.
topology_has_hole(Grid, Val, Bg, Bool) :-
% Check whether the enclosed set is non-empty.
    topology_enclosed(Grid, Val, Bg, Enclosed),
    (Enclosed \= [] -> Bool = 1 ; Bool = 0).

% topology_hole_count(+Grid, +Val, +Bg, -N): count of distinct enclosed Bg
% components (holes).
topology_hole_count(Grid, Val, Bg, N) :-
% Partition enclosed Bg cells into 4-connected groups and count.
    topology_enclosed(Grid, Val, Bg, Enclosed),
    topology_split_cells_plain_(Enclosed, Comps),
    length(Comps, N).

% topology_fill_holes(+Grid, +Val, +Bg, -Grid2): replace all enclosed Bg cells
% with Val, leaving all other cells unchanged.
topology_fill_holes(Grid, Val, Bg, Grid2) :-
% Find enclosed Bg cells then substitute them in a new grid.
    topology_enclosed(Grid, Val, Bg, Enclosed),
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(Row2, (
        between(0, H1, R),
        findall(V2, (
            between(0, W1, C),
            nth0(R, Grid, Row), nth0(C, Row, V),
            (memberchk(R-C, Enclosed) -> V2 = Val ; V2 = V)
        ), Row2)
    ), Grid2).

% topology_border_components(+Grid, +Val, -Components): components of Val that
% have at least one cell touching the outer grid border.
topology_border_components(Grid, Val, Components) :-
% Collect all components; keep those with at least one border cell.
    topology_all_components(Grid, Val, All),
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(C, (
        member(C, All),
        once((member(R-CC, C),
              (R =:= 0 ; R =:= H1 ; CC =:= 0 ; CC =:= W1)))
    ), Components).

% topology_interior_components(+Grid, +Val, -Components): components of Val that
% have NO cell on the outer grid border.
topology_interior_components(Grid, Val, Components) :-
% Collect all components; keep those with no border cell.
    topology_all_components(Grid, Val, All),
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(C, (
        member(C, All),
        \+ (member(R-CC, C),
            (R =:= 0 ; R =:= H1 ; CC =:= 0 ; CC =:= W1))
    ), Components).

% topology_label_components(+Grid, +Val, -LabelGrid): produce a same-size grid
% where each Val cell is replaced by its 1-based component index and all
% non-Val cells become 0.
topology_label_components(Grid, Val, LabelGrid) :-
% Build a label lookup from components then apply to each cell position.
    topology_all_components(Grid, Val, Comps),
    topology_build_label_map_(Comps, 1, LabelMap),
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(RowL, (
        between(0, H1, R),
        findall(Label, (
            between(0, W1, C),
            (member(R-C-Label, LabelMap) -> true ; Label = 0)
        ), RowL)
    ), LabelGrid).

% topology_same_component(+Grid, +Val, +P1, +P2, -Bool): Bool=1 iff P1 and P2
% are cells in the same 4-connected component of Val.
topology_same_component(Grid, Val, P1, P2, Bool) :-
% Flood fill from P1 and check if P2 is reached.
    topology_reachable(Grid, Val, P1, P2, Bool).

% Private: BFS flood fill through Val cells.
% topology_grow_(+Grid, +Val, +Queue, +Visited, -Result).
topology_grow_(_, _, [], Acc, Acc).
topology_grow_(Grid, Val, [H|T], Acc, Result) :-
    (memberchk(H, Acc) ->
% Cell already visited: skip and continue.
        topology_grow_(Grid, Val, T, Acc, Result)
    ;
% New cell: find in-bounds Val-valued 4-neighbors, add to queue.
        H = R-C,
        length(Grid, Height), TH is Height - 1,
        (Grid = [Fr|_] -> length(Fr, Width) ; Width = 0), TW is Width - 1,
        findall(R2-C2, topology_val_nbr_(Grid, R, C, Val, TH, TW, R2-C2), Nbrs),
        append(Nbrs, T, Q1),
        topology_grow_(Grid, Val, Q1, [H|Acc], Result)
    ).

% Private: one valid 4-connected in-bounds Val-valued neighbor.
topology_val_nbr_(Grid, R, C, Val, H1, W1, NR-NC) :-
    (NR is R-1, NR >= 0, NC = C
    ; NR is R+1, NR =< H1, NC = C
    ; NR = R, NC is C-1, NC >= 0
    ; NR = R, NC is C+1, NC =< W1
    ),
    nth0(NR, Grid, NRow), nth0(NC, NRow, Val).

% Private: BFS flood fill within a restricted set of cells (no Grid/Val).
topology_grow_plain_(_, [], Acc, Acc).
topology_grow_plain_(Allowed, [H|T], Acc, Result) :-
    (memberchk(H, Acc) ->
        topology_grow_plain_(Allowed, T, Acc, Result)
    ;
        H = R-C,
        findall(R2-C2, (
            (R2 is R-1, C2 = C ; R2 is R+1, C2 = C ;
             R2 = R, C2 is C-1 ; R2 = R, C2 is C+1),
            memberchk(R2-C2, Allowed)
        ), Nbrs),
        append(Nbrs, T, Q1),
        topology_grow_plain_(Allowed, Q1, [H|Acc], Result)
    ).

% Private: partition a list of R-C pairs into 4-connected groups.
% topology_split_cells_(+Grid, +Val, +AllCells, -Components) uses Grid/Val BFS.
topology_split_cells_(_, _, [], []).
topology_split_cells_(Grid, Val, AllCells, [Comp|Rest]) :-
    AllCells = [Seed|_],
    topology_grow_(Grid, Val, [Seed], [], Acc),
    sort(Acc, Comp),
    subtract(AllCells, Comp, Remaining),
    topology_split_cells_(Grid, Val, Remaining, Rest).

% Private: partition a plain cell list into 4-connected groups.
topology_split_cells_plain_([], []).
topology_split_cells_plain_(All, [Comp|Rest]) :-
    All = [Seed|_],
    topology_grow_plain_(All, [Seed], [], Acc),
    sort(Acc, Comp),
    subtract(All, Comp, Remaining),
    topology_split_cells_plain_(Remaining, Rest).

% Private: find element with the largest first key in a N-Cells list.
topology_max_key_([H], H).
topology_max_key_([H|T], Max) :-
    topology_max_key_(T, BestT),
    (H @> BestT -> Max = H ; Max = BestT).

% Private: build R-C-Label triples for each component with sequential labels.
topology_build_label_map_([], _, []).
topology_build_label_map_([Comp|Rest], N, Map) :-
    findall(R-C-N, member(R-C, Comp), Entries),
    N1 is N + 1,
    topology_build_label_map_(Rest, N1, RestMap),
    append(Entries, RestMap, Map).
