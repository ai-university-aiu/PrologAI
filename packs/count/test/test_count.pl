% PLUnit tests for the count pack (cn_* predicates).
:- use_module(library(plunit)).
:- use_module(library(count)).

% Helper grids.
% 3x3 with three colors.
g3x3([[0,1,2],[0,1,2],[0,1,2]]).
% 2x2 uniform color 5.
g22_5([[5,5],[5,5]]).
% 3x3 with one dominant color (0).
g3x3_dom([[0,0,0],[0,1,0],[0,0,0]]).
% 2x3 grid.
g23([[1,2,3],[4,5,6]]).
% Two identical grids.
g_same([[1,2],[3,4]]).
% Grid differing in one cell.
g_diff1([[1,9],[3,4]]).
% Grid for region color test.
g_rc([[0,1,0],[1,2,1],[0,1,0]]).

:- begin_tests(count_by_value).

test(by_value_zero) :-
    cn_by_value([1,2,3], 0, N), N =:= 0.

test(by_value_one) :-
    cn_by_value([1,2,3], 2, N), N =:= 1.

test(by_value_all) :-
    cn_by_value([5,5,5], 5, N), N =:= 3.

test(by_value_empty) :-
    cn_by_value([], 1, N), N =:= 0.

:- end_tests(count_by_value).

:- begin_tests(count_color_count).

test(color_count_zero_in_uniform) :-
    g22_5(G), cn_color_count(G, 0, N), N =:= 0.

test(color_count_all) :-
    g22_5(G), cn_color_count(G, 5, N), N =:= 4.

test(color_count_partial) :-
    g3x3(G), cn_color_count(G, 1, N), N =:= 3.

test(color_count_dominant) :-
    g3x3_dom(G), cn_color_count(G, 0, N), N =:= 8.

:- end_tests(count_color_count).

:- begin_tests(count_histogram).

test(histogram_uniform) :-
    g22_5(G), cn_histogram(G, Colors, Counts),
    Colors = [5], Counts = [4].

test(histogram_3colors) :-
    g3x3(G), cn_histogram(G, Colors, Counts),
    Colors = [0,1,2], Counts = [3,3,3].

test(histogram_dominant) :-
    g3x3_dom(G), cn_histogram(G, Colors, Counts),
    Colors = [0,1], Counts = [8,1].

test(histogram_parallel_lengths) :-
    g23(G), cn_histogram(G, Colors, Counts),
    length(Colors, N), length(Counts, N), N > 0.

:- end_tests(count_histogram).

:- begin_tests(count_max_color).

test(max_uniform) :-
    g22_5(G), cn_max_color(G, C), C =:= 5.

test(max_3x3) :-
    g3x3(G), cn_max_color(G, C),
    % All colors tied at 3; returns the first (lowest value = 0).
    C =:= 0.

test(max_dominant) :-
    g3x3_dom(G), cn_max_color(G, C), C =:= 0.

:- end_tests(count_max_color).

:- begin_tests(count_min_color).

test(min_uniform) :-
    g22_5(G), cn_min_color(G, C), C =:= 5.

test(min_dominant) :-
    g3x3_dom(G), cn_min_color(G, C), C =:= 1.

test(min_3x3_tied) :-
    g3x3(G), cn_min_color(G, C), C =:= 0.

:- end_tests(count_min_color).

:- begin_tests(count_color_rows).

test(color_rows_all) :-
    g3x3(G), cn_color_rows(G, 0, N), N =:= 3.

test(color_rows_none) :-
    g3x3(G), cn_color_rows(G, 9, N), N =:= 0.

test(color_rows_one) :-
    g3x3_dom(G), cn_color_rows(G, 1, N), N =:= 1.

test(color_rows_partial) :-
    % g23 = [[1,2,3],[4,5,6]]; color 1 in row 0 only.
    g23(G), cn_color_rows(G, 1, N), N =:= 1.

:- end_tests(count_color_rows).

:- begin_tests(count_color_cols).

test(color_cols_all) :-
    g3x3(G), cn_color_cols(G, 0, N), N =:= 1.

