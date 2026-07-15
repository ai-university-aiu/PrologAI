% cross.pl - Layer 121: 1D Cross-Section Extraction from 2D Grids (cx_* prefix).
% General-purpose predicates for slicing rows, columns, and diagonals from grids.
:- module(cross, [
    cross_row/3, cross_col/3,
    cross_diag/2, cross_antidiag/2,
    cross_row_sum/3, cross_col_sum/3,
    cross_row_count/4, cross_col_count/4,
    cross_rows_with/3, cross_cols_with/3,
    cross_row_uniq/3, cross_col_uniq/3,
    cross_row_mode/4, cross_col_mode/4
]).
% Import list operations needed throughout this module.
:- use_module(library(lists), [member/2, nth0/3, sum_list/2, max_list/2]).

% cross_row(+Grid, +R, -Row): extract row R from Grid as a list.
cross_row(Grid, R, Row) :-
% Use nth0 to retrieve the R-th row directly.
    nth0(R, Grid, Row).

% cross_col(+Grid, +C, -Col): extract column C from Grid as a list, one entry per row.
cross_col(Grid, C, Col) :-
% Collect the C-th element from every row in order.
    findall(V, (member(Row, Grid), nth0(C, Row, V)), Col).

% cross_diag(+Grid, -Diag): extract the main diagonal (top-left to bottom-right).
cross_diag(Grid, Diag) :-
% Diag length is bounded by the shorter of H and W; iterate R and pair with C=R.
    length(Grid, H), H1 is H - 1,
    findall(V, (
        between(0, H1, R),
        nth0(R, Grid, Row),
        nth0(R, Row, V)
    ), Diag).

% cross_antidiag(+Grid, -Diag): extract the anti-diagonal (top-right to bottom-left).
cross_antidiag(Grid, Diag) :-
% Width W needed to compute the mirrored column index C = W - 1 - R.
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0),
    length(Grid, H), H1 is H - 1,
    findall(V, (
        between(0, H1, R),
        C is W - 1 - R,
        C >= 0,
        nth0(R, Grid, Row),
        nth0(C, Row, V)
    ), Diag).

% cross_row_sum(+Grid, +R, -Sum): sum of all values in row R.
cross_row_sum(Grid, R, Sum) :-
% Retrieve row then delegate to sum_list/2 from library(lists).
    nth0(R, Grid, Row),
    sum_list(Row, Sum).

% cross_col_sum(+Grid, +C, -Sum): sum of all values in column C.
cross_col_sum(Grid, C, Sum) :-
% Extract column then sum its elements.
    cross_col(Grid, C, Col),
    sum_list(Col, Sum).

% cross_row_count(+Grid, +R, +V, -N): count occurrences of V in row R.
cross_row_count(Grid, R, V, N) :-
% Collect one witness per matching element then measure length.
    nth0(R, Grid, Row),
    findall(_, member(V, Row), Ks),
    length(Ks, N).

% cross_col_count(+Grid, +C, +V, -N): count occurrences of V in column C.
cross_col_count(Grid, C, V, N) :-
% Extract column then count matching elements.
    cross_col(Grid, C, Col),
    findall(_, member(V, Col), Ks),
    length(Ks, N).

% cross_rows_with(+Grid, +V, -Rows): sorted list of row indices containing at least one V.
cross_rows_with(Grid, V, Rows) :-
% Enumerate row indices; keep those whose row contains V; deduplicate with sort.
    length(Grid, H), H1 is H - 1,
    findall(R, (
        between(0, H1, R),
        nth0(R, Grid, Row),
        member(V, Row)
    ), Unsorted),
    sort(Unsorted, Rows).

% cross_cols_with(+Grid, +V, -Cols): sorted list of column indices containing at least one V.
cross_cols_with(Grid, V, Cols) :-
% Enumerate column indices; keep those where at least one row has V at that column.
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(C, (
        between(0, W1, C),
        member(Row, Grid),
        nth0(C, Row, V)
    ), Unsorted),
    sort(Unsorted, Cols).

% cross_row_uniq(+Grid, +R, -Vals): sorted unique values present in row R.
cross_row_uniq(Grid, R, Vals) :-
% sort/2 on the row list both sorts and deduplicates.
    nth0(R, Grid, Row),
    sort(Row, Vals).

% cross_col_uniq(+Grid, +C, -Vals): sorted unique values present in column C.
cross_col_uniq(Grid, C, Vals) :-
% Extract column then sort/deduplicate.
    cross_col(Grid, C, Col),
    sort(Col, Vals).

% cross_row_mode(+Grid, +R, +Bg, -Mode): most frequent value in row R; Bg on tie.
cross_row_mode(Grid, R, Bg, Mode) :-
% Retrieve row then delegate to shared mode helper.
    nth0(R, Grid, Row),
    cross_mode_(Row, Bg, Mode).

% cross_col_mode(+Grid, +C, +Bg, -Mode): most frequent value in column C; Bg on tie.
cross_col_mode(Grid, C, Bg, Mode) :-
% Extract column then delegate to shared mode helper.
    cross_col(Grid, C, Col),
    cross_mode_(Col, Bg, Mode).

% cross_mode_(+Vals, +Bg, -Mode): most frequent value in Vals; Bg if there is a tie.
cross_mode_(Vals, Bg, Mode) :-
% Build frequency pairs N-V for each unique value.
    sort(Vals, Unique),
    findall(N-V, (
        member(V, Unique),
        findall(_, member(V, Vals), Ks),
        length(Ks, N)
    ), Counts),
% Find the maximum frequency.
    findall(N, member(N-_, Counts), Ns),
    max_list(Ns, MaxN),
% Collect all values tied at the maximum frequency.
    findall(V, member(MaxN-V, Counts), Winners),
% A single winner becomes Mode; a tie resolves to Bg.
    (Winners = [Mode] -> true ; Mode = Bg).
