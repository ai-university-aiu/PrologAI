% test_median.pl - 42 PLUnit tests for the median pack (md_* predicates).
:- use_module('../prolog/median.pl').

% Shared test grids.
% G3: 3x3 grid with values 1-9 in reading order.
g3([[1,2,3],[4,5,6],[7,8,9]]).
% G3u: 3x3 uniform grid of 1s.
g3u([[1,1,1],[1,1,1],[1,1,1]]).
% G2: 2x2 grid.
g2([[1,2],[3,4]]).
% G3b: 3x3 peak grid.
g3b([[1,2,1],[2,4,2],[1,2,1]]).

% Tests for md_median/2.
:- begin_tests(md_median).
test(median_odd) :- md_median([1,2,3,4,5], M), M =:= 3.
test(median_even) :- md_median([1,2,3,4], M), M =:= 2.
test(median_dups) :- md_median([1,1,1,2,3], M), M =:= 1.
:- end_tests(md_median).

% Tests for md_row/3.
:- begin_tests(md_row).
test(row0) :- g3(G), md_row(G, 0, M), M =:= 2.
test(row1) :- g3(G), md_row(G, 1, M), M =:= 5.
test(row2) :- g3(G), md_row(G, 2, M), M =:= 8.
:- end_tests(md_row).

% Tests for md_col/3.
:- begin_tests(md_col).
test(col0) :- g3(G), md_col(G, 0, M), M =:= 4.
test(col1) :- g3(G), md_col(G, 1, M), M =:= 5.
test(col2) :- g3(G), md_col(G, 2, M), M =:= 6.
:- end_tests(md_col).

% Tests for md_row_medians/2.
:- begin_tests(md_row_medians).
test(row_med_g3) :- g3(G), md_row_medians(G, Ms), Ms = [2,5,8].
test(row_med_uni) :- g3u(G), md_row_medians(G, Ms), Ms = [1,1,1].
test(row_med_g2) :- g2(G), md_row_medians(G, Ms), Ms = [1,3].
:- end_tests(md_row_medians).

% Tests for md_col_medians/2.
:- begin_tests(md_col_medians).
test(col_med_g3) :- g3(G), md_col_medians(G, Ms), Ms = [4,5,6].
test(col_med_uni) :- g3u(G), md_col_medians(G, Ms), Ms = [1,1,1].
test(col_med_g2) :- g2(G), md_col_medians(G, Ms), Ms = [1,2].
:- end_tests(md_col_medians).

% Tests for md_grid/2.
:- begin_tests(md_grid).
test(grid_g3) :- g3(G), md_grid(G, M), M =:= 5.
test(grid_uni) :- g3u(G), md_grid(G, M), M =:= 1.
test(grid_g2) :- g2(G), md_grid(G, M), M =:= 2.
:- end_tests(md_grid).

% Tests for md_filter4/2.
:- begin_tests(md_filter4).
test(filter4_g3) :- g3(G), md_filter4(G, F), F = [[2,2,3],[4,5,5],[7,7,8]].
test(filter4_uni) :- g3u(G), md_filter4(G, F), F = [[1,1,1],[1,1,1],[1,1,1]].
test(filter4_g3b) :- g3b(G), md_filter4(G, F), F = [[2,1,2],[1,2,1],[2,1,2]].
:- end_tests(md_filter4).

% Tests for md_filter8/2.
:- begin_tests(md_filter8).
test(filter8_g3) :- g3(G), md_filter8(G, F), F = [[2,3,3],[4,5,5],[5,6,6]].
test(filter8_uni) :- g3u(G), md_filter8(G, F), F = [[1,1,1],[1,1,1],[1,1,1]].
test(filter8_g3b) :- g3b(G), md_filter8(G, F), F = [[2,2,2],[2,2,2],[2,2,2]].
:- end_tests(md_filter8).

% Tests for md_above/2.
:- begin_tests(md_above).
test(above_g3) :- g3(G), md_above(G, C), C = [1-2,2-0,2-1,2-2].
test(above_uni) :- g3u(G), md_above(G, C), C = [].
test(above_g2) :- g2(G), md_above(G, C), C = [1-0,1-1].
:- end_tests(md_above).

% Tests for md_below/2.
:- begin_tests(md_below).
test(below_g3) :- g3(G), md_below(G, C), C = [0-0,0-1,0-2,1-0].
test(below_uni) :- g3u(G), md_below(G, C), C = [].
test(below_g2) :- g2(G), md_below(G, C), C = [0-0].
:- end_tests(md_below).

% Tests for md_row_above/3.
:- begin_tests(md_row_above).
test(row_above_g3_1) :- g3(G), md_row_above(G, 1, C), C = [1-2].
test(row_above_uni) :- g3u(G), md_row_above(G, 0, C), C = [].
test(row_above_g2_0) :- g2(G), md_row_above(G, 0, C), C = [0-1].
:- end_tests(md_row_above).

% Tests for md_row_below/3.
:- begin_tests(md_row_below).
test(row_below_g3_1) :- g3(G), md_row_below(G, 1, C), C = [1-0].
test(row_below_uni) :- g3u(G), md_row_below(G, 0, C), C = [].
test(row_below_g2_0) :- g2(G), md_row_below(G, 0, C), C = [].
:- end_tests(md_row_below).

% Tests for md_col_above/3.
:- begin_tests(md_col_above).
test(col_above_g3_1) :- g3(G), md_col_above(G, 1, C), C = [2-1].
test(col_above_uni) :- g3u(G), md_col_above(G, 0, C), C = [].
test(col_above_g2_0) :- g2(G), md_col_above(G, 0, C), C = [1-0].
:- end_tests(md_col_above).

% Tests for md_col_below/3.
:- begin_tests(md_col_below).
test(col_below_g3_1) :- g3(G), md_col_below(G, 1, C), C = [0-1].
test(col_below_uni) :- g3u(G), md_col_below(G, 0, C), C = [].
test(col_below_g2_0) :- g2(G), md_col_below(G, 0, C), C = [].
:- end_tests(md_col_below).
