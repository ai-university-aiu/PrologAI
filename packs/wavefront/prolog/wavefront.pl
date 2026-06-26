% wavefront.pl - Layer 168: Wavefront BFS Propagation Through Passable Cells (wf_* prefix).
% General-purpose predicates for BFS wavefronts: spreading from seed cells through
% cells matching a passable color, tracking exact wave distances, painting distance
% maps, multi-source competition, collision zones, and enclosed-region detection.
% Differs from the voronoi pack (Manhattan distance in open space) by using actual
% BFS path length, which correctly handles obstacles and non-rectangular regions.
:- module(wavefront, [
    wf_passable/3,
    wf_bfs/4,
    wf_reachable/4,
    wf_unreachable/4,
    wf_at_dist/3,
    wf_within_dist/3,
    wf_dist_of/3,
    wf_max_dist/2,
    wf_all_dists/2,
    wf_path_exists/4,
    wf_paint_bg/5,
    wf_multi_wave/4,
    wf_collision/4,
    wf_enclosed/3
]).
% member/2, nth0/3, append/3, subtract/3, max_list/2 from library(lists).
:- use_module(library(lists), [member/2, nth0/3, append/3, subtract/3, max_list/2]).

% wf_4adj_(+R, +C, -NR, -NC): enumerate four orthogonal neighbors of r(R,C).
% Used internally by wf_bfs_ to expand the wavefront one cell at a time.
wf_4adj_(R, C, NR, C)  :- NR is R - 1.
% Step downward by one row.
wf_4adj_(R, C, NR, C)  :- NR is R + 1.
% Step left by one column.
wf_4adj_(R, C, R,  NC) :- NC is C - 1.
% Step right by one column.
wf_4adj_(R, C, R,  NC) :- NC is C + 1.

% wf_passable(+Grid, +PassColor, -Cells): sorted list of all r(R,C) positions in
% Grid whose value equals PassColor. These are the cells the wavefront can traverse.
wf_passable(Grid, PassColor, Cells) :-
% Collect every grid position where the stored value matches PassColor.
    findall(r(R,C),
            (nth0(R, Grid, Row), nth0(C, Row, PassColor)),
            Raw),
% Sort to canonical order and remove any accidental duplicates.
    sort(Raw, Cells).

% wf_bfs_(+Queue, +Grid, +PassColor, +Enqueued, +Acc, -DistPairs): BFS worker.
% Queue: list of D-r(R,C) entries waiting to be processed.
% Enqueued: set of r(R,C) cells already queued (prevents re-insertion).
% Acc: accumulator of D-r(R,C) results processed so far.
% DistPairs: final result, msort-ed by distance then cell.
wf_bfs_([], _, _, _, Acc, Sorted) :-
% Base case: queue exhausted; sort accumulator by distance for the caller.
    msort(Acc, Sorted).
% Recursive case: dequeue one cell, expand to unvisited PassColor neighbors.
wf_bfs_([D-r(R,C)|Queue], Grid, PassColor, Enqueued, Acc, DistPairs) :-
% Distance for newly discovered neighbors is one step further.
    D1 is D + 1,
% Find all four-adjacent cells that are PassColor and not yet enqueued.
    findall(r(NR,NC),
            (wf_4adj_(R, C, NR, NC),
             nth0(NR, Grid, NRow),
             nth0(NC, NRow, PassColor),
             \+ memberchk(r(NR,NC), Enqueued)),
            Neighbors),
% Pair each new neighbor with its distance D1.
    findall(D1-N, member(N, Neighbors), NewEntries),
% Append new entries to the end of the queue (BFS ordering).
    append(Queue, NewEntries, NewQueue),
% Mark all new neighbors as enqueued so they are not added again.
    append(Neighbors, Enqueued, NewEnqueued),
% Recurse with current cell added to the result accumulator.
    wf_bfs_(NewQueue, Grid, PassColor, NewEnqueued, [D-r(R,C)|Acc], DistPairs).

% wf_bfs(+Grid, +Seeds, +PassColor, -DistPairs): BFS from all Seeds through
% PassColor cells. Seeds appear at distance 0 regardless of their own color.
% PassColor neighbors of seeds appear at distance 1, and so on.
% DistPairs is a sorted list of D-r(R,C) terms (ascending D, then cell order).
wf_bfs(Grid, Seeds, PassColor, DistPairs) :-
% Build the initial queue: every seed enters at distance 0.
    findall(0-S, member(S, Seeds), InitQueue),
