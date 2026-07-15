% test_projection.pl - 42 PLUnit tests for the projection pack (pj_* predicates).
:- use_module('../prolog/projection.pl').

% Shared test grids.
% G3: 3x3 all-1 grid.
g3([[1,1,1],[1,1,1],[1,1,1]]).
% G3v: 3x3 with varied values.
g3v([[1,2,3],[4,5,6],[7,8,9]]).
% G3c: 3x3 count grid: one 0, one 1, one 2 per row.
g3c([[0,1,2],[0,1,2],[0,1,2]]).
% G3s: 3x3 with a stripe pattern for run tests.
g3s([[1,1,0],[1,0,0],[1,1,1]]).
% G2m: 2x3 mode test.
g2m([[1,1,2],[1,2,2]]).

% Tests for projection_row_sums/2.
:- begin_tests(projection_row_sums).
test(uniform) :- g3(G), projection_row_sums(G, S), S = [3,3,3].
test(varied) :- g3v(G), projection_row_sums(G, S), S = [6,15,24].
test(count_grid) :- g3c(G), projection_row_sums(G, S), S = [3,3,3].
:- end_tests(projection_row_sums).

% Tests for projection_col_sums/2.
:- begin_tests(projection_col_sums).
test(uniform) :- g3(G), projection_col_sums(G, S), S = [3,3,3].
test(varied) :- g3v(G), projection_col_sums(G, S), S = [12,15,18].
test(count_grid) :- g3c(G), projection_col_sums(G, S), S = [0,3,6].
:- end_tests(projection_col_sums).

% Tests for projection_row_counts/3.
:- begin_tests(projection_row_counts).
test(uniform_count1) :- g3(G), projection_row_counts(G, 1, C), C = [3,3,3].
test(count_grid_zeros) :- g3c(G), projection_row_counts(G, 0, C), C = [1,1,1].
test(count_grid_twos) :- g3c(G), projection_row_counts(G, 2, C), C = [1,1,1].
:- end_tests(projection_row_counts).

% Tests for projection_col_counts/3.
:- begin_tests(projection_col_counts).
test(uniform_count1) :- g3(G), projection_col_counts(G, 1, C), C = [3,3,3].
test(count_grid_zeros) :- g3c(G), projection_col_counts(G, 0, C), C = [3,0,0].
test(count_grid_twos) :- g3c(G), projection_col_counts(G, 2, C), C = [0,0,3].
:- end_tests(projection_col_counts).

% Tests for projection_row_maxes/2.
:- begin_tests(projection_row_maxes).
test(uniform) :- g3(G), projection_row_maxes(G, M), M = [1,1,1].
test(varied) :- g3v(G), projection_row_maxes(G, M), M = [3,6,9].
test(count_grid) :- g3c(G), projection_row_maxes(G, M), M = [2,2,2].
:- end_tests(projection_row_maxes).

% Tests for projection_col_maxes/2.
:- begin_tests(projection_col_maxes).
test(uniform) :- g3(G), projection_col_maxes(G, M), M = [1,1,1].
test(varied) :- g3v(G), projection_col_maxes(G, M), M = [7,8,9].
test(count_grid) :- g3c(G), projection_col_maxes(G, M), M = [0,1,2].
:- end_tests(projection_col_maxes).

% Tests for projection_row_uniq/2.
:- begin_tests(projection_row_uniq).
test(uniform) :- g3(G), projection_row_uniq(G, U), U = [[1],[1],[1]].
test(count_grid) :- g3c(G), projection_row_uniq(G, U), U = [[0,1,2],[0,1,2],[0,1,2]].
test(varied) :- g3v(G), projection_row_uniq(G, U), U = [[1,2,3],[4,5,6],[7,8,9]].
:- end_tests(projection_row_uniq).

% Tests for projection_col_uniq/2.
:- begin_tests(projection_col_uniq).
test(uniform) :- g3(G), projection_col_uniq(G, U), U = [[1],[1],[1]].
test(count_grid) :- g3c(G), projection_col_uniq(G, U), U = [[0],[1],[2]].
test(varied) :- g3v(G), projection_col_uniq(G, U), U = [[1,4,7],[2,5,8],[3,6,9]].
:- end_tests(projection_col_uniq).

% Tests for projection_shadow_h/3.
:- begin_tests(projection_shadow_h).
test(uniform_all_cols) :- g3(G), projection_shadow_h(G, 1, C), C = [0,1,2].
test(count_grid_zero_col) :- g3c(G), projection_shadow_h(G, 0, C), C = [0].
test(count_grid_two_col) :- g3c(G), projection_shadow_h(G, 2, C), C = [2].
:- end_tests(projection_shadow_h).

% Tests for projection_shadow_v/3.
:- begin_tests(projection_shadow_v).
test(uniform_all_rows) :- g3(G), projection_shadow_v(G, 1, R), R = [0,1,2].
test(count_grid_zero_rows) :- g3c(G), projection_shadow_v(G, 0, R), R = [0,1,2].
test(count_grid_two_rows) :- g3c(G), projection_shadow_v(G, 2, R), R = [0,1,2].
:- end_tests(projection_shadow_v).

% Tests for projection_h_profile/3.
:- begin_tests(projection_h_profile).
test(run_lengths_rows) :- g3s(G), projection_h_profile(G, 1, P), P = [2,1,3].
test(uniform_full_run) :- g3(G), projection_h_profile(G, 1, P), P = [3,3,3].
test(no_run_for_absent) :- g3c(G), projection_h_profile(G, 9, P), P = [0,0,0].
:- end_tests(projection_h_profile).

% Tests for projection_v_profile/3.
:- begin_tests(projection_v_profile).
test(col_run_lengths) :- g3s(G), projection_v_profile(G, 1, P), P = [3,1,1].
test(uniform_full_cols) :- g3(G), projection_v_profile(G, 1, P), P = [3,3,3].
test(no_run_absent) :- g3c(G), projection_v_profile(G, 9, P), P = [0,0,0].
:- end_tests(projection_v_profile).

% Tests for projection_row_modes/2.
:- begin_tests(projection_row_modes).
test(uniform_mode) :- g3(G), projection_row_modes(G, M), M = [1,1,1].
test(mode_grid_rows) :- g2m(G), projection_row_modes(G, M), M = [1,2].
test(count_grid_modes) :- g3c(G), projection_row_modes(G, M), M = [0,0,0].
:- end_tests(projection_row_modes).

% Tests for projection_col_modes/2.
:- begin_tests(projection_col_modes).
test(uniform_mode) :- g3(G), projection_col_modes(G, M), M = [1,1,1].
test(mode_grid_cols) :- g2m(G), projection_col_modes(G, M), M = [1,1,2].
test(count_grid_col_modes) :- g3c(G), projection_col_modes(G, M), M = [0,1,2].
:- end_tests(projection_col_modes).
