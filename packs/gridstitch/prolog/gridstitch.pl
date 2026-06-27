:- module(gridstitch, [
    gst_concat_h/3,
    gst_concat_v/3,
    gst_hstack/2,
    gst_vstack/2,
    gst_split_h/4,
    gst_split_v/4,
    gst_halves_h/3,
    gst_halves_v/3,
    gst_quadrants/5,
    gst_tile_grid/4,
    gst_add_border/4,
    gst_strip_border/3,
    gst_repeat_h/3,
    gst_repeat_v/3
]).
% gridstitch.pl - Layer 210: Grid Assembly - concatenation, splitting,
% tiling, border addition/removal, and arrangement (gst_* prefix).
% Operates on raw grid format: list of rows, each a list of color atoms, 0-indexed.
:- use_module(library(lists), [
    nth0/3, append/2, append/3
]).

% --- PRIVATE HELPERS ---

% Grid dimensions: H rows, W columns.
gst_dims_(Grid, H, W) :-
% Count rows.
    length(Grid, H),
% Count columns from first row when grid is non-empty.
    (H > 0 -> Grid = [FR|_], length(FR, W) ; W = 0).

% Cell value at row R, column C (0-indexed).
gst_cell_(Grid, R, C, V) :-
% Select row R.
    nth0(R, Grid, Row),
% Select column C.
    nth0(C, Row, V).

% Build a new H x W grid using a lambda Goal(R, C, V).
gst_build_(H, W, Goal, Grid) :-
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
gst_fill_(H, W, Color, Grid) :-
% Each row is W copies of Color.
    length(FillRow, W),
% Unify all elements to Color.
    maplist(=(Color), FillRow),
% Repeat the same row H times.
    length(Grid, H),
    maplist(=(FillRow), Grid).

% --- CONCATENATION ---

% gst_concat_h(+GridA, +GridB, -Result)
% Result is GridA and GridB placed side by side (GridA on left, GridB on right).
% Both grids must have the same number of rows.
gst_concat_h(GridA, GridB, Result) :-
% Get dimensions of both grids.
    gst_dims_(GridA, H, _),
% Verify row counts match.
    gst_dims_(GridB, H, _),
% Append each row pair horizontally.
    maplist([RA, RB, RC]>>(append(RA, RB, RC)), GridA, GridB, Result).

% gst_concat_v(+GridA, +GridB, -Result)
% Result is GridA stacked on top of GridB (GridA rows first, then GridB rows).
% Both grids must have the same number of columns.
gst_concat_v(GridA, GridB, Result) :-
% Verify column counts match.
    gst_dims_(GridA, _, W),
% Check GridB column count matches.
    gst_dims_(GridB, _, W),
% Append row lists vertically.
    append(GridA, GridB, Result).

% gst_hstack(+Grids, -Result)
% Result is all grids in Grids placed side by side left to right.
% All grids must have the same number of rows.
gst_hstack([], []).
gst_hstack([G], G) :- !.
gst_hstack([G1, G2 | Rest], Result) :-
% Combine the first two grids.
    gst_concat_h(G1, G2, G12),
% Recurse on the combined grid and the remainder.
    gst_hstack([G12 | Rest], Result).

% gst_vstack(+Grids, -Result)
% Result is all grids in Grids stacked top to bottom.
% All grids must have the same number of columns.
gst_vstack([], []).
gst_vstack([G], G) :- !.
gst_vstack([G1, G2 | Rest], Result) :-
% Combine the first two grids.
    gst_concat_v(G1, G2, G12),
% Recurse on the combined grid and the remainder.
    gst_vstack([G12 | Rest], Result).

% --- SPLITTING ---

% gst_split_h(+Grid, +R, -Top, -Bottom)
% Split Grid horizontally at row R: Top has rows 0..R-1, Bottom has rows R..H-1.
% R must be in [1, H-1].
gst_split_h(Grid, R, Top, Bottom) :-
% Take first R rows as Top.
    length(Top, R),
% Append Top and Bottom to reconstruct Grid.
    append(Top, Bottom, Grid).

