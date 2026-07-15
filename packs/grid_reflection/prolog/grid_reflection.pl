:- module(grid_reflection, [
    grid_reflection_flip_h/2,
    grid_reflection_flip_v/2,
    grid_reflection_rot90/2,
    grid_reflection_rot180/2,
    grid_reflection_rot270/2,
    grid_reflection_transpose/2,
    grid_reflection_antidiag/2,
    grid_reflection_is_sym_h/1,
    grid_reflection_is_sym_v/1,
    grid_reflection_is_sym_d/1,
    grid_reflection_is_sym_a/1,
    grid_reflection_sym_axes/2,
    grid_reflection_make_sym_h/3,
    grid_reflection_make_sym_v/3
]).
% gridrefl.pl - Layer 232: Grid Reflection and Rotation (grf_* prefix).
% Fourteen predicates for geometric transformations of symbolic grids:
% horizontal and vertical flips, 90/180/270 rotations, main-diagonal
% transpose, anti-diagonal transpose, symmetry detection on all four axes,
% listing all symmetry axes, and symmetry completion.
% Raw grid format: list of rows, each a list of color atoms, 0-indexed.
% No cross-pack dependencies.
:- use_module(library(lists), [member/2, reverse/2, nth0/3]).

% --- PRIVATE HELPERS ---

% grid_reflection_transpose_/2: transpose a rectangular grid (swap rows and columns).
% Cuts on base cases prevent choicepoint warnings from PLUnit.
grid_reflection_transpose_([], []) :- !.
grid_reflection_transpose_([[]|_], []) :- !.
grid_reflection_transpose_(Grid, [Row|Rows]) :-
% Peel the first element of each row to form the first output row.
    grid_reflection_heads_tails_(Grid, Row, Tails),
% Recurse on the remaining columns.
    grid_reflection_transpose_(Tails, Rows).

% grid_reflection_heads_tails_/3: split a list of non-empty rows into heads and tails.
grid_reflection_heads_tails_([], [], []).
grid_reflection_heads_tails_([[H|T]|Rest], [H|Hs], [T|Ts]) :-
    grid_reflection_heads_tails_(Rest, Hs, Ts).

% grid_reflection_merge_rows_/4: merge two rows cell by cell; non-bg beats bg.
% When both are bg the cell stays bg; when both are non-bg, the first wins.
grid_reflection_merge_rows_([], [], _, []).
grid_reflection_merge_rows_([V1|T1], [V2|T2], Bg, [V|Rest]) :-
% First cell wins if non-bg; otherwise mirror wins; otherwise bg.
    (V1 \= Bg -> V = V1 ; V2 \= Bg -> V = V2 ; V = Bg),
    grid_reflection_merge_rows_(T1, T2, Bg, Rest).

% --- PUBLIC PREDICATES ---

% grid_reflection_flip_h(+Grid, -Flipped)
% Reverse each row (left-right mirror of the grid).
grid_reflection_flip_h(Grid, Flipped) :-
% Collect reversed rows.
    findall(RevRow, (member(Row, Grid), reverse(Row, RevRow)), Flipped).

% grid_reflection_flip_v(+Grid, -Flipped)
% Reverse the list of rows (top-bottom mirror of the grid).
grid_reflection_flip_v(Grid, Flipped) :-
% Reverse the row order.
    reverse(Grid, Flipped).

% grid_reflection_rot90(+Grid, -Rotated)
% Rotate the grid 90 degrees clockwise.
% Equivalent to transpose then flip_h.
grid_reflection_rot90(Grid, Rotated) :-
% Transpose: rows become columns.
    grid_reflection_transpose_(Grid, T),
% Flip left-right to complete the 90-degree clockwise rotation.
    grid_reflection_flip_h(T, Rotated).

% grid_reflection_rot180(+Grid, -Rotated)
% Rotate the grid 180 degrees.
% Equivalent to flip_v then flip_h (or two successive rot90 steps).
grid_reflection_rot180(Grid, Rotated) :-
% Flip top-bottom first.
    grid_reflection_flip_v(Grid, V),
% Then flip left-right.
    grid_reflection_flip_h(V, Rotated).

% grid_reflection_rot270(+Grid, -Rotated)
% Rotate the grid 270 degrees clockwise (equivalent to 90 degrees counter-clockwise).
% Equivalent to flip_h then transpose.
grid_reflection_rot270(Grid, Rotated) :-
% Flip left-right first.
    grid_reflection_flip_h(Grid, FH),
