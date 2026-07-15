% test_count.pl - PLUnit tests for the count pack (Layer 96: cn_* predicates).
:- use_module('../prolog/count').

% Tests for count_by_value/3

:- begin_tests(count_by_value).

test(absent_value) :-
    count_by_value([1,2,3], 0, N), N =:= 0.

test(one_occurrence) :-
    count_by_value([1,2,3], 2, N), N =:= 1.

test(all_match) :-
    count_by_value([5,5,5], 5, N), N =:= 3.

:- end_tests(count_by_value).

% Tests for count_color_count/3

:- begin_tests(count_color_count).

test(absent_in_uniform) :-
    count_color_count([[5,5],[5,5]], 0, N), N =:= 0.

test(all_cells) :-
    count_color_count([[5,5],[5,5]], 5, N), N =:= 4.

test(partial_match) :-
    count_color_count([[0,1,2],[0,1,2],[0,1,2]], 1, N), N =:= 3.

:- end_tests(count_color_count).

% Tests for count_histogram/3

:- begin_tests(count_histogram).

test(uniform_grid) :-
    count_histogram([[5,5],[5,5]], Colors, Counts),
    Colors = [5], Counts = [4].

test(three_equal_colors) :-
    count_histogram([[0,1,2],[0,1,2],[0,1,2]], Colors, Counts),
    Colors = [0,1,2], Counts = [3,3,3].

test(dominant_color) :-
    count_histogram([[0,0,0],[0,1,0],[0,0,0]], Colors, Counts),
    Colors = [0,1], Counts = [8,1].

:- end_tests(count_histogram).

% Tests for count_max_color/2

:- begin_tests(count_max_color).

test(uniform) :-
    count_max_color([[5,5],[5,5]], C), C =:= 5.

test(tied_returns_lowest) :-
    count_max_color([[0,1,2],[0,1,2],[0,1,2]], C), C =:= 0.

test(clear_dominant) :-
    count_max_color([[0,0,0],[0,1,0],[0,0,0]], C), C =:= 0.

:- end_tests(count_max_color).

% Tests for count_min_color/2

:- begin_tests(count_min_color).

test(uniform) :-
    count_min_color([[5,5],[5,5]], C), C =:= 5.

test(minority) :-
    count_min_color([[0,0,0],[0,1,0],[0,0,0]], C), C =:= 1.

test(tied_returns_lowest) :-
    count_min_color([[0,1,2],[0,1,2],[0,1,2]], C), C =:= 0.

:- end_tests(count_min_color).

% Tests for count_color_rows/3

:- begin_tests(count_color_rows).

test(color_in_all_rows) :-
    count_color_rows([[0,1,2],[0,1,2],[0,1,2]], 0, N), N =:= 3.

test(color_absent) :-
    count_color_rows([[0,1,2],[0,1,2],[0,1,2]], 9, N), N =:= 0.

test(color_in_one_row) :-
    count_color_rows([[0,0,0],[0,1,0],[0,0,0]], 1, N), N =:= 1.

:- end_tests(count_color_rows).

% Tests for count_color_cols/3

:- begin_tests(count_color_cols).

test(color_in_one_col) :-
    count_color_cols([[0,1,2],[0,1,2],[0,1,2]], 0, N), N =:= 1.

test(color_absent) :-
    count_color_cols([[0,1,2],[0,1,2],[0,1,2]], 9, N), N =:= 0.

test(color_in_all_cols) :-
    count_color_cols([[0,0,0],[0,1,0],[0,0,0]], 0, N), N =:= 3.

:- end_tests(count_color_cols).

% Tests for count_row_distinct/3

:- begin_tests(count_row_distinct).

test(all_same) :-
    count_row_distinct([[5,5,5]], 0, N), N =:= 1.

test(all_different) :-
    count_row_distinct([[1,2,3],[4,5,6]], 0, N), N =:= 3.

test(mixed_row) :-
    count_row_distinct([[0,1,2],[0,1,2],[0,1,2]], 1, N), N =:= 3.

:- end_tests(count_row_distinct).

% Tests for count_col_distinct/3

:- begin_tests(count_col_distinct).

test(uniform_column) :-
    count_col_distinct([[5,5],[5,5]], 0, N), N =:= 1.

test(all_same_values_in_col) :-
    count_col_distinct([[0,1,2],[0,1,2],[0,1,2]], 0, N), N =:= 1.

test(mixed_column) :-
    count_col_distinct([[0,0,0],[0,1,0],[0,0,0]], 1, N), N =:= 2.

:- end_tests(count_col_distinct).

% Tests for count_grid_total/2

:- begin_tests(count_grid_total).

test(two_by_two) :-
    count_grid_total([[1,2],[3,4]], N), N =:= 4.

test(three_by_three) :-
    count_grid_total([[0,1,2],[0,1,2],[0,1,2]], N), N =:= 9.

test(two_by_three) :-
    count_grid_total([[1,2,3],[4,5,6]], N), N =:= 6.

:- end_tests(count_grid_total).

% Tests for count_equal_cells/3

:- begin_tests(count_equal_cells).

test(identical_grids) :-
    G = [[1,2],[3,4]], count_equal_cells(G, G, N), N =:= 4.

test(one_cell_different) :-
    count_equal_cells([[1,2],[3,4]], [[1,9],[3,4]], N), N =:= 3.

test(all_different) :-
    count_equal_cells([[1,2],[3,4]], [[5,6],[7,8]], N), N =:= 0.

:- end_tests(count_equal_cells).

% Tests for count_diff_cells/3

:- begin_tests(count_diff_cells).

test(identical_grids) :-
    G = [[1,2],[3,4]], count_diff_cells(G, G, N), N =:= 0.

test(one_cell_different) :-
    count_diff_cells([[1,2],[3,4]], [[1,9],[3,4]], N), N =:= 1.

test(all_different) :-
    count_diff_cells([[1,2],[3,4]], [[5,6],[7,8]], N), N =:= 4.

:- end_tests(count_diff_cells).

% Tests for count_region_color/3

:- begin_tests(count_region_color).

test(top_left_cell) :-
    count_region_color([[0,1,0],[1,2,1],[0,1,0]], [r(0,0)], C), C =:= 0.

test(top_center_cell) :-
    count_region_color([[0,1,0],[1,2,1],[0,1,0]], [r(0,1)], C), C =:= 1.

test(center_cell) :-
    count_region_color([[0,1,0],[1,2,1],[0,1,0]], [r(1,1)], C), C =:= 2.

:- end_tests(count_region_color).

% Tests for count_regions_per_color/3

:- begin_tests(count_regions_per_color).

test(empty_regions) :-
    count_regions_per_color([[0,1],[1,2]], [], Pairs), Pairs = [].

test(one_region) :-
    count_regions_per_color([[0,1],[1,2]], [[r(0,0)]], Pairs),
    Pairs = [0-1].

test(two_same_color_regions) :-
    count_regions_per_color([[0,1],[0,2]], [[r(0,0)], [r(1,0)]], Pairs),
    member(0-2, Pairs).

:- end_tests(count_regions_per_color).
