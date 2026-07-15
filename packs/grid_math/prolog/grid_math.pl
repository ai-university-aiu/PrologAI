% gridmath.pl - Layer 125: Cell-Wise Arithmetic on 2D Grids (gm_* prefix).
% General-purpose predicates for applying arithmetic operations to grids.
:- module(grid_math, [
    grid_math_add/3, grid_math_sub/3, grid_math_mul/3, grid_math_max/3, grid_math_min/3,
    grid_math_scale/3, grid_math_offset/3, grid_math_abs/2,
    grid_math_eq_mask/3, grid_math_diff_mask/3,
    grid_math_clamp/4, grid_math_modulo/3,
    grid_math_sum/2, grid_math_product/2
]).
% Import higher-order operations for row-level and cell-level transforms.
:- use_module(library(apply), [maplist/3, maplist/4]).
% Import list utilities for sum and product computation.
:- use_module(library(lists), [member/2, append/2]).

% grid_math_add(+GridA, +GridB, -GridC): cell-wise sum; GridC[R][C] = GridA[R][C] + GridB[R][C].
grid_math_add(A, B, C) :-
% Apply row-wise addition using maplist/4 over matching rows.
    maplist(grid_math_add_row_, A, B, C).
% Per-row helper applies element-wise addition with maplist/4.
grid_math_add_row_(RA, RB, RC) :-
    maplist(grid_math_add_, RA, RB, RC).
% Per-cell addition helper.
grid_math_add_(X, Y, Z) :- Z is X + Y.

% grid_math_sub(+GridA, +GridB, -GridC): cell-wise difference; GridC[R][C] = GridA[R][C] - GridB[R][C].
grid_math_sub(A, B, C) :-
% Apply row-wise subtraction using maplist/4 over matching rows.
    maplist(grid_math_sub_row_, A, B, C).
% Per-row helper applies element-wise subtraction.
grid_math_sub_row_(RA, RB, RC) :-
    maplist(grid_math_sub_, RA, RB, RC).
% Per-cell subtraction helper.
grid_math_sub_(X, Y, Z) :- Z is X - Y.

% grid_math_mul(+GridA, +GridB, -GridC): cell-wise product; GridC[R][C] = GridA[R][C] * GridB[R][C].
grid_math_mul(A, B, C) :-
% Apply row-wise multiplication using maplist/4 over matching rows.
    maplist(grid_math_mul_row_, A, B, C).
% Per-row helper applies element-wise multiplication.
grid_math_mul_row_(RA, RB, RC) :-
    maplist(grid_math_mul_, RA, RB, RC).
% Per-cell multiplication helper.
grid_math_mul_(X, Y, Z) :- Z is X * Y.

% grid_math_max(+GridA, +GridB, -GridC): cell-wise maximum; GridC[R][C] = max(GridA[R][C], GridB[R][C]).
grid_math_max(A, B, C) :-
% Apply row-wise maximum using maplist/4 over matching rows.
    maplist(grid_math_max_row_, A, B, C).
% Per-row helper applies element-wise maximum.
grid_math_max_row_(RA, RB, RC) :-
    maplist(grid_math_max_, RA, RB, RC).
% Per-cell maximum helper.
grid_math_max_(X, Y, Z) :- Z is max(X, Y).

% grid_math_min(+GridA, +GridB, -GridC): cell-wise minimum; GridC[R][C] = min(GridA[R][C], GridB[R][C]).
grid_math_min(A, B, C) :-
% Apply row-wise minimum using maplist/4 over matching rows.
    maplist(grid_math_min_row_, A, B, C).
% Per-row helper applies element-wise minimum.
grid_math_min_row_(RA, RB, RC) :-
    maplist(grid_math_min_, RA, RB, RC).
% Per-cell minimum helper.
grid_math_min_(X, Y, Z) :- Z is min(X, Y).

% grid_math_scale(+Grid, +K, -Grid2): multiply every cell by scalar K.
grid_math_scale(Grid, K, Grid2) :-
% Apply per-row scale using maplist/3 with a row-level helper capturing K.
    maplist(grid_math_scale_row_(K), Grid, Grid2).
% Per-row scale helper applies maplist/3 with a cell helper capturing K.
grid_math_scale_row_(K, Row, Row2) :-
    maplist(grid_math_scale_(K), Row, Row2).
% Per-cell scale helper; K captured from outer call.
grid_math_scale_(K, V, S) :- S is V * K.

