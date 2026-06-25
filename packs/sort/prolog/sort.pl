% sort - Layer 80: sorting, ranking, and ordering operations on grids.
% Module sort exports 14 so_* predicates covering per-row/column sums and counts,
% row/column sorting by value frequency, identifying extremal rows/columns,
% and cell ranking within a grid.
:- module(sort, [
    % Integer sum of each row.
    so_row_sums/2,
    % Integer sum of each column.
    so_col_sums/2,
    % Count of a specific value per row.
    so_row_count/3,
    % Count of a specific value per column.
    so_col_count/3,
    % Sort rows ascending by count of a specific value.
    so_sort_rows_asc/3,
    % Sort rows descending by count of a specific value.
    so_sort_rows_desc/3,
    % Sort columns ascending by count of a specific value.
    so_sort_cols_asc/3,
    % Sort columns descending by count of a specific value.
    so_sort_cols_desc/3,
    % Row index with the highest count of a specific value.
    so_max_row/3,
    % Row index with the lowest count of a specific value.
    so_min_row/3,
    % Column index with the highest count of a specific value.
    so_max_col/3,
    % Column index with the lowest count of a specific value.
    so_min_col/3,
    % All cell values sorted ascending, preserving duplicates.
    so_sorted_vals/2,
    % 1-based rank of a cell value among distinct grid values.
    so_cell_rank/4
]).

% Load list utilities for index access and extrema.
:- use_module(library(lists), [member/2, nth0/3, nth1/3, numlist/3,
                                max_member/2, min_member/2]).
% Load apply utilities for row and column mapping.
:- use_module(library(apply), [maplist/2, maplist/3, include/3]).

% so_row_sums(+Grid, -Sums)
% Sums is a list of integers, one per row, each being the sum of that row's cells.
so_row_sums(Grid, Sums) :-
    % Sum each row independently.
    maplist(so_sum_list_, Grid, Sums).

% so_sum_list_(+List, -Sum): integer sum of a list of numbers.
so_sum_list_(List, Sum) :-
    % Accumulate using a fold.
    foldl([X, Acc, NAcc]>>(NAcc is Acc + X), List, 0, Sum).

% so_col_sums(+Grid, -Sums)
% Sums is a list of integers, one per column, each being the sum of that column's cells.
so_col_sums(Grid, Sums) :-
    % Transpose rows to columns, then sum each column as a row.
    so_transpose_(Grid, T),
    maplist(so_sum_list_, T, Sums).

% so_row_count(+Grid, +Val, -Counts)
% Counts is a list of integers, one per row: the count of cells equal to Val.
so_row_count(Grid, Val, Counts) :-
    % Count Val occurrences in each row.
    maplist(so_count_val_(Val), Grid, Counts).

% so_count_val_(+Val, +Row, -Count): count cells equal to Val in a row.
so_count_val_(Val, Row, Count) :-
    % include filters to matching cells.
    include([X]>>(X == Val), Row, Matches),
    % Length gives the count.
    length(Matches, Count).

% so_col_count(+Grid, +Val, -Counts)
% Counts is a list of integers, one per column: the count of cells equal to Val.
so_col_count(Grid, Val, Counts) :-
    % Transpose and count each column as a row.
    so_transpose_(Grid, T),
    maplist(so_count_val_(Val), T, Counts).

% so_sort_rows_asc(+Grid, +Val, -Sorted)
% Sorted has the same rows as Grid, but ordered ascending by count of Val.
% Rows with fewer Val cells come first; ties preserve original order (msort is stable).
so_sort_rows_asc(Grid, Val, Sorted) :-
    % Build (count, row_index) pairs.
    length(Grid, NRows),
    NRowsM1 is NRows - 1,
    numlist(0, NRowsM1, Indices),
    maplist([I, Count-I]>>(nth0(I, Grid, Row), so_count_val_(Val, Row, Count)),
            Indices, Pairs),
    % msort orders ascending by count (stable).
    msort(Pairs, SortedPairs),
    % Reconstruct rows in sorted order.
    maplist([_-I, Row]>>(nth0(I, Grid, Row)), SortedPairs, Sorted).

% so_sort_rows_desc(+Grid, +Val, -Sorted)
% Sorted has the same rows as Grid, but ordered descending by count of Val.
% Rows with more Val cells come first; ties preserve original order.
so_sort_rows_desc(Grid, Val, Sorted) :-
    % Build (negated_count, row_index) pairs for stable descending msort.
    length(Grid, NRows),
    NRowsM1 is NRows - 1,
    numlist(0, NRowsM1, Indices),
    maplist([I, NegCount-I]>>(nth0(I, Grid, Row), so_count_val_(Val, Row, Count),
                               NegCount is -Count),
            Indices, Pairs),
    % msort on negated counts gives descending order.
    msort(Pairs, SortedPairs),
    % Reconstruct rows in sorted order.
    maplist([_-I, Row]>>(nth0(I, Grid, Row)), SortedPairs, Sorted).

