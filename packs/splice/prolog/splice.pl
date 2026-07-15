% splice.pl - Layer 147: Row and Column Structural Editing (sp_* prefix).
% Provides predicates for inserting, deleting, swapping, reversing, rotating,
% replicating, and selecting rows and columns in 2D grids. These operations
% structurally reshape the grid by changing its row or column count, unlike
% cell-level predicates that only modify individual values.
:- module(splice, [
    % splice_insert_row/4: insert a new row before row index R.
    splice_insert_row/4,
    % splice_delete_row/3: delete the row at index R.
    splice_delete_row/3,
    % splice_insert_col/4: insert a column of constant value V before column index C.
    splice_insert_col/4,
    % splice_delete_col/3: delete the column at index C.
    splice_delete_col/3,
    % splice_swap_rows/4: swap rows R1 and R2.
    splice_swap_rows/4,
    % splice_swap_cols/4: swap columns C1 and C2.
    splice_swap_cols/4,
    % splice_reverse_rows/2: reverse the order of rows (top-bottom flip at row level).
    splice_reverse_rows/2,
    % splice_reverse_cols/2: reverse the order of cells in each row (left-right flip).
    splice_reverse_cols/2,
    % splice_rotate_rows/3: shift rows cyclically so that row K becomes row 0.
    splice_rotate_rows/3,
    % splice_rotate_cols/3: shift columns cyclically so that column K becomes column 0.
    splice_rotate_cols/3,
    % splice_replicate_row/4: replace row R with N copies of it in the output.
    splice_replicate_row/4,
    % splice_replicate_col/4: replace column C with N copies of it in the output.
    splice_replicate_col/4,
    % splice_select_rows/3: keep only the rows at the given list of indices (in order).
    splice_select_rows/3,
    % splice_select_cols/3: keep only the columns at the given list of indices (in order).
    splice_select_cols/3
]).

% Import list utilities; sort/2, length/2, between/3, forall/2 are built-ins.
:- use_module(library(lists), [member/2, nth0/3, append/2, append/3, reverse/2]).
% Import maplist/2 and maplist/3 for row-level transformations.
:- use_module(library(apply), [maplist/2, maplist/3]).

% splice_insert_row(+Grid, +R, +NewRow, -Out): insert NewRow before row index R.
% Rows originally at R, R+1, ... shift to R+1, R+2, ... .
% R must satisfy 0 =< R =< H where H is the number of rows in Grid.
splice_insert_row(Grid, R, NewRow, Out) :-
% Split Grid at position R: Prefix holds the first R rows.
    length(Prefix, R),
% Unify Prefix with the first R rows and Suffix with the rest.
    append(Prefix, Suffix, Grid),
% Re-assemble with NewRow inserted between Prefix and Suffix.
    append(Prefix, [NewRow|Suffix], Out).

% splice_delete_row(+Grid, +R, -Out): delete the row at index R.
% Out has one fewer row than Grid. R must be a valid row index.
splice_delete_row(Grid, R, Out) :-
% Split Grid at R: the next element is the row to remove.
    length(Prefix, R),
% Unify Prefix with the first R rows; [_|Suffix] discards row R.
    append(Prefix, [_|Suffix], Grid),
% Re-assemble without the deleted row.
    append(Prefix, Suffix, Out).

% splice_insert_col_row_(+C, +V, +Row, -NewRow): insert V before column C in one row.
splice_insert_col_row_(C, V, Row, NewRow) :-
% Split Row at column C.
    length(Prefix, C),
% Unify Prefix with the first C cells; Suffix holds the rest.
    append(Prefix, Suffix, Row),
% Re-assemble with V inserted at position C.
    append(Prefix, [V|Suffix], NewRow).

% splice_insert_col(+Grid, +C, +V, -Out): insert a column of value V before column C.
% Every row gets V inserted at position C; all columns >= C shift right.
splice_insert_col(Grid, C, V, Out) :-
% Apply column insertion to every row independently.
    maplist(splice_insert_col_row_(C, V), Grid, Out).

% splice_delete_col_row_(+C, +Row, -NewRow): delete the cell at column C from one row.
splice_delete_col_row_(C, Row, NewRow) :-
% Split Row at column C.
    length(Prefix, C),
% Unify Prefix with the first C cells; [_|Suffix] discards cell C.
    append(Prefix, [_|Suffix], Row),
% Re-assemble without the deleted cell.
    append(Prefix, Suffix, NewRow).

% splice_delete_col(+Grid, +C, -Out): delete the column at index C from every row.
% Out has one fewer column than Grid. C must be a valid column index.
splice_delete_col(Grid, C, Out) :-
% Apply column deletion to every row independently.
    maplist(splice_delete_col_row_(C), Grid, Out).

% splice_swap_rows(+Grid, +R1, +R2, -Out): swap the rows at indices R1 and R2.
% If R1 = R2 the grid is unchanged. Both indices must be valid.
splice_swap_rows(Grid, R1, R2, Out) :-
% Fetch the two rows to be exchanged.
    nth0(R1, Grid, Row1),
% Fetch the second row.
    nth0(R2, Grid, Row2),
% Determine the last valid row index.
    length(Grid, H),
% Compute H-1 as an integer for between/3.
    H1 is H - 1,
% Build output by enumerating each row index and swapping as needed.
    findall(Row, (
        between(0, H1, I),
        nth0(I, Grid, OldRow),
        ( I =:= R1 -> Row = Row2
        ; I =:= R2 -> Row = Row1
        ; Row = OldRow )
    ), Out).

% splice_swap_in_row_(+C1, +C2, +Row, -NewRow): swap cells at C1 and C2 within one row.
splice_swap_in_row_(C1, C2, Row, NewRow) :-
% Fetch the two values to exchange.
    nth0(C1, Row, V1),
