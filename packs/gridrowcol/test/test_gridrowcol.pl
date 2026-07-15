:- use_module('../prolog/gridrowcol').

% Grid fixtures
% 3x3 grid with all rows and columns distinct
g3x3([[a,b,c],[d,e,f],[g,h,i]]).
% 3x3 with rows 0 and 2 equal to [r,r,r]; row 1 is [x,x,x]
g3x3_dup([[r,r,r],[x,x,x],[r,r,r]]).
% 3x3 with all rows and columns identical [r,r,r]
g3x3_uni([[r,r,r],[r,r,r],[r,r,r]]).
% 3x3 with columns 0 and 2 matching: col0=[a,c,e], col1=[b,d,f], col2=[a,c,e]
g3x3_c02([[a,b,a],[c,d,c],[e,f,e]]).
% 1x1 single-cell grid
g1x1([[x]]).
% 4x3 with columns in unsorted order c, a, b
g4x3_unsorted([[c,a,b],[c,a,b],[c,a,b],[c,a,b]]).
% 3x3 with rows in reverse sorted order
g3x3_unsorted([[c,c,c],[a,a,a],[b,b,b]]).

:- begin_tests(gridrowcol).

% --- gridrowcol_row ---
test(row_r0, []) :-
    g3x3(G), gridrowcol_row(G, 0, [a,b,c]).

test(row_r2, []) :-
    g3x3(G), gridrowcol_row(G, 2, [g,h,i]).

% --- gridrowcol_col ---
test(col_c0, []) :-
    g3x3(G), gridrowcol_col(G, 0, [a,d,g]).

test(col_c2, []) :-
    g3x3(G), gridrowcol_col(G, 2, [c,f,i]).

% --- gridrowcol_row_uniform ---
test(row_uniform_yes, []) :-
    g3x3_uni(G), gridrowcol_row_uniform(G, 0, r).

test(row_uniform_no, []) :-
    g3x3(G), \+ gridrowcol_row_uniform(G, 0, _).

test(row_uniform_1x1, []) :-
    g1x1(G), gridrowcol_row_uniform(G, 0, x).

% --- gridrowcol_col_uniform ---
test(col_uniform_yes, []) :-
    g3x3_uni(G), gridrowcol_col_uniform(G, 2, r).

test(col_uniform_no, []) :-
    g3x3(G), \+ gridrowcol_col_uniform(G, 0, _).

test(col_uniform_1x1, []) :-
    g1x1(G), gridrowcol_col_uniform(G, 0, x).

% --- gridrowcol_equal_rows ---
test(equal_rows_yes, []) :-
    g3x3_dup(G), gridrowcol_equal_rows(G, 0, 2).

test(equal_rows_no, []) :-
    g3x3(G), \+ gridrowcol_equal_rows(G, 0, 1).

test(equal_rows_self, []) :-
    g3x3(G), gridrowcol_equal_rows(G, 1, 1).

% --- gridrowcol_equal_cols ---
test(equal_cols_yes, []) :-
    g3x3_c02(G), gridrowcol_equal_cols(G, 0, 2).

test(equal_cols_no, []) :-
    g3x3(G), \+ gridrowcol_equal_cols(G, 0, 1).

test(equal_cols_self, []) :-
    g3x3(G), gridrowcol_equal_cols(G, 2, 2).

% --- gridrowcol_row_positions ---
test(row_positions_found, []) :-
    g3x3_dup(G), gridrowcol_row_positions(G, [r,r,r], [0,2]).

test(row_positions_not_found, []) :-
    g3x3(G), gridrowcol_row_positions(G, [z,z,z], []).

test(row_positions_all, []) :-
    g3x3_uni(G), gridrowcol_row_positions(G, [r,r,r], [0,1,2]).

% --- gridrowcol_col_positions ---
test(col_positions_found, []) :-
    g3x3_c02(G), gridrowcol_col_positions(G, [a,c,e], [0,2]).

test(col_positions_not_found, []) :-
    g3x3(G), gridrowcol_col_positions(G, [z,z,z], []).

test(col_positions_all, []) :-
    g3x3_uni(G), gridrowcol_col_positions(G, [r,r,r], [0,1,2]).

% --- gridrowcol_matching_rows ---
test(matching_rows_none, []) :-
    g3x3(G), gridrowcol_matching_rows(G, []).

test(matching_rows_one, []) :-
    g3x3_dup(G), gridrowcol_matching_rows(G, [0-2]).

test(matching_rows_three, []) :-
    % All 3 rows identical: pairs are (0,1),(0,2),(1,2) = 3 pairs.
    g3x3_uni(G), gridrowcol_matching_rows(G, Pairs), length(Pairs, 3).

