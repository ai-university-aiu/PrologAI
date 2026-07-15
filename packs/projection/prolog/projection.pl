% projection.pl - Layer 131: Row and Column Projection and Profile Analysis (pj_* prefix).
% General-purpose predicates for computing 1D summaries of 2D grids by
% projecting along rows or columns.
:- module(projection, [
    projection_row_sums/2, projection_col_sums/2,
    projection_row_counts/3, projection_col_counts/3,
    projection_row_maxes/2, projection_col_maxes/2,
    projection_row_uniq/2, projection_col_uniq/2,
    projection_shadow_h/3, projection_shadow_v/3,
    projection_h_profile/3, projection_v_profile/3,
    projection_row_modes/2, projection_col_modes/2
]).
% Import list utilities for aggregation and filtering.
:- use_module(library(lists), [member/2, nth0/3, max_list/2, sum_list/2]).
:- use_module(library(apply), [maplist/2, maplist/3, include/3]).

% projection_row_sums(+Grid, -Sums): Sums is the list of integer sums, one per row.
projection_row_sums(Grid, Sums) :-
% Apply sum_list to each row using maplist.
    maplist(sum_list, Grid, Sums).

% projection_col_sums(+Grid, -Sums): Sums is the list of column sums.
projection_col_sums(Grid, Sums) :-
% Extract each column and sum its elements.
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(S, (between(0, W1, C), projection_col_(Grid, C, Col), sum_list(Col, S)), Sums).

% projection_row_counts(+Grid, +Val, -Counts): Counts is the list of counts of Val
% per row.
projection_row_counts(Grid, Val, Counts) :-
% For each row, count members equal to Val.
    findall(N, (member(Row, Grid), include(=(Val), Row, Occ), length(Occ, N)), Counts).

% projection_col_counts(+Grid, +Val, -Counts): Counts is the list of counts of Val
% per column.
projection_col_counts(Grid, Val, Counts) :-
% Extract each column and count Val occurrences.
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(N, (
        between(0, W1, C),
        projection_col_(Grid, C, Col),
        include(=(Val), Col, Occ), length(Occ, N)
    ), Counts).

% projection_row_maxes(+Grid, -Maxes): Maxes is the list of maximum values per row.
projection_row_maxes(Grid, Maxes) :-
% Apply max_list to each row.
    maplist(max_list, Grid, Maxes).

% projection_col_maxes(+Grid, -Maxes): Maxes is the list of maximum values per column.
projection_col_maxes(Grid, Maxes) :-
% Extract each column and find its maximum.
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(M, (between(0, W1, C), projection_col_(Grid, C, Col), max_list(Col, M)), Maxes).

% projection_row_uniq(+Grid, -ValLists): ValLists is the list of sorted unique values
% per row.
projection_row_uniq(Grid, ValLists) :-
% Apply sort/2 to each row.
    findall(U, (member(Row, Grid), sort(Row, U)), ValLists).

% projection_col_uniq(+Grid, -ValLists): ValLists is the list of sorted unique values
% per column.
projection_col_uniq(Grid, ValLists) :-
% Extract each column and sort it to get unique values.
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(U, (between(0, W1, C), projection_col_(Grid, C, Col), sort(Col, U)), ValLists).

% projection_shadow_h(+Grid, +Val, -ColIndices): sorted list of column indices (0-based)
% that contain at least one cell with value Val.
projection_shadow_h(Grid, Val, ColIndices) :-
% Collect column indices where Val appears in any row.
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(C, (
        between(0, W1, C),
        member(Row, Grid), nth0(C, Row, Val)
    ), Unsorted),
    sort(Unsorted, ColIndices).

% projection_shadow_v(+Grid, +Val, -RowIndices): sorted list of row indices (0-based)
% that contain at least one cell with value Val.
projection_shadow_v(Grid, Val, RowIndices) :-
% Collect row indices where Val appears in that row.
    length(Grid, H), H1 is H - 1,
    findall(R, (
        between(0, H1, R),
        nth0(R, Grid, Row), member(Val, Row)
    ), Unsorted),
    sort(Unsorted, RowIndices).

% projection_h_profile(+Grid, +Val, -Profile): Profile is the list of longest-run
% lengths of Val in each row.
projection_h_profile(Grid, Val, Profile) :-
% Apply longest-run computation to each row.
    findall(N, (member(Row, Grid), projection_longest_run_(Row, Val, N)), Profile).

% projection_v_profile(+Grid, +Val, -Profile): Profile is the list of longest-run
% lengths of Val in each column.
projection_v_profile(Grid, Val, Profile) :-
% Extract each column and compute its longest Val run.
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(N, (between(0, W1, C), projection_col_(Grid, C, Col), projection_longest_run_(Col, Val, N)), Profile).

% projection_row_modes(+Grid, -Modes): Modes is the list of modal values per row.
% The modal value is the most frequent; on ties, the smallest wins.
projection_row_modes(Grid, Modes) :-
% Apply mode computation to each row.
    findall(M, (member(Row, Grid), projection_mode_(Row, M)), Modes).

% projection_col_modes(+Grid, -Modes): Modes is the list of modal values per column.
projection_col_modes(Grid, Modes) :-
% Extract each column and compute its modal value.
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(M, (between(0, W1, C), projection_col_(Grid, C, Col), projection_mode_(Col, M)), Modes).

% Private: extract the C-th column from Grid as a list.
projection_col_(Grid, C, Col) :-
    findall(V, (member(Row, Grid), nth0(C, Row, V)), Col).

% Private: compute the longest contiguous run of Val in a list.
projection_longest_run_(List, Val, N) :-
    projection_run_acc_(List, Val, 0, 0, N).
projection_run_acc_([], _, Cur, Max, N) :- N is max(Cur, Max).
projection_run_acc_([H|T], Val, Cur, Max, N) :-
    (H =:= Val ->
        Cur1 is Cur + 1, Max1 is max(Cur1, Max),
        projection_run_acc_(T, Val, Cur1, Max1, N)
    ;
        Max1 is max(Cur, Max),
        projection_run_acc_(T, Val, 0, Max1, N)
    ).

% Private: compute the modal value (most frequent, smallest on tie) of a list.
projection_mode_(List, Mode) :-
    sort(List, Unique),
    findall(N-V, (
        member(V, Unique),
        include(=(V), List, Occ), length(Occ, N)
    ), Pairs),
    projection_max_pair_(Pairs, N-Mode),
    N > 0.

% Private: find the pair with the maximum count; on tie, pick smallest value.
% Pairs are N-V where N is count and V is value.
projection_max_pair_([H], H).
projection_max_pair_([N-V|T], Best) :-
    projection_max_pair_(T, BestT),
    BestT = BN-BV,
    (N > BN -> Best = N-V
    ; N =:= BN, V < BV -> Best = N-V
    ; Best = BN-BV
    ).