% so_sort_cols_asc(+Grid, +Val, -Sorted)
% Sorted has the same columns as Grid, but ordered ascending by count of Val.
so_sort_cols_asc(Grid, Val, Sorted) :-
    % Transpose to make columns into rows.
    so_transpose_(Grid, T),
    % Sort rows (= columns) ascending.
    so_sort_rows_asc(T, Val, SortedT),
    % Transpose back.
    so_transpose_(SortedT, Sorted).

% so_sort_cols_desc(+Grid, +Val, -Sorted)
% Sorted has the same columns as Grid, but ordered descending by count of Val.
so_sort_cols_desc(Grid, Val, Sorted) :-
    % Transpose to make columns into rows.
    so_transpose_(Grid, T),
    % Sort rows (= columns) descending by Val count.
    so_sort_rows_desc(T, Val, SortedT),
    % Transpose back to restore row/column orientation.
    so_transpose_(SortedT, Sorted).

% so_max_row(+Grid, +Val, -R)
% R is the 0-based index of the row with the highest count of Val.
% On ties, the first (smallest index) row is chosen.
so_max_row(Grid, Val, R) :-
    % Build (count, row_index) pairs.
    length(Grid, NRows),
    NRowsM1 is NRows - 1,
    numlist(0, NRowsM1, Indices),
    maplist([I, Count-I]>>(nth0(I, Grid, Row), so_count_val_(Val, Row, Count)),
            Indices, Pairs),
    % max_member finds the pair with the highest count.
    max_member(_-R, Pairs).

% so_min_row(+Grid, +Val, -R)
% R is the 0-based index of the row with the lowest count of Val.
so_min_row(Grid, Val, R) :-
    % Build (count, row_index) pairs.
    length(Grid, NRows),
    NRowsM1 is NRows - 1,
    numlist(0, NRowsM1, Indices),
    maplist([I, Count-I]>>(nth0(I, Grid, Row), so_count_val_(Val, Row, Count)),
            Indices, Pairs),
    % min_member finds the pair with the lowest count.
    min_member(_-R, Pairs).

% so_max_col(+Grid, +Val, -C)
% C is the 0-based index of the column with the highest count of Val.
so_max_col(Grid, Val, C) :-
    % Transpose and find the max row (= max column) index.
    so_transpose_(Grid, T),
    so_max_row(T, Val, C).

% so_min_col(+Grid, +Val, -C)
% C is the 0-based index of the column with the lowest count of Val.
so_min_col(Grid, Val, C) :-
    % Transpose and find the min row (= min column) index.
    so_transpose_(Grid, T),
    so_min_row(T, Val, C).

% so_sorted_vals(+Grid, -Vals)
% Vals is all cell values from Grid, sorted ascending with duplicates preserved.
so_sorted_vals(Grid, Vals) :-
    % Collect all cell values.
    findall(V, (member(Row, Grid), member(V, Row)), All),
    % msort preserves duplicates; sort removes them.
    msort(All, Vals).

% so_cell_rank(+Grid, +R, +C, -Rank)
% Rank is the 1-based position of Grid[R,C] among the distinct values of Grid
% in ascending order. The smallest distinct value has rank 1.
so_cell_rank(Grid, R, C, Rank) :-
    % Get the cell value.
    nth0(R, Grid, Row),
    nth0(C, Row, CellVal),
    % Get all distinct values sorted.
    findall(V, (member(GRow, Grid), member(V, GRow)), All),
    sort(All, Distinct),
    % Find 1-based position of CellVal in Distinct; cut to commit to first.
    nth1(Rank, Distinct, CellVal), !.

% so_transpose_(+Grid, -Transposed): transpose a list-of-lists grid.
% Used internally for column operations.
so_transpose_([], []) :- !.
so_transpose_(Grid, Transposed) :-
    Grid = [FirstRow|_],
    length(FirstRow, NCols),
    NColsM1 is NCols - 1,
    numlist(0, NColsM1, CIdxs),
    maplist([CI, Col]>>(maplist([Row, V]>>(nth0(CI, Row, V)), Grid, Col)), CIdxs, Transposed).

% foldl/4 is a built-in in SWI-Prolog; no import needed.
