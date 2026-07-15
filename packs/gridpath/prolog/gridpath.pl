:- module(gridpath, [
    gridpath_shortest_path/7,
    gridpath_path_length/7,
    gridpath_reachable/6,
    gridpath_all_reachable/5,
    gridpath_distance_map/5,
    gridpath_nearest/6,
    gridpath_flood_n/6,
    gridpath_wavefront/6,
    gridpath_straight_h/4,
    gridpath_straight_v/4,
    gridpath_line_of_sight/6,
    gridpath_between_h/4,
    gridpath_between_v/4,
    gridpath_region_path/5
]).
% gridpath.pl - Layer 205: Grid Pathfinding - BFS shortest path, distance maps,
% flood-N steps, wavefront, line-of-sight, and multi-region path (gpa_* prefix).
% All predicates work on raw grid format: list of rows, each row a list of color
% atoms, 0-indexed (row 0 = top, col 0 = left).
% ObsColor (obstacle color) cells are impassable; start and end cells are
% assumed passable (i.e., their color differs from ObsColor).
:- use_module(library(lists), [
    nth0/3, member/2, memberchk/2, append/2, append/3
]).

% --- PRIVATE HELPERS ---

% Grid dimensions.
gridpath_dims_(Grid, H, W) :-
    length(Grid, H),
    (H > 0 -> Grid = [FR|_], length(FR, W) ; W = 0).

% Cell value at (R, C).
gridpath_cell_(Grid, R, C, V) :-
    nth0(R, Grid, Row), nth0(C, Row, V).

% BFS for shortest path from (R1,C1) to (R2,C2) avoiding ObsColor.
% Queue entries: node(R, C, RevPath) where RevPath is the path from start to
% the predecessor of (R,C) in reverse; the full path to (R,C) is [R-C|RevPath].
gridpath_path_bfs_(_, _, _, _, TR, TC, [node(TR, TC, RevPath)|_], _, Path) :- !,
    reverse([TR-TC|RevPath], Path).
gridpath_path_bfs_(Grid, H, W, Obs, TR, TC, [node(R, C, RevPath)|Rest], Vis, Path) :-
% Skip already-visited cells.
    (memberchk(R-C, Vis) ->
        gridpath_path_bfs_(Grid, H, W, Obs, TR, TC, Rest, Vis, Path)
    ;
        Vis1 = [R-C|Vis],
% Expand 4-connected unvisited passable neighbors.
        findall(node(NR, NC, [R-C|RevPath]),
            (member(DR-DC, [(-1)-0, 1-0, 0-(-1), 0-1]),
             NR is R + DR, NC is C + DC,
             NR >= 0, NR < H, NC >= 0, NC < W,
             \+ memberchk(NR-NC, Vis1),
             gridpath_cell_(Grid, NR, NC, V), V \= Obs),
            Nbrs),
        append(Rest, Nbrs, Q1),
        gridpath_path_bfs_(Grid, H, W, Obs, TR, TC, Q1, Vis1, Path)
    ).

% BFS collecting all cells reachable from the initial queue (non-Obs neighbors).
gridpath_reach_bfs_(_, _, _, _, [], Acc, Acc) :- !.
gridpath_reach_bfs_(Grid, H, W, Obs, [R-C|Q], Acc, Result) :-
    (memberchk(R-C, Acc) ->
        gridpath_reach_bfs_(Grid, H, W, Obs, Q, Acc, Result)
    ;
        Acc1 = [R-C|Acc],
        findall(NR-NC,
            (member(DR-DC, [(-1)-0, 1-0, 0-(-1), 0-1]),
             NR is R + DR, NC is C + DC,
             NR >= 0, NR < H, NC >= 0, NC < W,
             \+ memberchk(NR-NC, Acc1),
             gridpath_cell_(Grid, NR, NC, V), V \= Obs),
            Nbrs),
        append(Q, Nbrs, Q1),
        gridpath_reach_bfs_(Grid, H, W, Obs, Q1, Acc1, Result)
    ).

% BFS collecting R-C-Dist triples for all reachable cells.
gridpath_dist_bfs_(_, _, _, _, [], Acc, Acc) :- !.
gridpath_dist_bfs_(Grid, H, W, Obs, [node(R, C, D)|Q], Acc, Map) :-
    (memberchk(R-C-_, Acc) ->
        gridpath_dist_bfs_(Grid, H, W, Obs, Q, Acc, Map)
    ;
        Acc1 = [R-C-D|Acc],
        D1 is D + 1,
        findall(node(NR, NC, D1),
            (member(DR-DC, [(-1)-0, 1-0, 0-(-1), 0-1]),
             NR is R + DR, NC is C + DC,
             NR >= 0, NR < H, NC >= 0, NC < W,
             \+ memberchk(NR-NC-_, Acc1),
             gridpath_cell_(Grid, NR, NC, V), V \= Obs),
            Nbrs),
        append(Q, Nbrs, Q1),
        gridpath_dist_bfs_(Grid, H, W, Obs, Q1, Acc1, Map)
    ).

