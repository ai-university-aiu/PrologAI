% test_varstat.pl - 42 PLUnit tests for the varstat pack (vt_* predicates).
:- use_module('../prolog/varstat.pl').

% Shared test grids.
% G3: 3x3 sequential grid, row-major values 1-9.
% Row sums: [6,15,24]. Col sums: [12,15,18]. Global mean floor: 45//9=5.
g3([[1,2,3],[4,5,6],[7,8,9]]).
% G3u: 3x3 uniform grid, all cells equal to 2.
% Row/col sums: [6,6,6]. Global mean: 18//9=2.
g3u([[2,2,2],[2,2,2],[2,2,2]]).
% G3b: 3x3 transposed sequential grid; columns are 1-3, 4-6, 7-9.
% Row sums: [12,15,18]. Col sums: [6,15,24]. Global mean floor: 45//9=5.
g3b([[1,4,7],[2,5,8],[3,6,9]]).

% Tests for vt_sum/2.
:- begin_tests(vt_sum).
test(sum_basic) :- vt_sum([1,2,3], S), S =:= 6.
test(sum_zeros) :- vt_sum([0,0,0], S), S =:= 0.
test(sum_single) :- vt_sum([5], S), S =:= 5.
:- end_tests(vt_sum).

% Tests for vt_mean_floor/2.
:- begin_tests(vt_mean_floor).
test(mean_floor_basic) :- vt_mean_floor([1,2,3], M), M =:= 2.
test(mean_floor_truncates) :- vt_mean_floor([1,1,2], M), M =:= 1.
test(mean_floor_row) :- vt_mean_floor([4,5,6], M), M =:= 5.
:- end_tests(vt_mean_floor).

% Tests for vt_mean_round/2.
:- begin_tests(vt_mean_round).
test(mean_round_exact) :- vt_mean_round([1,2,3], M), M =:= 2.
test(mean_round_pair) :- vt_mean_round([2,4], M), M =:= 3.
test(mean_round_row) :- vt_mean_round([4,5,6], M), M =:= 5.
:- end_tests(vt_mean_round).

% Tests for vt_deviation/2.
:- begin_tests(vt_deviation).
test(deviation_basic) :- vt_deviation([1,2,3], Devs), Devs = [-1,0,1].
test(deviation_uniform) :- vt_deviation([2,2,2], Devs), Devs = [0,0,0].
test(deviation_spread) :- vt_deviation([1,3,5], Devs), Devs = [-2,0,2].
:- end_tests(vt_deviation).

% Tests for vt_abs_deviation/2.
:- begin_tests(vt_abs_deviation).
test(abs_dev_basic) :- vt_abs_deviation([1,2,3], Devs), Devs = [1,0,1].
test(abs_dev_uniform) :- vt_abs_deviation([2,2,2], Devs), Devs = [0,0,0].
test(abs_dev_spread) :- vt_abs_deviation([1,3,5], Devs), Devs = [2,0,2].
:- end_tests(vt_abs_deviation).

% Tests for vt_row_sums/2.
:- begin_tests(vt_row_sums).
test(row_sums_g3) :- g3(G), vt_row_sums(G, S), S = [6,15,24].
test(row_sums_uni) :- g3u(G), vt_row_sums(G, S), S = [6,6,6].
test(row_sums_g3b) :- g3b(G), vt_row_sums(G, S), S = [12,15,18].
:- end_tests(vt_row_sums).

% Tests for vt_col_sums/2.
:- begin_tests(vt_col_sums).
test(col_sums_g3) :- g3(G), vt_col_sums(G, S), S = [12,15,18].
test(col_sums_uni) :- g3u(G), vt_col_sums(G, S), S = [6,6,6].
test(col_sums_g3b) :- g3b(G), vt_col_sums(G, S), S = [6,15,24].
:- end_tests(vt_col_sums).

