% test_permute.pl - PLUnit tests for the permute pack (Layer 94: pm_* predicates).
:- use_module('../prolog/permute').

% Tests for permute_permute_rows/3

:- begin_tests(permute_permute_rows).

test(reverse_two_rows) :-
    permute_permute_rows([[1,2],[3,4]], [1,0], R),
    R = [[3,4],[1,2]].

test(identity_permutation) :-
    permute_permute_rows([[1,2],[3,4],[5,6]], [0,1,2], R),
    R = [[1,2],[3,4],[5,6]].

test(cycle_three_rows) :-
    permute_permute_rows([[1,2],[3,4],[5,6]], [2,0,1], R),
    R = [[5,6],[1,2],[3,4]].

:- end_tests(permute_permute_rows).

% Tests for permute_permute_cols/3

:- begin_tests(permute_permute_cols).

test(reverse_two_cols) :-
    permute_permute_cols([[1,2],[3,4]], [1,0], R),
    R = [[2,1],[4,3]].

test(identity_permutation) :-
    permute_permute_cols([[1,2,3],[4,5,6]], [0,1,2], R),
    R = [[1,2,3],[4,5,6]].

test(cycle_three_cols) :-
    permute_permute_cols([[1,2,3],[4,5,6]], [2,0,1], R),
    R = [[3,1,2],[6,4,5]].

:- end_tests(permute_permute_cols).

% Tests for permute_swap_rows/4

:- begin_tests(permute_swap_rows).

test(swap_first_last_of_three) :-
    permute_swap_rows([[1,2],[3,4],[5,6]], 0, 2, R),
    R = [[5,6],[3,4],[1,2]].

test(swap_adjacent_rows) :-
    permute_swap_rows([[1,2],[3,4],[5,6]], 1, 2, R),
    R = [[1,2],[5,6],[3,4]].

test(swap_same_row_identity) :-
    permute_swap_rows([[1,2],[3,4]], 0, 0, R),
    R = [[1,2],[3,4]].

:- end_tests(permute_swap_rows).

% Tests for permute_swap_cols/4

:- begin_tests(permute_swap_cols).

test(swap_first_last_col) :-
    permute_swap_cols([[1,2,3],[4,5,6]], 0, 2, R),
    R = [[3,2,1],[6,5,4]].

test(swap_adjacent_cols) :-
    permute_swap_cols([[1,2,3],[4,5,6]], 0, 1, R),
    R = [[2,1,3],[5,4,6]].

test(swap_same_col_identity) :-
    permute_swap_cols([[1,2],[3,4]], 1, 1, R),
    R = [[1,2],[3,4]].

:- end_tests(permute_swap_cols).

% Tests for permute_cycle_rows/3

:- begin_tests(permute_cycle_rows).

test(cycle_one_row_down) :-
    permute_cycle_rows([[1,2],[3,4],[5,6]], 1, R),
    R = [[5,6],[1,2],[3,4]].

test(cycle_two_rows_down) :-
    permute_cycle_rows([[1,2],[3,4],[5,6],[7,8]], 2, R),
    R = [[5,6],[7,8],[1,2],[3,4]].

test(cycle_zero_unchanged) :-
    permute_cycle_rows([[1,2],[3,4]], 0, R),
    R = [[1,2],[3,4]].

:- end_tests(permute_cycle_rows).

% Tests for permute_cycle_cols/3

:- begin_tests(permute_cycle_cols).

test(cycle_one_col_right) :-
    permute_cycle_cols([[1,2,3],[4,5,6]], 1, R),
    R = [[3,1,2],[6,4,5]].

test(cycle_two_cols_right) :-
    permute_cycle_cols([[1,2,3,4],[5,6,7,8]], 2, R),
    R = [[3,4,1,2],[7,8,5,6]].

test(cycle_zero_cols_unchanged) :-
    permute_cycle_cols([[1,2],[3,4]], 0, R),
    R = [[1,2],[3,4]].

:- end_tests(permute_cycle_cols).

% Tests for permute_find_row_perm/3

:- begin_tests(permute_find_row_perm).

test(reversed_two_rows) :-
    permute_find_row_perm([[1,2],[3,4]], [[3,4],[1,2]], P),
    P = [1,0].

test(identity_perm) :-
    permute_find_row_perm([[1,2],[3,4],[5,6]], [[1,2],[3,4],[5,6]], P),
    P = [0,1,2].