test(color_cols_dominant) :-
    % g3x3_dom col 0,2 have only 0; col 1 has 0 and 1.
    % All 3 columns contain color 0.
    g3x3_dom(G), cn_color_cols(G, 0, N), N =:= 3.

test(color_cols_none) :-
    g3x3(G), cn_color_cols(G, 9, N), N =:= 0.

test(color_cols_one) :-
    % g3x3 = [[0,1,2],...]; color 2 is in column 2 only.
    g3x3(G), cn_color_cols(G, 2, N), N =:= 1.

:- end_tests(count_color_cols).

:- begin_tests(count_row_distinct).

test(row_distinct_all_same) :-
    cn_row_distinct([[5,5,5]], 0, N), N =:= 1.

test(row_distinct_all_diff) :-
    g23(G), cn_row_distinct(G, 0, N), N =:= 3.

test(row_distinct_g3x3) :-
    g3x3(G), cn_row_distinct(G, 1, N), N =:= 3.

:- end_tests(count_row_distinct).

:- begin_tests(count_col_distinct).

test(col_distinct_all_same) :-
    g22_5(G), cn_col_distinct(G, 0, N), N =:= 1.

test(col_distinct_all_diff) :-
    g3x3(G), cn_col_distinct(G, 0, N), N =:= 1.

test(col_distinct_mixed) :-
    % g3x3_dom column 1 has values [0,1,0] -> 2 distinct.
    g3x3_dom(G), cn_col_distinct(G, 1, N), N =:= 2.

:- end_tests(count_col_distinct).

:- begin_tests(count_grid_total).

test(total_2x2) :-
    g_same(G), cn_grid_total(G, N), N =:= 4.

test(total_3x3) :-
    g3x3(G), cn_grid_total(G, N), N =:= 9.

test(total_2x3) :-
    g23(G), cn_grid_total(G, N), N =:= 6.

:- end_tests(count_grid_total).

:- begin_tests(count_equal_cells).

test(equal_identical) :-
    g_same(G), cn_equal_cells(G, G, N), N =:= 4.

test(equal_one_diff) :-
    g_same(G), g_diff1(H), cn_equal_cells(G, H, N), N =:= 3.

test(equal_all_diff) :-
    cn_equal_cells([[1,2],[3,4]], [[5,6],[7,8]], N), N =:= 0.

:- end_tests(count_equal_cells).

:- begin_tests(count_diff_cells).

test(diff_identical) :-
    g_same(G), cn_diff_cells(G, G, N), N =:= 0.

test(diff_one) :-
    g_same(G), g_diff1(H), cn_diff_cells(G, H, N), N =:= 1.

test(diff_all) :-
    cn_diff_cells([[1,2],[3,4]], [[5,6],[7,8]], N), N =:= 4.

:- end_tests(count_diff_cells).

:- begin_tests(count_region_color).

test(region_color_0) :-
    g_rc(G), cn_region_color(G, [r(0,0)], C), C =:= 0.

test(region_color_1) :-
    g_rc(G), cn_region_color(G, [r(0,1)], C), C =:= 1.

test(region_color_2) :-
    g_rc(G), cn_region_color(G, [r(1,2), r(0,2)], C), C =:= 1.

test(region_color_center) :-
    g_rc(G), cn_region_color(G, [r(1,1)], C), C =:= 2.

:- end_tests(count_region_color).

:- begin_tests(count_regions_per_color).

test(regions_per_color_empty) :-
    g_rc(G), cn_regions_per_color(G, [], Pairs), Pairs = [].

test(regions_per_color_one) :-
    g_rc(G), cn_regions_per_color(G, [[r(0,0)]], Pairs),
    Pairs = [0-1].

test(regions_per_color_two_same) :-
    g_rc(G), cn_regions_per_color(G, [[r(0,0)], [r(0,2)]], Pairs),
    % Both regions are color 0; result should tally color 0 twice.
    member(0-2, Pairs).

test(regions_per_color_two_diff) :-
    g_rc(G), cn_regions_per_color(G, [[r(0,0)], [r(0,1)]], Pairs),
    % Color 0 and color 1 each appear once; sort to get canonical order.
    msort(Pairs, Sorted),
    Sorted = [0-1, 1-1].

:- end_tests(count_regions_per_color).
