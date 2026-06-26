% gridmath.pl - Layer 125: Cell-Wise Arithmetic on 2D Grids (gm_* prefix).
% General-purpose predicates for applying arithmetic operations to grids.
:- module(gridmath, [
    gm_add/3, gm_sub/3, gm_mul/3, gm_max/3, gm_min/3,
    gm_scale/3, gm_offset/3, gm_abs/2,
    gm_eq_mask/3, gm_diff_mask/3,
    gm_clamp/4, gm_modulo/3,
    gm_sum/2, gm_product/2
]).
% Import higher-order operations for row-level and cell-level transforms.
:- use_module(library(apply), [maplist/3, maplist/4]).
% Import list utilities for sum and product computation.
:- use_module(library(lists), [member/2, append/2]).

% gm_add(+GridA, +GridB, -GridC): cell-wise sum; GridC[R][C] = GridA[R][C] + GridB[R][C].
gm_add(A, B, C) :-
% Apply row-wise addition using maplist/4 over matching rows.
    maplist(gm_add_row_, A, B, C).
% Per-row helper applies element-wise addition with maplist/4.
gm_add_row_(RA, RB, RC) :-
    maplist(gm_add_, RA, RB, RC).
% Per-cell addition helper.
gm_add_(X, Y, Z) :- Z is X + Y.

% gm_sub(+GridA, +GridB, -GridC): cell-wise difference; GridC[R][C] = GridA[R][C] - GridB[R][C].
gm_sub(A, B, C) :-
% Apply row-wise subtraction using maplist/4 over matching rows.
    maplist(gm_sub_row_, A, B, C).
% Per-row helper applies element-wise subtraction.
gm_sub_row_(RA, RB, RC) :-
    maplist(gm_sub_, RA, RB, RC).
% Per-cell subtraction helper.
gm_sub_(X, Y, Z) :- Z is X - Y.

% gm_mul(+GridA, +GridB, -GridC): cell-wise product; GridC[R][C] = GridA[R][C] * GridB[R][C].
gm_mul(A, B, C) :-
% Apply row-wise multiplication using maplist/4 over matching rows.
    maplist(gm_mul_row_, A, B, C).
% Per-row helper applies element-wise multiplication.
gm_mul_row_(RA, RB, RC) :-
    maplist(gm_mul_, RA, RB, RC).
% Per-cell multiplication helper.
gm_mul_(X, Y, Z) :- Z is X * Y.

% gm_max(+GridA, +GridB, -GridC): cell-wise maximum; GridC[R][C] = max(GridA[R][C], GridB[R][C]).
gm_max(A, B, C) :-
% Apply row-wise maximum using maplist/4 over matching rows.
    maplist(gm_max_row_, A, B, C).
% Per-row helper applies element-wise maximum.
gm_max_row_(RA, RB, RC) :-
    maplist(gm_max_, RA, RB, RC).
% Per-cell maximum helper.
gm_max_(X, Y, Z) :- Z is max(X, Y).

% gm_min(+GridA, +GridB, -GridC): cell-wise minimum; GridC[R][C] = min(GridA[R][C], GridB[R][C]).
gm_min(A, B, C) :-
% Apply row-wise minimum using maplist/4 over matching rows.
    maplist(gm_min_row_, A, B, C).
% Per-row helper applies element-wise minimum.
gm_min_row_(RA, RB, RC) :-
    maplist(gm_min_, RA, RB, RC).
% Per-cell minimum helper.
gm_min_(X, Y, Z) :- Z is min(X, Y).

% gm_scale(+Grid, +K, -Grid2): multiply every cell by scalar K.
gm_scale(Grid, K, Grid2) :-
% Apply per-row scale using maplist/3 with a row-level helper capturing K.
    maplist(gm_scale_row_(K), Grid, Grid2).
% Per-row scale helper applies maplist/3 with a cell helper capturing K.
gm_scale_row_(K, Row, Row2) :-
    maplist(gm_scale_(K), Row, Row2).
% Per-cell scale helper; K captured from outer call.
gm_scale_(K, V, S) :- S is V * K.

% gm_offset(+Grid, +D, -Grid2): add constant D to every cell.
gm_offset(Grid, D, Grid2) :-
% Apply per-row offset using maplist/3 with a row-level helper capturing D.
    maplist(gm_offset_row_(D), Grid, Grid2).
