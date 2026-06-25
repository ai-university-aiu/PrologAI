% permute.pl - Layer 94: Row and Column Permutation Operations (pm_* prefix).
% Provides arbitrary reordering, swapping, cyclic shifting, permutation
% discovery, lexicographic sorting, and insertion/deletion for grid rows
% and columns.
:- module(permute, [
    pm_permute_rows/3,
    pm_permute_cols/3,
    pm_swap_rows/4,
    pm_swap_cols/4,
    pm_cycle_rows/3,
    pm_cycle_cols/3,
    pm_find_row_perm/3,
    pm_find_col_perm/3,
    pm_sort_rows/2,
    pm_sort_cols/2,
    pm_insert_row/4,
    pm_delete_row/3,
    pm_insert_col/4,
    pm_delete_col/3
]).
% Import nth0/3 for indexed access and nth0/4 for list replacement.
:- use_module(library(lists), [nth0/3, nth0/4, numlist/3, append/2, append/3]).
% Import higher-order utilities for row and column mapping.
:- use_module(library(apply), [maplist/2, maplist/3, maplist/4]).

% pm_col_: extract column C from Grid as a list of values (top to bottom).
pm_col_(Grid, C, Col) :-
% For each row in Grid, take the Cth element.
    maplist([Row, V]>>(nth0(C, Row, V)), Grid, Col).

% pm_first_row_idx_: find the 0-based index of the first row in Grid
% that equals TargetRow. Fails if no matching row exists.
pm_first_row_idx_(Grid, TargetRow, I) :-
% nth0 will try indices in order; cut commits to the first match.
    nth0(I, Grid, TargetRow), !.

% pm_first_col_idx_: find the 0-based column index whose column list
% in Grid equals TargetCol. Fails if no matching column exists.
pm_first_col_idx_(Grid, TargetCol, I) :-
% Enumerate columns until the extracted column matches TargetCol.
    Grid = [FirstRow|_], length(FirstRow, NC), NC1 is NC - 1,
    between(0, NC1, I),
    pm_col_(Grid, I, TargetCol), !.

% pm_permute_rows(+Grid, +Perm, -Result): reorder rows of Grid according
% to index permutation Perm. Result[i] = Grid[Perm[i]].
pm_permute_rows(Grid, Perm, Result) :-
% For each index I in Perm, retrieve row I from Grid.
    maplist([I, Row]>>(nth0(I, Grid, Row)), Perm, Result).

% pm_permute_cols(+Grid, +Perm, -Result): reorder columns of Grid according
% to index permutation Perm. Result column j = Grid column Perm[j].
pm_permute_cols(Grid, Perm, Result) :-
% For each row, reorder its cells by Perm.
    maplist([GRow, ResRow]>>(
        maplist([C, Val]>>(nth0(C, GRow, Val)), Perm, ResRow)
    ), Grid, Result).

% pm_swap_rows(+Grid, +R1, +R2, -Result): exchange rows R1 and R2 in Grid.
pm_swap_rows(Grid, R1, R2, Result) :-
% Extract both rows.
    nth0(R1, Grid, RowA),
    nth0(R2, Grid, RowB),
% Build the result by substituting RowB at R1 and RowA at R2.
    length(Grid, NR), NR1 is NR - 1, numlist(0, NR1, Idxs),
    maplist([I, Row]>>(
        (I == R1 -> Row = RowB ; I == R2 -> Row = RowA ; nth0(I, Grid, Row))
    ), Idxs, Result).

% pm_swap_cols(+Grid, +C1, +C2, -Result): exchange columns C1 and C2.
pm_swap_cols(Grid, C1, C2, Result) :-
% Compute a permutation that swaps C1 and C2 and leaves others unchanged.
    Grid = [FR|_], length(FR, NC), NC1 is NC - 1, numlist(0, NC1, Idxs),
    maplist([I, J]>>(
        (I == C1 -> J = C2 ; I == C2 -> J = C1 ; J = I)
    ), Idxs, Perm),
% Apply the column permutation.
    pm_permute_cols(Grid, Perm, Result).

% pm_cycle_rows(+Grid, +N, -Result): shift rows cyclically by N positions
% downward. The last N rows move to the front.
% N=0 returns Grid unchanged; N=1 moves the last row to position 0.
pm_cycle_rows(Grid, N, Result) :-
% Compute the effective shift modulo row count.
    length(Grid, NR),
    Shift is N mod NR,
    (Shift =:= 0 ->
        Result = Grid
    ;
% Split Grid into top (NR-Shift rows) and bottom (Shift rows).
        Split is NR - Shift,
        length(TopRows, Split),
        append(TopRows, BottomRows, Grid),
% Move the bottom rows to the front.
        append(BottomRows, TopRows, Result)
    ).

