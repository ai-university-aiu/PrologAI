:- module(gridflood, [
    gf_fill/5,
    gf_fill8/5,
    gf_recolor/4,
    gf_isolate/5,
    gf_region_cells/4,
    gf_region_size/4,
    gf_region_bbox/7,
    gf_enclosed_cells/3,
    gf_fill_enclosed/4,
    gf_components/3,
    gf_n_components/3,
    gf_largest/3,
    gf_is_connected/3,
    gf_boundary_fill/6
]).
% gridflood.pl - Layer 204: Grid Flood-Fill, Region Analysis, Hole Filling,
% and Connected Components (gf_* prefix).
% All predicates operate on raw grid format: list of rows, each row a list
% of color atoms, 0-indexed (row 0 = top, col 0 = left).
% A "region" is a maximal set of 4-connected cells sharing the same color.
:- use_module(library(lists), [
    nth0/3, member/2, memberchk/2, append/2, append/3,
    list_to_set/2, subtract/3, min_list/2, max_list/2
]).
:- use_module(library(apply), [foldl/4]).

% --- PRIVATE HELPERS ---

% Grid dimensions: H rows, W columns.
gf_dims_(Grid, H, W) :-
% Count rows.
    length(Grid, H),
% Count columns from first row; 0 for empty grid.
    (H > 0 -> Grid = [FR|_], length(FR, W) ; W = 0).

% Cell value at (R, C).
gf_cell_(Grid, R, C, V) :-
    nth0(R, Grid, Row), nth0(C, Row, V).

% BFS: collect all 4-connected cells reachable from Queue that share Color.
gf_bfs4_(_, _, _, _, [], Acc, Acc) :- !.
gf_bfs4_(Grid, H, W, Color, [R-C|Q], Acc, Result) :-
% Skip if already visited.
    (memberchk(R-C, Acc) ->
        gf_bfs4_(Grid, H, W, Color, Q, Acc, Result)
    ;
% Mark visited and find unvisited 4-neighbors of same Color.
        Acc1 = [R-C|Acc],
        findall(NR-NC,
            (member(DR-DC, [(-1)-0, 1-0, 0-(-1), 0-1]),
             NR is R + DR, NC is C + DC,
             NR >= 0, NR < H, NC >= 0, NC < W,
             \+ memberchk(NR-NC, Acc1),
             gf_cell_(Grid, NR, NC, Color)),
            Nbrs),
        append(Q, Nbrs, Q1),
        gf_bfs4_(Grid, H, W, Color, Q1, Acc1, Result)
    ).

% BFS: collect all 8-connected cells reachable from Queue that share Color.
gf_bfs8_(_, _, _, _, [], Acc, Acc) :- !.
gf_bfs8_(Grid, H, W, Color, [R-C|Q], Acc, Result) :-
    (memberchk(R-C, Acc) ->
        gf_bfs8_(Grid, H, W, Color, Q, Acc, Result)
    ;
        Acc1 = [R-C|Acc],
        findall(NR-NC,
            (member(DR-DC, [(-1)-0, 1-0, 0-(-1), 0-1,
                            (-1)-(-1), (-1)-1, 1-(-1), 1-1]),
             NR is R + DR, NC is C + DC,
             NR >= 0, NR < H, NC >= 0, NC < W,
             \+ memberchk(NR-NC, Acc1),
             gf_cell_(Grid, NR, NC, Color)),
            Nbrs),
        append(Q, Nbrs, Q1),
        gf_bfs8_(Grid, H, W, Color, Q1, Acc1, Result)
    ).

% Rebuild Grid setting every cell in RegionCells to NewColor; others unchanged.
gf_set_cells_(Grid, RegionCells, NewColor, Result) :-
    gf_dims_(Grid, H, W),
    H1 is H - 1, W1 is W - 1,
    findall(NewRow,
        (between(0, H1, R),
         nth0(R, Grid, OrigRow),
         findall(V,
             (between(0, W1, C),
              (memberchk(R-C, RegionCells) ->
                  V = NewColor
              ;
                  nth0(C, OrigRow, V))),
             NewRow)),
        Result).

% Fold helper for gf_largest: keep the longer of two region lists.
gf_keep_larger_(Region, Best, Winner) :-
    length(Region, L), length(Best, BL),
% Strictly longer replaces the current best; ties keep the earlier one.
    (L > BL -> Winner = Region ; Winner = Best).

