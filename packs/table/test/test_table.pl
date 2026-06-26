:- use_module('../prolog/table').

:- begin_tests(table).

% --- tb_transpose ---

test(transpose_3x3) :-
    tb_transpose([[1,2,3],[4,5,6],[7,8,9]], T),
    T = [[1,4,7],[2,5,8],[3,6,9]].

test(transpose_2x3) :-
    tb_transpose([[1,2,3],[4,5,6]], T),
    T = [[1,4],[2,5],[3,6]].

test(transpose_1x1) :-
    tb_transpose([[5]], T),
    T = [[5]].

% --- tb_sort_rows ---

test(sort_rows_by_col0) :-
    tb_sort_rows([[3,a],[1,b],[2,c]], 0, Sorted),
    Sorted = [[1,b],[2,c],[3,a]].

test(sort_rows_by_col1) :-
    tb_sort_rows([[1,3],[2,1],[3,2]], 1, Sorted),
    Sorted = [[2,1],[3,2],[1,3]].

test(sort_rows_already_sorted) :-
    tb_sort_rows([[1,2],[3,4]], 0, Sorted),
    Sorted = [[1,2],[3,4]].

% --- tb_filter_rows ---

test(filter_rows_present) :-
    tb_filter_rows([[1,a],[2,b],[1,c]], 0, 1, Filtered),
    Filtered = [[1,a],[1,c]].

test(filter_rows_absent) :-
    tb_filter_rows([[1,a],[2,b]], 0, 9, Filtered),
    Filtered = [].

test(filter_rows_all) :-
    tb_filter_rows([[0,x],[0,y],[0,z]], 0, 0, Filtered),
    Filtered = [[0,x],[0,y],[0,z]].

% --- tb_group_by ---

test(group_by_two_vals) :-
    tb_group_by([[1,a],[2,b],[1,c]], 0, Groups),
    Groups = [1-[[1,a],[1,c]], 2-[[2,b]]].

test(group_by_all_same) :-
    tb_group_by([[0,a],[0,b]], 0, Groups),
    Groups = [0-[[0,a],[0,b]]].

test(group_by_all_diff) :-
    tb_group_by([[1,a],[2,b],[3,c]], 0, Groups),
    Groups = [1-[[1,a]], 2-[[2,b]], 3-[[3,c]]].

% --- tb_count_by ---

test(count_by_mixed) :-
    tb_count_by([[1,a],[2,b],[1,c],[1,d]], 0, Counts),
    Counts = [1-3, 2-1].

test(count_by_equal) :-
    tb_count_by([[0,x],[1,y],[0,z],[1,w]], 0, Counts),
    Counts = [0-2, 1-2].

test(count_by_single) :-
    tb_count_by([[5,a]], 0, Counts),
    Counts = [5-1].

% --- tb_unique_rows ---

test(unique_rows_mixed) :-
    tb_unique_rows([[1,2],[3,4],[1,2],[5,6]], U),
    U = [[1,2],[3,4],[5,6]].

test(unique_rows_all_same) :-
    tb_unique_rows([[a,b],[a,b],[a,b]], U),
    U = [[a,b]].

test(unique_rows_all_diff) :-
    tb_unique_rows([[1,2],[3,4]], U),
    U = [[1,2],[3,4]].

% --- tb_select_cols ---

test(select_cols_two) :-
    tb_select_cols([[1,2,3],[4,5,6]], [0,2], Sub),
    Sub = [[1,3],[4,6]].

test(select_cols_one) :-
    tb_select_cols([[1,2],[3,4],[5,6]], [1], Sub),
    Sub = [[2],[4],[6]].

test(select_cols_reorder) :-
    tb_select_cols([[1,2,3]], [2,0], Sub),
    Sub = [[3,1]].

% --- tb_drop_col ---

test(drop_col_middle) :-
    tb_drop_col([[1,2,3],[4,5,6]], 1, G),
    G = [[1,3],[4,6]].

test(drop_col_first) :-
    tb_drop_col([[1,2],[3,4]], 0, G),
    G = [[2],[4]].

test(drop_col_last) :-
    tb_drop_col([[1,2,3]], 2, G),
    G = [[1,2]].

% --- tb_add_col ---

test(add_col_numbers) :-
    tb_add_col([[1,2],[3,4]], [5,6], G),
    G = [[1,2,5],[3,4,6]].

test(add_col_single_row) :-
    tb_add_col([[a,b]], [c], G),
    G = [[a,b,c]].

test(add_col_empty_rows) :-
    tb_add_col([[],[],[]], [1,2,3], G),
    G = [[1],[2],[3]].

% --- tb_insert_row ---

test(insert_row_at_0) :-
    tb_insert_row([[1,2],[3,4]], [0,0], 0, G),
    G = [[0,0],[1,2],[3,4]].

test(insert_row_at_end) :-
    tb_insert_row([[1,2],[3,4]], [5,6], 2, G),
    G = [[1,2],[3,4],[5,6]].

test(insert_row_middle) :-
    tb_insert_row([[1,2],[5,6]], [3,4], 1, G),
    G = [[1,2],[3,4],[5,6]].

% --- tb_delete_row ---

test(delete_row_middle) :-
    tb_delete_row([[1,2],[3,4],[5,6]], 1, G),
    G = [[1,2],[5,6]].

test(delete_row_first) :-
    tb_delete_row([[1,2],[3,4]], 0, G),
    G = [[3,4]].

test(delete_row_last) :-
    tb_delete_row([[1,2],[3,4]], 1, G),
    G = [[1,2]].

% --- tb_swap_rows ---

test(swap_rows_two) :-
    tb_swap_rows([[1,2],[3,4],[5,6]], 0, 2, G),
    G = [[5,6],[3,4],[1,2]].

test(swap_rows_adjacent) :-
    tb_swap_rows([[1,2],[3,4]], 0, 1, G),
    G = [[3,4],[1,2]].

test(swap_rows_same) :-
    tb_swap_rows([[1,2],[3,4]], 1, 1, G),
    G = [[1,2],[3,4]].

% --- tb_col_max_row ---

test(col_max_row_clear) :-
    tb_col_max_row([[1,5],[3,2],[2,8]], 1, R),
    R = 2.

test(col_max_row_first_col) :-
    tb_col_max_row([[9,0],[1,0],[3,0]], 0, R),
    R = 0.

test(col_max_row_tie_first) :-
    tb_col_max_row([[5,0],[5,0],[2,0]], 0, R),
    R = 0.

% --- tb_col_min_row ---

test(col_min_row_clear) :-
    tb_col_min_row([[5,3],[1,7],[9,2]], 1, R),
    R = 2.

test(col_min_row_first_col) :-
    tb_col_min_row([[9,0],[1,0],[3,0]], 0, R),
    R = 1.

test(col_min_row_tie_first) :-
    tb_col_min_row([[2,0],[5,0],[2,0]], 0, R),
    R = 0.

:- end_tests(table).
