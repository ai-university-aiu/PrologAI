% test_extrema.pl - 42 PLUnit tests for the extrema pack (ex_* predicates).
:- use_module('../prolog/extrema.pl').

% Shared test grids.
% G3: 3x3 grid with values 1-9 in reading order.
g3([[1,2,3],[4,5,6],[7,8,9]]).
% G3m: 3x3 grid with mixed values 1-3 per row.
g3m([[3,1,2],[2,3,1],[1,2,3]]).
% G2: 2x2 grid with two zeros and two ones.
g2([[0,1],[1,0]]).
% G3u: 3x3 uniform grid.
g3u([[1,1,1],[1,1,1],[1,1,1]]).
% G3p: 3x3 grid with a peak at the center.
g3p([[1,2,1],[2,4,2],[1,2,1]]).

% Tests for ex_max_val/2.
:- begin_tests(ex_max_val).
test(max_inc) :- g3(G), ex_max_val(G, V), V =:= 9.
test(max_uni) :- g3u(G), ex_max_val(G, V), V =:= 1.
test(max_mixed) :- g3m(G), ex_max_val(G, V), V =:= 3.
:- end_tests(ex_max_val).

% Tests for ex_min_val/2.
:- begin_tests(ex_min_val).
test(min_inc) :- g3(G), ex_min_val(G, V), V =:= 1.
test(min_zeros) :- g2(G), ex_min_val(G, V), V =:= 0.
test(min_mixed) :- g3m(G), ex_min_val(G, V), V =:= 1.
:- end_tests(ex_min_val).

% Tests for ex_max_cells/2.
:- begin_tests(ex_max_cells).
test(max_cell_unique) :- g3(G), ex_max_cells(G, C), C = [2-2].
test(max_cells_multi) :- g3m(G), ex_max_cells(G, C), length(C, N), N =:= 3.
test(max_cells_all) :- g3u(G), ex_max_cells(G, C), length(C, N), N =:= 9.
:- end_tests(ex_max_cells).

% Tests for ex_min_cells/2.
:- begin_tests(ex_min_cells).
test(min_cell_unique) :- g3(G), ex_min_cells(G, C), C = [0-0].
test(min_cells_zeros) :- g2(G), ex_min_cells(G, C), length(C, N), N =:= 2.
test(min_cells_all) :- g3u(G), ex_min_cells(G, C), length(C, N), N =:= 9.
:- end_tests(ex_min_cells).

% Tests for ex_row_argmax/2.
:- begin_tests(ex_row_argmax).
test(argmax_row) :- g3(G), ex_row_argmax(G, R), R =:= 2.
test(argmax_row_tie) :- g3u(G), ex_row_argmax(G, R), R =:= 0.
test(argmax_row_mixed) :- g3m(G), ex_row_argmax(G, R), R =:= 0.
:- end_tests(ex_row_argmax).

% Tests for ex_col_argmax/2.
:- begin_tests(ex_col_argmax).
test(argmax_col) :- g3(G), ex_col_argmax(G, C), C =:= 2.
test(argmax_col_tie) :- g3u(G), ex_col_argmax(G, C), C =:= 0.
test(argmax_col_mixed) :- g3m(G), ex_col_argmax(G, C), C =:= 0.
:- end_tests(ex_col_argmax).

% Tests for ex_row_argmin/2.
:- begin_tests(ex_row_argmin).
test(argmin_row) :- g3(G), ex_row_argmin(G, R), R =:= 0.
test(argmin_row_tie) :- g3u(G), ex_row_argmin(G, R), R =:= 0.
test(argmin_row_simple) :- ex_row_argmin([[1,2],[3,4]], R), R =:= 0.
:- end_tests(ex_row_argmin).

% Tests for ex_col_argmin/2.
:- begin_tests(ex_col_argmin).
test(argmin_col) :- g3(G), ex_col_argmin(G, C), C =:= 0.
test(argmin_col_tie) :- g3u(G), ex_col_argmin(G, C), C =:= 0.
test(argmin_col_simple) :- ex_col_argmin([[1,2],[3,4]], C), C =:= 0.
:- end_tests(ex_col_argmin).

% Tests for ex_local_max4/2.
:- begin_tests(ex_local_max4).
test(local_max_center) :- g3p(G), ex_local_max4(G, C), C = [1-1].
test(local_max_none_uniform) :- g3u(G), ex_local_max4(G, C), C = [].
test(local_max_corner) :- g3(G), ex_local_max4(G, C), C = [2-2].
:- end_tests(ex_local_max4).

% Tests for ex_local_min4/2.
:- begin_tests(ex_local_min4).
test(local_min_corners) :- g3p(G), ex_local_min4(G, C), length(C, N), N =:= 4.
test(local_min_none_uniform) :- g3u(G), ex_local_min4(G, C), C = [].
test(local_min_corner) :- g3(G), ex_local_min4(G, C), C = [0-0].
:- end_tests(ex_local_min4).

% Tests for ex_above/3.
:- begin_tests(ex_above).
test(above_thresh) :- g3(G), ex_above(G, 5, C), length(C, N), N =:= 4.
test(above_none) :- g3(G), ex_above(G, 9, C), C = [].
test(above_all) :- g3u(G), ex_above(G, 0, C), length(C, N), N =:= 9.
:- end_tests(ex_above).

% Tests for ex_below/3.
:- begin_tests(ex_below).
test(below_thresh) :- g3(G), ex_below(G, 5, C), length(C, N), N =:= 4.
test(below_none) :- g3(G), ex_below(G, 1, C), C = [].
test(below_zeros) :- g2(G), ex_below(G, 1, C), length(C, N), N =:= 2.
:- end_tests(ex_below).

% Tests for ex_range/2.
:- begin_tests(ex_range).
test(range_inc) :- g3(G), ex_range(G, R), R =:= 8.
test(range_uni) :- g3u(G), ex_range(G, R), R =:= 0.
test(range_peak) :- g3p(G), ex_range(G, R), R =:= 3.
:- end_tests(ex_range).

% Tests for ex_nonzero/2.
:- begin_tests(ex_nonzero).
test(nonzero_inc) :- g3(G), ex_nonzero(G, C), length(C, N), N =:= 9.
test(nonzero_with_zeros) :- g2(G), ex_nonzero(G, C), length(C, N), N =:= 2.
test(nonzero_all_zeros) :- ex_nonzero([[0,0],[0,0]], C), C = [].
:- end_tests(ex_nonzero).