% Iteratively extract one connected component at a time from remaining cells.
gf_extract_components_(_, _, _, _, [], []) :- !.
gf_extract_components_(Grid, H, W, Color, [Seed|Rest], [Region|Components]) :-
    gf_bfs4_(Grid, H, W, Color, [Seed], [], Region),
    subtract(Rest, Region, Remaining),
    gf_extract_components_(Grid, H, W, Color, Remaining, Components).

% --- EXPORTED PREDICATES ---

% gf_fill(+Grid, +R, +C, +NewColor, -Result)
% Result is Grid with the 4-connected same-color region at (R,C) replaced by NewColor.
% If Grid[R][C] already equals NewColor, Result = Grid (no-op).
gf_fill(Grid, R, C, NewColor, Result) :-
    gf_cell_(Grid, R, C, SeedColor),
    (SeedColor = NewColor ->
        Result = Grid
    ;
        gf_dims_(Grid, H, W),
        gf_bfs4_(Grid, H, W, SeedColor, [R-C], [], Region),
        gf_set_cells_(Grid, Region, NewColor, Result)
    ).

% gf_fill8(+Grid, +R, +C, +NewColor, -Result)
% Result is Grid with the 8-connected same-color region at (R,C) replaced by NewColor.
gf_fill8(Grid, R, C, NewColor, Result) :-
    gf_cell_(Grid, R, C, SeedColor),
    (SeedColor = NewColor ->
        Result = Grid
    ;
        gf_dims_(Grid, H, W),
        gf_bfs8_(Grid, H, W, SeedColor, [R-C], [], Region),
        gf_set_cells_(Grid, Region, NewColor, Result)
    ).

% gf_recolor(+Grid, +OldColor, +NewColor, -Result)
% Result is Grid with every cell of OldColor replaced by NewColor, regardless
% of connectivity (global palette swap).
gf_recolor(Grid, OldColor, NewColor, Result) :-
    gf_dims_(Grid, H, W),
    H1 is H - 1, W1 is W - 1,
    findall(NewRow,
        (between(0, H1, R),
         nth0(R, Grid, OrigRow),
         findall(V,
             (between(0, W1, C),
              nth0(C, OrigRow, Orig),
              (Orig = OldColor -> V = NewColor ; V = Orig)),
             NewRow)),
        Result).

% gf_isolate(+Grid, +R, +C, +BgColor, -Result)
% Result keeps the 4-connected region at (R,C) intact and sets all other cells
% to BgColor. Useful for extracting a single region onto a blank background.
gf_isolate(Grid, R, C, BgColor, Result) :-
    gf_cell_(Grid, R, C, SeedColor),
    gf_dims_(Grid, H, W),
    gf_bfs4_(Grid, H, W, SeedColor, [R-C], [], RegionCells),
    H1 is H - 1, W1 is W - 1,
    findall(NewRow,
        (between(0, H1, RowR),
         nth0(RowR, Grid, OrigRow),
         findall(V,
             (between(0, W1, ColC),
              (memberchk(RowR-ColC, RegionCells) ->
                  nth0(ColC, OrigRow, V)
              ;
                  V = BgColor)),
             NewRow)),
        Result).

% gf_region_cells(+Grid, +R, +C, -Cells)
% Cells is the list of R-C coordinates of the 4-connected same-color region
% at (R,C), returned in BFS discovery order.
gf_region_cells(Grid, R, C, Cells) :-
    gf_cell_(Grid, R, C, SeedColor),
    gf_dims_(Grid, H, W),
    gf_bfs4_(Grid, H, W, SeedColor, [R-C], [], Cells).

% gf_region_size(+Grid, +R, +C, -N)
% N is the number of cells in the 4-connected same-color region at (R,C).
gf_region_size(Grid, R, C, N) :-
    gf_region_cells(Grid, R, C, Cells),
    length(Cells, N).

% gf_region_bbox(+Grid, +R, +C, -MinR, -MinC, -MaxR, -MaxC)
% Bounding box of the 4-connected region at (R,C).
% Row range [MinR..MaxR], column range [MinC..MaxC].
gf_region_bbox(Grid, R, C, MinR, MinC, MaxR, MaxC) :-
    gf_region_cells(Grid, R, C, Cells),
    findall(PR, member(PR-_, Cells), Rows),
    findall(PC, member(_-PC, Cells), Cols),
    min_list(Rows, MinR), max_list(Rows, MaxR),
    min_list(Cols, MinC), max_list(Cols, MaxC).