% --- gridrowcol_matching_cols ---
test(matching_cols_none, []) :-
    g3x3(G), gridrowcol_matching_cols(G, []).

test(matching_cols_one, []) :-
    g3x3_c02(G), gridrowcol_matching_cols(G, [0-2]).

test(matching_cols_three, []) :-
    % All 3 cols identical: pairs are (0,1),(0,2),(1,2) = 3 pairs.
    g3x3_uni(G), gridrowcol_matching_cols(G, Pairs), length(Pairs, 3).

% --- gridrowcol_unique_rows ---
test(unique_rows_all, []) :-
    % All rows distinct: all 3 are unique.
    g3x3(G), gridrowcol_unique_rows(G, Rows), length(Rows, 3).

test(unique_rows_one, []) :-
    % Rows 0 and 2 duplicate [r,r,r]; only row 1 [x,x,x] is unique.
    g3x3_dup(G), gridrowcol_unique_rows(G, [1]).

test(unique_rows_none, []) :-
    % All rows are [r,r,r]: no row is unique.
    g3x3_uni(G), gridrowcol_unique_rows(G, []).

% --- gridrowcol_unique_cols ---
test(unique_cols_all, []) :-
    % All cols distinct: all 3 are unique.
    g3x3(G), gridrowcol_unique_cols(G, Cols), length(Cols, 3).

test(unique_cols_one, []) :-
    % Cols 0 and 2 duplicate [a,c,e]; only col 1 [b,d,f] is unique.
    g3x3_c02(G), gridrowcol_unique_cols(G, [1]).

test(unique_cols_none, []) :-
    % All cols are [r,r,r]: no col is unique.
    g3x3_uni(G), gridrowcol_unique_cols(G, []).

% --- gridrowcol_row_sort ---
test(row_sort_already_sorted, []) :-
    % [a,b,c] < [d,e,f] < [g,h,i] so g3x3 is already sorted.
    g3x3(G), gridrowcol_row_sort(G, G).

test(row_sort_reverse, []) :-
    % Rows [c,c,c],[a,a,a],[b,b,b] sort to [a,a,a],[b,b,b],[c,c,c].
    g3x3_unsorted(G), gridrowcol_row_sort(G, [[a,a,a],[b,b,b],[c,c,c]]).

test(row_sort_uniform, []) :-
    % All rows identical: sort leaves them unchanged.
    g3x3_uni(G), gridrowcol_row_sort(G, G).

% --- gridrowcol_col_sort ---
test(col_sort_unsorted, []) :-
    % Columns are [c,c,c,c],[a,a,a,a],[b,b,b,b]; sorted: [a,a,a,a],[b,b,b,b],[c,c,c,c].
    g4x3_unsorted(G),
    gridrowcol_col_sort(G, [[a,b,c],[a,b,c],[a,b,c],[a,b,c]]).

test(col_sort_symmetric, []) :-
    % Cols: [a,c,e],[b,d,f],[a,c,e]; sorted: [a,c,e],[a,c,e],[b,d,f].
    g3x3_c02(G),
    gridrowcol_col_sort(G, [[a,a,b],[c,c,d],[e,e,f]]).

test(col_sort_uniform, []) :-
    % All cols identical: sort leaves them unchanged.
    g3x3_uni(G), gridrowcol_col_sort(G, G).

% --- Combined tests ---
test(combined_row_positions_equal_rows, []) :-
    % row_positions and equal_rows agree: positions [0,2] implies gridrowcol_equal_rows(0,2).
    g3x3_dup(G),
    gridrowcol_row_positions(G, [r,r,r], [R1,R2|_]),
    gridrowcol_equal_rows(G, R1, R2).

test(combined_unique_and_matching, []) :-
    % For g3x3_dup: 1 unique row (index 1), 1 matching pair (0-2).
    g3x3_dup(G),
    gridrowcol_unique_rows(G, Unique), gridrowcol_matching_rows(G, Matching),
    length(Unique, 1), length(Matching, 1).

test(combined_col_positions_equal_cols, []) :-
    % col_positions and equal_cols agree: positions [0,2] implies gridrowcol_equal_cols(0,2).
    g3x3_c02(G),
    gridrowcol_col_positions(G, [a,c,e], [C1,C2|_]),
    gridrowcol_equal_cols(G, C1, C2).

test(combined_row_sort_length, []) :-
    % gridrowcol_row_sort preserves the number of rows.
    g3x3_unsorted(G), gridrowcol_row_sort(G, Sorted),
    length(G, H), length(Sorted, H).

:- end_tests(gridrowcol).
