% enclosure.pl - Layer 106: Grid Enclosure, Inside/Outside Classification,
% and Region Boundary Analysis (en_* prefix).
% Provides predicates for classifying grid background cells as exterior (reachable
% from the grid border) or interior (enclosed by non-background walls), for finding
% and filling enclosed regions, for extracting the boundary vs interior of a color
% region, and for testing various forms of spatial enclosure and surround.
:- module(enclosure, [
    en_border_cells/2,
    en_outer_cells/3,
    en_inner_cells/3,
    en_is_inner/4,
    en_is_outer/4,
    en_fill_inner/4,
    en_inner_count/3,
    en_has_inner/2,
    en_inner_components/3,
    en_outer_components/3,
    en_fill_hole/6,
    en_boundary_cells/3,
    en_interior_cells/3,
    en_is_surrounded/4
]).
% Import list utilities.
:- use_module(library(lists), [member/2, memberchk/2, nth0/3, append/2, append/3, subtract/3]).
% Import higher-order utilities.
:- use_module(library(apply), [maplist/3, include/3]).

% en_dims_: extract row count and column count from a grid.
en_dims_(Grid, NR, NC) :-
% Count rows.
    length(Grid, NR),
% Get column count from the first row, default zero for empty grid.
    (NR > 0 -> Grid = [FR|_], length(FR, NC) ; NC = 0).

% en_cell_val_: retrieve the value at cell R-C.
en_cell_val_(Grid, R-C, V) :-
    nth0(R, Grid, Row),
    nth0(C, Row, V).

% en_4candidates_: in-bounds 4-adjacent cells of (R,C) in an NR x NC grid.
en_4candidates_(R, C, NR, NC, Nbrs) :-
    findall(NbR-NbC, (
        member(DR-DC, [-1-0, 1-0, 0-1, 0-(-1)]),
        NbR is R + DR, NbC is C + DC,
        0 =< NbR, NbR < NR, 0 =< NbC, NbC < NC
    ), Nbrs).

% en_all_bg_: all cells in Grid with value Bg, as a sorted list.
en_all_bg_(Grid, Bg, BgCells) :-
    en_dims_(Grid, NR, NC),
    NR1 is NR - 1, NC1 is NC - 1,
    findall(R-C, (
        between(0, NR1, R), between(0, NC1, C),
        nth0(R, Grid, Row), nth0(C, Row, V), V =:= Bg
    ), BgRaw),
    sort(BgRaw, BgCells).

% en_all_color_: all cells in Grid with value Color, as a sorted list.
en_all_color_(Grid, Color, Cells) :-
    en_dims_(Grid, NR, NC),
    NR1 is NR - 1, NC1 is NC - 1,
    findall(R-C, (
        between(0, NR1, R), between(0, NC1, C),
        nth0(R, Grid, Row), nth0(C, Row, V), V =:= Color
    ), Raw),
    sort(Raw, Cells).

% en_bfs_bg_: BFS through Bg cells; returns all reached Bg cells (sorted).
% Queue: list of R-C cells to expand. Vis: visited Bg cells.
en_bfs_bg_([], _, _, _, _, Vis, Vis) :- !.
en_bfs_bg_([Cell|Rest], Grid, Bg, NR, NC, Vis0, Result) :-
    Cell = CR-CC,
    en_4candidates_(CR, CC, NR, NC, Cands),
    include([N]>>(
        N = NbR-NbC,
        nth0(NbR, Grid, Row), nth0(NbC, Row, Val),
        Val =:= Bg,
        \+ member(N, Vis0)
    ), Cands, Nbrs),
    append(Rest, Nbrs, Queue1),
    append(Vis0, Nbrs, Vis1),
    en_bfs_bg_(Queue1, Grid, Bg, NR, NC, Vis1, Result).

