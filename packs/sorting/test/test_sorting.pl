% PLUnit tests for the sort pack (so_* predicates, Layer 80).
:- use_module(library(plunit)).
:- use_module(library(sorting)).

:- begin_tests(sorting_row_sums).

test(row_sums_basic) :-
    sorting_row_sums([[1,2],[3,4]], S),
    S = [3,7].

test(row_sums_zeros) :-
    sorting_row_sums([[0,0],[0,0]], S),
    S = [0,0].

test(row_sums_single) :-
    sorting_row_sums([[5,3,2]], S),
    S = [10].

:- end_tests(sorting_row_sums).

:- begin_tests(sorting_col_sums).

test(col_sums_basic) :-
    sorting_col_sums([[1,2],[3,4]], S),
    S = [4,6].

test(col_sums_zeros) :-
    sorting_col_sums([[0,0],[0,0]], S),
    S = [0,0].

test(col_sums_single_row) :-
    sorting_col_sums([[1,2,3]], S),
    S = [1,2,3].

:- end_tests(sorting_col_sums).

:- begin_tests(sorting_row_count).

test(row_count_basic) :-
    sorting_row_count([[1,0,1],[0,0,1]], 1, C),
    C = [2,1].

test(row_count_none) :-
    sorting_row_count([[0,0],[0,0]], 1, C),
    C = [0,0].

test(row_count_all) :-
    sorting_row_count([[1,1],[1,1]], 1, C),
    C = [2,2].

:- end_tests(sorting_row_count).

:- begin_tests(sorting_col_count).

test(col_count_basic) :-
    sorting_col_count([[1,0],[1,0],[0,1]], 1, C),
    C = [2,1].

test(col_count_none) :-
    sorting_col_count([[0,0],[0,0]], 1, C),
    C = [0,0].

test(col_count_all) :-
    sorting_col_count([[1,1],[1,1]], 1, C),
    C = [2,2].

:- end_tests(sorting_col_count).

:- begin_tests(sort_rows_asc).

test(sort_rows_asc_basic) :-
    sorting_sort_rows_asc([[1,1,0],[0,0,0],[1,0,0]], 1, S),
    S = [[0,0,0],[1,0,0],[1,1,0]].

test(sort_rows_asc_already) :-
    sorting_sort_rows_asc([[0,0],[1,0],[1,1]], 1, S),
    S = [[0,0],[1,0],[1,1]].

test(sort_rows_asc_all_zero) :-
    sorting_sort_rows_asc([[0,0],[0,0]], 1, S),
    S = [[0,0],[0,0]].

:- end_tests(sort_rows_asc).

:- begin_tests(sort_rows_desc).

test(sort_rows_desc_basic) :-
    sorting_sort_rows_desc([[1,0,0],[1,1,0],[0,0,0]], 1, S),
    S = [[1,1,0],[1,0,0],[0,0,0]].

test(sort_rows_desc_single) :-
    sorting_sort_rows_desc([[1,1]], 1, S),
    S = [[1,1]].

test(sort_rows_desc_reverse) :-
    sorting_sort_rows_desc([[0,0],[1,0],[1,1]], 1, S),
    S = [[1,1],[1,0],[0,0]].

:- end_tests(sort_rows_desc).

:- begin_tests(sort_cols_asc).

test(sort_cols_asc_basic) :-
    sorting_sort_cols_asc([[1,0,1],[1,0,0],[0,0,1]], 1, S),
    S = [[0,1,1],[0,1,0],[0,0,1]].

test(sort_cols_asc_no_change) :-
    sorting_sort_cols_asc([[0,0,1],[0,1,1]], 1, S),
    S = [[0,0,1],[0,1,1]].

test(sort_cols_asc_all_same) :-
    sorting_sort_cols_asc([[1,1],[1,1]], 1, S),
    S = [[1,1],[1,1]].

:- end_tests(sort_cols_asc).

:- begin_tests(sort_cols_desc).

test(sort_cols_desc_basic) :-
    sorting_sort_cols_desc([[1,0,1],[1,0,0],[0,0,1]], 1, S),
    S = [[1,1,0],[1,0,0],[0,1,0]].

test(sort_cols_desc_single_col) :-
    sorting_sort_cols_desc([[1],[0],[1]], 1, S),
    S = [[1],[0],[1]].

test(sort_cols_desc_two_cols) :-
    sorting_sort_cols_desc([[0,1],[0,1]], 1, S),
    S = [[1,0],[1,0]].

:- end_tests(sort_cols_desc).

:- begin_tests(sorting_max_row).

test(max_row_basic) :-
    sorting_max_row([[0,0],[1,0],[1,1]], 1, R),
    R = 2.

test(max_row_first) :-
    sorting_max_row([[1,1],[0,0],[0,1]], 1, R),
    R = 0.

test(max_row_single) :-
    sorting_max_row([[1,1,1]], 1, R),
    R = 0.

:- end_tests(sorting_max_row).

:- begin_tests(sorting_min_row).

test(min_row_basic) :-
    sorting_min_row([[1,1],[1,0],[0,0]], 1, R),
    R = 2.

test(min_row_first) :-
    sorting_min_row([[0,0],[1,0],[1,1]], 1, R),
    R = 0.

test(min_row_single) :-
    sorting_min_row([[0,0,0]], 1, R),
    R = 0.

:- end_tests(sorting_min_row).

:- begin_tests(sorting_max_col).

test(max_col_basic) :-
    sorting_max_col([[0,1,1],[0,1,0],[0,1,0]], 1, C),
    C = 1.

test(max_col_last) :-
    sorting_max_col([[0,0,1],[0,0,1]], 1, C),
    C = 2.

test(max_col_single) :-
    sorting_max_col([[1],[1],[1]], 1, C),
    C = 0.

:- end_tests(sorting_max_col).

:- begin_tests(sorting_min_col).

test(min_col_basic) :-
    sorting_min_col([[1,0,1],[1,0,1]], 1, C),
    C = 1.

test(min_col_first) :-
    sorting_min_col([[0,1,1],[0,1,1]], 1, C),
    C = 0.

test(min_col_single) :-
    sorting_min_col([[0],[1],[0]], 1, C),
    C = 0.

:- end_tests(sorting_min_col).

:- begin_tests(sorting_sorted_vals).

test(sorted_vals_basic) :-
    sorting_sorted_vals([[3,1],[2,1]], V),
    V = [1,1,2,3].

test(sorted_vals_all_same) :-
    sorting_sorted_vals([[5,5],[5,5]], V),
    V = [5,5,5,5].

test(sorted_vals_single) :-
    sorting_sorted_vals([[3]], V),
    V = [3].

:- end_tests(sorting_sorted_vals).

:- begin_tests(sorting_cell_rank).

test(cell_rank_basic) :-
    sorting_cell_rank([[1,2],[3,4]], 0, 0, R),
    R = 1.

test(cell_rank_max) :-
    sorting_cell_rank([[1,2],[3,4]], 1, 1, R),
    R = 4.

test(cell_rank_middle) :-
    sorting_cell_rank([[1,3],[5,7]], 0, 1, R),
    R = 2.

:- end_tests(sorting_cell_rank).
