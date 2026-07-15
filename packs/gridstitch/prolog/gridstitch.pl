:- module(gridstitch, [
    gridstitch_concat_h/3,
    gridstitch_concat_v/3,
    gridstitch_hstack/2,
    gridstitch_vstack/2,
    gridstitch_split_h/4,
    gridstitch_split_v/4,
    gridstitch_halves_h/3,
    gridstitch_halves_v/3,
    gridstitch_quadrants/5,
    gridstitch_tile_grid/4,
    gridstitch_add_border/4,
    gridstitch_strip_border/3,
    gridstitch_repeat_h/3,
    gridstitch_repeat_v/3
]).
% gridstitch.pl - Layer 210: Grid Assembly - concatenation, splitting,
% tiling, border addition/removal, and arrangement (gst_* prefix).
% Operates on raw grid format: list of rows, each a list of color atoms, 0-indexed.
:- use_module(library(lists), [
    nth0/3, append/2, append/3
]).

% --- PRIVATE HELPERS ---

% Grid dimensions: H rows, W columns.
gridstitch_dims_(Grid, H, W) :-
% Count rows.
    length(Grid, H),
% Count columns from first row when grid is non-empty.
    (H > 0 -> Grid = [FR|_], length(FR, W) ; W = 0).

% Cell value at row R, column C (0-indexed).
gridstitch_cell_(Grid, R, C, V) :-
% Select row R.
    nth0(R, Grid, Row),
% Select column C.
    nth0(C, Row, V).

% Build a new H x W grid using a lambda Goal(R, C, V).
gridstitch_build_(H, W, Goal, Grid) :-
% Compute last row and column indices.
    H1 is H - 1,
% Compute last column index.
    W1 is W - 1,
% Collect rows.
    findall(Row,
        (between(0, H1, R),
         findall(V, (between(0, W1, C), call(Goal, R, C, V)), Row)),
        Grid).

% Build a constant-fill H x W grid with all cells set to Color.
gridstitch_fill_(H, W, Color, Grid) :-
% Each row is W copies of Color.
    length(FillRow, W),
% Unify all elements to Color.
    maplist(=(Color), FillRow),
% Repeat the same row H times.
    length(Grid, H),
    maplist(=(FillRow), Grid).

% --- CONCATENATION ---

% gridstitch_concat_h(+GridA, +GridB, -Result)
% Result is GridA and GridB placed side by side (GridA on left, GridB on right).
% Both grids must have the same number of rows.
gridstitch_concat_h(GridA, GridB, Result) :-
% Get dimensions of both grids.
    gridstitch_dims_(GridA, H, _),
% Verify row counts match.
    gridstitch_dims_(GridB, H, _),
% Append each row pair horizontally.
    maplist([RA, RB, RC]>>(append(RA, RB, RC)), GridA, GridB, Result).

% gridstitch_concat_v(+GridA, +GridB, -Result)
% Result is GridA stacked on top of GridB (GridA rows first, then GridB rows).
% Both grids must have the same number of columns.
gridstitch_concat_v(GridA, GridB, Result) :-
% Verify column counts match.
    gridstitch_dims_(GridA, _, W),
% Check GridB column count matches.
    gridstitch_dims_(GridB, _, W),
% Append row lists vertically.
    append(GridA, GridB, Result).

% gridstitch_hstack(+Grids, -Result)
% Result is all grids in Grids placed side by side left to right.
% All grids must have the same number of rows.
gridstitch_hstack([], []).
gridstitch_hstack([G], G) :- !.
gridstitch_hstack([G1, G2 | Rest], Result) :-
% Combine the first two grids.
    gridstitch_concat_h(G1, G2, G12),
% Recurse on the combined grid and the remainder.
    gridstitch_hstack([G12 | Rest], Result).

% gridstitch_vstack(+Grids, -Result)
% Result is all grids in Grids stacked top to bottom.
% All grids must have the same number of columns.
gridstitch_vstack([], []).
gridstitch_vstack([G], G) :- !.
gridstitch_vstack([G1, G2 | Rest], Result) :-
% Combine the first two grids.
    gridstitch_concat_v(G1, G2, G12),
% Recurse on the combined grid and the remainder.
    gridstitch_vstack([G12 | Rest], Result).

% --- SPLITTING ---

% gridstitch_split_h(+Grid, +R, -Top, -Bottom)
% Split Grid horizontally at row R: Top has rows 0..R-1, Bottom has rows R..H-1.
% R must be in [1, H-1].
gridstitch_split_h(Grid, R, Top, Bottom) :-
% Take first R rows as Top.
    length(Top, R),
% Append Top and Bottom to reconstruct Grid.
    append(Top, Bottom, Grid).

