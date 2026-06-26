% gradient.pl - Layer 132: Row and Column Gradient and Progression Analysis (gr_* prefix).
% General-purpose predicates for measuring value gradients, monotonicity,
% range, cumulative sums, and second-order differences in 2D grids.
:- module(gradient, [
    gr_h_diffs/2, gr_v_diffs/2,
    gr_h_mono/2, gr_v_mono/2,
    gr_h_range/2, gr_v_range/2,
    gr_h_slope/2, gr_v_slope/2,
    gr_h_const/2, gr_v_const/2,
    gr_h_cum/2, gr_v_cum/2,
    gr_h_second/2, gr_v_second/2
]).
% Import list utilities for aggregation operations.
:- use_module(library(lists), [member/2, nth0/3, max_list/2, min_list/2, last/2]).
% Import maplist/3 for applying per-row transformations.
:- use_module(library(apply), [maplist/3]).

% gr_h_diffs(+Grid, -DiffGrid): DiffGrid has one list per row, each list holds
% the adjacent differences [V1-V0, V2-V1, ...]. A row of length N gives N-1 diffs.
gr_h_diffs(Grid, DiffGrid) :-
% Apply adjacent differencing to each row.
    maplist(gr_adj_diffs_, Grid, DiffGrid).

% gr_v_diffs(+Grid, -DiffGrid): DiffGrid has one list per adjacent row pair, each
% holding column-wise differences. H rows produce H-1 lists of differences.
gr_v_diffs(Grid, DiffGrid) :-
% Compute column-wise differences between each adjacent row pair.
    gr_v_diffs_(Grid, DiffGrid).

% gr_h_mono(+Grid, -Flags): Flags is a list of 1 (non-decreasing), -1
% (non-increasing), or 0 (mixed) for each row.
gr_h_mono(Grid, Flags) :-
% Classify the monotonicity of each row.
    maplist(gr_mono_, Grid, Flags).

% gr_v_mono(+Grid, -Flags): Flags is a list of 1, -1, or 0 for each column.
gr_v_mono(Grid, Flags) :-
% Extract each column and classify its monotonicity.
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(F, (between(0, W1, C), gr_col_(Grid, C, Col), gr_mono_(Col, F)), Flags).

% gr_h_range(+Grid, -Ranges): Ranges is the list of (max - min) for each row.
gr_h_range(Grid, Ranges) :-
% Compute the value range of each row as max minus min.
    findall(R, (
        member(Row, Grid),
        max_list(Row, Mx), min_list(Row, Mn),
        R is Mx - Mn
    ), Ranges).

% gr_v_range(+Grid, -Ranges): Ranges is the list of (max - min) for each column.
gr_v_range(Grid, Ranges) :-
% Extract each column and compute its value range.
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(R, (
        between(0, W1, C), gr_col_(Grid, C, Col),
        max_list(Col, Mx), min_list(Col, Mn),
        R is Mx - Mn
    ), Ranges).

% gr_h_slope(+Grid, -Slopes): Slopes is the list of (last - first) for each row.
% This is the net horizontal change regardless of intermediate values.
gr_h_slope(Grid, Slopes) :-
% Compute the net change from first to last element per row.
    findall(S, (
        member(Row, Grid),
        Row = [H|_], last(Row, L),
        S is L - H
    ), Slopes).

% gr_v_slope(+Grid, -Slopes): Slopes is the list of (last - first) for each column.
gr_v_slope(Grid, Slopes) :-
% Extract each column and compute its net change from top to bottom.
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(S, (
        between(0, W1, C), gr_col_(Grid, C, Col),
        Col = [H|_], last(Col, L),
        S is L - H
    ), Slopes).

% gr_h_const(+Grid, -Bools): Bools is a list of 1 (all values equal) or 0 per row.
gr_h_const(Grid, Bools) :-
% Test whether every element in each row is identical.
    findall(B, (
        member(Row, Grid),
        (gr_all_equal_(Row) -> B = 1 ; B = 0)
    ), Bools).

% gr_v_const(+Grid, -Bools): Bools is a list of 1 (all values equal) or 0 per column.
gr_v_const(Grid, Bools) :-
% Extract each column and test whether all its values are identical.
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(B, (
        between(0, W1, C), gr_col_(Grid, C, Col),
        (gr_all_equal_(Col) -> B = 1 ; B = 0)
    ), Bools).

% gr_h_cum(+Grid, -CumGrid): each row in CumGrid is the running cumulative sum
% of the corresponding input row: [V0, V0+V1, V0+V1+V2, ...].
gr_h_cum(Grid, CumGrid) :-
% Apply cumulative sum to each row independently.
    maplist(gr_cumsum_, Grid, CumGrid).