test(cycled_rows) :-
    permute_find_row_perm([[1,2],[3,4],[5,6]], [[5,6],[1,2],[3,4]], P),
    P = [2,0,1].

:- end_tests(permute_find_row_perm).

% Tests for permute_find_col_perm/3

:- begin_tests(permute_find_col_perm).

test(reversed_two_cols) :-
    permute_find_col_perm([[1,2],[3,4]], [[2,1],[4,3]], P),
    P = [1,0].

test(identity_col_perm) :-
    permute_find_col_perm([[1,2,3],[4,5,6]], [[1,2,3],[4,5,6]], P),
    P = [0,1,2].

test(cycled_cols) :-
    permute_find_col_perm([[1,2,3],[4,5,6]], [[3,1,2],[6,4,5]], P),
    P = [2,0,1].

:- end_tests(permute_find_col_perm).

% Tests for permute_sort_rows/2

:- begin_tests(permute_sort_rows).

test(sorting_two_rows_in_order) :-
    permute_sort_rows([[3,4],[1,2]], R),
    R = [[1,2],[3,4]].

test(already_sorted_unchanged) :-
    permute_sort_rows([[1,2],[3,4]], R),
    R = [[1,2],[3,4]].

test(sorting_three_rows) :-
    permute_sort_rows([[5,6],[1,2],[3,4]], R),
    R = [[1,2],[3,4],[5,6]].

:- end_tests(permute_sort_rows).

% Tests for permute_sort_cols/2

:- begin_tests(permute_sort_cols).

test(sorting_two_cols) :-
    permute_sort_cols([[2,1],[4,3]], R),
    R = [[1,2],[3,4]].

test(already_sorted_cols_unchanged) :-
    permute_sort_cols([[1,2],[3,4]], R),
    R = [[1,2],[3,4]].

test(sorting_three_cols) :-
    permute_sort_cols([[3,1,2],[6,4,5]], R),
    R = [[1,2,3],[4,5,6]].

:- end_tests(permute_sort_cols).

% Tests for permute_insert_row/4

:- begin_tests(permute_insert_row).

test(insert_at_front) :-
    permute_insert_row([[1,2],[3,4]], 0, [9,9], R),
    R = [[9,9],[1,2],[3,4]].

test(insert_in_middle) :-
    permute_insert_row([[1,2],[3,4]], 1, [9,9], R),
    R = [[1,2],[9,9],[3,4]].

test(insert_at_end) :-
    permute_insert_row([[1,2],[3,4]], 2, [9,9], R),
    R = [[1,2],[3,4],[9,9]].

:- end_tests(permute_insert_row).

% Tests for permute_delete_row/3

:- begin_tests(permute_delete_row).

test(delete_first_row) :-
    permute_delete_row([[1,2],[3,4],[5,6]], 0, R),
    R = [[3,4],[5,6]].

test(delete_last_row) :-
    permute_delete_row([[1,2],[3,4],[5,6]], 2, R),
    R = [[1,2],[3,4]].

test(delete_middle_row) :-
    permute_delete_row([[1,2],[3,4],[5,6]], 1, R),
    R = [[1,2],[5,6]].

:- end_tests(permute_delete_row).

% Tests for permute_insert_col/4

:- begin_tests(permute_insert_col).

test(insert_col_at_front) :-
    permute_insert_col([[1,2],[3,4]], 0, [9,9], R),
    R = [[9,1,2],[9,3,4]].

test(insert_col_in_middle) :-
    permute_insert_col([[1,2],[3,4]], 1, [9,9], R),
    R = [[1,9,2],[3,9,4]].

test(insert_col_at_end) :-
    permute_insert_col([[1,2],[3,4]], 2, [9,9], R),
    R = [[1,2,9],[3,4,9]].

:- end_tests(permute_insert_col).

% Tests for permute_delete_col/3

:- begin_tests(permute_delete_col).

test(delete_first_col) :-
    permute_delete_col([[1,2,3],[4,5,6]], 0, R),
    R = [[2,3],[5,6]].

test(delete_last_col) :-
    permute_delete_col([[1,2,3],[4,5,6]], 2, R),
    R = [[1,2],[4,5]].

test(delete_middle_col) :-
    permute_delete_col([[1,2,3],[4,5,6]], 1, R),
    R = [[1,3],[4,6]].

:- end_tests(permute_delete_col).
