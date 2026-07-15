% morph.pl - Layer 84: Morphological Grid Operations (mo_* prefix).
% ARC-AGI-2 visual reasoning: dilation, erosion, boundary detection, distance, holes.
:- module(morph, [
    morph_dilate/3,
    morph_erode/3,
    morph_dilate_n/4,
    morph_erode_n/4,
    morph_open/3,
    morph_close/3,
    morph_smooth/3,
    morph_boundary/3,
    morph_interior/3,
    morph_dilate_val/4,
    morph_grow_from/5,
    morph_dist_to_bg/3,
    morph_ring/4,
    morph_fill_holes/4
]).

% Import list operations used throughout this module.
:- use_module(library(lists), [member/2, nth0/3, numlist/3, append/3,
                                memberchk/2, min_member/2]).
% Import higher-order operations used throughout this module.
:- use_module(library(apply), [maplist/2, maplist/3, maplist/4, foldl/4]).

% morph_dilate(+Grid, +Bg, -Result): expand all non-Bg regions by one 4-connected step.
% Each Bg cell adjacent to a non-Bg cell copies the value of its first non-Bg neighbor.
morph_dilate(Grid, Bg, Result) :-
    % Compute grid bounds for neighbor checks.
    length(Grid, NRows), NRowsM1 is NRows - 1,
    Grid = [FR|_], length(FR, NCols), NColsM1 is NCols - 1,
    numlist(0, NRowsM1, RowIdxs), numlist(0, NColsM1, ColIdxs),
    % For each cell: if Bg, fill with first non-Bg neighbor's value; else keep.
    maplist([RI, GRow, RRow]>>(
        maplist([CI, GV, RV]>>(
            (GV == Bg ->
                (member(DR-DC, [-1-0, 1-0, 0-(-1), 0-1]),
                 R2 is RI + DR, C2 is CI + DC,
                 R2 >= 0, R2 =< NRowsM1, C2 >= 0, C2 =< NColsM1,
                 nth0(R2, Grid, NRow), nth0(C2, NRow, NV), NV \== Bg
                -> RV = NV
                ; RV = Bg
                )
            ;
                RV = GV
            )
        ), ColIdxs, GRow, RRow)
    ), RowIdxs, Grid, Result).

% morph_erode(+Grid, +Bg, -Result): shrink all non-Bg regions by one 4-connected step.
% Each non-Bg cell adjacent to any Bg 4-neighbor becomes Bg.
morph_erode(Grid, Bg, Result) :-
    % Compute grid bounds for neighbor checks.
    length(Grid, NRows), NRowsM1 is NRows - 1,
    Grid = [FR|_], length(FR, NCols), NColsM1 is NCols - 1,
    numlist(0, NRowsM1, RowIdxs), numlist(0, NColsM1, ColIdxs),
    % For each cell: if non-Bg and has a Bg 4-neighbor, erode to Bg; else keep.
    maplist([RI, GRow, RRow]>>(
        maplist([CI, GV, RV]>>(
            (GV \== Bg,
             member(DR-DC, [-1-0, 1-0, 0-(-1), 0-1]),
             R2 is RI + DR, C2 is CI + DC,
             R2 >= 0, R2 =< NRowsM1, C2 >= 0, C2 =< NColsM1,
             nth0(R2, Grid, NRow), nth0(C2, NRow, Bg)
            -> RV = Bg
            ; RV = GV
            )
        ), ColIdxs, GRow, RRow)
    ), RowIdxs, Grid, Result).

% morph_dilate_n(+Grid, +Bg, +N, -Result): dilate N times; N=0 returns Grid unchanged.
morph_dilate_n(Grid, _, 0, Grid) :- !.
morph_dilate_n(Grid, Bg, N, Result) :-
    % Fold N dilation steps over the grid using foldl.
    N > 0, numlist(1, N, Steps),
    foldl([_, Acc, NAcc]>>(morph_dilate(Acc, Bg, NAcc)), Steps, Grid, Result).

