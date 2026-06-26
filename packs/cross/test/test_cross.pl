:- use_module('../prolog/cross').

:- begin_tests(cross).

% --- cx_row ---

test(row_middle) :-
    cx_row([[1,2],[3,4],[5,6]], 1, Row),
    Row = [3,4].

test(row_first) :-
    cx_row([[a,b],[c,d]], 0, Row),
    Row = [a,b].

test(row_single) :-
    cx_row([[7]], 0, Row),
    Row = [7].

% --- cx_col ---

test(col_first) :-
    cx_col([[1,2,3],[4,5,6]], 0, Col),
    Col = [1,4].

test(col_last) :-
    cx_col([[1,2],[3,4]], 1, Col),
    Col = [2,4].

test(col_single) :-
    cx_col([[9]], 0, Col),
    Col = [9].

% --- cx_diag ---

test(diag_3x3) :-
    cx_diag([[1,2,3],[4,5,6],[7,8,9]], Diag),
    Diag = [1,5,9].

test(diag_2x2) :-
    cx_diag([[1,2],[3,4]], Diag),
    Diag = [1,4].

test(diag_1x1) :-
    cx_diag([[5]], Diag),
    Diag = [5].

% --- cx_antidiag ---

test(antidiag_3x3) :-
    cx_antidiag([[1,2,3],[4,5,6],[7,8,9]], Diag),
    Diag = [3,5,7].

test(antidiag_2x2) :-
    cx_antidiag([[1,2],[3,4]], Diag),
    Diag = [2,3].

test(antidiag_1x1) :-
    cx_antidiag([[5]], Diag),
    Diag = [5].

% --- cx_row_sum ---

test(row_sum_middle) :-
    cx_row_sum([[1,2],[3,4],[5,6]], 1, Sum),
    Sum = 7.

test(row_sum_first) :-
    cx_row_sum([[10,20,30]], 0, Sum),
    Sum = 60.

test(row_sum_zeros) :-
    cx_row_sum([[0,0],[0,0]], 0, Sum),
    Sum = 0.

% --- cx_col_sum ---

test(col_sum_first) :-
    cx_col_sum([[1,2],[3,4],[5,6]], 0, Sum),
    Sum = 9.

test(col_sum_last) :-
    cx_col_sum([[1,2],[3,4]], 1, Sum),
    Sum = 6.

test(col_sum_zeros) :-
    cx_col_sum([[0,0],[0,0]], 1, Sum),
    Sum = 0.

% --- cx_row_count ---

test(row_count_present) :-
    cx_row_count([[1,2,1],[3,4,5]], 0, 1, N),
    N = 2.

test(row_count_absent) :-
    cx_row_count([[1,2,3]], 0, 9, N),
    N = 0.

test(row_count_all) :-
    cx_row_count([[5,5,5]], 0, 5, N),
    N = 3.

% --- cx_col_count ---

test(col_count_present) :-
    cx_col_count([[1,2],[1,3],[1,4]], 0, 1, N),
    N = 3.

test(col_count_absent) :-
    cx_col_count([[1,2],[3,4]], 0, 9, N),
    N = 0.

test(col_count_all) :-
    cx_col_count([[5,5],[5,5]], 1, 5, N),
    N = 2.

% --- cx_rows_with ---

test(rows_with_one) :-
    cx_rows_with([[0,0],[1,0],[0,0]], 1, Rows),
    Rows = [1].

test(rows_with_all) :-
    cx_rows_with([[1,0],[1,1],[0,1]], 1, Rows),
    Rows = [0,1,2].

test(rows_with_none) :-
    cx_rows_with([[0,0],[0,0]], 1, Rows),
    Rows = [].

% --- cx_cols_with ---

test(cols_with_one) :-
    cx_cols_with([[0,1,0],[0,0,0]], 1, Cols),
    Cols = [1].

test(cols_with_all) :-
    cx_cols_with([[1,0],[0,1],[1,1]], 1, Cols),
    Cols = [0,1].

test(cols_with_none) :-
    cx_cols_with([[0,0],[0,0]], 1, Cols),
    Cols = [].

% --- cx_row_uniq ---

test(row_uniq_mixed) :-
    cx_row_uniq([[1,2,1,3,2]], 0, Vals),
    Vals = [1,2,3].

test(row_uniq_uniform) :-
    cx_row_uniq([[5,5,5]], 0, Vals),
    Vals = [5].

test(row_uniq_all_diff) :-
    cx_row_uniq([[3,1,2]], 0, Vals),
    Vals = [1,2,3].

% --- cx_col_uniq ---

test(col_uniq_mixed) :-
    cx_col_uniq([[1],[2],[1],[3]], 0, Vals),
    Vals = [1,2,3].

test(col_uniq_uniform) :-
    cx_col_uniq([[7],[7],[7]], 0, Vals),
    Vals = [7].

test(col_uniq_two) :-
    cx_col_uniq([[0],[1],[0]], 0, Vals),
    Vals = [0,1].

% --- cx_row_mode ---

test(row_mode_clear) :-
    cx_row_mode([[1,2,1,1]], 0, 0, Mode),
    Mode = 1.

test(row_mode_tie) :-
    cx_row_mode([[1,2]], 0, 0, Mode),
    Mode = 0.

test(row_mode_uniform) :-
    cx_row_mode([[3,3,3]], 0, 0, Mode),
    Mode = 3.

% --- cx_col_mode ---

test(col_mode_clear) :-
    cx_col_mode([[1],[2],[1],[1]], 0, 0, Mode),
    Mode = 1.

test(col_mode_tie) :-
    cx_col_mode([[1],[2]], 0, 0, Mode),
    Mode = 0.

test(col_mode_uniform) :-
    cx_col_mode([[5],[5],[5]], 0, 0, Mode),
    Mode = 5.

:- end_tests(cross).
