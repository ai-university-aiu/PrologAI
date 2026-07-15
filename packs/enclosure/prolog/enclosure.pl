% enclosure.pl - Layer 106: Grid Enclosure, Inside/Outside Classification,
% and Region Boundary Analysis (en_* prefix).
% Provides predicates for classifying grid background cells as exterior (reachable
% from the grid border) or interior (enclosed by non-background walls), for finding
% and filling enclosed regions, for extracting the boundary vs interior of a color
% region, and for testing various forms of spatial enclosure and surround.
:- module(enclosure, [
    enclosure_border_cells/2,
    enclosure_outer_cells/3,
    enclosure_inner_cells/3,
    enclosure_is_inner/4,
    enclosure_is_outer/4,
    enclosure_fill_inner/4,
    enclosure_inner_count/3,
    enclosure_has_inner/2,
    enclosure_inner_components/3,
    enclosure_outer_components/3,
    enclosure_fill_hole/6,
    enclosure_boundary_cells/3,
    enclosure_interior_cells/3,
    enclosure_is_surrounded/4
]).
% Import list utilities.
:- use_module(library(lists), [member/2, memberchk/2, nth0/3, append/2, append/3, subtract/3]).
% Import higher-order utilities.
:- use_module(library(apply), [maplist/3, include/3]).

% enclosure_dims_: extract row count and column count from a grid.
enclosure_dims_(Grid, NR, NC) :-
% Count rows.
    length(Grid, NR),
% Get column count from the first row, default zero for empty grid.
    (NR > 0 -> Grid = [FR|_], length(FR, NC) ; NC = 0).

% enclosure_cell_val_: retrieve the value at cell R-C.
enclosure_cell_val_(Grid, R-C, V) :-
    nth0(R, Grid, Row),
    nth0(C, Row, V).

% enclosure_4candidates_: in-bounds 4-adjacent cells of (R,C) in an NR x NC grid.
enclosure_4candidates_(R, C, NR, NC, Nbrs) :-
    findall(NbR-NbC, (
        member(DR-DC, [-1-0, 1-0, 0-1, 0-(-1)]),
        NbR is R + DR, NbC is C + DC,
        0 =< NbR, NbR < NR, 0 =< NbC, NbC < NC
    ), Nbrs).

% enclosure_all_bg_: all cells in Grid with value Bg, as a sorted list.
enclosure_all_bg_(Grid, Bg, BgCells) :-
    enclosure_dims_(Grid, NR, NC),
    NR1 is NR - 1, NC1 is NC - 1,
    findall(R-C, (
        between(0, NR1, R), between(0, NC1, C),
        nth0(R, Grid, Row), nth0(C, Row, V), V =:= Bg
    ), BgRaw),
    sort(BgRaw, BgCells).

% enclosure_all_color_: all cells in Grid with value Color, as a sorted list.
enclosure_all_color_(Grid, Color, Cells) :-
    enclosure_dims_(Grid, NR, NC),
    NR1 is NR - 1, NC1 is NC - 1,
    findall(R-C, (
        between(0, NR1, R), between(0, NC1, C),
        nth0(R, Grid, Row), nth0(C, Row, V), V =:= Color
    ), Raw),
    sort(Raw, Cells).

% enclosure_bfs_bg_: BFS through Bg cells; returns all reached Bg cells (sorted).
% Queue: list of R-C cells to expand. Vis: visited Bg cells.
enclosure_bfs_bg_([], _, _, _, _, Vis, Vis) :- !.
enclosure_bfs_bg_([Cell|Rest], Grid, Bg, NR, NC, Vis0, Result) :-
    Cell = CR-CC,
    enclosure_4candidates_(CR, CC, NR, NC, Cands),
    include([N]>>(
        N = NbR-NbC,
        nth0(NbR, Grid, Row), nth0(NbC, Row, Val),
        Val =:= Bg,
        \+ member(N, Vis0)
    ), Cands, Nbrs),
    append(Rest, Nbrs, Queue1),
    append(Vis0, Nbrs, Vis1),
    enclosure_bfs_bg_(Queue1, Grid, Bg, NR, NC, Vis1, Result).

% enclosure_set_cell_: replace the value at (R,C) in Grid with Val.
enclosure_set_cell_(Grid, R, C, Val, NewGrid) :-
    nth0(R, Grid, OldRow, RestRows),
    nth0(C, OldRow, _, RestCols),
    nth0(C, NewRow, Val, RestCols),
    nth0(R, NewGrid, NewRow, RestRows).