% morph_erode_n(+Grid, +Bg, +N, -Result): erode N times; N=0 returns Grid unchanged.
morph_erode_n(Grid, _, 0, Grid) :- !.
morph_erode_n(Grid, Bg, N, Result) :-
    % Fold N erosion steps over the grid using foldl.
    N > 0, numlist(1, N, Steps),
    foldl([_, Acc, NAcc]>>(morph_erode(Acc, Bg, NAcc)), Steps, Grid, Result).

% morph_open(+Grid, +Bg, -Result): morphological opening = erode then dilate.
% Removes small protrusions and isolated pixels.
morph_open(Grid, Bg, Result) :-
    morph_erode(Grid, Bg, Eroded),
    morph_dilate(Eroded, Bg, Result).

% morph_close(+Grid, +Bg, -Result): morphological closing = dilate then erode.
% Fills small gaps and notches at the boundary.
morph_close(Grid, Bg, Result) :-
    morph_dilate(Grid, Bg, Dilated),
    morph_erode(Dilated, Bg, Result).

% morph_smooth(+Grid, +Bg, -Result): morphological smoothing = open then close.
% Removes protrusions and fills gaps; produces smoother object boundaries.
morph_smooth(Grid, Bg, Result) :-
    morph_open(Grid, Bg, Opened),
    morph_close(Opened, Bg, Result).

% morph_boundary(+Grid, +Bg, -Result): keep only non-Bg cells on the object perimeter.
% A non-Bg cell is a perimeter cell if it is on the grid edge or has a Bg 4-neighbor.
morph_boundary(Grid, Bg, Result) :-
    % Compute grid bounds for edge and neighbor checks.
    length(Grid, NRows), NRowsM1 is NRows - 1,
    Grid = [FR|_], length(FR, NCols), NColsM1 is NCols - 1,
    numlist(0, NRowsM1, RowIdxs), numlist(0, NColsM1, ColIdxs),
    % For each cell: keep if non-Bg and on edge or has Bg 4-neighbor; else set Bg.
    maplist([RI, GRow, RRow]>>(
        maplist([CI, GV, RV]>>(
            (GV \== Bg,
             (  RI =:= 0 ; RI =:= NRowsM1 ; CI =:= 0 ; CI =:= NColsM1
             ;  member(DR-DC, [-1-0, 1-0, 0-(-1), 0-1]),
                R2 is RI + DR, C2 is CI + DC,
                R2 >= 0, R2 =< NRowsM1, C2 >= 0, C2 =< NColsM1,
                nth0(R2, Grid, NRow), nth0(C2, NRow, Bg)
             )
            -> RV = GV
            ; RV = Bg
            )
        ), ColIdxs, GRow, RRow)
    ), RowIdxs, Grid, Result).

% morph_interior(+Grid, +Bg, -Result): keep only non-Bg cells not on the perimeter.
% Interior cells are non-Bg cells with no Bg 4-neighbor and not on the grid edge.
morph_interior(Grid, Bg, Result) :-
    % Compute boundary, then interior = foreground minus boundary.
    morph_boundary(Grid, Bg, BoundaryGrid),
    % A cell is interior if it is non-Bg in Grid but Bg in BoundaryGrid.
    maplist([GRow, BRow, RRow]>>(
        maplist([GV, BV, RV]>>(
            (GV \== Bg, BV == Bg -> RV = GV ; RV = Bg)
        ), GRow, BRow, RRow)
    ), Grid, BoundaryGrid, Result).

