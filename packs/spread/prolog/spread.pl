% spread.pl - Layer 105: BFS Spreading, Distance Maps, and Reachability (sd_* prefix).
% Provides single-source and multi-source Breadth-First Search (BFS) distance
% computation, reachability queries, ring and zone filtering, Voronoi-style
% cell assignment, color spreading, distance map overlay, and one-step BFS
% expansion over 2D integer-coordinate grids with a background color.
:- module(spread, [
    sd_dist_map/5,
    sd_dist_multi/4,
    sd_reachable/5,
    sd_path_dist/7,
    sd_path_exists/6,
    sd_ring/6,
    sd_zone/6,
    sd_dist_to_set/6,
    sd_farthest/5,
    sd_expand_once/5,
    sd_spread_color/5,
    sd_max_dist/5,
    sd_fill_dist/5,
    sd_voronoi/4
]).
% Import list utilities for membership, indexing, range, and aggregates.
:- use_module(library(lists), [member/2, nth0/3, numlist/3, append/2, append/3, max_list/2, min_list/2]).
% Import higher-order utilities.
:- use_module(library(apply), [maplist/3, maplist/4, include/3]).

% sd_dims_: get the row and column count of a grid.
sd_dims_(Grid, NR, NC) :-
% Count rows.
    length(Grid, NR),
% Get column count from the first row when grid is non-empty.
    (NR > 0 -> Grid = [FR|_], length(FR, NC) ; NC = 0).

% sd_cell_val_: retrieve the grid value at a cell coordinate R-C.
sd_cell_val_(Grid, R-C, V) :-
    nth0(R, Grid, Row),
    nth0(C, Row, V).

% sd_4candidates_: in-bounds 4-adjacent cells of (R,C) in a NR x NC grid.
sd_4candidates_(R, C, NR, NC, Nbrs) :-
% Collect all in-bounds orthogonal neighbors using findall.
    findall(NbR-NbC, (
        member(DR-DC, [-1-0, 1-0, 0-1, 0-(-1)]),
        NbR is R + DR, NbC is C + DC,
        0 =< NbR, NbR < NR, 0 =< NbC, NbC < NC
    ), Nbrs).

% sd_bg4unvis_: in-bounds Bg 4-neighbors of (R,C) not already in Vis.
sd_bg4unvis_(R, C, NR, NC, Grid, Bg, Vis, Nbrs) :-
% Get all candidate 4-neighbors.
    sd_4candidates_(R, C, NR, NC, Cands),
% Keep only those that are background color and not yet visited.
    include([N]>>(
        N = NbR-NbC,
        nth0(NbR, Grid, Row), nth0(NbC, Row, Val),
        Val =:= Bg,
        \+ member(N, Vis)
    ), Cands, Nbrs).

% sd_make_bfs1_: create a single-source BFS queue entry.
sd_make_bfs1_(D, Cell, bfs1(Cell, D)).

% sd_bfs_single_: BFS loop for single (or multi) source distance computation.
% Queue: list of bfs1(Cell, D) entries; Vis: visited cells list.
% Acc accumulates Cell-D pairs; Result is the final accumulated list.
sd_bfs_single_([], _, _, _, _, _, Acc, Acc) :- !.
sd_bfs_single_([bfs1(Cell, D)|Rest], Grid, Bg, NR, NC, Vis0, Acc0, Result) :-
% Unpack the current cell.
    Cell = CR-CC,
% Find unvisited Bg 4-neighbors.
    sd_bg4unvis_(CR, CC, NR, NC, Grid, Bg, Vis0, Nbrs),
% Distance to neighbors is D+1.
    D1 is D + 1,
% Build queue entries for neighbors.
    maplist(sd_make_bfs1_(D1), Nbrs, Tagged),
% Add neighbors to the end of the queue (FIFO BFS).
    append(Rest, Tagged, Queue1),
% Mark all new neighbors as visited.
    append(Vis0, Nbrs, Vis1),
% Record the current cell with its distance.
    sd_bfs_single_(Queue1, Grid, Bg, NR, NC, Vis1, [Cell-D|Acc0], Result).