% gst_split_v(+Grid, +C, -Left, -Right)
% Split Grid vertically at column C: Left has columns 0..C-1, Right has C..W-1.
% C must be in [1, W-1].
gst_split_v(Grid, C, Left, Right) :-
% Split each row at column C.
    maplist([Row, LRow, RRow]>>(length(LRow, C), append(LRow, RRow, Row)),
            Grid, Left, Right).

% gst_halves_h(+Grid, -Top, -Bottom)
% Split Grid into equal top and bottom halves. Grid must have even row count.
gst_halves_h(Grid, Top, Bottom) :-
% Get row count.
    gst_dims_(Grid, H, _),
% Compute half.
    Half is H // 2,
% Split at the midpoint.
    gst_split_h(Grid, Half, Top, Bottom).

% gst_halves_v(+Grid, -Left, -Right)
% Split Grid into equal left and right halves. Grid must have even column count.
gst_halves_v(Grid, Left, Right) :-
% Get column count.
    gst_dims_(Grid, _, W),
% Compute half.
    Half is W // 2,
% Split at the midpoint.
    gst_split_v(Grid, Half, Left, Right).

% gst_quadrants(+Grid, -TL, -TR, -BL, -BR)
% Split Grid into four quadrants: top-left, top-right, bottom-left, bottom-right.
% Grid must have even row and column counts.
gst_quadrants(Grid, TL, TR, BL, BR) :-
% Split into top and bottom halves first.
    gst_halves_h(Grid, Top, Bottom),
% Split top half into left and right.
    gst_halves_v(Top, TL, TR),
% Split bottom half into left and right.
    gst_halves_v(Bottom, BL, BR).

% --- TILING AND ARRANGEMENT ---

% gst_tile_grid(+SubGrids, +NR, +NC, -Result)
% Arrange SubGrids (a list of NR*NC grids in row-major order) into an NR x NC layout.
% All sub-grids must have the same dimensions.
gst_tile_grid(SubGrids, NR, NC, Result) :-
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
         gst_hstack(RowSubs, Band)),
        Bands),
% Stack all bands vertically.
    gst_vstack(Bands, Result).

% gst_repeat_h(+Grid, +N, -Result)
% Result is Grid repeated N times horizontally (side by side).
gst_repeat_h(Grid, N, Result) :-
% Build a list of N copies.
    findall(Grid, between(1, N, _), Copies),
% Stack horizontally.
    gst_hstack(Copies, Result).

% gst_repeat_v(+Grid, +N, -Result)
% Result is Grid repeated N times vertically (stacked).
gst_repeat_v(Grid, N, Result) :-
% Build a list of N copies.
    findall(Grid, between(1, N, _), Copies),
% Stack vertically.
    gst_vstack(Copies, Result).

% --- BORDER OPERATIONS ---

% gst_add_border(+Grid, +N, +Color, -Result)
% Result is Grid with an N-cell-wide border of Color added on all four sides.
gst_add_border(Grid, N, Color, Result) :-
% Get original dimensions.
    gst_dims_(Grid, H, W),
% New dimensions include border on each side.
    NewH is H + 2 * N,
% New width includes border on each side.
    NewW is W + 2 * N,
% Build result: border cells get Color, interior cells copy from Grid.
    gst_build_(NewH, NewW,
        [R, C, V]>>(OR is R - N, OC is C - N,
                    (OR >= 0, OR < H, OC >= 0, OC < W ->
                        gst_cell_(Grid, OR, OC, V)
                    ;
                        V = Color)),
        Result).

% gst_strip_border(+Grid, +N, -Result)
% Result is Grid with N cells removed from all four sides (interior only).
% Grid must be at least (2*N+1) x (2*N+1).
gst_strip_border(Grid, N, Result) :-
% Get original dimensions.
    gst_dims_(Grid, H, W),
% New dimensions after stripping.
    NewH is H - 2 * N,
% New width after stripping.
    NewW is W - 2 * N,
% Extract the interior sub-region.
    gst_build_(NewH, NewW,
        [R, C, V]>>(OR is R + N, OC is C + N, gst_cell_(Grid, OR, OC, V)),
        Result).
