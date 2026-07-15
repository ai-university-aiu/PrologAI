% sort - Layer 80: sorting, ranking, and ordering operations on grids.
% Module sort exports 14 so_* predicates covering per-row/column sums and counts,
% row/column sorting by value frequency, identifying extremal rows/columns,
% and cell ranking within a grid.
:- module(sort, [
    % Integer sum of each row.
    sort_row_sums/2,
    % Integer sum of each column.
    sort_col_sums/2,
    % Count of a specific value per row.
    sort_row_count/3,
    % Count of a specific value per column.
    sort_col_count/3,
    % Sort rows ascending by count of a specific value.
    sort_sort_rows_asc/3,
    % Sort rows descending by count of a specific value.
    sort_sort_rows_desc/3,
    % Sort columns ascending by count of a specific value.
    sort_sort_cols_asc/3,
    % Sort columns descending by count of a specific value.
    sort_sort_cols_desc/3,
    % Row index with the highest count of a specific value.
    sort_max_row/3,
    % Row index with the lowest count of a specific value.
    sort_min_row/3,
    % Column index with the highest count of a specific value.
    sort_max_col/3,
    % Column index with the lowest count of a specific value.
    sort_min_col/3,
    % All cell values sorted ascending, preserving duplicates.
    sort_sorted_vals/2,
    % 1-based rank of a cell value among distinct grid values.
    sort_cell_rank/4
]).

% Load list utilities for index access and extrema.
:- use_module(library(lists), [member/2, nth0/3, nth1/3, numlist/3,
                                max_member/2, min_member/2]).
% Load apply utilities for row and column mapping.
:- use_module(library(apply), [maplist/2, maplist/3, include/3]).

% sort_row_sums(+Grid, -Sums)
% Sums is a list of integers, one per row, each being the sum of that row's cells.
sort_row_sums(Grid, Sums) :-
    % Sum each row independently.
    maplist(sort_sum_list_, Grid, Sums).

% sort_sum_list_(+List, -Sum): integer sum of a list of numbers.
sort_sum_list_(List, Sum) :-
    % Accumulate using a fold.
    foldl([X, Acc, NAcc]>>(NAcc is Acc + X), List, 0, Sum).

% sort_col_sums(+Grid, -Sums)
% Sums is a list of integers, one per column, each being the sum of that column's cells.
sort_col_sums(Grid, Sums) :-
    % Transpose rows to columns, then sum each column as a row.
    sort_transpose_(Grid, T),
    maplist(sort_sum_list_, T, Sums).

% sort_row_count(+Grid, +Val, -Counts)
% Counts is a list of integers, one per row: the count of cells equal to Val.
sort_row_count(Grid, Val, Counts) :-
    % Count Val occurrences in each row.
    maplist(sort_count_val_(Val), Grid, Counts).

% sort_count_val_(+Val, +Row, -Count): count cells equal to Val in a row.
sort_count_val_(Val, Row, Count) :-
    % include filters to matching cells.
    include([X]>>(X == Val), Row, Matches),
    % Length gives the count.
    length(Matches, Count).

% sort_col_count(+Grid, +Val, -Counts)
% Counts is a list of integers, one per column: the count of cells equal to Val.
sort_col_count(Grid, Val, Counts) :-
    % Transpose and count each column as a row.
    sort_transpose_(Grid, T),
    maplist(sort_count_val_(Val), T, Counts).

% sort_sort_rows_asc(+Grid, +Val, -Sorted)
% Sorted has the same rows as Grid, but ordered ascending by count of Val.
% Rows with fewer Val cells come first; ties preserve original order (msort is stable).
sort_sort_rows_asc(Grid, Val, Sorted) :-
    % Build (count, row_index) pairs.
    length(Grid, NRows),
    NRowsM1 is NRows - 1,
    numlist(0, NRowsM1, Indices),
    maplist([I, Count-I]>>(nth0(I, Grid, Row), sort_count_val_(Val, Row, Count)),
            Indices, Pairs),
    % msort orders ascending by count (stable).
    msort(Pairs, SortedPairs),
    % Reconstruct rows in sorted order.
    maplist([_-I, Row]>>(nth0(I, Grid, Row)), SortedPairs, Sorted).

% sort_sort_rows_desc(+Grid, +Val, -Sorted)
% Sorted has the same rows as Grid, but ordered descending by count of Val.
% Rows with more Val cells come first; ties preserve original order.
sort_sort_rows_desc(Grid, Val, Sorted) :-
    % Build (negated_count, row_index) pairs for stable descending msort.
    length(Grid, NRows),
    NRowsM1 is NRows - 1,
    numlist(0, NRowsM1, Indices),
    maplist([I, NegCount-I]>>(nth0(I, Grid, Row), sort_count_val_(Val, Row, Count),
                               NegCount is -Count),
            Indices, Pairs),
    % msort on negated counts gives descending order.
    msort(Pairs, SortedPairs),
    % Reconstruct rows in sorted order.
    maplist([_-I, Row]>>(nth0(I, Grid, Row)), SortedPairs, Sorted).

