% test_count.pl - PLUnit tests for the count pack (Layer 96: cn_* predicates).
:- use_module('../prolog/count').

% Tests for cn_by_value/3

:- begin_tests(cn_by_value).

test(absent_value) :-
    cn_by_value([1,2,3], 0, N), N =:= 0.

test(one_occurrence) :-
    cn_by_value([1,2,3], 2, N), N =:= 1.

test(all_match) :-
    cn_by_value([5,5,5], 5, N), N =:= 3.

:- end_tests(cn_by_value).

% Tests for cn_color_count/3

:- begin_tests(cn_color_count).

test(absent_in_uniform) :-
    cn_color_count([[5,5],[5,5]], 0, N), N =:= 0.

test(all_cells) :-
    cn_color_count([[5,5],[5,5]], 5, N), N =:= 4.

test(partial_match) :-
    cn_color_count([[0,1,2],[0,1,2],[0,1,2]], 1, N), N =:= 3.

:- end_tests(cn_color_count).

% Tests for cn_histogram/3

:- begin_tests(cn_histogram).

test(uniform_grid) :-
    cn_histogram([[5,5],[5,5]], Colors, Counts),
    Colors = [5], Counts = [4].

test(three_equal_colors) :-
    cn_histogram([[0,1,2],[0,1,2],[0,1,2]], Colors, Counts),
    Colors = [0,1,2], Counts = [3,3,3].

test(dominant_color) :-
    cn_histogram([[0,0,0],[0,1,0],[0,0,0]], Colors, Counts),
    Colors = [0,1], Counts = [8,1].

:- end_tests(cn_histogram).

% Tests for cn_max_color/2

:- begin_tests(cn_max_color).

test(uniform) :-
    cn_max_color([[5,5],[5,5]], C), C =:= 5.

test(tied_returns_lowest) :-
    cn_max_color([[0,1,2],[0,1,2],[0,1,2]], C), C =:= 0.

test(clear_dominant) :-
    cn_max_color([[0,0,0],[0,1,0],[0,0,0]], C), C =:= 0.

:- end_tests(cn_max_color).

% Tests for cn_min_color/2

:- begin_tests(cn_min_color).

test(uniform) :-
    cn_min_color([[5,5],[5,5]], C), C =:= 5.

test(minority) :-
    cn_min_color([[0,0,0],[0,1,0],[0,0,0]], C), C =:= 1.

test(tied_returns_lowest) :-
    cn_min_color([[0,1,2],[0,1,2],[0,1,2]], C), C =:= 0.

:- end_tests(cn_min_color).

% Tests for cn_color_rows/3

:- begin_tests(cn_color_rows).

test(color_in_all_rows) :-
    cn_color_rows([[0,1,2],[0,1,2],[0,1,2]], 0, N), N =:= 3.

test(color_absent) :-
    cn_color_rows([[0,1,2],[0,1,2],[0,1,2]], 9, N), N =:= 0.

test(color_in_one_row) :-
    cn_color_rows([[0,0,0],[0,1,0],[0,0,0]], 1, N), N =:= 1.

:- end_tests(cn_color_rows).

% Tests for cn_color_cols/3

:- begin_tests(cn_color_cols).

test(color_in_one_col) :-
    cn_color_cols([[0,1,2],[0,1,2],[0,1,2]], 0, N), N =:= 1.

test(color_absent) :-
    cn_color_cols([[0,1,2],[0,1,2],[0,1,2]], 9, N), N =:= 0.

test(color_in_all_cols) :-
    cn_color_cols([[0,0,0],[0,1,0],[0,0,0]], 0, N), N =:= 3.

:- end_tests(cn_color_cols).

% Tests for cn_row_distinct/3

:- begin_tests(cn_row_distinct).

test(all_same) :-
    cn_row_distinct([[5,5,5]], 0, N), N =:= 1.

test(all_different) :-
    cn_row_distinct([[1,2,3],[4,5,6]], 0, N), N =:= 3.

test(mixed_row) :-
    cn_row_distinct([[0,1,2],[0,1,2],[0,1,2]], 1, N), N =:= 3.

:- end_tests(cn_row_distinct).

% Tests for cn_col_distinct/3

:- begin_tests(cn_col_distinct).

test(uniform_column) :-
    cn_col_distinct([[5,5],[5,5]], 0, N), N =:= 1.

test(all_same_values_in_col) :-
    cn_col_distinct([[0,1,2],[0,1,2],[0,1,2]], 0, N), N =:= 1.

test(mixed_column) :-
    cn_col_distinct([[0,0,0],[0,1,0],[0,0,0]], 1, N), N =:= 2.

:- end_tests(cn_col_distinct).

% Tests for cn_grid_total/2

:- begin_tests(cn_grid_total).

test(two_by_two) :-
    cn_grid_total([[1,2],[3,4]], N), N =:= 4.

test(three_by_three) :-
    cn_grid_total([[0,1,2],[0,1,2],[0,1,2]], N), N =:= 9.

test(two_by_three) :-
    cn_grid_total([[1,2,3],[4,5,6]], N), N =:= 6.

:- end_tests(cn_grid_total).

% Tests for cn_equal_cells/3

:- begin_tests(cn_equal_cells).

test(identical_grids) :-
    G = [[1,2],[3,4]], cn_equal_cells(G, G, N), N =:= 4.

test(one_cell_different) :-
    cn_equal_cells([[1,2],[3,4]], [[1,9],[3,4]], N), N =:= 3.

test(all_different) :-
    cn_equal_cells([[1,2],[3,4]], [[5,6],[7,8]], N), N =:= 0.

:- end_tests(cn_equal_cells).

% Tests for cn_diff_cells/3

:- begin_tests(cn_diff_cells).

test(identical_grids) :-
    G = [[1,2],[3,4]], cn_diff_cells(G, G, N), N =:= 0.

test(one_cell_different) :-
    cn_diff_cells([[1,2],[3,4]], [[1,9],[3,4]], N), N =:= 1.

test(all_different) :-
    cn_diff_cells([[1,2],[3,4]], [[5,6],[7,8]], N), N =:= 4.

:- end_tests(cn_diff_cells).

% Tests for cn_region_color/3

:- begin_tests(cn_region_color).

test(top_left_cell) :-
    cn_region_color([[0,1,0],[1,2,1],[0,1,0]], [r(0,0)], C), C =:= 0.

test(top_center_cell) :-
    cn_region_color([[0,1,0],[1,2,1],[0,1,0]], [r(0,1)], C), C =:= 1.

test(center_cell) :-
    cn_region_color([[0,1,0],[1,2,1],[0,1,0]], [r(1,1)], C), C =:= 2.

:- end_tests(cn_region_color).

% Tests for cn_regions_per_color/3

:- begin_tests(cn_regions_per_color).

test(empty_regions) :-
    cn_regions_per_color([[0,1],[1,2]], [], Pairs), Pairs = [].

test(one_region) :-
    cn_regions_per_color([[0,1],[1,2]], [[r(0,0)]], Pairs),
    Pairs = [0-1].

test(two_same_color_regions) :-
    cn_regions_per_color([[0,1],[0,2]], [[r(0,0)], [r(1,0)]], Pairs),
    member(0-2, Pairs).

:- end_tests(cn_regions_per_color).