% Pre-populate Enqueued with all seeds so they are never re-inserted.
    sort(Seeds, Enqueued),
% Run BFS; the accumulator starts empty.
    wf_bfs_(InitQueue, Grid, PassColor, Enqueued, [], DistPairs).

% wf_reachable(+Grid, +Seeds, +PassColor, -Cells): sorted list of all cells
% (seeds and PassColor cells) that appear in the BFS distance map.
wf_reachable(Grid, Seeds, PassColor, Cells) :-
% Run BFS to get the full distance map.
    wf_bfs(Grid, Seeds, PassColor, DP),
% Extract just the cell terms from the distance-cell pairs.
    findall(Cell, member(_-Cell, DP), Raw),
% Sort for canonical ordering and duplicate removal.
    sort(Raw, Cells).

% wf_unreachable(+Grid, +Seeds, +PassColor, -Cells): sorted list of PassColor cells
% that are NOT reachable from Seeds (isolated passable pockets with no BFS path).
wf_unreachable(Grid, Seeds, PassColor, Cells) :-
% Collect all cells whose value equals PassColor.
    wf_passable(Grid, PassColor, All),
% Collect all cells that the BFS reached.
    wf_reachable(Grid, Seeds, PassColor, Reached),
% Cells in All but not in Reached are unreachable PassColor cells.
    subtract(All, Reached, Cells).

% wf_at_dist(+DistPairs, +D, -Cells): sorted list of cells at exactly distance D.
wf_at_dist(DistPairs, D, Cells) :-
% Filter DistPairs to entries matching the given distance D exactly.
    findall(Cell, member(D-Cell, DistPairs), Raw),
% Sort for canonical ordering.
    sort(Raw, Cells).

% wf_within_dist(+DistPairs, +MaxD, -Cells): sorted list of cells at distance <= MaxD.
wf_within_dist(DistPairs, MaxD, Cells) :-
% Filter DistPairs to entries whose distance does not exceed MaxD.
    findall(Cell, (member(D-Cell, DistPairs), D =< MaxD), Raw),
% Sort for canonical ordering and duplicate removal.
    sort(Raw, Cells).

% wf_dist_of(+DistPairs, +Cell, -D): distance D of Cell in DistPairs.
% Fails if Cell does not appear in DistPairs (not reachable).
wf_dist_of(DistPairs, Cell, D) :-
% Search for the unique D-Cell pair; memberchk stops at first match.
    memberchk(D-Cell, DistPairs).

% wf_max_dist(+DistPairs, -MaxD): maximum wave distance present in DistPairs.
% Fails if DistPairs is empty.
wf_max_dist(DistPairs, MaxD) :-
% Collect all distance values from the pairs.
    findall(D, member(D-_, DistPairs), Ds),
% Ds is non-empty because DistPairs is non-empty; take the maximum.
    max_list(Ds, MaxD).

% wf_all_dists(+DistPairs, -Dists): sorted list of distinct distance values in DistPairs.
wf_all_dists(DistPairs, Dists) :-
% Collect all distance values; there may be duplicates (many cells at same distance).
    findall(D, member(D-_, DistPairs), Raw),
% sort/2 removes duplicates and sorts ascending.
    sort(Raw, Dists).

% wf_path_exists(+Grid, +CellA, +CellB, +PassColor): true when CellB is reachable
% from CellA via BFS through PassColor cells. CellA is always reachable (distance 0).
wf_path_exists(Grid, CellA, CellB, PassColor) :-
% Run BFS from CellA as the sole seed.
    wf_bfs(Grid, [CellA], PassColor, DP),
% Succeed iff CellB appears anywhere in the distance map; cut via memberchk.
    memberchk(_-CellB, DP).

% wf_paint_bg(+Grid, +Seeds, +PassColor, +MaxD, -NewGrid): replace each PassColor cell
% in Grid with its BFS distance from Seeds (capped at MaxD). Unreachable PassColor
% cells and non-PassColor cells are left unchanged.
wf_paint_bg(Grid, Seeds, PassColor, MaxD, NewGrid) :-
% Compute the BFS distance map from Seeds through PassColor cells.
    wf_bfs(Grid, Seeds, PassColor, DP),
% Rebuild Grid row by row, replacing reachable PassColor cells with their distance.
    findall(NewRow,
            (nth0(R, Grid, Row),
             findall(New,
                     (nth0(C, Row, V),
                      (V = PassColor,
                       member(D-r(R,C), DP)
                       -> New is min(D, MaxD)
                       ;  New = V)),
                     NewRow)),
            NewGrid).