% sort_sort_cols_asc(+Grid, +Val, -Sorted)
% Sorted has the same columns as Grid, but ordered ascending by count of Val.
sort_sort_cols_asc(Grid, Val, Sorted) :-
    % Transpose to make columns into rows.
    sort_transpose_(Grid, T),
    % Sort rows (= columns) ascending.
    sort_sort_rows_asc(T, Val, SortedT),
    % Transpose back.
    sort_transpose_(SortedT, Sorted).

% sort_sort_cols_desc(+Grid, +Val, -Sorted)
% Sorted has the same columns as Grid, but ordered descending by count of Val.
sort_sort_cols_desc(Grid, Val, Sorted) :-
    % Transpose to make columns into rows.
    sort_transpose_(Grid, T),
    % Sort rows (= columns) descending by Val count.
    sort_sort_rows_desc(T, Val, SortedT),
    % Transpose back to restore row/column orientation.
    sort_transpose_(SortedT, Sorted).

% sort_max_row(+Grid, +Val, -R)
% R is the 0-based index of the row with the highest count of Val.
% On ties, the first (smallest index) row is chosen.
sort_max_row(Grid, Val, R) :-
    % Build (count, row_index) pairs.
    length(Grid, NRows),
    NRowsM1 is NRows - 1,
    numlist(0, NRowsM1, Indices),
    maplist([I, Count-I]>>(nth0(I, Grid, Row), sort_count_val_(Val, Row, Count)),
            Indices, Pairs),
    % max_member finds the pair with the highest count.
    max_member(_-R, Pairs).

% sort_min_row(+Grid, +Val, -R)
% R is the 0-based index of the row with the lowest count of Val.
sort_min_row(Grid, Val, R) :-
    % Build (count, row_index) pairs.
    length(Grid, NRows),
    NRowsM1 is NRows - 1,
    numlist(0, NRowsM1, Indices),
    maplist([I, Count-I]>>(nth0(I, Grid, Row), sort_count_val_(Val, Row, Count)),
            Indices, Pairs),
    % min_member finds the pair with the lowest count.
    min_member(_-R, Pairs).

% sort_max_col(+Grid, +Val, -C)
% C is the 0-based index of the column with the highest count of Val.
sort_max_col(Grid, Val, C) :-
    % Transpose and find the max row (= max column) index.
    sort_transpose_(Grid, T),
    sort_max_row(T, Val, C).

% sort_min_col(+Grid, +Val, -C)
% C is the 0-based index of the column with the lowest count of Val.
sort_min_col(Grid, Val, C) :-
    % Transpose and find the min row (= min column) index.
    sort_transpose_(Grid, T),
    sort_min_row(T, Val, C).

% sort_sorted_vals(+Grid, -Vals)
% Vals is all cell values from Grid, sorted ascending with duplicates preserved.
sort_sorted_vals(Grid, Vals) :-
    % Collect all cell values.
    findall(V, (member(Row, Grid), member(V, Row)), All),
    % msort preserves duplicates; sort removes them.
    msort(All, Vals).

% sort_cell_rank(+Grid, +R, +C, -Rank)
% Rank is the 1-based position of Grid[R,C] among the distinct values of Grid
% in ascending order. The smallest distinct value has rank 1.
sort_cell_rank(Grid, R, C, Rank) :-
    % Get the cell value.
    nth0(R, Grid, Row),
    nth0(C, Row, CellVal),
    % Get all distinct values sorted.
    findall(V, (member(GRow, Grid), member(V, GRow)), All),
    sort(All, Distinct),
    % Find 1-based position of CellVal in Distinct; cut to commit to first.
    nth1(Rank, Distinct, CellVal), !.

% sort_transpose_(+Grid, -Transposed): transpose a list-of-lists grid.
% Used internally for column operations.
sort_transpose_([], []) :- !.
sort_transpose_(Grid, Transposed) :-
    Grid = [FirstRow|_],
    length(FirstRow, NCols),
    NColsM1 is NCols - 1,
    numlist(0, NColsM1, CIdxs),
    maplist([CI, Col]>>(maplist([Row, V]>>(nth0(CI, Row, V)), Grid, Col)), CIdxs, Transposed).

% foldl/4 is a built-in in SWI-Prolog; no import needed.