% Transpose to complete the 90-degree counter-clockwise rotation.
    grid_reflection_transpose_(FH, Rotated).

% grid_reflection_transpose(+Grid, -Transposed)
% Transpose the grid: rows become columns, columns become rows.
grid_reflection_transpose(Grid, Transposed) :-
% Delegate to the private transpose helper.
    grid_reflection_transpose_(Grid, Transposed).

% grid_reflection_antidiag(+Grid, -AntiDiag)
% Reflect the grid across the anti-diagonal (from top-right to bottom-left).
% Equivalent to rot180 then transpose.
% AntiDiag[R][C] = Grid[N-1-C][N-1-R] for square NxN grids.
grid_reflection_antidiag(Grid, AntiDiag) :-
% Rotate 180 degrees.
    grid_reflection_rot180(Grid, R180),
% Transpose the rotated grid to produce the anti-diagonal reflection.
    grid_reflection_transpose_(R180, AntiDiag).

% grid_reflection_is_sym_h(+Grid)
% Succeed if Grid is horizontally symmetric (left-right mirror of itself).
grid_reflection_is_sym_h(Grid) :-
% The grid equals its horizontal flip if and only if each row is a palindrome.
    grid_reflection_flip_h(Grid, Grid).

% grid_reflection_is_sym_v(+Grid)
% Succeed if Grid is vertically symmetric (top-bottom mirror of itself).
grid_reflection_is_sym_v(Grid) :-
% The grid equals its vertical flip if and only if the row list is a palindrome.
    reverse(Grid, Grid).

% grid_reflection_is_sym_d(+Grid)
% Succeed if Grid is symmetric across the main diagonal (Grid = transpose(Grid)).
% Only meaningful for square grids; fails for non-square grids with distinct values.
grid_reflection_is_sym_d(Grid) :-
% The grid equals its own transpose if and only if it is diagonally symmetric.
    grid_reflection_transpose_(Grid, Grid).

% grid_reflection_is_sym_a(+Grid)
% Succeed if Grid is symmetric across the anti-diagonal (Grid = antidiag(Grid)).
% Only meaningful for square grids.
grid_reflection_is_sym_a(Grid) :-
% The grid equals its own anti-diagonal reflection if and only if it is anti-sym.
    grid_reflection_antidiag(Grid, Grid).

% grid_reflection_sym_axes(+Grid, -Axes)
% Return the list of symmetry axes that Grid satisfies.
% Axes is a subset of [h, v, d, a] in that order.
grid_reflection_sym_axes(Grid, Axes) :-
% Collect each axis label where the corresponding symmetry test succeeds.
    findall(A,
        ((A = h, grid_reflection_is_sym_h(Grid)) ;
         (A = v, grid_reflection_is_sym_v(Grid)) ;
         (A = d, grid_reflection_is_sym_d(Grid)) ;
         (A = a, grid_reflection_is_sym_a(Grid))),
        Axes).

% grid_reflection_make_sym_h(+Grid, +BgColor, -Sym)
% Make Grid horizontally symmetric by merging each row with its reversal.
% Non-BgColor cells override BgColor cells; when both sides are non-bg, left wins.
grid_reflection_make_sym_h(Grid, Bg, Sym) :-
% For each row, merge it with its own reverse to fill bg cells from the mirror.
    findall(NewRow,
        (member(Row, Grid),
         reverse(Row, Rev),
         grid_reflection_merge_rows_(Row, Rev, Bg, NewRow)),
        Sym).

% grid_reflection_make_sym_v(+Grid, +BgColor, -Sym)
% Make Grid vertically symmetric by merging each row with its mirror row.
% Non-BgColor cells override BgColor cells; when both sides are non-bg, top wins.
grid_reflection_make_sym_v(Grid, Bg, Sym) :-
% Compute the last row index.
    length(Grid, H), H1 is H - 1,
% For each row index R, merge row R with row (H1-R).
    findall(NewRow,
        (between(0, H1, R),
         MR is H1 - R,
         nth0(R, Grid, Row),
         nth0(MR, Grid, MirRow),
         grid_reflection_merge_rows_(Row, MirRow, Bg, NewRow)),
        Sym).
