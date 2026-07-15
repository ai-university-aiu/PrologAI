% rowsig.pl - Layer 140: Row and Column Signature Analysis (rs_* prefix).
% Provides predicates for extracting individual and all columns, computing
% row and column frequency tables, finding the modal row and column, identifying
% rows and columns that appear exactly once, finding duplicate row and column
% index pairs, testing rows and columns for palindrome structure, and testing
% whether two rows or two columns are anagrams (same value multiset).
:- module(rowsig, [
    rowsig_col_at/3,
    rowsig_all_cols/2,
    rowsig_row_freq/2,
    rowsig_col_freq/2,
    rowsig_modal_row/2,
    rowsig_modal_col/2,
    rowsig_uniq_rows/2,
    rowsig_uniq_cols/2,
    rowsig_dup_row_pairs/2,
    rowsig_dup_col_pairs/2,
    rowsig_row_palindrome/2,
    rowsig_col_palindrome/2,
    rowsig_rows_anagram/3,
    rowsig_cols_anagram/3
]).
% Import list utilities; sort/2, msort/2, length/2, between/3, findall/3 are built-ins.
:- use_module(library(lists), [member/2, nth0/3, reverse/2, last/2]).
% Import include/3 for filtering by row or column equality.
:- use_module(library(apply), [include/3]).

% rowsig_col_at(+Grid, +C, -Col): Col is the ordered list of values in column C,
% enumerated top-to-bottom (row 0 first). Fails if C is out of range.
rowsig_col_at(Grid, C, Col) :-
% Collect the value at column C from every row in Grid order.
    findall(V, (member(Row, Grid), nth0(C, Row, V)), Col).

% rowsig_all_cols(+Grid, -Cols): Cols is the list of all columns in column order
% (column 0 first). Each element of Cols is a top-to-bottom list of values.
rowsig_all_cols(Grid, Cols) :-
% Determine column count from the first row; default 0 for empty grid.
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0),
% Highest valid column index.
    W1 is W - 1,
% Collect each column as a list using rowsig_col_at.
    findall(Col, (between(0, W1, C), rowsig_col_at(Grid, C, Col)), Cols).

% rowsig_row_freq(+Grid, -Freqs): Freqs is the list of Row-N pairs where N is the
% number of times Row appears in Grid. Sorted by N descending (most common first);
% rows with equal count are ordered by reverse standard order (largest row last).
rowsig_row_freq(Grid, Freqs) :-
% Collect unique rows via sort (removes duplicates; sorts ascending).
    sort(Grid, UniqRows),
% For each unique row, count its occurrences in Grid.
    findall(N-Row, (member(Row, UniqRows),
        include(=(Row), Grid, M), length(M, N)), Raw),
% Sort ascending by N (then by Row on tie); reverse for descending.
    msort(Raw, Sorted),
    reverse(Sorted, Rev),
% Convert N-Row key format to Row-N output format.
    findall(Row-N, member(N-Row, Rev), Freqs).

% rowsig_col_freq(+Grid, -Freqs): Freqs is the list of Col-N pairs where N is the
% number of times column list Col appears. Sorted by N descending.
rowsig_col_freq(Grid, Freqs) :-
% Extract all columns as lists.
    rowsig_all_cols(Grid, Cols),
% Collect unique column lists.
    sort(Cols, UniqCols),
% For each unique column, count its occurrences.
    findall(N-Col, (member(Col, UniqCols),
        include(=(Col), Cols, M), length(M, N)), Raw),
% Sort ascending by count; reverse for descending.
    msort(Raw, Sorted),
    reverse(Sorted, Rev),
% Convert N-Col key format to Col-N output format.
    findall(Col-N, member(N-Col, Rev), Freqs).

% rowsig_modal_row(+Grid, -Row): Row is the row that appears most often in Grid.
% Ties broken by standard order descending (largest row wins, via msort + last).
% Fails if Grid is empty.
rowsig_modal_row(Grid, Row) :-
% Collect unique rows.
    sort(Grid, UniqRows),
% Count each unique row.
    findall(N-Row2, (member(Row2, UniqRows),
        include(=(Row2), Grid, M), length(M, N)), Raw),
% Sort ascending; the last element has the highest count (and largest row on tie).
    msort(Raw, Sorted),
    last(Sorted, _-Row).

% rowsig_modal_col(+Grid, -Col): Col is the column list that appears most often.
% Ties broken by largest column list (standard order, via msort + last).
% Fails if Grid is empty or has no columns.
rowsig_modal_col(Grid, Col) :-
% Extract all columns.
    rowsig_all_cols(Grid, Cols),