% enclosure_set_cells_: set all cells in a list to Val in Grid.
enclosure_set_cells_(Grid, [], _, Grid) :- !.
enclosure_set_cells_(Grid0, [CR-CC|Rest], Val, Out) :-
    enclosure_set_cell_(Grid0, CR, CC, Val, Grid1),
    enclosure_set_cells_(Grid1, Rest, Val, Out).

% enclosure_comp_bfs_: BFS within a restricted cell set (Avail).
% Returns all cells reachable from the queue within Avail (sorted, deduplicated).
enclosure_comp_bfs_([], _, _, _, Acc, Acc) :- !.
enclosure_comp_bfs_([Cell|Rest], NR, NC, Avail, Vis0, Result) :-
    Cell = CR-CC,
    enclosure_4candidates_(CR, CC, NR, NC, Cands),
    include([N]>>(member(N, Avail), \+ member(N, Vis0)), Cands, Nbrs),
    append(Rest, Nbrs, Queue1),
    append(Vis0, Nbrs, Vis1),
    enclosure_comp_bfs_(Queue1, NR, NC, Avail, Vis1, Result).

% enclosure_all_comps_: partition a cell list into connected components.
enclosure_all_comps_([], _, _, []) :- !.
enclosure_all_comps_(Cells, NR, NC, [Comp|Comps]) :-
    Cells = [H|_],
    enclosure_comp_bfs_([H], NR, NC, Cells, [H], Comp),
    subtract(Cells, Comp, Remaining),
    enclosure_all_comps_(Remaining, NR, NC, Comps).

% enclosure_border_cells(+Grid, -Cells): all cells on the four edges of Grid, sorted.
enclosure_border_cells(Grid, Cells) :-
    enclosure_dims_(Grid, NR, NC),
    NR1 is NR - 1, NC1 is NC - 1,
    findall(R-C, (
        (R = 0 ; R = NR1),
        between(0, NC1, C)
    ), TopBottom),
    findall(R-C, (
        between(1, NR1, R_inner),  % inner rows only (corners already in TopBottom)
        R = R_inner,
        (C = 0 ; C = NC1)
    ), Sides),
    append(TopBottom, Sides, Raw),
    sort(Raw, Cells).

% enclosure_outer_cells(+Grid, +Bg, -Cells): sorted list of Bg cells reachable from
% any cell on the grid border. These are the exterior Bg cells.
enclosure_outer_cells(Grid, Bg, OuterCells) :-
    enclosure_dims_(Grid, NR, NC),
    NR1 is NR - 1, NC1 is NC - 1,
% Collect all border cells that have Bg value as BFS seeds.
    findall(R-C, (
        (R = 0 ; R = NR1 ; C = 0 ; C = NC1),
        between(0, NR1, R), between(0, NC1, C),
        nth0(R, Grid, Row), nth0(C, Row, V), V =:= Bg
    ), SeedsRaw),
    sort(SeedsRaw, Seeds),
% BFS from border Bg seeds through all Bg cells.
    enclosure_bfs_bg_(Seeds, Grid, Bg, NR, NC, Seeds, OuterRaw),
    sort(OuterRaw, OuterCells).

% enclosure_inner_cells(+Grid, +Bg, -Cells): sorted list of Bg cells NOT reachable from
% the grid border. These are the enclosed or interior Bg cells.
enclosure_inner_cells(Grid, Bg, InnerCells) :-
    enclosure_all_bg_(Grid, Bg, AllBg),
    enclosure_outer_cells(Grid, Bg, Outer),
    subtract(AllBg, Outer, InnerCells).

% enclosure_is_inner(+Grid, +R, +C, +Bg): succeed if cell (R,C) is an enclosed Bg cell.
enclosure_is_inner(Grid, R, C, Bg) :-
    enclosure_cell_val_(Grid, R-C, V),
    V =:= Bg,
    enclosure_inner_cells(Grid, Bg, Inner),
    memberchk(R-C, Inner).

% enclosure_is_outer(+Grid, +R, +C, +Bg): succeed if cell (R,C) is an exterior Bg cell.
enclosure_is_outer(Grid, R, C, Bg) :-
    enclosure_cell_val_(Grid, R-C, V),
    V =:= Bg,
    enclosure_outer_cells(Grid, Bg, Outer),
    memberchk(R-C, Outer).

% enclosure_fill_inner(+Grid, +Bg, +Color, -Out): paint all enclosed Bg cells with Color.
enclosure_fill_inner(Grid, Bg, Color, Out) :-
    enclosure_inner_cells(Grid, Bg, Inner),
    enclosure_set_cells_(Grid, Inner, Color, Out).