% pm_cycle_cols(+Grid, +N, -Result): shift columns cyclically by N positions
% rightward. The last N columns move to the left.
% N=0 returns Grid unchanged; N=1 moves the last column to position 0.
pm_cycle_cols(Grid, N, Result) :-
% Compute the effective shift modulo column count.
    Grid = [FirstRow|_], length(FirstRow, NC),
    Shift is N mod NC,
    (Shift =:= 0 ->
        Result = Grid
    ;
        Split is NC - Shift,
% For each row, split into left and right then recombine with right first.
        maplist([Row, ResRow]>>(
            length(LeftPart, Split),
            append(LeftPart, RightPart, Row),
            append(RightPart, LeftPart, ResRow)
        ), Grid, Result)
    ).

% pm_find_row_perm(+Grid1, +Grid2, -Perm): find the index permutation
% such that Grid2[i] = Grid1[Perm[i]] for each i.
% Fails if any row of Grid2 does not appear in Grid1.
pm_find_row_perm(Grid1, Grid2, Perm) :-
% For each row in Grid2, find its first matching index in Grid1.
    maplist(pm_first_row_idx_(Grid1), Grid2, Perm).

% pm_find_col_perm(+Grid1, +Grid2, -Perm): find the index permutation
% such that column j of Grid2 equals column Perm[j] of Grid1.
% Fails if any column of Grid2 does not appear in Grid1.
pm_find_col_perm(Grid1, Grid2, Perm) :-
% Extract all columns from Grid2 as lists.
    Grid2 = [FR2|_], length(FR2, NC2), NC2_1 is NC2 - 1, numlist(0, NC2_1, ColIdxs2),
    maplist([C, Col]>>(pm_col_(Grid2, C, Col)), ColIdxs2, Cols2),
% For each column of Grid2, find its first matching column index in Grid1.
    maplist(pm_first_col_idx_(Grid1), Cols2, Perm).

% pm_sort_rows(+Grid, -Sorted): sort Grid rows in ascending lexicographic
% order. Duplicate rows are preserved (msort, not sort).
pm_sort_rows(Grid, Sorted) :-
% msort is a built-in that sorts without removing duplicates.
    msort(Grid, Sorted).

% pm_sort_cols(+Grid, -Sorted): sort Grid columns in ascending lexicographic
% order. Duplicate columns are preserved.
pm_sort_cols(Grid, Sorted) :-
% Extract all columns as lists.
    Grid = [FR|_], length(FR, NC), NC1 is NC - 1, numlist(0, NC1, ColIdxs),
    maplist([C, Col]>>(pm_col_(Grid, C, Col)), ColIdxs, Cols),
% Sort the column list lexicographically.
    msort(Cols, SortedCols),
% Reconstruct the grid from sorted columns.
    length(Grid, NR), NR1 is NR - 1, numlist(0, NR1, RowIdxs),
    maplist([R, ResRow]>>(
        maplist([Col, V]>>(nth0(R, Col, V)), SortedCols, ResRow)
    ), RowIdxs, Sorted).

% pm_insert_row(+Grid, +R, +NewRow, -Result): insert NewRow before position R.
% Existing rows at R and beyond are shifted down by one.
pm_insert_row(Grid, R, NewRow, Result) :-
% Split Grid into the prefix (first R rows) and the suffix (remaining rows).
    length(Prefix, R),
    append(Prefix, Suffix, Grid),
% Insert NewRow between Prefix and Suffix.
    append(Prefix, [NewRow|Suffix], Result).

% pm_delete_row(+Grid, +R, -Result): remove row R from Grid.
% Rows beyond R shift up by one. Fails if R is out of range.
pm_delete_row(Grid, R, Result) :-
% nth0/4: removes the element at index R and returns the rest.
    nth0(R, Grid, _, Result).

% pm_insert_col(+Grid, +C, +NewCol, -Result): insert NewCol before column C.
% Existing columns at C and beyond shift right by one.
% NewCol must be a list with one value per row.
pm_insert_col(Grid, C, NewCol, Result) :-
% For each row and corresponding column value, split and insert.
    maplist([Row, NewVal, ResRow]>>(
        length(Prefix, C),
        append(Prefix, Suffix, Row),
        append(Prefix, [NewVal|Suffix], ResRow)
    ), Grid, NewCol, Result).

% pm_delete_col(+Grid, +C, -Result): remove column C from every row.
% Fails if C is out of range for any row.
pm_delete_col(Grid, C, Result) :-
% For each row, remove the element at index C using nth0/4.
    maplist([Row, ResRow]>>(nth0(C, Row, _, ResRow)), Grid, Result).
