% extrema.pl - Layer 133: 2D Grid Extrema, Local Peaks, and Threshold Filtering (ex_* prefix).
% General-purpose predicates for finding maximum and minimum values and their positions,
% detecting local maxima and minima, computing row and column argmax/argmin,
% threshold filtering, range computation, and sparse cell enumeration.
:- module(extrema, [
    ex_max_val/2, ex_min_val/2,
    ex_max_cells/2, ex_min_cells/2,
    ex_row_argmax/2, ex_col_argmax/2,
    ex_row_argmin/2, ex_col_argmin/2,
    ex_local_max4/2, ex_local_min4/2,
    ex_above/3, ex_below/3,
    ex_range/2, ex_nonzero/2
]).
% Import list utilities for aggregation, extrema, and column extraction.
:- use_module(library(lists), [member/2, nth0/3, max_list/2, min_list/2, sum_list/2]).

% ex_max_val(+Grid, -Val): Val is the maximum value across all cells in Grid.
ex_max_val(Grid, Val) :-
% Collect all cell values, then find the maximum.
    ex_flat_vals_(Grid, Vals),
    max_list(Vals, Val).

% ex_min_val(+Grid, -Val): Val is the minimum value across all cells in Grid.
ex_min_val(Grid, Val) :-
% Collect all cell values, then find the minimum.
    ex_flat_vals_(Grid, Vals),
    min_list(Vals, Val).

% ex_max_cells(+Grid, -Cells): Cells is the sorted list of R-C positions whose
% value equals the grid maximum.
ex_max_cells(Grid, Cells) :-
% Find the max value, then collect all positions holding that value.
    ex_max_val(Grid, Val),
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(R-C, (
        between(0, H1, R), between(0, W1, C),
        nth0(R, Grid, Row), nth0(C, Row, Val)
    ), Cells).

% ex_min_cells(+Grid, -Cells): Cells is the sorted list of R-C positions whose
% value equals the grid minimum.
ex_min_cells(Grid, Cells) :-
% Find the min value, then collect all positions holding that value.
    ex_min_val(Grid, Val),
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(R-C, (
        between(0, H1, R), between(0, W1, C),
        nth0(R, Grid, Row), nth0(C, Row, Val)
    ), Cells).

% ex_row_argmax(+Grid, -R): R is the 0-based index of the row with the maximum
% sum. On ties, the first (lowest-index) row wins.
ex_row_argmax(Grid, R) :-
% Collect sum-index pairs for each row, then pick the index with maximum sum.
    length(Grid, H), H1 is H - 1,
    findall(S-I, (between(0, H1, I), nth0(I, Grid, Row), sum_list(Row, S)), Pairs),
    ex_argmax_idx_(Pairs, R).

% ex_col_argmax(+Grid, -C): C is the 0-based index of the column with the maximum
% sum. On ties, the first (lowest-index) column wins.
ex_col_argmax(Grid, C) :-
% Collect sum-index pairs for each column, then pick the index with maximum sum.
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(S-I, (between(0, W1, I), ex_col_sum_(Grid, I, S)), Pairs),
    ex_argmax_idx_(Pairs, C).

% ex_row_argmin(+Grid, -R): R is the 0-based index of the row with the minimum
% sum. On ties, the first row wins.
ex_row_argmin(Grid, R) :-
% Collect sum-index pairs for each row, then pick the index with minimum sum.
    length(Grid, H), H1 is H - 1,
    findall(S-I, (between(0, H1, I), nth0(I, Grid, Row), sum_list(Row, S)), Pairs),
    ex_argmin_idx_(Pairs, R).

% ex_col_argmin(+Grid, -C): C is the 0-based index of the column with the minimum
% sum. On ties, the first column wins.
ex_col_argmin(Grid, C) :-
% Collect sum-index pairs for each column, then pick the index with minimum sum.
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(S-I, (between(0, W1, I), ex_col_sum_(Grid, I, S)), Pairs),
    ex_argmin_idx_(Pairs, C).

% ex_local_max4(+Grid, -Cells): Cells is the sorted list of R-C positions that
% are strictly greater than every in-bounds 4-connected neighbor.
% Border and corner cells have fewer than 4 neighbors; out-of-bounds directions
% are ignored (do not disqualify a cell).
ex_local_max4(Grid, Cells) :-
% For each cell, test that all in-bounds 4-neighbors are strictly less.
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(R-C, (
        between(0, H1, R), between(0, W1, C),
        nth0(R, Grid, Row), nth0(C, Row, V),
        ex_all_nbr4_lt_(Grid, H, W, R, C, V)
    ), Cells).

% ex_local_min4(+Grid, -Cells): Cells is the sorted list of R-C positions that
% are strictly less than every in-bounds 4-connected neighbor.
ex_local_min4(Grid, Cells) :-
% For each cell, test that all in-bounds 4-neighbors are strictly greater.
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(R-C, (
        between(0, H1, R), between(0, W1, C),
        nth0(R, Grid, Row), nth0(C, Row, V),
        ex_all_nbr4_gt_(Grid, H, W, R, C, V)
    ), Cells).