% morph_dilate_val(+Grid, +Bg, +Val, -Result): dilate using a fixed fill value.
% Each Bg cell adjacent to any non-Bg cell becomes Val instead of the neighbor's value.
morph_dilate_val(Grid, Bg, Val, Result) :-
    % Compute grid bounds for neighbor checks.
    length(Grid, NRows), NRowsM1 is NRows - 1,
    Grid = [FR|_], length(FR, NCols), NColsM1 is NCols - 1,
    numlist(0, NRowsM1, RowIdxs), numlist(0, NColsM1, ColIdxs),
    % For each Bg cell adjacent to any non-Bg cell, fill with fixed Val.
    maplist([RI, GRow, RRow]>>(
        maplist([CI, GV, RV]>>(
            (GV == Bg ->
                (member(DR-DC, [-1-0, 1-0, 0-(-1), 0-1]),
                 R2 is RI + DR, C2 is CI + DC,
                 R2 >= 0, R2 =< NRowsM1, C2 >= 0, C2 =< NColsM1,
                 nth0(R2, Grid, NRow), nth0(C2, NRow, NV), NV \== Bg
                -> RV = Val
                ; RV = Bg
                )
            ;
                RV = GV
            )
        ), ColIdxs, GRow, RRow)
    ), RowIdxs, Grid, Result).

% morph_bfs_bg_(+Queue, +Visited, +Grid, +Bg, +MaxR, +MaxC, -ReachedBg): BFS through Bg.
% Expands from Queue into connected Bg cells not yet in Visited.
morph_bfs_bg_([], Visited, _, _, _, _, Visited).
morph_bfs_bg_([R-C|Queue], Visited, Grid, Bg, MaxR, MaxC, ReachedBg) :-
    % Find Bg 4-neighbors not yet in Visited.
    findall(R2-C2, (
        member(DR-DC, [-1-0, 1-0, 0-(-1), 0-1]),
        R2 is R + DR, C2 is C + DC,
        R2 >= 0, R2 =< MaxR, C2 >= 0, C2 =< MaxC,
        nth0(R2, Grid, Row2), nth0(C2, Row2, Bg),
        \+ member(R2-C2, Visited)
    ), NewCells0),
    % Deduplicate new cells before expanding.
    sort(NewCells0, NewCells),
    append(Visited, NewCells, NewVisited),
    append(Queue, NewCells, NewQueue0),
    sort(NewQueue0, NewQueue),
    morph_bfs_bg_(NewQueue, NewVisited, Grid, Bg, MaxR, MaxC, ReachedBg).

% morph_grow_from(+Grid, +Seeds, +Bg, +Val, -Result): BFS flood from Seeds into Bg.
% Expands from Bg cells adjacent to Seeds through connected Bg territory.
% All reached Bg cells become Val; non-Bg cells and unreached Bg cells unchanged.
morph_grow_from(Grid, Seeds, Bg, Val, Result) :-
    % Compute grid bounds.
    length(Grid, NRows), NRowsM1 is NRows - 1,
    Grid = [FR|_], length(FR, NCols), NColsM1 is NCols - 1,
    % Find Bg cells immediately adjacent to any seed cell as the initial frontier.
    findall(R2-C2, (
        member(R-C, Seeds),
        member(DR-DC, [-1-0, 1-0, 0-(-1), 0-1]),
        R2 is R + DR, C2 is C + DC,
        R2 >= 0, R2 =< NRowsM1, C2 >= 0, C2 =< NColsM1,
        nth0(R2, Grid, Row2), nth0(C2, Row2, Bg)
    ), InitDup),
    sort(InitDup, InitFrontier),
    % BFS through all Bg territory reachable from the initial frontier.
    morph_bfs_bg_(InitFrontier, InitFrontier, Grid, Bg, NRowsM1, NColsM1, ReachedBg),
    % Mark all reached Bg cells with Val; leave all other cells unchanged.
    numlist(0, NRowsM1, RowIdxs), numlist(0, NColsM1, ColIdxs),
    maplist([RI, GRow, RRow]>>(
        maplist([CI, GV, RV]>>(
            (memberchk(RI-CI, ReachedBg) -> RV = Val ; RV = GV)
        ), ColIdxs, GRow, RRow)
    ), RowIdxs, Grid, Result).

