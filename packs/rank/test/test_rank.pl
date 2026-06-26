% test_rank.pl - 42 PLUnit tests for the rank pack (rk_* predicates).
:- use_module('../prolog/rank.pl').

% Shared test grids.
% G3: 3x3 sequential grid with values 1-9 in reading order.
g3([[1,2,3],[4,5,6],[7,8,9]]).
% G3u: 3x3 uniform grid of all 1s.
g3u([[1,1,1],[1,1,1],[1,1,1]]).
% G3b: 3x3 grid with 3 distinct values {1,3,5} and repeated values.
g3b([[5,1,3],[1,5,1],[3,1,5]]).

% Tests for rk_rank_of/3.
:- begin_tests(rk_rank_of).
test(rank_of_middle) :- rk_rank_of([1,2,3], 2, R), R =:= 2.
test(rank_of_with_dups) :- rk_rank_of([1,1,3], 3, R), R =:= 2.
test(rank_of_largest) :- rk_rank_of([5,1,3], 5, R), R =:= 3.
:- end_tests(rk_rank_of).

% Tests for rk_dense/2.
:- begin_tests(rk_dense).
test(dense_sorted) :- rk_dense([1,2,3], Rs), Rs = [1,2,3].
test(dense_reversed) :- rk_dense([3,1,2], Rs), Rs = [3,1,2].
test(dense_with_dups) :- rk_dense([1,1,2,3], Rs), Rs = [1,1,2,3].
:- end_tests(rk_dense).

% Tests for rk_argsort_asc/2.
:- begin_tests(rk_argsort_asc).
test(argsort_asc_basic) :- rk_argsort_asc([3,1,2], Is), Is = [1,2,0].
test(argsort_asc_sorted) :- rk_argsort_asc([1,2,3], Is), Is = [0,1,2].
test(argsort_asc_dups) :- rk_argsort_asc([3,1,1], Is), Is = [1,2,0].
:- end_tests(rk_argsort_asc).

% Tests for rk_argsort_desc/2.
:- begin_tests(rk_argsort_desc).
test(argsort_desc_basic) :- rk_argsort_desc([3,1,2], Is), Is = [0,2,1].
test(argsort_desc_sorted) :- rk_argsort_desc([1,2,3], Is), Is = [2,1,0].
test(argsort_desc_dups) :- rk_argsort_desc([1,1,3], Is), Is = [2,0,1].
:- end_tests(rk_argsort_desc).

% Tests for rk_row_dense/2.
:- begin_tests(rk_row_dense).
test(row_dense_g3) :- g3(G), rk_row_dense(G, R), R = [[1,2,3],[1,2,3],[1,2,3]].
test(row_dense_uni) :- g3u(G), rk_row_dense(G, R), R = [[1,1,1],[1,1,1],[1,1,1]].
test(row_dense_g3b) :- g3b(G), rk_row_dense(G, R), R = [[3,1,2],[1,2,1],[2,1,3]].
:- end_tests(rk_row_dense).

% Tests for rk_col_dense/2.
:- begin_tests(rk_col_dense).
test(col_dense_g3) :- g3(G), rk_col_dense(G, R), R = [[1,1,1],[2,2,2],[3,3,3]].
test(col_dense_uni) :- g3u(G), rk_col_dense(G, R), R = [[1,1,1],[1,1,1],[1,1,1]].
test(col_dense_g3b) :- g3b(G), rk_col_dense(G, R), R = [[3,1,2],[1,2,1],[2,1,3]].
:- end_tests(rk_col_dense).

% Tests for rk_grid_dense/2.
:- begin_tests(rk_grid_dense).
test(grid_dense_g3) :- g3(G), rk_grid_dense(G, R), R = [[1,2,3],[4,5,6],[7,8,9]].
test(grid_dense_uni) :- g3u(G), rk_grid_dense(G, R), R = [[1,1,1],[1,1,1],[1,1,1]].
test(grid_dense_g3b) :- g3b(G), rk_grid_dense(G, R), R = [[3,1,2],[1,3,1],[2,1,3]].
:- end_tests(rk_grid_dense).