% gr_v_cum(+Grid, -CumGrid): each cell in CumGrid is the cumulative sum of the
% corresponding column down to (and including) that row.
gr_v_cum(Grid, CumGrid) :-
% Accumulate column sums row by row.
    gr_v_cum_acc_(Grid, [], CumGrid).

% gr_h_second(+Grid, -D2Grid): D2Grid holds the second-order differences
% (differences of adjacent differences) for each row.
% A row of length N gives N-2 second-order differences.
gr_h_second(Grid, D2Grid) :-
% Apply two passes of adjacent differencing to each row.
    maplist(gr_second_diffs_, Grid, D2Grid).

% gr_v_second(+Grid, -D2Grid): D2Grid holds second-order vertical differences.
% Computed by applying gr_v_diffs twice. H rows give H-2 rows in D2Grid.
gr_v_second(Grid, D2Grid) :-
% Apply vertical differencing twice.
    gr_v_diffs(Grid, D1),
    gr_v_diffs(D1, D2Grid).

% Private: extract the C-th column from Grid as a flat list.
gr_col_(Grid, C, Col) :-
    findall(V, (member(Row, Grid), nth0(C, Row, V)), Col).

% Private: compute adjacent differences [B-A, C-B, ...] for a list.
gr_adj_diffs_([], []).
gr_adj_diffs_([_], []).
gr_adj_diffs_([A, B | T], [D | Ds]) :-
% Subtract each element from its successor.
    D is B - A,
    gr_adj_diffs_([B | T], Ds).

% Private: compute element-wise differences between two equal-length lists.
gr_pair_diffs_([], [], []).
gr_pair_diffs_([A | As], [B | Bs], [D | Ds]) :-
% Subtract each element of the first list from the corresponding element of the second.
    D is B - A,
    gr_pair_diffs_(As, Bs, Ds).

% Private: compute vertical differences between each adjacent row pair.
gr_v_diffs_([], []).
gr_v_diffs_([_], []).
gr_v_diffs_([R1, R2 | Rows], [Diffs | Rest]) :-
% Compute element-wise differences between R1 and R2, then recurse.
    gr_pair_diffs_(R1, R2, Diffs),
    gr_v_diffs_([R2 | Rows], Rest).

% Private: classify a list as 1, -1, or 0.
% Returns 1 if non-decreasing, -1 if non-increasing (and not non-decreasing), 0 otherwise.
gr_mono_(List, F) :-
    (gr_is_nondec_(List) -> F = 1
    ; gr_is_noninc_(List) -> F = -1
    ; F = 0).

% Private: succeed iff the list is weakly non-decreasing (each element >= predecessor).
gr_is_nondec_([]).
gr_is_nondec_([_]).
gr_is_nondec_([A, B | T]) :- B >= A, gr_is_nondec_([B | T]).

% Private: succeed iff the list is weakly non-increasing (each element =< predecessor).
gr_is_noninc_([]).
gr_is_noninc_([_]).
gr_is_noninc_([A, B | T]) :- B =< A, gr_is_noninc_([B | T]).

% Private: succeed iff all elements in the list are arithmetically equal.
gr_all_equal_([]).
gr_all_equal_([_]).
gr_all_equal_([A, B | T]) :- A =:= B, gr_all_equal_([B | T]).

% Private: compute the cumulative sum of a list. Delegates to accumulator.
gr_cumsum_(List, Cum) :- gr_cumsum_acc_(List, 0, Cum).

% Private: accumulator for cumulative sum. Acc holds the running total.
gr_cumsum_acc_([], _, []).
gr_cumsum_acc_([H | T], Acc, [N | Ns]) :-
% Add H to the running total, emit the new total, recurse.
    N is Acc + H,
    gr_cumsum_acc_(T, N, Ns).

% Private: add corresponding elements of two equal-length lists.
gr_row_add_([], [], []).
gr_row_add_([A | As], [B | Bs], [C | Cs]) :-
% Sum each pair of elements.
    C is A + B,
    gr_row_add_(As, Bs, Cs).

% Private: accumulate vertical cumulative sums. Prev holds the cumulative row so far.
gr_v_cum_acc_([], _, []).
gr_v_cum_acc_([Row | Rows], Prev, [CumRow | CumRows]) :-
% For the first row, CumRow = Row; for subsequent rows, add Prev element-wise.
    (Prev = [] ->
        CumRow = Row
    ;
        gr_row_add_(Prev, Row, CumRow)
    ),
    gr_v_cum_acc_(Rows, CumRow, CumRows).

% Private: compute second-order differences by differencing twice.
gr_second_diffs_(List, D2) :-
% Apply gr_adj_diffs_ twice.
    gr_adj_diffs_(List, D1),
    gr_adj_diffs_(D1, D2).
