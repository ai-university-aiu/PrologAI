% gradient.pl - Layer 132: Row and Column Gradient and Progression Analysis (gr_* prefix).
% General-purpose predicates for measuring value gradients, monotonicity,
% range, cumulative sums, and second-order differences in 2D grids.
:- module(gradient, [
    gradient_h_diffs/2, gradient_v_diffs/2,
    gradient_h_mono/2, gradient_v_mono/2,
    gradient_h_range/2, gradient_v_range/2,
    gradient_h_slope/2, gradient_v_slope/2,
    gradient_h_const/2, gradient_v_const/2,
    gradient_h_cum/2, gradient_v_cum/2,
    gradient_h_second/2, gradient_v_second/2
]).
% Import list utilities for aggregation operations.
:- use_module(library(lists), [member/2, nth0/3, max_list/2, min_list/2, last/2]).
% Import maplist/3 for applying per-row transformations.
:- use_module(library(apply), [maplist/3]).

% gradient_h_diffs(+Grid, -DiffGrid): DiffGrid has one list per row, each list holds
% the adjacent differences [V1-V0, V2-V1, ...]. A row of length N gives N-1 diffs.
gradient_h_diffs(Grid, DiffGrid) :-
% Apply adjacent differencing to each row.
    maplist(gradient_adj_diffs_, Grid, DiffGrid).

% gradient_v_diffs(+Grid, -DiffGrid): DiffGrid has one list per adjacent row pair, each
% holding column-wise differences. H rows produce H-1 lists of differences.
gradient_v_diffs(Grid, DiffGrid) :-
% Compute column-wise differences between each adjacent row pair.
    gradient_v_diffs_(Grid, DiffGrid).

% gradient_h_mono(+Grid, -Flags): Flags is a list of 1 (non-decreasing), -1
% (non-increasing), or 0 (mixed) for each row.
gradient_h_mono(Grid, Flags) :-
% Classify the monotonicity of each row.
    maplist(gradient_mono_, Grid, Flags).

% gradient_v_mono(+Grid, -Flags): Flags is a list of 1, -1, or 0 for each column.
gradient_v_mono(Grid, Flags) :-
% Extract each column and classify its monotonicity.
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(F, (between(0, W1, C), gradient_col_(Grid, C, Col), gradient_mono_(Col, F)), Flags).

% gradient_h_range(+Grid, -Ranges): Ranges is the list of (max - min) for each row.
gradient_h_range(Grid, Ranges) :-
% Compute the value range of each row as max minus min.
    findall(R, (
        member(Row, Grid),
        max_list(Row, Mx), min_list(Row, Mn),
        R is Mx - Mn
    ), Ranges).

% gradient_v_range(+Grid, -Ranges): Ranges is the list of (max - min) for each column.
gradient_v_range(Grid, Ranges) :-
% Extract each column and compute its value range.
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(R, (
        between(0, W1, C), gradient_col_(Grid, C, Col),
        max_list(Col, Mx), min_list(Col, Mn),
        R is Mx - Mn
    ), Ranges).

% gradient_h_slope(+Grid, -Slopes): Slopes is the list of (last - first) for each row.
% This is the net horizontal change regardless of intermediate values.
gradient_h_slope(Grid, Slopes) :-
% Compute the net change from first to last element per row.
    findall(S, (
        member(Row, Grid),
        Row = [H|_], last(Row, L),
        S is L - H
    ), Slopes).

% gradient_v_slope(+Grid, -Slopes): Slopes is the list of (last - first) for each column.
gradient_v_slope(Grid, Slopes) :-
% Extract each column and compute its net change from top to bottom.
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(S, (
        between(0, W1, C), gradient_col_(Grid, C, Col),
        Col = [H|_], last(Col, L),
        S is L - H
    ), Slopes).

% gradient_h_const(+Grid, -Bools): Bools is a list of 1 (all values equal) or 0 per row.
gradient_h_const(Grid, Bools) :-
% Test whether every element in each row is identical.
    findall(B, (
        member(Row, Grid),
        (gradient_all_equal_(Row) -> B = 1 ; B = 0)
    ), Bools).

% gradient_v_const(+Grid, -Bools): Bools is a list of 1 (all values equal) or 0 per column.
gradient_v_const(Grid, Bools) :-
% Extract each column and test whether all its values are identical.
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(B, (
        between(0, W1, C), gradient_col_(Grid, C, Col),
        (gradient_all_equal_(Col) -> B = 1 ; B = 0)
    ), Bools).

% gradient_h_cum(+Grid, -CumGrid): each row in CumGrid is the running cumulative sum
% of the corresponding input row: [V0, V0+V1, V0+V1+V2, ...].
gradient_h_cum(Grid, CumGrid) :-
% Apply cumulative sum to each row independently.
    maplist(gradient_cumsum_, Grid, CumGrid).

