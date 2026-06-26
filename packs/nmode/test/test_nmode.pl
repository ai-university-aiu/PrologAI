% test_nmode.pl - 42 PLUnit tests for the nmode pack (nm_* predicates).
:- use_module('../prolog/nmode.pl').

% Shared test grids.
% G3: 3x3 sequential grid with values 1-9 in reading order.
g3([[1,2,3],[4,5,6],[7,8,9]]).
% G3u: 3x3 uniform grid of all 1s.
g3u([[1,1,1],[1,1,1],[1,1,1]]).
% G2: 2x2 small grid.
g2([[1,2],[3,4]]).
% G3b: 3x3 checkerboard alternating 1 and 2.
g3b([[1,2,1],[2,1,2],[1,2,1]]).

% Tests for nm_mode/2.
:- begin_tests(nm_mode).
test(mode_all_distinct) :- nm_mode([1,2,3], M), M =:= 1.
test(mode_clear_winner) :- nm_mode([1,1,2,3], M), M =:= 1.
test(mode_tied_smallest) :- nm_mode([1,1,2,2], M), M =:= 1.
:- end_tests(nm_mode).

% Tests for nm_mode_all/2.
:- begin_tests(nm_mode_all).
test(mode_all_three_tied) :- nm_mode_all([1,2,3], Ms), Ms = [1,2,3].
test(mode_all_two_tied) :- nm_mode_all([1,1,2,2], Ms), Ms = [1,2].
test(mode_all_one_winner) :- nm_mode_all([1,1,2,3], Ms), Ms = [1].
:- end_tests(nm_mode_all).

% Tests for nm_mode_count/3.
:- begin_tests(nm_mode_count).
test(mode_count_distinct) :- nm_mode_count([1,2,3], M, C), M =:= 1, C =:= 1.
test(mode_count_winner) :- nm_mode_count([1,1,2,3], M, C), M =:= 1, C =:= 2.
test(mode_count_tied) :- nm_mode_count([1,1,2,2], M, C), M =:= 1, C =:= 2.
:- end_tests(nm_mode_count).

% Tests for nm_row/3.
:- begin_tests(nm_row).
test(row0) :- g3(G), nm_row(G, 0, M), M =:= 1.
test(row1) :- g3(G), nm_row(G, 1, M), M =:= 4.
test(row2) :- g3(G), nm_row(G, 2, M), M =:= 7.
:- end_tests(nm_row).

% Tests for nm_col/3.
:- begin_tests(nm_col).
test(col0) :- g3(G), nm_col(G, 0, M), M =:= 1.
test(col1) :- g3(G), nm_col(G, 1, M), M =:= 2.
test(col2) :- g3(G), nm_col(G, 2, M), M =:= 3.
:- end_tests(nm_col).

% Tests for nm_row_modes/2.
:- begin_tests(nm_row_modes).
test(row_modes_g3) :- g3(G), nm_row_modes(G, Ms), Ms = [1,4,7].
test(row_modes_uni) :- g3u(G), nm_row_modes(G, Ms), Ms = [1,1,1].
test(row_modes_g2) :- g2(G), nm_row_modes(G, Ms), Ms = [1,3].
:- end_tests(nm_row_modes).

% Tests for nm_col_modes/2.
:- begin_tests(nm_col_modes).
test(col_modes_g3) :- g3(G), nm_col_modes(G, Ms), Ms = [1,2,3].
test(col_modes_uni) :- g3u(G), nm_col_modes(G, Ms), Ms = [1,1,1].
test(col_modes_g2) :- g2(G), nm_col_modes(G, Ms), Ms = [1,2].
:- end_tests(nm_col_modes).

% Tests for nm_grid/2.
:- begin_tests(nm_grid).
test(grid_g3) :- g3(G), nm_grid(G, M), M =:= 1.
test(grid_uni) :- g3u(G), nm_grid(G, M), M =:= 1.
test(grid_g2) :- g2(G), nm_grid(G, M), M =:= 1.
:- end_tests(nm_grid).

% Tests for nm_filter4/2.
:- begin_tests(nm_filter4).
test(filter4_g3) :- g3(G), nm_filter4(G, F), F = [[1,1,2],[1,2,3],[4,5,6]].
test(filter4_uni) :- g3u(G), nm_filter4(G, F), F = [[1,1,1],[1,1,1],[1,1,1]].
test(filter4_g3b) :- g3b(G), nm_filter4(G, F), F = [[2,1,2],[1,2,1],[2,1,2]].
:- end_tests(nm_filter4).

% Tests for nm_filter8/2.
:- begin_tests(nm_filter8).
test(filter8_g3) :- g3(G), nm_filter8(G, F), F = [[1,1,2],[1,1,2],[4,4,5]].
test(filter8_uni) :- g3u(G), nm_filter8(G, F), F = [[1,1,1],[1,1,1],[1,1,1]].
test(filter8_g3b) :- g3b(G), nm_filter8(G, F), F = [[1,1,1],[1,1,1],[1,1,1]].
:- end_tests(nm_filter8).

% Tests for nm_uniform4/2.
:- begin_tests(nm_uniform4).
test(uniform4_g3) :- g3(G), nm_uniform4(G, C), C = [].
test(uniform4_uni) :- g3u(G), nm_uniform4(G, C),
    C = [0-0,0-1,0-2,1-0,1-1,1-2,2-0,2-1,2-2].
test(uniform4_g3b) :- g3b(G), nm_uniform4(G, C),
    C = [0-0,0-1,0-2,1-0,1-1,1-2,2-0,2-1,2-2].
:- end_tests(nm_uniform4).

% Tests for nm_uniform8/2.
:- begin_tests(nm_uniform8).
test(uniform8_g3) :- g3(G), nm_uniform8(G, C), C = [].
test(uniform8_uni) :- g3u(G), nm_uniform8(G, C),
    C = [0-0,0-1,0-2,1-0,1-1,1-2,2-0,2-1,2-2].
test(uniform8_g3b) :- g3b(G), nm_uniform8(G, C), C = [].
:- end_tests(nm_uniform8).

% Tests for nm_outlier4/2.
:- begin_tests(nm_outlier4).
test(outlier4_g3) :- g3(G), nm_outlier4(G, C),
    C = [0-0,0-1,0-2,1-0,1-1,1-2,2-0,2-1,2-2].
test(outlier4_uni) :- g3u(G), nm_outlier4(G, C), C = [].
test(outlier4_g3b) :- g3b(G), nm_outlier4(G, C),
    C = [0-0,0-1,0-2,1-0,1-1,1-2,2-0,2-1,2-2].
:- end_tests(nm_outlier4).

% Tests for nm_outlier8/2.
:- begin_tests(nm_outlier8).
test(outlier8_g3) :- g3(G), nm_outlier8(G, C),
    C = [0-0,0-1,0-2,1-0,1-1,1-2,2-0,2-1,2-2].
test(outlier8_uni) :- g3u(G), nm_outlier8(G, C), C = [].
test(outlier8_g3b) :- g3b(G), nm_outlier8(G, C),
    C = [0-0,0-1,0-2,1-0,1-2,2-0,2-1,2-2].
:- end_tests(nm_outlier8).