% en_set_cell_: replace the value at (R,C) in Grid with Val.
en_set_cell_(Grid, R, C, Val, NewGrid) :-
    nth0(R, Grid, OldRow, RestRows),
    nth0(C, OldRow, _, RestCols),
    nth0(C, NewRow, Val, RestCols),
    nth0(R, NewGrid, NewRow, RestRows).

% en_set_cells_: set all cells in a list to Val in Grid.
en_set_cells_(Grid, [], _, Grid) :- !.
en_set_cells_(Grid0, [CR-CC|Rest], Val, Out) :-
    en_set_cell_(Grid0, CR, CC, Val, Grid1),
    en_set_cells_(Grid1, Rest, Val, Out).

% en_comp_bfs_: BFS within a restricted cell set (Avail).
% Returns all cells reachable from the queue within Avail (sorted, deduplicated).
en_comp_bfs_([], _, _, _, Acc, Acc) :- !.
en_comp_bfs_([Cell|Rest], NR, NC, Avail, Vis0, Result) :-
    Cell = CR-CC,
    en_4candidates_(CR, CC, NR, NC, Cands),
    include([N]>>(member(N, Avail), \+ member(N, Vis0)), Cands, Nbrs),
    append(Rest, Nbrs, Queue1),
    append(Vis0, Nbrs, Vis1),
    en_comp_bfs_(Queue1, NR, NC, Avail, Vis1, Result).

% en_all_comps_: partition a cell list into connected components.
en_all_comps_([], _, _, []) :- !.
en_all_comps_(Cells, NR, NC, [Comp|Comps]) :-
    Cells = [H|_],
    en_comp_bfs_([H], NR, NC, Cells, [H], Comp),
    subtract(Cells, Comp, Remaining),
    en_all_comps_(Remaining, NR, NC, Comps).

% en_border_cells(+Grid, -Cells): all cells on the four edges of Grid, sorted.
en_border_cells(Grid, Cells) :-
    en_dims_(Grid, NR, NC),
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

% en_outer_cells(+Grid, +Bg, -Cells): sorted list of Bg cells reachable from
% any cell on the grid border. These are the exterior Bg cells.
en_outer_cells(Grid, Bg, OuterCells) :-
    en_dims_(Grid, NR, NC),
    NR1 is NR - 1, NC1 is NC - 1,
% Collect all border cells that have Bg value as BFS seeds.
    findall(R-C, (
        (R = 0 ; R = NR1 ; C = 0 ; C = NC1),
        between(0, NR1, R), between(0, NC1, C),
        nth0(R, Grid, Row), nth0(C, Row, V), V =:= Bg
    ), SeedsRaw),
    sort(SeedsRaw, Seeds),
% BFS from border Bg seeds through all Bg cells.
    en_bfs_bg_(Seeds, Grid, Bg, NR, NC, Seeds, OuterRaw),
    sort(OuterRaw, OuterCells).

% en_inner_cells(+Grid, +Bg, -Cells): sorted list of Bg cells NOT reachable from
% the grid border. These are the enclosed or interior Bg cells.
en_inner_cells(Grid, Bg, InnerCells) :-
    en_all_bg_(Grid, Bg, AllBg),
    en_outer_cells(Grid, Bg, Outer),
    subtract(AllBg, Outer, InnerCells).

% en_is_inner(+Grid, +R, +C, +Bg): succeed if cell (R,C) is an enclosed Bg cell.
en_is_inner(Grid, R, C, Bg) :-
    en_cell_val_(Grid, R-C, V),
    V =:= Bg,
    en_inner_cells(Grid, Bg, Inner),
    memberchk(R-C, Inner).

% en_is_outer(+Grid, +R, +C, +Bg): succeed if cell (R,C) is an exterior Bg cell.
en_is_outer(Grid, R, C, Bg) :-
    en_cell_val_(Grid, R-C, V),
    V =:= Bg,
    en_outer_cells(Grid, Bg, Outer),
    memberchk(R-C, Outer).