% sd_dist_map(+Grid, +R, +C, +Bg, -DistMap): BFS from (R,C) through cells with
% value Bg. DistMap is a list of Cell-D pairs giving BFS distance D from (R,C)
% to every reachable Bg cell (including (R,C) itself at D=0). Returns [] if
% (R,C) does not have value Bg.
sd_dist_map(Grid, R, C, Bg, DistMap) :-
    sd_cell_val_(Grid, R-C, Val),
    (Val =:= Bg ->
% Source is background: start BFS.
        sd_dims_(Grid, NR, NC),
        sd_bfs_single_([bfs1(R-C, 0)], Grid, Bg, NR, NC, [R-C], [], DistMap)
    ;
% Source is not background: no reachable cells.
        DistMap = []
    ).

% sd_dist_multi(+Grid, +Seeds, +Bg, -DistMap): multi-source BFS from all Seed
% cells simultaneously. DistMap gives the minimum BFS distance from any seed to
% every reachable Bg cell. Seeds is a list of R-C cell coordinates.
sd_dist_multi(Grid, Seeds, Bg, DistMap) :-
    sd_dims_(Grid, NR, NC),
% Filter seeds to those that are actually Bg.
    include([S]>>(sd_cell_val_(Grid, S, V), V =:= Bg), Seeds, BgSeeds),
% Build initial queue entries (all seeds at distance 0).
    maplist(sd_make_bfs1_(0), BgSeeds, InitQueue),
% Run BFS starting with all seeds as visited.
    sd_bfs_single_(InitQueue, Grid, Bg, NR, NC, BgSeeds, [], DistMap).

% sd_reachable(+Grid, +R, +C, +Bg, -Cells): all Bg cells reachable from (R,C)
% by 4-connected steps through Bg cells. Returns the sorted list of R-C cells.
sd_reachable(Grid, R, C, Bg, Cells) :-
    sd_dist_map(Grid, R, C, Bg, DistMap),
% Extract just the cell coordinates from the distance map.
    maplist([Pair, Cell]>>(Pair = Cell-_), DistMap, CellsUnsorted),
    sort(CellsUnsorted, Cells).

% sd_path_dist(+Grid, +R1, +C1, +R2, +C2, +Bg, -D): BFS shortest path distance
% from (R1,C1) to (R2,C2) through Bg cells. Fails if (R2,C2) is unreachable.
sd_path_dist(Grid, R1, C1, R2, C2, Bg, D) :-
    sd_dist_map(Grid, R1, C1, Bg, DistMap),
    member((R2-C2)-D, DistMap), !.

% sd_path_exists(+Grid, +R1, +C1, +R2, +C2, +Bg): succeed if (R2,C2) is
% reachable from (R1,C1) via 4-connected steps through Bg cells.
sd_path_exists(Grid, R1, C1, R2, C2, Bg) :-
    sd_path_dist(Grid, R1, C1, R2, C2, Bg, _).

% sd_ring(+Grid, +R, +C, +Bg, +D, -Cells): all Bg cells at exactly BFS distance
% D from (R,C). Cells is a sorted list.
sd_ring(Grid, R, C, Bg, D, Cells) :-
    sd_dist_map(Grid, R, C, Bg, DistMap),
% Filter to cells with distance exactly D.
    include([Pair]>>(Pair = _-PD, PD =:= D), DistMap, Filtered),
% Extract cell coordinates and sort.
    maplist([Pair, Cell]>>(Pair = Cell-_), Filtered, CellsUnsorted),
    sort(CellsUnsorted, Cells).

% sd_zone(+Grid, +R, +C, +Bg, +MaxD, -Cells): all Bg cells at BFS distance at
% most MaxD from (R,C). Cells is a sorted list.
sd_zone(Grid, R, C, Bg, MaxD, Cells) :-
    sd_dist_map(Grid, R, C, Bg, DistMap),
% Filter to cells within MaxD.
    include([Pair]>>(Pair = _-PD, PD =< MaxD), DistMap, Filtered),
% Extract cell coordinates and sort.
    maplist([Pair, Cell]>>(Pair = Cell-_), Filtered, CellsUnsorted),
    sort(CellsUnsorted, Cells).