% gradient_v_cum(+Grid, -CumGrid): each cell in CumGrid is the cumulative sum of the
% corresponding column down to (and including) that row.
gradient_v_cum(Grid, CumGrid) :-
% Accumulate column sums row by row.
    gradient_v_cum_acc_(Grid, [], CumGrid).

% gradient_h_second(+Grid, -D2Grid): D2Grid holds the second-order differences
% (differences of adjacent differences) for each row.
% A row of length N gives N-2 second-order differences.
gradient_h_second(Grid, D2Grid) :-
% Apply two passes of adjacent differencing to each row.
    maplist(gradient_second_diffs_, Grid, D2Grid).

% gradient_v_second(+Grid, -D2Grid): D2Grid holds second-order vertical differences.
% Computed by applying gradient_v_diffs twice. H rows give H-2 rows in D2Grid.
gradient_v_second(Grid, D2Grid) :-
% Apply vertical differencing twice.
    gradient_v_diffs(Grid, D1),
    gradient_v_diffs(D1, D2Grid).

% Private: extract the C-th column from Grid as a flat list.
gradient_col_(Grid, C, Col) :-
    findall(V, (member(Row, Grid), nth0(C, Row, V)), Col).

% Private: compute adjacent differences [B-A, C-B, ...] for a list.
gradient_adj_diffs_([], []).
gradient_adj_diffs_([_], []).
gradient_adj_diffs_([A, B | T], [D | Ds]) :-
% Subtract each element from its successor.
    D is B - A,
    gradient_adj_diffs_([B | T], Ds).

% Private: compute element-wise differences between two equal-length lists.
gradient_pair_diffs_([], [], []).
gradient_pair_diffs_([A | As], [B | Bs], [D | Ds]) :-
% Subtract each element of the first list from the corresponding element of the second.
    D is B - A,
    gradient_pair_diffs_(As, Bs, Ds).

% Private: compute vertical differences between each adjacent row pair.
gradient_v_diffs_([], []).
gradient_v_diffs_([_], []).
gradient_v_diffs_([R1, R2 | Rows], [Diffs | Rest]) :-
% Compute element-wise differences between R1 and R2, then recurse.
    gradient_pair_diffs_(R1, R2, Diffs),
    gradient_v_diffs_([R2 | Rows], Rest).

% Private: classify a list as 1, -1, or 0.
% Returns 1 if non-decreasing, -1 if non-increasing (and not non-decreasing), 0 otherwise.
gradient_mono_(List, F) :-
    (gradient_is_nondec_(List) -> F = 1
    ; gradient_is_noninc_(List) -> F = -1
    ; F = 0).

% Private: succeed iff the list is weakly non-decreasing (each element >= predecessor).
gradient_is_nondec_([]).
gradient_is_nondec_([_]).
gradient_is_nondec_([A, B | T]) :- B >= A, gradient_is_nondec_([B | T]).

% Private: succeed iff the list is weakly non-increasing (each element =< predecessor).
gradient_is_noninc_([]).
gradient_is_noninc_([_]).
gradient_is_noninc_([A, B | T]) :- B =< A, gradient_is_noninc_([B | T]).

% Private: succeed iff all elements in the list are arithmetically equal.
gradient_all_equal_([]).
gradient_all_equal_([_]).
gradient_all_equal_([A, B | T]) :- A =:= B, gradient_all_equal_([B | T]).

% Private: compute the cumulative sum of a list. Delegates to accumulator.
gradient_cumsum_(List, Cum) :- gradient_cumsum_acc_(List, 0, Cum).

% Private: accumulator for cumulative sum. Acc holds the running total.
gradient_cumsum_acc_([], _, []).
gradient_cumsum_acc_([H | T], Acc, [N | Ns]) :-
% Add H to the running total, emit the new total, recurse.
    N is Acc + H,
    gradient_cumsum_acc_(T, N, Ns).

% Private: add corresponding elements of two equal-length lists.
gradient_row_add_([], [], []).
gradient_row_add_([A | As], [B | Bs], [C | Cs]) :-
% Sum each pair of elements.
    C is A + B,
    gradient_row_add_(As, Bs, Cs).

% Private: accumulate vertical cumulative sums. Prev holds the cumulative row so far.
gradient_v_cum_acc_([], _, []).
gradient_v_cum_acc_([Row | Rows], Prev, [CumRow | CumRows]) :-
% For the first row, CumRow = Row; for subsequent rows, add Prev element-wise.
    (Prev = [] ->
        CumRow = Row
    ;
        gradient_row_add_(Prev, Row, CumRow)
    ),
    gradient_v_cum_acc_(Rows, CumRow, CumRows).

% Private: compute second-order differences by differencing twice.
gradient_second_diffs_(List, D2) :-
% Apply gradient_adj_diffs_ twice.
    gradient_adj_diffs_(List, D1),
    gradient_adj_diffs_(D1, D2).