% Tests for rk_row_rank_of/4.
:- begin_tests(rk_row_rank_of).
test(row_rank_of_0_1) :- g3(G), rk_row_rank_of(G, 0, 1, Rank), Rank =:= 2.
test(row_rank_of_1_0) :- g3(G), rk_row_rank_of(G, 1, 0, Rank), Rank =:= 1.
test(row_rank_of_2_2) :- g3(G), rk_row_rank_of(G, 2, 2, Rank), Rank =:= 3.
:- end_tests(rk_row_rank_of).

% Tests for rk_col_rank_of/4.
:- begin_tests(rk_col_rank_of).
test(col_rank_of_0_0) :- g3(G), rk_col_rank_of(G, 0, 0, Rank), Rank =:= 1.
test(col_rank_of_1_1) :- g3(G), rk_col_rank_of(G, 1, 1, Rank), Rank =:= 2.
test(col_rank_of_2_2) :- g3(G), rk_col_rank_of(G, 2, 2, Rank), Rank =:= 3.
:- end_tests(rk_col_rank_of).

% Tests for rk_grid_rank_of/4.
:- begin_tests(rk_grid_rank_of).
test(grid_rank_of_0_0) :- g3(G), rk_grid_rank_of(G, 0, 0, Rank), Rank =:= 1.
test(grid_rank_of_1_1) :- g3(G), rk_grid_rank_of(G, 1, 1, Rank), Rank =:= 5.
test(grid_rank_of_2_2) :- g3(G), rk_grid_rank_of(G, 2, 2, Rank), Rank =:= 9.
:- end_tests(rk_grid_rank_of).

% Tests for rk_top_n/3.
:- begin_tests(rk_top_n).
test(top_n_2) :- g3(G), rk_top_n(G, 2, C), C = [2-1,2-2].
test(top_n_1) :- g3(G), rk_top_n(G, 1, C), C = [2-2].
test(top_n_uni) :- g3u(G), rk_top_n(G, 1, C),
    C = [0-0,0-1,0-2,1-0,1-1,1-2,2-0,2-1,2-2].
:- end_tests(rk_top_n).

% Tests for rk_bottom_n/3.
:- begin_tests(rk_bottom_n).
test(bottom_n_2) :- g3(G), rk_bottom_n(G, 2, C), C = [0-0,0-1].
test(bottom_n_1) :- g3(G), rk_bottom_n(G, 1, C), C = [0-0].
test(bottom_n_uni) :- g3u(G), rk_bottom_n(G, 1, C),
    C = [0-0,0-1,0-2,1-0,1-1,1-2,2-0,2-1,2-2].
:- end_tests(rk_bottom_n).

% Tests for rk_above_rank/3.
:- begin_tests(rk_above_rank).
test(above_rank_7) :- g3(G), rk_above_rank(G, 7, C), C = [2-1,2-2].
test(above_rank_8) :- g3(G), rk_above_rank(G, 8, C), C = [2-2].
test(above_rank_0_uni) :- g3u(G), rk_above_rank(G, 0, C),
    C = [0-0,0-1,0-2,1-0,1-1,1-2,2-0,2-1,2-2].
:- end_tests(rk_above_rank).

% Tests for rk_below_rank/3.
:- begin_tests(rk_below_rank).
test(below_rank_2) :- g3(G), rk_below_rank(G, 2, C), C = [0-0].
test(below_rank_3) :- g3(G), rk_below_rank(G, 3, C), C = [0-0,0-1].
test(below_rank_2_uni) :- g3u(G), rk_below_rank(G, 2, C),
    C = [0-0,0-1,0-2,1-0,1-1,1-2,2-0,2-1,2-2].
:- end_tests(rk_below_rank).