% gridstitch_split_v(+Grid, +C, -Left, -Right)
% Split Grid vertically at column C: Left has columns 0..C-1, Right has C..W-1.
% C must be in [1, W-1].
gridstitch_split_v(Grid, C, Left, Right) :-
% Split each row at column C.
    maplist([Row, LRow, RRow]>>(length(LRow, C), append(LRow, RRow, Row)),
            Grid, Left, Right).

% gridstitch_halves_h(+Grid, -Top, -Bottom)
% Split Grid into equal top and bottom halves. Grid must have even row count.
gridstitch_halves_h(Grid, Top, Bottom) :-
% Get row count.
    gridstitch_dims_(Grid, H, _),
% Compute half.
    Half is H // 2,
% Split at the midpoint.
    gridstitch_split_h(Grid, Half, Top, Bottom).

% gridstitch_halves_v(+Grid, -Left, -Right)
% Split Grid into equal left and right halves. Grid must have even column count.
gridstitch_halves_v(Grid, Left, Right) :-
% Get column count.
    gridstitch_dims_(Grid, _, W),
% Compute half.
    Half is W // 2,
% Split at the midpoint.
    gridstitch_split_v(Grid, Half, Left, Right).

% gridstitch_quadrants(+Grid, -TL, -TR, -BL, -BR)
% Split Grid into four quadrants: top-left, top-right, bottom-left, bottom-right.
% Grid must have even row and column counts.
gridstitch_quadrants(Grid, TL, TR, BL, BR) :-
% Split into top and bottom halves first.
    gridstitch_halves_h(Grid, Top, Bottom),
% Split top half into left and right.
    gridstitch_halves_v(Top, TL, TR),
% Split bottom half into left and right.
    gridstitch_halves_v(Bottom, BL, BR).

% --- TILING AND ARRANGEMENT ---

% gridstitch_tile_grid(+SubGrids, +NR, +NC, -Result)
% Arrange SubGrids (a list of NR*NC grids in row-major order) into an NR x NC layout.
% All sub-grids must have the same dimensions.
gridstitch_tile_grid(SubGrids, NR, NC, Result) :-
% Check we have exactly NR*NC sub-grids.
    NTotal is NR * NC,
% Verify length.
    length(SubGrids, NTotal),
% Collect NR row-bands (each is one horizontal strip of NC sub-grids).
    findall(Band,
        (between(1, NR, RowIdx),
         Start is (RowIdx - 1) * NC,
         findall(SG, (between(0, NC, ColOffset), ColOffset < NC,
                      Pos is Start + ColOffset, nth0(Pos, SubGrids, SG)),
                 RowSubs),
         gridstitch_hstack(RowSubs, Band)),
        Bands),
% Stack all bands vertically.
    gridstitch_vstack(Bands, Result).

% gridstitch_repeat_h(+Grid, +N, -Result)
% Result is Grid repeated N times horizontally (side by side).
gridstitch_repeat_h(Grid, N, Result) :-
% Build a list of N copies.
    findall(Grid, between(1, N, _), Copies),
% Stack horizontally.
    gridstitch_hstack(Copies, Result).

% gridstitch_repeat_v(+Grid, +N, -Result)
% Result is Grid repeated N times vertically (stacked).
gridstitch_repeat_v(Grid, N, Result) :-
% Build a list of N copies.
    findall(Grid, between(1, N, _), Copies),
% Stack vertically.
    gridstitch_vstack(Copies, Result).

% --- BORDER OPERATIONS ---

% gridstitch_add_border(+Grid, +N, +Color, -Result)
% Result is Grid with an N-cell-wide border of Color added on all four sides.
gridstitch_add_border(Grid, N, Color, Result) :-
% Get original dimensions.
    gridstitch_dims_(Grid, H, W),
% New dimensions include border on each side.
    NewH is H + 2 * N,
% New width includes border on each side.
    NewW is W + 2 * N,
% Build result: border cells get Color, interior cells copy from Grid.
    gridstitch_build_(NewH, NewW,
        [R, C, V]>>(OR is R - N, OC is C - N,
                    (OR >= 0, OR < H, OC >= 0, OC < W ->
                        gridstitch_cell_(Grid, OR, OC, V)
                    ;
                        V = Color)),
        Result).

% gridstitch_strip_border(+Grid, +N, -Result)
% Result is Grid with N cells removed from all four sides (interior only).
% Grid must be at least (2*N+1) x (2*N+1).
gridstitch_strip_border(Grid, N, Result) :-
% Get original dimensions.
    gridstitch_dims_(Grid, H, W),
% New dimensions after stripping.
    NewH is H - 2 * N,
% New width after stripping.
    NewW is W - 2 * N,
% Extract the interior sub-region.
    gridstitch_build_(NewH, NewW,
        [R, C, V]>>(OR is R + N, OC is C + N, gridstitch_cell_(Grid, OR, OC, V)),
        Result).
