:- use_module('../prolog/splice').

:- begin_tests(splice).

% sp_insert_row/4 tests.
test(insert_row_at_start) :-
    sp_insert_row([[1,2],[3,4],[5,6]], 0, [9,9], Out),
    Out = [[9,9],[1,2],[3,4],[5,6]].

test(insert_row_in_middle) :-
    sp_insert_row([[1,2],[3,4],[5,6]], 2, [7,8], Out),
    Out = [[1,2],[3,4],[7,8],[5,6]].

test(insert_row_at_end) :-
    sp_insert_row([[1,2],[3,4]], 2, [9,9], Out),
    Out = [[1,2],[3,4],[9,9]].

% sp_delete_row/3 tests.
test(delete_row_first) :-
    sp_delete_row([[1,2],[3,4],[5,6]], 0, Out),
    Out = [[3,4],[5,6]].

test(delete_row_middle) :-
    sp_delete_row([[1,2],[3,4],[5,6]], 1, Out),
    Out = [[1,2],[5,6]].

test(delete_row_last) :-
    sp_delete_row([[1,2],[3,4],[5,6]], 2, Out),
    Out = [[1,2],[3,4]].

% sp_insert_col/4 tests.
test(insert_col_at_start) :-
    sp_insert_col([[1,2],[3,4]], 0, 9, Out),
    Out = [[9,1,2],[9,3,4]].

test(insert_col_in_middle) :-
    sp_insert_col([[1,2,3],[4,5,6]], 2, 0, Out),
    Out = [[1,2,0,3],[4,5,0,6]].

test(insert_col_at_end) :-
    sp_insert_col([[1,2],[3,4]], 2, 7, Out),
    Out = [[1,2,7],[3,4,7]].

% sp_delete_col/3 tests.
test(delete_col_first) :-
    sp_delete_col([[1,2,3],[4,5,6]], 0, Out),
    Out = [[2,3],[5,6]].

test(delete_col_middle) :-
    sp_delete_col([[1,2,3],[4,5,6]], 1, Out),
    Out = [[1,3],[4,6]].

test(delete_col_last) :-
    sp_delete_col([[1,2,3],[4,5,6]], 2, Out),
    Out = [[1,2],[4,5]].

% sp_swap_rows/4 tests.
test(swap_rows_adjacent) :-
    sp_swap_rows([[1,2],[3,4],[5,6]], 0, 1, Out),
    Out = [[3,4],[1,2],[5,6]].

test(swap_rows_non_adjacent) :-
    sp_swap_rows([[1,2],[3,4],[5,6]], 0, 2, Out),
    Out = [[5,6],[3,4],[1,2]].

test(swap_rows_same_index) :-
    sp_swap_rows([[1,2],[3,4],[5,6]], 1, 1, Out),
    Out = [[1,2],[3,4],[5,6]].

% sp_swap_cols/4 tests.
test(swap_cols_adjacent) :-
    sp_swap_cols([[1,2,3],[4,5,6]], 0, 1, Out),
    Out = [[2,1,3],[5,4,6]].

test(swap_cols_non_adjacent) :-
    sp_swap_cols([[1,2,3],[4,5,6]], 0, 2, Out),
    Out = [[3,2,1],[6,5,4]].

test(swap_cols_same_index) :-
    sp_swap_cols([[1,2,3],[4,5,6]], 1, 1, Out),
    Out = [[1,2,3],[4,5,6]].

% sp_reverse_rows/2 tests.
test(reverse_rows_three) :-
    sp_reverse_rows([[1,2],[3,4],[5,6]], Out),
    Out = [[5,6],[3,4],[1,2]].

test(reverse_rows_two) :-
    sp_reverse_rows([[1,1],[2,2]], Out),
    Out = [[2,2],[1,1]].

test(reverse_rows_one) :-
    sp_reverse_rows([[9,8,7]], Out),
    Out = [[9,8,7]].