% grid_math_offset(+Grid, +D, -Grid2): add constant D to every cell.
grid_math_offset(Grid, D, Grid2) :-
% Apply per-row offset using maplist/3 with a row-level helper capturing D.
    maplist(grid_math_offset_row_(D), Grid, Grid2).
% Per-row offset helper applies maplist/3 with a cell helper capturing D.
grid_math_offset_row_(D, Row, Row2) :-
    maplist(grid_math_offset_(D), Row, Row2).
% Per-cell offset helper; D captured from outer call.
grid_math_offset_(D, V, S) :- S is V + D.

% grid_math_abs(+Grid, -Grid2): absolute value of every cell.
grid_math_abs(Grid, Grid2) :-
% Apply per-row abs using maplist/3.
    maplist(grid_math_abs_row_, Grid, Grid2).
% Per-row abs helper applies maplist/3 with a cell helper.
grid_math_abs_row_(Row, Row2) :-
    maplist(grid_math_abs_, Row, Row2).
% Per-cell absolute value helper.
grid_math_abs_(V, A) :- A is abs(V).

% grid_math_eq_mask(+GridA, +GridB, -Mask): 1 where cells are equal, 0 where they differ.
grid_math_eq_mask(A, B, Mask) :-
% Apply row-wise equality test using maplist/4.
    maplist(grid_math_eq_row_, A, B, Mask).
% Per-row equality helper applies maplist/4 with a cell helper.
grid_math_eq_row_(RA, RB, RM) :-
    maplist(grid_math_eq_, RA, RB, RM).
% Per-cell equality helper: 1 on match, 0 otherwise.
grid_math_eq_(X, X, 1) :- !.
grid_math_eq_(_, _, 0).

% grid_math_diff_mask(+GridA, +GridB, -Mask): 1 where cells differ, 0 where they are equal.
grid_math_diff_mask(A, B, Mask) :-
% Apply row-wise difference test using maplist/4.
    maplist(grid_math_diff_row_, A, B, Mask).
% Per-row difference helper applies maplist/4 with a cell helper.
grid_math_diff_row_(RA, RB, RM) :-
    maplist(grid_math_diff_, RA, RB, RM).
% Per-cell difference helper: 0 on match, 1 otherwise.
grid_math_diff_(X, X, 0) :- !.
grid_math_diff_(_, _, 1).

% grid_math_clamp(+Grid, +Lo, +Hi, -Grid2): clamp each cell to the inclusive range [Lo, Hi].
grid_math_clamp(Grid, Lo, Hi, Grid2) :-
% Apply per-row clamp using maplist/3 with a row-level helper capturing Lo and Hi.
    maplist(grid_math_clamp_row_(Lo, Hi), Grid, Grid2).
% Per-row clamp helper applies maplist/3 with a cell helper capturing Lo and Hi.
grid_math_clamp_row_(Lo, Hi, Row, Row2) :-
    maplist(grid_math_clamp_(Lo, Hi), Row, Row2).
% Per-cell clamp helper: enforce lower bound then upper bound.
grid_math_clamp_(Lo, Hi, V, C) :- C is max(Lo, min(Hi, V)).

% grid_math_modulo(+Grid, +M, -Grid2): apply modulo M to every cell; Grid2[R][C] = Grid[R][C] mod M.
grid_math_modulo(Grid, M, Grid2) :-
% Apply per-row modulo using maplist/3 with a row-level helper capturing M.
    maplist(grid_math_modulo_row_(M), Grid, Grid2).
% Per-row modulo helper applies maplist/3 with a cell helper capturing M.
grid_math_modulo_row_(M, Row, Row2) :-
    maplist(grid_math_modulo_(M), Row, Row2).
% Per-cell modulo helper; M captured from outer call.
grid_math_modulo_(M, V, R) :- R is V mod M.

% grid_math_sum(+Grid, -Sum): sum of all cell values in Grid.
grid_math_sum(Grid, Sum) :-
% Flatten all rows into one list then sum with findall + member twice.
    findall(V, (member(Row, Grid), member(V, Row)), Vs),
    sumlist_(Vs, Sum).
% Recursive sum accumulator.
sumlist_([], 0).
sumlist_([H|T], S) :-
    sumlist_(T, S0),
    S is S0 + H.

% grid_math_product(+Grid, -Prod): product of all cell values in Grid.
grid_math_product(Grid, Prod) :-
% Flatten all rows into one list then compute product.
    findall(V, (member(Row, Grid), member(V, Row)), Vs),
    prodlist_(Vs, Prod).
% Recursive product accumulator.
prodlist_([], 1).
prodlist_([H|T], P) :-
    prodlist_(T, P0),
    P is P0 * H.