% sd_dist_to_set(+Grid, +R, +C, +Targets, +Bg, -D): minimum BFS distance from
% (R,C) to any cell in Targets through Bg cells. Fails if no target is reachable.
sd_dist_to_set(Grid, R, C, Targets, Bg, D) :-
    sd_dist_map(Grid, R, C, Bg, DistMap),
% Collect all distances to target cells.
    findall(TD, (member(T, Targets), member(T-TD, DistMap)), Dists),
    Dists \= [],
    min_list(Dists, D).

% sd_farthest(+Grid, +R, +C, +Bg, -Cell): the Bg cell farthest from (R,C) by
% BFS distance. If multiple cells share the maximum distance the first in BFS
% order is returned.
sd_farthest(Grid, R, C, Bg, Cell) :-
    sd_dist_map(Grid, R, C, Bg, DistMap),
    DistMap \= [],
% Extract all distances.
    maplist([Pair, D]>>(Pair = _-D), DistMap, Dists),
    max_list(Dists, MaxD),
% Find the first cell with that maximum distance.
    member(Cell-MaxD, DistMap), !.

% sd_expand_once(+Grid, +Frontier, +Visited, +Bg, -NextFrontier): one BFS
% expansion step. Frontier is a list of R-C cells representing the current BFS
% level. Returns all unvisited Bg 4-neighbors of any Frontier cell, deduplicated.
sd_expand_once(Grid, Frontier, Visited, Bg, NextFrontier) :-
    sd_dims_(Grid, NR, NC),
% Collect all candidate neighbors from all frontier cells.
    findall(N, (
        member(CR-CC, Frontier),
        member(DR-DC, [-1-0, 1-0, 0-1, 0-(-1)]),
        NbR is CR + DR, NbC is CC + DC,
        0 =< NbR, NbR < NR, 0 =< NbC, NbC < NC,
        N = NbR-NbC,
        nth0(NbR, Grid, Row), nth0(NbC, Row, Val), Val =:= Bg,
        \+ member(N, Visited),
        \+ member(N, Frontier)
    ), AllNbrs),
% Deduplicate while preserving a canonical order.
    sort(AllNbrs, NextFrontier).

% sd_color_cells_: find all cells with a given value in a grid.
sd_color_cells_(Grid, Color, Cells) :-
    sd_dims_(Grid, NR, NC),
% Compute inclusive upper bounds for between/3.
    NR1 is NR - 1,
    NC1 is NC - 1,
    findall(R-C, (
        between(0, NR1, R), between(0, NC1, C),
        nth0(R, Grid, Row), nth0(C, Row, V), V =:= Color
    ), Cells).

% sd_set_grid_cell_: replace the value at (R,C) in Grid with Val.
sd_set_grid_cell_(Grid, R, C, Val, NewGrid) :-
% Remove and re-insert the target row.
    nth0(R, Grid, OldRow, RestRows),
% Remove and re-insert the target column within that row.
    nth0(C, OldRow, _, RestCols),
    nth0(C, NewRow, Val, RestCols),
% Reconstruct the grid with the modified row.
    nth0(R, NewGrid, NewRow, RestRows).

% sd_apply_vals_: set all cells in a list to Val in Grid.
sd_apply_vals_(Grid, [], _, Grid) :- !.
sd_apply_vals_(Grid0, [CR-CC|Rest], Val, Out) :-
    sd_set_grid_cell_(Grid0, CR, CC, Val, Grid1),
    sd_apply_vals_(Grid1, Rest, Val, Out).

% sd_spread_color(+Grid, +Color, +Bg, +MaxD, -Out): spread Color cells outward
% through Bg cells up to MaxD BFS steps. The output grid has all Bg cells
% within MaxD of any Color cell set to Color; other cells are unchanged.
sd_spread_color(Grid, Color, Bg, MaxD, Out) :-
% Find all Color cells as the BFS seeds.
    sd_color_cells_(Grid, Color, Seeds),
    (Seeds = [] ->
% No seeds: output equals input.
        Out = Grid
    ;
% Run BFS directly from Color seeds without Bg filtering (seeds are non-Bg).
        sd_dims_(Grid, NR, NC),
        maplist(sd_make_bfs1_(0), Seeds, InitQueue),
% Vis initialised to Seeds so they are never revisited as Bg neighbors.
        sd_bfs_single_(InitQueue, Grid, Bg, NR, NC, Seeds, [], RawMap),
% Keep only newly reached Bg cells (D > 0 excludes the Color seeds at dist 0).
        include([Pair]>>(Pair = _-D, D =< MaxD, D > 0), RawMap, InRange),
% Extract just the cell coordinates.
        maplist([Pair, Cell]>>(Pair = Cell-_), InRange, ToColor),
% Paint those cells with Color.
        sd_apply_vals_(Grid, ToColor, Color, Out)
    ).