% Collect unique columns.
    sort(Cols, UniqCols),
% Count each unique column.
    findall(N-Col2, (member(Col2, UniqCols),
        include(=(Col2), Cols, M), length(M, N)), Raw),
% Sort ascending; last element has highest count (largest col on tie).
    msort(Raw, Sorted),
    last(Sorted, _-Col).

% rowsig_uniq_rows(+Grid, -Pairs): Pairs is the list of R-Row terms for each row index R
% whose row value appears exactly once in Grid. Ordered by row index ascending.
rowsig_uniq_rows(Grid, Pairs) :-
% Determine row index range.
    length(Grid, H), H1 is H - 1,
% Collect rows that appear exactly once (include count = 1).
    findall(R-Row, (between(0, H1, R),
        nth0(R, Grid, Row),
        include(=(Row), Grid, M), length(M, 1)), Pairs).

% rowsig_uniq_cols(+Grid, -Pairs): Pairs is the list of C-Col terms for each column
% index C whose column list appears exactly once. Ordered by column index ascending.
rowsig_uniq_cols(Grid, Pairs) :-
% Extract all columns.
    rowsig_all_cols(Grid, Cols),
% Determine column index range.
    length(Cols, W), W1 is W - 1,
% Collect columns that appear exactly once.
    findall(C-Col, (between(0, W1, C),
        nth0(C, Cols, Col),
        include(=(Col), Cols, M), length(M, 1)), Pairs).

% rowsig_dup_row_pairs(+Grid, -Pairs): Pairs is the list of R1-R2 index pairs where
% row R1 equals row R2 and R1 < R2. Ordered lexicographically by R1 then R2.
rowsig_dup_row_pairs(Grid, Pairs) :-
% Determine row index range.
    length(Grid, H), H1 is H - 1,
% Find all strictly ordered index pairs sharing the same row value.
    findall(R1-R2, (between(0, H1, R1), between(0, H1, R2),
        R1 < R2,
        nth0(R1, Grid, Row), nth0(R2, Grid, Row)), Pairs).

% rowsig_dup_col_pairs(+Grid, -Pairs): Pairs is the list of C1-C2 index pairs where
% column C1 equals column C2 and C1 < C2. Ordered by C1 then C2.
rowsig_dup_col_pairs(Grid, Pairs) :-
% Extract all column lists.
    rowsig_all_cols(Grid, Cols),
% Determine column index range.
    length(Cols, W), W1 is W - 1,
% Find all strictly ordered index pairs sharing the same column value list.
    findall(C1-C2, (between(0, W1, C1), between(0, W1, C2),
        C1 < C2,
        nth0(C1, Cols, Col), nth0(C2, Cols, Col)), Pairs).

% rowsig_row_palindrome(+Grid, +R): succeeds if row R reads the same left-to-right
% and right-to-left (i.e., the row list equals its own reverse).
rowsig_row_palindrome(Grid, R) :-
% Extract row R.
    nth0(R, Grid, Row),
% Palindrome iff reverse equals original.
    reverse(Row, Row).

% rowsig_col_palindrome(+Grid, +C): succeeds if column C reads the same top-to-bottom
% and bottom-to-top (i.e., the column list equals its own reverse).
rowsig_col_palindrome(Grid, C) :-
% Extract column C as a list.
    rowsig_col_at(Grid, C, Col),
% Palindrome iff reverse equals original.
    reverse(Col, Col).

% rowsig_rows_anagram(+Grid, +R1, +R2): succeeds if rows R1 and R2 in Grid have the
% same multiset of values (i.e., msort of both rows produces the same list).
rowsig_rows_anagram(Grid, R1, R2) :-
% Extract both rows.
    nth0(R1, Grid, Row1),
    nth0(R2, Grid, Row2),
% Anagram iff sorted multisets are equal.
    msort(Row1, Sorted),
    msort(Row2, Sorted).

% rowsig_cols_anagram(+Grid, +C1, +C2): succeeds if columns C1 and C2 in Grid have
% the same multiset of values (i.e., msort of both columns produces the same list).
rowsig_cols_anagram(Grid, C1, C2) :-
% Extract both columns.
    rowsig_col_at(Grid, C1, Col1),
    rowsig_col_at(Grid, C2, Col2),
% Anagram iff sorted multisets are equal.
    msort(Col1, Sorted),
    msort(Col2, Sorted).