% morph_dist_to_bg(+Grid, +Bg, -DistGrid): L1 (Manhattan) distance to nearest Bg cell.
% DistGrid[R][C] = 0 for Bg cells; for non-Bg cells = min L1 distance to any Bg cell.
% When no Bg cells are present, all non-Bg distances are 0.
morph_dist_to_bg(Grid, Bg, DistGrid) :-
    % Collect all Bg cell positions for distance computation.
    length(Grid, NRows), NRowsM1 is NRows - 1,
    Grid = [FR|_], length(FR, NCols), NColsM1 is NCols - 1,
    findall(BR-BC, (
        between(0, NRowsM1, BR), between(0, NColsM1, BC),
        nth0(BR, Grid, BRow), nth0(BC, BRow, Bg)
    ), BgCells),
    numlist(0, NRowsM1, RowIdxs), numlist(0, NColsM1, ColIdxs),
    % For each cell: Bg → distance 0; non-Bg → min Manhattan distance to any Bg cell.
    maplist([RI, GRow, DRow]>>(
        maplist([CI, GV, DV]>>(
            (GV == Bg ->
                DV = 0
            ;
                (BgCells = [] ->
                    DV = 0
                ;
                    findall(D, (
                        member(BR-BC, BgCells),
                        D is abs(RI - BR) + abs(CI - BC)
                    ), Ds),
                    min_member(DV, Ds)
                )
            )
        ), ColIdxs, GRow, DRow)
    ), RowIdxs, Grid, DistGrid).

% morph_ring(+Grid, +Bg, +N, -Ring): cells at exactly N dilation steps from any non-Bg cell.
% Ring contains only cells added at exactly the Nth dilation step (not earlier steps).
% For N=0 the ring is empty (Bg everywhere).
morph_ring(Grid, Bg, 0, Ring) :- !,
    % Ring at N=0 is empty: no cells are "newly reached" at step 0.
    maplist([GRow, RRow]>>(maplist([_, RV]>>(RV = Bg), GRow, RRow)), Grid, Ring).
morph_ring(Grid, Bg, N, Ring) :-
    % Compute N-step and (N-1)-step dilations; ring = new cells at step N.
    N > 0,
    morph_dilate_n(Grid, Bg, N, Dilated),
    N1 is N - 1,
    morph_dilate_n(Grid, Bg, N1, Inner),
    % Ring cell: non-Bg in Dilated but Bg in Inner means it was added at step N.
    maplist([DRow, IRow, RRow]>>(
        maplist([DV, IV, RV]>>(
            (DV \== Bg, IV == Bg -> RV = DV ; RV = Bg)
        ), DRow, IRow, RRow)
    ), Dilated, Inner, Ring).

% morph_fill_holes(+Grid, +Bg, +FillVal, -Result): fill enclosed background regions.
% Bg cells not reachable from the grid border through Bg connectivity are interior holes;
% they become FillVal. Exterior Bg cells and all non-Bg cells are unchanged.
morph_fill_holes(Grid, Bg, FillVal, Result) :-
    % Compute grid bounds.
    length(Grid, NRows), NRowsM1 is NRows - 1,
    Grid = [FR|_], length(FR, NCols), NColsM1 is NCols - 1,
    % Collect Bg cells on the grid border as BFS seeds for exterior discovery.
    findall(R-C, (
        between(0, NRowsM1, R), between(0, NColsM1, C),
        nth0(R, Grid, Row), nth0(C, Row, Bg),
        (R =:= 0 ; R =:= NRowsM1 ; C =:= 0 ; C =:= NColsM1)
    ), BorderBgDup),
    sort(BorderBgDup, BorderBg),
    % BFS through Bg from border seeds to find all exterior (non-enclosed) Bg cells.
    morph_bfs_bg_(BorderBg, BorderBg, Grid, Bg, NRowsM1, NColsM1, ExteriorBg),
    % Fill all Bg cells not reachable from the border (interior holes) with FillVal.
    numlist(0, NRowsM1, RowIdxs), numlist(0, NColsM1, ColIdxs),
    maplist([RI, GRow, RRow]>>(
        maplist([CI, GV, RV]>>(
            (GV == Bg, \+ memberchk(RI-CI, ExteriorBg) ->
                RV = FillVal
            ;
                RV = GV
            )
        ), ColIdxs, GRow, RRow)
    ), RowIdxs, Grid, Result).