% --- EXPORTED PREDICATES ---

% gridpath_shortest_path(+Grid, +R1, +C1, +R2, +C2, +ObsColor, -Path)
% Path is the list of R-C coordinates of the shortest 4-connected path from
% (R1,C1) to (R2,C2) avoiding ObsColor cells. Includes both endpoints.
% Fails if no path exists or if either endpoint is ObsColor.
gridpath_shortest_path(Grid, R1, C1, R2, C2, Obs, Path) :-
    gridpath_dims_(Grid, H, W),
% Both endpoints must be passable.
    gridpath_cell_(Grid, R1, C1, V1), V1 \= Obs,
    gridpath_cell_(Grid, R2, C2, V2), V2 \= Obs,
    gridpath_path_bfs_(Grid, H, W, Obs, R2, C2, [node(R1, C1, [])], [], Path).

% gridpath_path_length(+Grid, +R1, +C1, +R2, +C2, +ObsColor, -N)
% N is the number of steps in the shortest 4-connected path (number of cells
% minus 1). Fails if no path exists.
gridpath_path_length(Grid, R1, C1, R2, C2, Obs, N) :-
    gridpath_shortest_path(Grid, R1, C1, R2, C2, Obs, Path),
    length(Path, L), N is L - 1.

% gridpath_reachable(+Grid, +R1, +C1, +R2, +C2, +ObsColor)
% Succeeds if (R2,C2) is 4-connected reachable from (R1,C1) avoiding ObsColor.
gridpath_reachable(Grid, R1, C1, R2, C2, Obs) :-
    gridpath_shortest_path(Grid, R1, C1, R2, C2, Obs, _).

% gridpath_all_reachable(+Grid, +R, +C, +ObsColor, -Cells)
% Cells is the list of all R-C positions reachable from (R,C) via 4-connected
% non-ObsColor cells. Includes (R,C) itself. Fails if (R,C) is ObsColor.
gridpath_all_reachable(Grid, R, C, Obs, Cells) :-
    gridpath_dims_(Grid, H, W),
    gridpath_cell_(Grid, R, C, V), V \= Obs,
    gridpath_reach_bfs_(Grid, H, W, Obs, [R-C], [], Cells).

% gridpath_distance_map(+Grid, +R, +C, +ObsColor, -Map)
% Map is a list of NR-NC-Dist triples for every cell reachable from (R,C)
% via 4-connected non-ObsColor paths. (R,C) itself has Dist = 0.
% Unreachable cells are omitted. Fails if (R,C) is ObsColor.
gridpath_distance_map(Grid, R, C, Obs, Map) :-
    gridpath_dims_(Grid, H, W),
    gridpath_cell_(Grid, R, C, V), V \= Obs,
    gridpath_dist_bfs_(Grid, H, W, Obs, [node(R, C, 0)], [], Map).

% gridpath_nearest(+Grid, +R, +C, +TargetColor, +ObsColor, -NR-NC)
% NR-NC is the cell of TargetColor nearest to (R,C) via 4-connected
% non-ObsColor paths. Ties broken by BFS order (first found at equal distance).
% Fails if no reachable TargetColor cell exists or if (R,C) is ObsColor.
gridpath_nearest(Grid, R, C, TargetColor, Obs, NR-NC) :-
    gridpath_distance_map(Grid, R, C, Obs, Map),
    findall(D-NR-NC, (member(NR-NC-D, Map), gridpath_cell_(Grid, NR, NC, TargetColor)), Keyed),
    Keyed = [_|_],
    msort(Keyed, [_-NR-NC|_]).

% gridpath_flood_n(+Grid, +R, +C, +N, +ObsColor, -Cells)
% Cells is the list of all R-C positions reachable from (R,C) in at most N
% 4-connected steps, avoiding ObsColor. Includes (R,C) itself (0 steps).
gridpath_flood_n(Grid, R, C, N, Obs, Cells) :-
    gridpath_distance_map(Grid, R, C, Obs, Map),
    findall(NR-NC, (member(NR-NC-D, Map), D =< N), Cells).

% gridpath_wavefront(+Grid, +R, +C, +N, +ObsColor, -Cells)
% Cells is the list of R-C positions exactly N 4-connected steps from (R,C),
% avoiding ObsColor. Returns [] if no cells are at that distance.
gridpath_wavefront(Grid, R, C, N, Obs, Cells) :-
    gridpath_distance_map(Grid, R, C, Obs, Map),
    findall(NR-NC, member(NR-NC-N, Map), Cells).