% Tests for vt_row_means/2.
:- begin_tests(vt_row_means).
test(row_means_g3) :- g3(G), vt_row_means(G, M), M = [2,5,8].
test(row_means_uni) :- g3u(G), vt_row_means(G, M), M = [2,2,2].
test(row_means_g3b) :- g3b(G), vt_row_means(G, M), M = [4,5,6].
:- end_tests(vt_row_means).

% Tests for vt_col_means/2.
:- begin_tests(vt_col_means).
test(col_means_g3) :- g3(G), vt_col_means(G, M), M = [4,5,6].
test(col_means_uni) :- g3u(G), vt_col_means(G, M), M = [2,2,2].
test(col_means_g3b) :- g3b(G), vt_col_means(G, M), M = [2,5,8].
:- end_tests(vt_col_means).

% Tests for vt_global_mean/2.
:- begin_tests(vt_global_mean).
test(global_mean_g3) :- g3(G), vt_global_mean(G, M), M =:= 5.
test(global_mean_uni) :- g3u(G), vt_global_mean(G, M), M =:= 2.
test(global_mean_g3b) :- g3b(G), vt_global_mean(G, M), M =:= 5.
:- end_tests(vt_global_mean).

% Tests for vt_above_mean/2.
% G3 global mean=5; above: 6@1-2, 7@2-0, 8@2-1, 9@2-2.
% G3b global mean=5; above: 7@0-2, 8@1-2, 6@2-1, 9@2-2.
:- begin_tests(vt_above_mean).
test(above_mean_g3) :- g3(G), vt_above_mean(G, C), C = [1-2,2-0,2-1,2-2].
test(above_mean_uni) :- g3u(G), vt_above_mean(G, C), C = [].
test(above_mean_g3b) :- g3b(G), vt_above_mean(G, C), C = [0-2,1-2,2-1,2-2].
:- end_tests(vt_above_mean).

% Tests for vt_below_mean/2.
% G3 global mean=5; below: 1@0-0, 2@0-1, 3@0-2, 4@1-0.
% G3b global mean=5; below: 1@0-0, 4@0-1, 2@1-0, 3@2-0.
:- begin_tests(vt_below_mean).
test(below_mean_g3) :- g3(G), vt_below_mean(G, C), C = [0-0,0-1,0-2,1-0].
test(below_mean_uni) :- g3u(G), vt_below_mean(G, C), C = [].
test(below_mean_g3b) :- g3b(G), vt_below_mean(G, C), C = [0-0,0-1,1-0,2-0].
:- end_tests(vt_below_mean).

% Tests for vt_row_above_mean/2.
% G3: row means [2,5,8]. Above row mean: 3@0-2, 6@1-2, 9@2-2.
% G3u: all means 2; no cell > 2.
% G3b: row means [4,5,6]. Above: 7@0-2, 8@1-2, 9@2-2.
:- begin_tests(vt_row_above_mean).
test(row_above_g3) :- g3(G), vt_row_above_mean(G, C), C = [0-2,1-2,2-2].
test(row_above_uni) :- g3u(G), vt_row_above_mean(G, C), C = [].
test(row_above_g3b) :- g3b(G), vt_row_above_mean(G, C), C = [0-2,1-2,2-2].
:- end_tests(vt_row_above_mean).

% Tests for vt_col_above_mean/2.
% G3: col means [4,5,6]. Above col mean: 7@2-0, 8@2-1, 9@2-2.
% G3u: all col means 2; no cell > 2.
% G3b: col means [2,5,8]. Above: 3@2-0, 6@2-1, 9@2-2.
:- begin_tests(vt_col_above_mean).
test(col_above_g3) :- g3(G), vt_col_above_mean(G, C), C = [2-0,2-1,2-2].
test(col_above_uni) :- g3u(G), vt_col_above_mean(G, C), C = [].
test(col_above_g3b) :- g3b(G), vt_col_above_mean(G, C), C = [2-0,2-1,2-2].
:- end_tests(vt_col_above_mean).