% gf_enclosed_cells(+Grid, +BgColor, -Enclosed)
% Enclosed is the list of BgColor cells unreachable from the grid border via
% 4-connected BgColor paths; i.e., "holes" completely surrounded by other colors.
gf_enclosed_cells(Grid, BgColor, Enclosed) :-
    gf_dims_(Grid, H, W),
    H1 is H - 1, W1 is W - 1,
% Seed BFS from every border cell whose color is BgColor.
    findall(R-C,
        ((R = 0 ; R = H1 ; C = 0 ; C = W1),
         between(0, H1, R),
         between(0, W1, C),
         gf_cell_(Grid, R, C, BgColor)),
        BorderSeeds),
    list_to_set(BorderSeeds, BorderSeeds1),
% BFS spreads to all BgColor cells reachable from the border.
    gf_bfs4_(Grid, H, W, BgColor, BorderSeeds1, [], Reachable),
% All BgColor cells not reached are enclosed.
    findall(R-C,
        (between(0, H1, R),
         between(0, W1, C),
         gf_cell_(Grid, R, C, BgColor),
         \+ memberchk(R-C, Reachable)),
        Enclosed).

% gf_fill_enclosed(+Grid, +BgColor, +FillColor, -Result)
% Result is Grid with every enclosed BgColor cell replaced by FillColor.
% Border-reachable BgColor cells are left unchanged.
gf_fill_enclosed(Grid, BgColor, FillColor, Result) :-
    gf_enclosed_cells(Grid, BgColor, Enclosed),
    gf_set_cells_(Grid, Enclosed, FillColor, Result).

% gf_components(+Grid, +Color, -Components)
% Components is a list of cell-lists, one per 4-connected region of Color.
% Within each sub-list cells are in BFS order; regions are in top-left order.
gf_components(Grid, Color, Components) :-
    gf_dims_(Grid, H, W),
    H1 is H - 1, W1 is W - 1,
    findall(R-C,
        (between(0, H1, R),
         between(0, W1, C),
         gf_cell_(Grid, R, C, Color)),
        AllCells),
    gf_extract_components_(Grid, H, W, Color, AllCells, Components).

% gf_n_components(+Grid, +Color, -N)
% N is the count of 4-connected Color regions.
gf_n_components(Grid, Color, N) :-
    gf_components(Grid, Color, Components),
    length(Components, N).

% gf_largest(+Grid, +Color, -Cells)
% Cells is the cell-list for the largest 4-connected Color region.
% Ties are broken in favor of the first region encountered (top-left seed).
% Fails if no Color cells exist.
gf_largest(Grid, Color, Cells) :-
    gf_components(Grid, Color, [First|Rest]),
    foldl(gf_keep_larger_, Rest, First, Cells).

% gf_is_connected(+Grid, +Color, +Connectivity)
% Succeeds if all Color cells form at most one connected region.
% Connectivity must be 4 or 8. Vacuously true for 0 Color cells.
gf_is_connected(Grid, Color, 4) :- !,
    gf_n_components(Grid, Color, N),
    N =< 1.
gf_is_connected(Grid, Color, 8) :-
    gf_dims_(Grid, H, W),
    H1 is H - 1, W1 is W - 1,
    findall(R-C,
        (between(0, H1, R), between(0, W1, C), gf_cell_(Grid, R, C, Color)),
        AllCells),
    (AllCells = [] -> true ;
        AllCells = [Seed|_],
        gf_bfs8_(Grid, H, W, Color, [Seed], [], Region),
        length(AllCells, N), length(Region, N)
    ).

% gf_boundary_fill(+Grid, +R, +C, +BoundaryColor, +FillColor, -Result)
% Result is Grid with the 4-connected same-color region at (R,C) replaced by
% FillColor. Cells of BoundaryColor or any other color act as walls. If the
% seed cell is itself BoundaryColor, Result = Grid (no-op).
gf_boundary_fill(Grid, R, C, BoundaryColor, FillColor, Result) :-
    gf_cell_(Grid, R, C, SeedColor),
    (SeedColor = BoundaryColor ->
        Result = Grid
    ;
        gf_dims_(Grid, H, W),
        gf_bfs4_(Grid, H, W, SeedColor, [R-C], [], Region),
        gf_set_cells_(Grid, Region, FillColor, Result)
    ).