% gridpath_straight_h(+R, +C1, +C2, -Cells)
% Cells is the list of R-C positions on row R from column C1 to column C2
% inclusive, in column order (left-to-right when C1 =< C2, right-to-left
% when C1 > C2). Does not check grid bounds.
gridpath_straight_h(R, C1, C2, Cells) :-
    (C1 =< C2 ->
        findall(R-C, between(C1, C2, C), Cells)
    ;
        findall(R-C, between(C2, C1, C), RevCells),
        reverse(RevCells, Cells)
    ).

% gridpath_straight_v(+C, +R1, +R2, -Cells)
% Cells is the list of R-C positions on column C from row R1 to row R2
% inclusive, in row order (top-to-bottom when R1 =< R2, bottom-to-top when
% R1 > R2). Does not check grid bounds.
gridpath_straight_v(C, R1, R2, Cells) :-
    (R1 =< R2 ->
        findall(R-C, between(R1, R2, R), Cells)
    ;
        findall(R-C, between(R2, R1, R), RevCells),
        reverse(RevCells, Cells)
    ).

% gridpath_line_of_sight(+Grid, +R1, +C1, +R2, +C2, +ObsColor)
% Succeeds if (R1,C1) and (R2,C2) share the same row or column AND no
% ObsColor cell lies strictly between them. Fails if they are on different
% rows and columns (diagonal), or if any intervening cell is ObsColor.
gridpath_line_of_sight(Grid, R1, C1, R2, C2, Obs) :-
    (R1 =:= R2 ->
% Same row: check every cell strictly between C1 and C2.
        (C1 < C2 -> Clo is C1 + 1, Chi is C2 - 1 ; Clo is C2 + 1, Chi is C1 - 1),
        (Clo > Chi -> true ;
            \+ (between(Clo, Chi, C), gridpath_cell_(Grid, R1, C, Obs)))
    ;
        C1 =:= C2,
% Same column: check every cell strictly between R1 and R2.
        (R1 < R2 -> Rlo is R1 + 1, Rhi is R2 - 1 ; Rlo is R2 + 1, Rhi is R1 - 1),
        (Rlo > Rhi -> true ;
            \+ (between(Rlo, Rhi, R), gridpath_cell_(Grid, R, C1, Obs)))
    ).

% gridpath_between_h(+R, +C1, +C2, -Cells)
% Cells is the list of R-C positions on row R strictly between columns C1 and C2
% (endpoints excluded), in ascending column order.
gridpath_between_h(R, C1, C2, Cells) :-
    (C1 < C2 -> Clo is C1 + 1, Chi is C2 - 1
              ; Clo is C2 + 1, Chi is C1 - 1),
    (Clo > Chi -> Cells = [] ; findall(R-C, between(Clo, Chi, C), Cells)).

% gridpath_between_v(+R1, +R2, +C, -Cells)
% Cells is the list of R-C positions on column C strictly between rows R1 and R2
% (endpoints excluded), in ascending row order.
gridpath_between_v(R1, R2, C, Cells) :-
    (R1 < R2 -> Rlo is R1 + 1, Rhi is R2 - 1
              ; Rlo is R2 + 1, Rhi is R1 - 1),
    (Rlo > Rhi -> Cells = [] ; findall(R-C, between(Rlo, Rhi, R), Cells)).

% gridpath_region_path(+Grid, +Color1, +Color2, +ObsColor, -Path)
% Path is the shortest 4-connected path from any cell of Color1 to any cell
% of Color2, avoiding ObsColor cells. Includes the endpoint cells. Fails if
% no path exists, or if no Color1 or Color2 cells exist.
% Note: Color1 and Color2 cells are not treated as obstacles for this search.
gridpath_region_path(Grid, Color1, Color2, Obs, Path) :-
    gridpath_dims_(Grid, H, W),
    H1 is H - 1, W1 is W - 1,
    findall(R-C,
        (between(0, H1, R), between(0, W1, C), gridpath_cell_(Grid, R, C, Color1)),
        Seeds1),
    findall(R-C,
        (between(0, H1, R), between(0, W1, C), gridpath_cell_(Grid, R, C, Color2)),
        Seeds2),
    Seeds1 = [_|_], Seeds2 = [_|_],
% Try all (Color1,Color2) pairs; collect paths and pick the shortest.
    findall(Len-P,
        (member(R1-C1, Seeds1),
         member(R2-C2, Seeds2),
         gridpath_shortest_path(Grid, R1, C1, R2, C2, Obs, P),
         length(P, Len)),
        Candidates),
    Candidates = [_|_],
    msort(Candidates, [_-Path|_]).