% wf_multi_wave_(+ColorDPs, +R, +C, -WinColor): helper for wf_multi_wave.
% Finds the WinColor (color whose seed reached r(R,C) with minimum BFS distance).
% Ties are broken by standard term order of Color (via sort/2 on D-Color pairs).
wf_multi_wave_(ColorDPs, R, C, WinColor) :-
% Collect all (Distance, Color) pairs for which r(R,C) appears in Color's BFS.
    findall(D-Color,
            (member(Color-DP, ColorDPs), member(D-r(R,C), DP)),
            Pairs),
% At least one color must reach this cell.
    Pairs \= [],
% sort/2 sorts ascending; the first element holds the minimum distance.
% When two colors tie on distance, their Color atoms sort lexicographically.
    sort(Pairs, [_-WinColor|_]).

% wf_multi_wave(+Grid, +ColoredSeeds, +PassColor, -Painted): paint each PassColor
% cell with the color of the nearest seed. ColoredSeeds is a list of Color-Seeds
% pairs where Seeds is a list of r(R,C) terms. Painted is a grid of the same
% dimensions as Grid with each PassColor cell replaced by its winning color.
% Ties between equidistant colors are broken by standard term order of the color.
wf_multi_wave(Grid, ColoredSeeds, PassColor, Painted) :-
% Pre-compute one BFS per color to avoid redundant BFS inside the cell loop.
    findall(Color-DP,
            (member(Color-Seeds, ColoredSeeds),
             wf_bfs(Grid, Seeds, PassColor, DP)),
            ColorDPs),
% Rebuild Grid, replacing each PassColor cell with its nearest-color winner.
    findall(NewRow,
            (nth0(R, Grid, Row),
             findall(New,
                     (nth0(C, Row, V),
                      (V = PassColor,
                       wf_multi_wave_(ColorDPs, R, C, WinColor)
                       -> New = WinColor
                       ;  New = V)),
                     NewRow)),
            Painted).

% wf_collision(+Grid, +ColoredSeeds, +PassColor, -Cells): sorted list of PassColor
% cells that are equidistant from at least two different-colored seed sets.
% These cells lie on the wavefront collision boundary between color regions.
wf_collision(Grid, ColoredSeeds, PassColor, Cells) :-
% Pre-compute one BFS per color.
    findall(Color-DP,
            (member(Color-Seeds, ColoredSeeds),
             wf_bfs(Grid, Seeds, PassColor, DP)),
            ColorDPs),
% Gather all PassColor positions in the grid.
    wf_passable(Grid, PassColor, PassCells),
% A cell is a collision cell iff the minimum distance is achieved by 2+ colors.
    findall(r(R,C),
            (member(r(R,C), PassCells),
             findall(D-Color,
                     (member(Color-DP, ColorDPs), member(D-r(R,C), DP)),
                     Pairs),
             Pairs \= [],
             sort(Pairs, [MinD-_|Rest]),
% Check that at least one other entry in Rest also carries the minimum distance.
             member(MinD-_, Rest)),
            Raw),
% Sort to produce canonical ordering of the collision boundary cells.
    sort(Raw, Cells).

% wf_enclosed(+Grid, +PassColor, -Cells): sorted list of PassColor cells that are
% NOT reachable from any PassColor cell on the grid border. These cells are
% completely enclosed by non-PassColor walls and cannot be reached from outside.
wf_enclosed(Grid, PassColor, Cells) :-
% Determine grid dimensions from row and column counts.
    length(Grid, NR), NR1 is NR - 1,
    (Grid = [FR|_] -> length(FR, NC) ; NC = 0), NC1 is NC - 1,
% Collect all PassColor cells that lie on the grid border (row 0, last row,
% column 0, or last column); these are the wave origins for the exterior BFS.
    findall(r(R,C),
            (nth0(R, Grid, Row), nth0(C, Row, PassColor),
             (R =:= 0 ; R =:= NR1 ; C =:= 0 ; C =:= NC1)),
            BorderSeeds),
% Run BFS from all border PassColor seeds to find the exterior-reachable cells.
    wf_bfs(Grid, BorderSeeds, PassColor, DP),
% Extract only the cell coordinates from the exterior distance map.
    findall(Cell, member(_-Cell, DP), Exterior),
% Collect all PassColor cells in the grid.
    wf_passable(Grid, PassColor, All),
% Enclosed cells are PassColor but not reachable from the exterior BFS.
    subtract(All, Exterior, Cells).