% sp_reverse_cols/2 tests.
test(reverse_cols_three) :-
    sp_reverse_cols([[1,2,3],[4,5,6]], Out),
    Out = [[3,2,1],[6,5,4]].

test(reverse_cols_two) :-
    sp_reverse_cols([[1,2],[3,4]], Out),
    Out = [[2,1],[4,3]].

test(reverse_cols_one) :-
    sp_reverse_cols([[5],[6],[7]], Out),
    Out = [[5],[6],[7]].

% sp_rotate_rows/3 tests.
test(rotate_rows_zero) :-
    sp_rotate_rows([[1,2],[3,4],[5,6]], 0, Out),
    Out = [[1,2],[3,4],[5,6]].

test(rotate_rows_by_one) :-
    sp_rotate_rows([[1,2],[3,4],[5,6]], 1, Out),
    Out = [[3,4],[5,6],[1,2]].

test(rotate_rows_full_cycle) :-
    sp_rotate_rows([[1,2],[3,4],[5,6]], 3, Out),
    Out = [[1,2],[3,4],[5,6]].

% sp_rotate_cols/3 tests.
test(rotate_cols_zero) :-
    sp_rotate_cols([[1,2,3],[4,5,6]], 0, Out),
    Out = [[1,2,3],[4,5,6]].

test(rotate_cols_by_one) :-
    sp_rotate_cols([[1,2,3],[4,5,6]], 1, Out),
    Out = [[2,3,1],[5,6,4]].

test(rotate_cols_full_cycle) :-
    sp_rotate_cols([[1,2,3],[4,5,6]], 3, Out),
    Out = [[1,2,3],[4,5,6]].

% sp_replicate_row/4 tests.
test(replicate_row_two_copies) :-
    sp_replicate_row([[1,2],[3,4],[5,6]], 1, 2, Out),
    Out = [[1,2],[3,4],[3,4],[5,6]].

test(replicate_row_one_copy) :-
    sp_replicate_row([[1,2],[3,4],[5,6]], 0, 1, Out),
    Out = [[1,2],[3,4],[5,6]].

test(replicate_row_zero_copies) :-
    sp_replicate_row([[1,2],[3,4],[5,6]], 1, 0, Out),
    Out = [[1,2],[5,6]].

% sp_replicate_col/4 tests.
test(replicate_col_two_copies) :-
    sp_replicate_col([[1,2,3],[4,5,6]], 1, 2, Out),
    Out = [[1,2,2,3],[4,5,5,6]].

test(replicate_col_one_copy) :-
    sp_replicate_col([[1,2,3],[4,5,6]], 0, 1, Out),
    Out = [[1,2,3],[4,5,6]].

test(replicate_col_zero_copies) :-
    sp_replicate_col([[1,2,3],[4,5,6]], 1, 0, Out),
    Out = [[1,3],[4,6]].

% sp_select_rows/3 tests.
test(select_rows_first_and_last) :-
    sp_select_rows([[1,2],[3,4],[5,6]], [0,2], Out),
    Out = [[1,2],[5,6]].

test(select_rows_all_in_order) :-
    sp_select_rows([[1,2],[3,4],[5,6]], [0,1,2], Out),
    Out = [[1,2],[3,4],[5,6]].

test(select_rows_single) :-
    sp_select_rows([[1,2],[3,4],[5,6]], [1], Out),
    Out = [[3,4]].

% sp_select_cols/3 tests.
test(select_cols_first_and_last) :-
    sp_select_cols([[1,2,3],[4,5,6]], [0,2], Out),
    Out = [[1,3],[4,6]].

test(select_cols_all_in_order) :-
    sp_select_cols([[1,2,3],[4,5,6]], [0,1,2], Out),
    Out = [[1,2,3],[4,5,6]].

test(select_cols_single) :-
    sp_select_cols([[1,2,3],[4,5,6]], [1], Out),
    Out = [[2],[5]].

:- end_tests(splice).
