% table.pl - Layer 123: Grid-as-Table Operations (tb_* prefix).
% General-purpose predicates for treating a 2D grid as a table of rows.
:- module(table, [
    tb_transpose/2,
    tb_sort_rows/3, tb_filter_rows/4,
    tb_group_by/3, tb_count_by/3,
    tb_unique_rows/2,
    tb_select_cols/3, tb_drop_col/3, tb_add_col/3,
    tb_insert_row/4, tb_delete_row/3,
    tb_swap_rows/4, tb_col_max_row/3, tb_col_min_row/3
]).
% Import list utilities used across this module.
:- use_module(library(lists), [member/2, nth0/3, append/3, max_list/2, min_list/2]).
% Import apply utilities for row-level transformations.
:- use_module(library(apply), [maplist/3]).

% tb_transpose(+Grid, -TGrid): transpose Grid so rows become columns.
tb_transpose(Grid, TGrid) :-
% Compute column count to know how many columns to collect.
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(Col, (
        between(0, W1, C),
        findall(V, (member(Row, Grid), nth0(C, Row, V)), Col)
    ), TGrid).

% tb_sort_rows(+Grid, +C, -Sorted): sort rows ascending by value in column C.
tb_sort_rows(Grid, C, Sorted) :-
% Build key-value pairs keyed by column C value then keysort.
    findall(V-Row, (member(Row, Grid), nth0(C, Row, V)), Pairs),
    keysort(Pairs, SortedPairs),
    findall(Row, member(_-Row, SortedPairs), Sorted).

% tb_filter_rows(+Grid, +C, +V, -Filtered): keep rows where column C equals V.
tb_filter_rows(Grid, C, V, Filtered) :-
% Collect rows that pass the column equality test.
    findall(Row, (member(Row, Grid), nth0(C, Row, V)), Filtered).

% tb_group_by(+Grid, +C, -Groups): group rows by their column C value.
tb_group_by(Grid, C, Groups) :-
% First collect and sort unique column C values.
    findall(V, (member(Row, Grid), nth0(C, Row, V)), Vs0),
    sort(Vs0, UniqueVs),
    findall(V-Rows, (
        member(V, UniqueVs),
        findall(Row, (member(Row, Grid), nth0(C, Row, V)), Rows)
    ), Groups).

% tb_count_by(+Grid, +C, -Counts): count rows per unique column C value.
tb_count_by(Grid, C, Counts) :-
% Delegate to tb_group_by then measure each group size.
    tb_group_by(Grid, C, Groups),
    findall(V-N, (member(V-Rows, Groups), length(Rows, N)), Counts).

% tb_unique_rows(+Grid, -UniqueGrid): deduplicate rows preserving first occurrence.
tb_unique_rows(Grid, UniqueGrid) :-
% Recursive helper accumulates seen rows and skips duplicates.
    tb_unique_rows_(Grid, [], UniqueGrid).
% Base case: empty grid produces no output.
tb_unique_rows_([], _, []).
% Row not yet seen: include it and add to seen set.
tb_unique_rows_([Row|Rest], Seen, [Row|UniqueRest]) :-
    \+ member(Row, Seen), !,
    tb_unique_rows_(Rest, [Row|Seen], UniqueRest).
% Row already seen: skip it.
tb_unique_rows_([_|Rest], Seen, UniqueRest) :-
    tb_unique_rows_(Rest, Seen, UniqueRest).

% tb_select_cols(+Grid, +ColIdxs, -SubGrid): extract columns at the given indices.
tb_select_cols(Grid, ColIdxs, SubGrid) :-
% For each row, collect only the elements at the specified column positions.
    findall(SubRow, (
        member(Row, Grid),
        findall(V, (member(C, ColIdxs), nth0(C, Row, V)), SubRow)
    ), SubGrid).

% tb_drop_col(+Grid, +C, -Grid2): remove column C from every row.
tb_drop_col(Grid, C, Grid2) :-
% For each row, collect all elements except at position C.
    findall(Row2, (
        member(Row, Grid),
        length(Row, W), W1 is W - 1,
        findall(V, (between(0, W1, Ci), Ci \= C, nth0(Ci, Row, V)), Row2)
    ), Grid2).

% tb_add_col(+Grid, +NewCol, -Grid2): append NewCol list as a new rightmost column.
tb_add_col(Grid, NewCol, Grid2) :-
% Pair each row by index with the corresponding element of NewCol then append.
    findall(Row2, (
        nth0(I, Grid, Row),
        nth0(I, NewCol, V),
        append(Row, [V], Row2)
    ), Grid2).

% tb_insert_row(+Grid, +Row, +R, -Grid2): insert Row before position R (0-indexed).
% Position 0 inserts at the beginning; position H inserts at the end.
tb_insert_row(Grid, Row, 0, [Row|Grid]) :- !.
tb_insert_row([H|T], Row, R, [H|T2]) :-
% Recurse with decremented R until the target position is reached.
    R > 0, R1 is R - 1,
    tb_insert_row(T, Row, R1, T2).

% tb_delete_row(+Grid, +R, -Grid2): remove the row at position R.
tb_delete_row(Grid, R, Grid2) :-
% Collect all rows except the one at index R.
    findall(Row, (nth0(I, Grid, Row), I \= R), Grid2).

% tb_swap_rows(+Grid, +R1, +R2, -Grid2): swap rows R1 and R2.
tb_swap_rows(Grid, R1, R2, Grid2) :-
% Fetch both rows first, then rebuild the grid substituting them.
    nth0(R1, Grid, Row1),
    nth0(R2, Grid, Row2),
    findall(Row, (
        nth0(I, Grid, Row0),
        (I =:= R1 -> Row = Row2 ; I =:= R2 -> Row = Row1 ; Row = Row0)
    ), Grid2).

% tb_col_max_row(+Grid, +C, -R): 0-indexed row where column C has its maximum value.
% On ties, returns the first (lowest-indexed) such row.
tb_col_max_row(Grid, C, R) :-
% Collect all column C values, find the max, then locate the first row with it.
    findall(V, (member(Row, Grid), nth0(C, Row, V)), Vs),
    max_list(Vs, MaxV),
    nth0(R, Grid, Row),
    nth0(C, Row, MaxV), !.

% tb_col_min_row(+Grid, +C, -R): 0-indexed row where column C has its minimum value.
% On ties, returns the first (lowest-indexed) such row.
tb_col_min_row(Grid, C, R) :-
% Collect all column C values, find the min, then locate the first row with it.
    findall(V, (member(Row, Grid), nth0(C, Row, V)), Vs),
    min_list(Vs, MinV),
    nth0(R, Grid, Row),
    nth0(C, Row, MinV), !.