% enclosure_inner_count(+Grid, +Bg, -N): number of enclosed Bg cells.
enclosure_inner_count(Grid, Bg, N) :-
    enclosure_inner_cells(Grid, Bg, Inner),
    length(Inner, N).

% enclosure_has_inner(+Grid, +Bg): succeed if there is at least one enclosed Bg cell.
enclosure_has_inner(Grid, Bg) :-
    enclosure_inner_cells(Grid, Bg, Inner),
    Inner \= [].

% enclosure_inner_components(+Grid, +Bg, -Comps): partition enclosed Bg cells into
% their 4-connected components. Each element of Comps is a list of R-C cells.
enclosure_inner_components(Grid, Bg, Comps) :-
    enclosure_inner_cells(Grid, Bg, Inner),
    enclosure_dims_(Grid, NR, NC),
    enclosure_all_comps_(Inner, NR, NC, Comps).

% enclosure_outer_components(+Grid, +Bg, -Comps): partition exterior Bg cells into
% their 4-connected components.
enclosure_outer_components(Grid, Bg, Comps) :-
    enclosure_outer_cells(Grid, Bg, Outer),
    enclosure_dims_(Grid, NR, NC),
    enclosure_all_comps_(Outer, NR, NC, Comps).

% enclosure_fill_hole(+Grid, +Bg, +R, +C, +Color, -Out): fill the enclosed Bg component
% that contains cell (R,C) with Color. Fails if (R,C) is not an inner Bg cell.
enclosure_fill_hole(Grid, Bg, R, C, Color, Out) :-
    enclosure_inner_cells(Grid, Bg, Inner),
    memberchk(R-C, Inner),
    enclosure_dims_(Grid, NR, NC),
    enclosure_comp_bfs_([R-C], NR, NC, Inner, [R-C], HoleCells),
    enclosure_set_cells_(Grid, HoleCells, Color, Out).

% enclosure_boundary_cells(+Grid, +Color, -Cells): sorted list of Color cells that have
% at least one 4-adjacent cell (in-bounds) with value different from Color, or
% that lie on the grid edge (fewer than 4 in-bounds neighbors).
enclosure_boundary_cells(Grid, Color, Cells) :-
    enclosure_dims_(Grid, NR, NC),
    enclosure_all_color_(Grid, Color, ColorCells),
    include([Cell]>>(
        Cell = CR-CC,
        enclosure_4candidates_(CR, CC, NR, NC, Nbrs),
        (length(Nbrs, 4) ->
% All four neighbors are in-bounds: boundary if any is not Color.
            (member(N, Nbrs),
             N = NR2-NC2,
             nth0(NR2, Grid, Row2), nth0(NC2, Row2, NV),
             NV =\= Color)
        ;
% Fewer than 4 in-bounds neighbors means the cell is on the grid edge.
            true
        )
    ), ColorCells, Cells).

% enclosure_interior_cells(+Grid, +Color, -Cells): sorted list of Color cells that have
% exactly 4 in-bounds neighbors (not on grid edge) and all of them are Color.
enclosure_interior_cells(Grid, Color, Cells) :-
    enclosure_dims_(Grid, NR, NC),
    enclosure_all_color_(Grid, Color, ColorCells),
    include([Cell]>>(
        Cell = CR-CC,
        enclosure_4candidates_(CR, CC, NR, NC, Nbrs),
        length(Nbrs, 4),
        forall(member(N, Nbrs), (
            N = NR2-NC2,
            nth0(NR2, Grid, Row2), nth0(NC2, Row2, NV),
            NV =:= Color
        ))
    ), ColorCells, Cells).

% enclosure_is_surrounded(+Grid, +R, +C, +WallColor): succeed if all 4 orthogonal
% neighbors of cell (R,C) are either out of bounds or have value WallColor.
enclosure_is_surrounded(Grid, R, C, WallColor) :-
    enclosure_dims_(Grid, NR, NC),
% Check all four directions; any in-bounds neighbor must be WallColor.
    forall(member(DR-DC, [-1-0, 1-0, 0-1, 0-(-1)]), (
        NbR is R + DR, NbC is C + DC,
        (0 =< NbR, NbR < NR, 0 =< NbC, NbC < NC ->
            nth0(NbR, Grid, Row), nth0(NbC, Row, V), V =:= WallColor
        ;
            true
        )
    )).