% Fetch the second value.
    nth0(C2, Row, V2),
% Determine the last valid column index.
    length(Row, W),
% Compute W-1 as an integer for between/3.
    W1 is W - 1,
% Build new row by enumerating each column and swapping as needed.
    findall(V, (
        between(0, W1, C),
        nth0(C, Row, OldV),
        ( C =:= C1 -> V = V2
        ; C =:= C2 -> V = V1
        ; V = OldV )
    ), NewRow).

% splice_swap_cols(+Grid, +C1, +C2, -Out): swap columns C1 and C2 in every row.
% If C1 = C2 the grid is unchanged. Both indices must be valid.
splice_swap_cols(Grid, C1, C2, Out) :-
% Apply column swap to every row independently.
    maplist(splice_swap_in_row_(C1, C2), Grid, Out).

% splice_reverse_rows(+Grid, -Out): reverse the order of rows.
% Row 0 becomes the last row; row H-1 becomes row 0.
splice_reverse_rows(Grid, Out) :-
% Reverse the top-level list of rows.
    reverse(Grid, Out).

% splice_reverse_cols(+Grid, -Out): reverse the order of cells in each row.
% Column 0 becomes the last column; mirrors the grid left-right.
splice_reverse_cols(Grid, Out) :-
% Reverse each row independently.
    maplist(reverse, Grid, Out).

% splice_rotate_rows(+Grid, +K, -Out): shift rows cyclically so that row K becomes row 0.
% Row K moves to index 0; row K+1 to index 1; row K-1 to index H-1.
% K is taken modulo H so values >= H and negative values work correctly.
splice_rotate_rows(Grid, K, Out) :-
% Get the total number of rows.
    length(Grid, H),
% Reduce K to the range [0, H-1].
    K1 is K mod H,
% Split: first K1 rows become the new tail.
    length(Prefix, K1),
% Unify Prefix with the first K1 rows; Suffix holds the rest.
    append(Prefix, Suffix, Grid),
% Re-assemble with Suffix first then Prefix.
    append(Suffix, Prefix, Out).

% splice_rotate_row_cols_(+K, +Row, -RotRow): cyclically shift one row by K positions.
splice_rotate_row_cols_(K, Row, RotRow) :-
% Get the length of the row.
    length(Row, W),
% Reduce K to the range [0, W-1].
    K1 is K mod W,
% Split: first K1 cells become the new tail.
    length(Prefix, K1),
% Unify Prefix with the first K1 cells; Suffix holds the rest.
    append(Prefix, Suffix, Row),
% Re-assemble with Suffix first then Prefix.
    append(Suffix, Prefix, RotRow).

% splice_rotate_cols(+Grid, +K, -Out): shift columns cyclically so that column K becomes column 0.
% Column K moves to index 0; column K+1 to index 1; column K-1 to index W-1.
splice_rotate_cols(Grid, K, Out) :-
% Apply column rotation to every row independently.
    maplist(splice_rotate_row_cols_(K), Grid, Out).

% splice_replicate_row(+Grid, +R, +N, -Out): replace row R with N copies of it.
% N=1 leaves row R unchanged; N=0 deletes it; N=2 inserts one extra copy after R.
splice_replicate_row(Grid, R, N, Out) :-
% Fetch the row to replicate.
    nth0(R, Grid, Row),
% Split Grid at position R: Prefix holds the R rows before row R.
    length(Prefix, R),
% Unify Prefix and [Row|Suffix] with Grid to separate the row.
    append(Prefix, [Row|Suffix], Grid),
% Build a list of N copies of Row.
    length(Copies, N),
% Unify each copy with Row.
    maplist(=(Row), Copies),
% Assemble: Prefix, N copies of Row, Suffix.
    append([Prefix, Copies, Suffix], Out).

% splice_replicate_col_in_row_(+C, +N, +Row, -NewRow): replace column C with N copies.
splice_replicate_col_in_row_(C, N, Row, NewRow) :-
% Split Row at position C: Prefix holds the C cells before column C.
    length(Prefix, C),
% Unify Prefix and [V|Suffix] with Row to isolate the cell value V.
    append(Prefix, [V|Suffix], Row),
% Build a list of N copies of V.
    length(Copies, N),
% Unify each copy with V.
    maplist(=(V), Copies),
% Assemble: Prefix, N copies of V, Suffix.
    append([Prefix, Copies, Suffix], NewRow).

% splice_replicate_col(+Grid, +C, +N, -Out): replace column C with N copies of it.
% N=1 leaves the column unchanged; N=0 deletes it; N=2 inserts one extra copy.
splice_replicate_col(Grid, C, N, Out) :-
% Apply column replication to every row independently.
    maplist(splice_replicate_col_in_row_(C, N), Grid, Out).

% splice_select_rows(+Grid, +Indices, -Out): keep only the rows at the given indices.
% Out is the list of rows in the order Indices specifies.
% Indices may repeat indices or omit any row index.
splice_select_rows(Grid, Indices, Out) :-
% Collect each row in order by its index.
    findall(Row, (member(I, Indices), nth0(I, Grid, Row)), Out).

% splice_select_col_from_row_(+Indices, +Row, -NewRow): keep only columns at Indices.
splice_select_col_from_row_(Indices, Row, NewRow) :-
% Collect each cell value in order by column index.
    findall(V, (member(C, Indices), nth0(C, Row, V)), NewRow).

% splice_select_cols(+Grid, +Indices, -Out): keep only the columns at the given indices.
% Out has columns reordered and filtered according to Indices.
% Indices may repeat indices or omit any column index.
splice_select_cols(Grid, Indices, Out) :-
% Apply column selection to every row independently.
    maplist(splice_select_col_from_row_(Indices), Grid, Out).