% en_fill_inner(+Grid, +Bg, +Color, -Out): paint all enclosed Bg cells with Color.
en_fill_inner(Grid, Bg, Color, Out) :-
    en_inner_cells(Grid, Bg, Inner),
    en_set_cells_(Grid, Inner, Color, Out).

% en_inner_count(+Grid, +Bg, -N): number of enclosed Bg cells.
en_inner_count(Grid, Bg, N) :-
    en_inner_cells(Grid, Bg, Inner),
    length(Inner, N).

% en_has_inner(+Grid, +Bg): succeed if there is at least one enclosed Bg cell.
en_has_inner(Grid, Bg) :-
    en_inner_cells(Grid, Bg, Inner),
    Inner \= [].

% en_inner_components(+Grid, +Bg, -Comps): partition enclosed Bg cells into
% their 4-connected components. Each element of Comps is a list of R-C cells.
en_inner_components(Grid, Bg, Comps) :-
    en_inner_cells(Grid, Bg, Inner),
    en_dims_(Grid, NR, NC),
    en_all_comps_(Inner, NR, NC, Comps).

% en_outer_components(+Grid, +Bg, -Comps): partition exterior Bg cells into
% their 4-connected components.
en_outer_components(Grid, Bg, Comps) :-
    en_outer_cells(Grid, Bg, Outer),
    en_dims_(Grid, NR, NC),
    en_all_comps_(Outer, NR, NC, Comps).

% en_fill_hole(+Grid, +Bg, +R, +C, +Color, -Out): fill the enclosed Bg component
% that contains cell (R,C) with Color. Fails if (R,C) is not an inner Bg cell.
en_fill_hole(Grid, Bg, R, C, Color, Out) :-
    en_inner_cells(Grid, Bg, Inner),
    memberchk(R-C, Inner),
    en_dims_(Grid, NR, NC),
    en_comp_bfs_([R-C], NR, NC, Inner, [R-C], HoleCells),
    en_set_cells_(Grid, HoleCells, Color, Out).

% en_boundary_cells(+Grid, +Color, -Cells): sorted list of Color cells that have
% at least one 4-adjacent cell (in-bounds) with value different from Color, or
% that lie on the grid edge (fewer than 4 in-bounds neighbors).
en_boundary_cells(Grid, Color, Cells) :-
    en_dims_(Grid, NR, NC),
    en_all_color_(Grid, Color, ColorCells),
    include([Cell]>>(
        Cell = CR-CC,
        en_4candidates_(CR, CC, NR, NC, Nbrs),
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

% en_interior_cells(+Grid, +Color, -Cells): sorted list of Color cells that have
% exactly 4 in-bounds neighbors (not on grid edge) and all of them are Color.
en_interior_cells(Grid, Color, Cells) :-
    en_dims_(Grid, NR, NC),
    en_all_color_(Grid, Color, ColorCells),
    include([Cell]>>(
        Cell = CR-CC,
        en_4candidates_(CR, CC, NR, NC, Nbrs),
        length(Nbrs, 4),
        forall(member(N, Nbrs), (
            N = NR2-NC2,
            nth0(NR2, Grid, Row2), nth0(NC2, Row2, NV),
            NV =:= Color
        ))
    ), ColorCells, Cells).

% en_is_surrounded(+Grid, +R, +C, +WallColor): succeed if all 4 orthogonal
% neighbors of cell (R,C) are either out of bounds or have value WallColor.
en_is_surrounded(Grid, R, C, WallColor) :-
    en_dims_(Grid, NR, NC),
% Check all four directions; any in-bounds neighbor must be WallColor.
    forall(member(DR-DC, [-1-0, 1-0, 0-1, 0-(-1)]), (
        NbR is R + DR, NbC is C + DC,
        (0 =< NbR, NbR < NR, 0 =< NbC, NbC < NC ->
            nth0(NbR, Grid, Row), nth0(NbC, Row, V), V =:= WallColor
        ;
            true
        )
    )).