% sd_max_dist(+Grid, +R, +C, +Bg, -MaxD): the maximum BFS distance from (R,C)
% to any reachable Bg cell. Returns 0 when (R,C) is the only reachable cell.
sd_max_dist(Grid, R, C, Bg, MaxD) :-
    sd_dist_map(Grid, R, C, Bg, DistMap),
    DistMap \= [],
    maplist([Pair, D]>>(Pair = _-D), DistMap, Dists),
    max_list(Dists, MaxD).

% sd_apply_dist_map_: set each cell in DistMap to its BFS distance value.
sd_apply_dist_map_(Grid, [], Grid) :- !.
sd_apply_dist_map_(Grid0, [Cell-D|Rest], Out) :-
    Cell = CR-CC,
    sd_set_grid_cell_(Grid0, CR, CC, D, Grid1),
    sd_apply_dist_map_(Grid1, Rest, Out).

% sd_fill_dist(+Grid, +R, +C, +Bg, -Out): overlay BFS distances onto the grid.
% Each reachable Bg cell is set to its BFS distance from (R,C); all other cells
% retain their original values. Unreachable Bg cells and non-Bg cells are
% unchanged.
sd_fill_dist(Grid, R, C, Bg, Out) :-
    sd_dist_map(Grid, R, C, Bg, DistMap),
    sd_apply_dist_map_(Grid, DistMap, Out).

% sd_make_bfs2_: create a Voronoi BFS queue entry with seed index.
sd_make_bfs2_(D, Seed, Cell, bfs2(Cell, D, Seed)).

% sd_bfs_voronoi_: BFS loop tracking which seed first discovered each cell.
% Queue entries: bfs2(Cell, D, SeedIdx). Result: list of Cell-SeedIdx pairs.
sd_bfs_voronoi_([], _, _, _, _, _, Acc, Acc) :- !.
sd_bfs_voronoi_([bfs2(Cell, D, Seed)|Rest], Grid, Bg, NR, NC, Vis0, Acc0, Result) :-
    Cell = CR-CC,
    sd_bg4unvis_(CR, CC, NR, NC, Grid, Bg, Vis0, Nbrs),
    D1 is D + 1,
    maplist(sd_make_bfs2_(D1, Seed), Nbrs, Tagged),
    append(Rest, Tagged, Queue1),
    append(Vis0, Nbrs, Vis1),
    sd_bfs_voronoi_(Queue1, Grid, Bg, NR, NC, Vis1, [Cell-Seed|Acc0], Result).

% sd_voronoi(+Grid, +Seeds, +Bg, -Assignment): Voronoi assignment of Bg cells to
% the nearest seed. Seeds is a list of R-C cells; each is assigned a 1-based
% index. Assignment is a list of Cell-SeedIdx pairs. Ties broken by seed index
% order (lower index wins). Only Bg cells reachable from at least one seed are
% included.
sd_voronoi(Grid, Seeds, Bg, Assignment) :-
    sd_dims_(Grid, NR, NC),
% Filter seeds to Bg cells only.
    include([S]>>(sd_cell_val_(Grid, S, V), V =:= Bg), Seeds, BgSeeds),
% Assign 1-based indices to the Bg seeds.
    length(BgSeeds, NSeed),
    (NSeed > 0 -> numlist(1, NSeed, Idxs) ; Idxs = []),
% Build initial queue: each seed at distance 0 with its index.
    maplist([Seed, Idx, bfs2(Seed, 0, Idx)]>>true, BgSeeds, Idxs, InitQueue),
% Run BFS with seed tracking.
    sd_bfs_voronoi_(InitQueue, Grid, Bg, NR, NC, BgSeeds, [], Assignment).