% ex_above(+Grid, +Thresh, -Cells): Cells is the sorted list of R-C positions
% whose value is strictly greater than Thresh.
ex_above(Grid, Thresh, Cells) :-
% Collect all positions where the cell value exceeds the threshold.
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(R-C, (
        between(0, H1, R), between(0, W1, C),
        nth0(R, Grid, Row), nth0(C, Row, V),
        V > Thresh
    ), Cells).

% ex_below(+Grid, +Thresh, -Cells): Cells is the sorted list of R-C positions
% whose value is strictly less than Thresh.
ex_below(Grid, Thresh, Cells) :-
% Collect all positions where the cell value is below the threshold.
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(R-C, (
        between(0, H1, R), between(0, W1, C),
        nth0(R, Grid, Row), nth0(C, Row, V),
        V < Thresh
    ), Cells).

% ex_range(+Grid, -Range): Range is the maximum value minus the minimum value
% across all cells in Grid.
ex_range(Grid, Range) :-
% Compute max and min of all cell values, then subtract.
    ex_flat_vals_(Grid, Vals),
    max_list(Vals, Mx), min_list(Vals, Mn),
    Range is Mx - Mn.

% ex_nonzero(+Grid, -Cells): Cells is the sorted list of R-C positions whose
% value is not arithmetically equal to 0.
ex_nonzero(Grid, Cells) :-
% Collect all positions where the cell value is non-zero.
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(R-C, (
        between(0, H1, R), between(0, W1, C),
        nth0(R, Grid, Row), nth0(C, Row, V),
        V =\= 0
    ), Cells).

% Private: flatten all grid cell values into a single list.
ex_flat_vals_(Grid, Vals) :-
    findall(V, (member(Row, Grid), member(V, Row)), Vals).

% Private: compute the sum of column C in Grid.
ex_col_sum_(Grid, C, Sum) :-
    findall(V, (member(Row, Grid), nth0(C, Row, V)), Vals),
    sum_list(Vals, Sum).

% Private: find the index I with the maximum sum S from a S-I pair list.
% Ties are broken by first occurrence (lowest I).
ex_argmax_idx_([S-I | Rest], Best) :-
    ex_argmax_acc_(Rest, S, I, Best).

% Private: accumulator for ex_argmax_idx_.
ex_argmax_acc_([], _, I, I).
ex_argmax_acc_([S2-I2 | Rest], BestS, BestI, Final) :-
% Update best if new sum is strictly greater; otherwise keep current best.
    (S2 > BestS ->
        ex_argmax_acc_(Rest, S2, I2, Final)
    ;
        ex_argmax_acc_(Rest, BestS, BestI, Final)
    ).

% Private: find the index I with the minimum sum S from a S-I pair list.
% Ties are broken by first occurrence (lowest I).
ex_argmin_idx_([S-I | Rest], Best) :-
    ex_argmin_acc_(Rest, S, I, Best).

% Private: accumulator for ex_argmin_idx_.
ex_argmin_acc_([], _, I, I).
ex_argmin_acc_([S2-I2 | Rest], BestS, BestI, Final) :-
% Update best if new sum is strictly less; otherwise keep current best.
    (S2 < BestS ->
        ex_argmin_acc_(Rest, S2, I2, Final)
    ;
        ex_argmin_acc_(Rest, BestS, BestI, Final)
    ).

% Private: succeed iff all in-bounds 4-neighbors of R-C have value strictly < V.
ex_all_nbr4_lt_(Grid, H, W, R, C, V) :-
% Check each of the four orthogonal directions with bounds guards.
    RU is R - 1, RD is R + 1, CL is C - 1, CR is C + 1,
    ex_check_nbr_lt_(Grid, H, W, RU, C, V),
    ex_check_nbr_lt_(Grid, H, W, RD, C, V),
    ex_check_nbr_lt_(Grid, H, W, R, CL, V),
    ex_check_nbr_lt_(Grid, H, W, R, CR, V).

% Private: succeed iff all in-bounds 4-neighbors of R-C have value strictly > V.
ex_all_nbr4_gt_(Grid, H, W, R, C, V) :-
% Check each of the four orthogonal directions with bounds guards.
    RU is R - 1, RD is R + 1, CL is C - 1, CR is C + 1,
    ex_check_nbr_gt_(Grid, H, W, RU, C, V),
    ex_check_nbr_gt_(Grid, H, W, RD, C, V),
    ex_check_nbr_gt_(Grid, H, W, R, CL, V),
    ex_check_nbr_gt_(Grid, H, W, R, CR, V).

% Private: if NR-NC is in bounds, require that its value < V; out-of-bounds succeeds.
ex_check_nbr_lt_(Grid, H, W, NR, NC, V) :-
    (NR >= 0, NR < H, NC >= 0, NC < W ->
        nth0(NR, Grid, NRow), nth0(NC, NRow, NV), NV < V
    ;
        true
    ).

% Private: if NR-NC is in bounds, require that its value > V; out-of-bounds succeeds.
ex_check_nbr_gt_(Grid, H, W, NR, NC, V) :-
    (NR >= 0, NR < H, NC >= 0, NC < W ->
        nth0(NR, Grid, NRow), nth0(NC, NRow, NV), NV > V
    ;
        true
    ).