% Per-row offset helper applies maplist/3 with a cell helper capturing D.
gm_offset_row_(D, Row, Row2) :-
    maplist(gm_offset_(D), Row, Row2).
% Per-cell offset helper; D captured from outer call.
gm_offset_(D, V, S) :- S is V + D.

% gm_abs(+Grid, -Grid2): absolute value of every cell.
gm_abs(Grid, Grid2) :-
% Apply per-row abs using maplist/3.
    maplist(gm_abs_row_, Grid, Grid2).
% Per-row abs helper applies maplist/3 with a cell helper.
gm_abs_row_(Row, Row2) :-
    maplist(gm_abs_, Row, Row2).
% Per-cell absolute value helper.
gm_abs_(V, A) :- A is abs(V).

% gm_eq_mask(+GridA, +GridB, -Mask): 1 where cells are equal, 0 where they differ.
gm_eq_mask(A, B, Mask) :-
% Apply row-wise equality test using maplist/4.
    maplist(gm_eq_row_, A, B, Mask).
% Per-row equality helper applies maplist/4 with a cell helper.
gm_eq_row_(RA, RB, RM) :-
    maplist(gm_eq_, RA, RB, RM).
% Per-cell equality helper: 1 on match, 0 otherwise.
gm_eq_(X, X, 1) :- !.
gm_eq_(_, _, 0).

% gm_diff_mask(+GridA, +GridB, -Mask): 1 where cells differ, 0 where they are equal.
gm_diff_mask(A, B, Mask) :-
% Apply row-wise difference test using maplist/4.
    maplist(gm_diff_row_, A, B, Mask).
% Per-row difference helper applies maplist/4 with a cell helper.
gm_diff_row_(RA, RB, RM) :-
    maplist(gm_diff_, RA, RB, RM).
% Per-cell difference helper: 0 on match, 1 otherwise.
gm_diff_(X, X, 0) :- !.
gm_diff_(_, _, 1).

% gm_clamp(+Grid, +Lo, +Hi, -Grid2): clamp each cell to the inclusive range [Lo, Hi].
gm_clamp(Grid, Lo, Hi, Grid2) :-
% Apply per-row clamp using maplist/3 with a row-level helper capturing Lo and Hi.
    maplist(gm_clamp_row_(Lo, Hi), Grid, Grid2).
% Per-row clamp helper applies maplist/3 with a cell helper capturing Lo and Hi.
gm_clamp_row_(Lo, Hi, Row, Row2) :-
    maplist(gm_clamp_(Lo, Hi), Row, Row2).
% Per-cell clamp helper: enforce lower bound then upper bound.
gm_clamp_(Lo, Hi, V, C) :- C is max(Lo, min(Hi, V)).

% gm_modulo(+Grid, +M, -Grid2): apply modulo M to every cell; Grid2[R][C] = Grid[R][C] mod M.
gm_modulo(Grid, M, Grid2) :-
% Apply per-row modulo using maplist/3 with a row-level helper capturing M.
    maplist(gm_modulo_row_(M), Grid, Grid2).
% Per-row modulo helper applies maplist/3 with a cell helper capturing M.
gm_modulo_row_(M, Row, Row2) :-
    maplist(gm_modulo_(M), Row, Row2).
% Per-cell modulo helper; M captured from outer call.
gm_modulo_(M, V, R) :- R is V mod M.

% gm_sum(+Grid, -Sum): sum of all cell values in Grid.
gm_sum(Grid, Sum) :-
% Flatten all rows into one list then sum with findall + member twice.
    findall(V, (member(Row, Grid), member(V, Row)), Vs),
    sumlist_(Vs, Sum).
% Recursive sum accumulator.
sumlist_([], 0).
sumlist_([H|T], S) :-
    sumlist_(T, S0),
    S is S0 + H.

% gm_product(+Grid, -Prod): product of all cell values in Grid.
gm_product(Grid, Prod) :-
% Flatten all rows into one list then compute product.
    findall(V, (member(Row, Grid), member(V, Row)), Vs),
    prodlist_(Vs, Prod).
% Recursive product accumulator.
prodlist_([], 1).
prodlist_([H|T], P) :-
    prodlist_(T, P0),
    P is P0 * H.
