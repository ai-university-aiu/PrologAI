% test_naggr.pl - 42 PLUnit tests for the naggr pack (na_* predicates).
:- use_module('../prolog/naggr.pl').

% Shared test grids.
% G3: 3x3 grid with values 1-9 in reading order.
g3([[1,2,3],[4,5,6],[7,8,9]]).
% G3u: 3x3 uniform grid of 1s.
g3u([[1,1,1],[1,1,1],[1,1,1]]).
% G2: 2x2 grid.
g2([[1,2],[3,4]]).
% G1: 1x1 grid, all neighborhoods empty.
g1([[5]]).
% G3b: 3x3 checkerboard-like grid alternating 1 and 2.
g3b([[1,2,1],[2,1,2],[1,2,1]]).

% Tests for na_sum4/2.
:- begin_tests(na_sum4).
test(sum4_3x3) :- g3(G), na_sum4(G, S), S = [[6,9,8],[13,20,17],[12,21,14]].
test(sum4_1x1) :- g1(G), na_sum4(G, S), S = [[0]].
test(sum4_2x2) :- g2(G), na_sum4(G, S), S = [[5,5],[5,5]].
:- end_tests(na_sum4).

% Tests for na_sum8/2.
:- begin_tests(na_sum8).
test(sum8_3x3) :- g3(G), na_sum8(G, S), S = [[11,19,13],[23,40,27],[17,31,19]].
test(sum8_1x1) :- g1(G), na_sum8(G, S), S = [[0]].
test(sum8_2x2) :- g2(G), na_sum8(G, S), S = [[9,8],[7,6]].
:- end_tests(na_sum8).

% Tests for na_max4/2.
:- begin_tests(na_max4).
test(max4_3x3) :- g3(G), na_max4(G, M), M = [[4,5,6],[7,8,9],[8,9,8]].
test(max4_1x1) :- g1(G), na_max4(G, M), M = [[0]].
test(max4_uniform) :- g3u(G), na_max4(G, M), M = [[1,1,1],[1,1,1],[1,1,1]].
:- end_tests(na_max4).

% Tests for na_max8/2.
:- begin_tests(na_max8).
test(max8_3x3) :- g3(G), na_max8(G, M), M = [[5,6,6],[8,9,9],[8,9,8]].
test(max8_1x1) :- g1(G), na_max8(G, M), M = [[0]].
test(max8_uniform) :- g3u(G), na_max8(G, M), M = [[1,1,1],[1,1,1],[1,1,1]].
:- end_tests(na_max8).

% Tests for na_min4/2.
:- begin_tests(na_min4).
test(min4_3x3) :- g3(G), na_min4(G, M), M = [[2,1,2],[1,2,3],[4,5,6]].
test(min4_1x1) :- g1(G), na_min4(G, M), M = [[0]].
test(min4_uniform) :- g3u(G), na_min4(G, M), M = [[1,1,1],[1,1,1],[1,1,1]].
:- end_tests(na_min4).

% Tests for na_min8/2.
:- begin_tests(na_min8).
test(min8_3x3) :- g3(G), na_min8(G, M), M = [[2,1,2],[1,1,2],[4,4,5]].
test(min8_1x1) :- g1(G), na_min8(G, M), M = [[0]].
test(min8_uniform) :- g3u(G), na_min8(G, M), M = [[1,1,1],[1,1,1],[1,1,1]].
:- end_tests(na_min8).

% Tests for na_mean4/2.
:- begin_tests(na_mean4).
test(mean4_3x3) :- g3(G), na_mean4(G, M), M = [[3,3,4],[4,5,5],[6,7,7]].
test(mean4_1x1) :- g1(G), na_mean4(G, M), M = [[0]].
test(mean4_uniform) :- g3u(G), na_mean4(G, M), M = [[1,1,1],[1,1,1],[1,1,1]].
:- end_tests(na_mean4).

% Tests for na_mean8/2.
:- begin_tests(na_mean8).
test(mean8_3x3) :- g3(G), na_mean8(G, M), M = [[3,3,4],[4,5,5],[5,6,6]].
test(mean8_1x1) :- g1(G), na_mean8(G, M), M = [[0]].
test(mean8_2x2) :- g2(G), na_mean8(G, M), M = [[3,2],[2,2]].
:- end_tests(na_mean8).

% Tests for na_range4/2.
:- begin_tests(na_range4).
test(range4_3x3) :- g3(G), na_range4(G, R), R = [[2,4,4],[6,6,6],[4,4,2]].
test(range4_1x1) :- g1(G), na_range4(G, R), R = [[0]].
test(range4_uniform) :- g3u(G), na_range4(G, R), R = [[0,0,0],[0,0,0],[0,0,0]].
:- end_tests(na_range4).

% Tests for na_range8/2.
:- begin_tests(na_range8).
test(range8_3x3) :- g3(G), na_range8(G, R), R = [[3,5,4],[7,8,7],[4,5,3]].
test(range8_1x1) :- g1(G), na_range8(G, R), R = [[0]].
test(range8_uniform) :- g3u(G), na_range8(G, R), R = [[0,0,0],[0,0,0],[0,0,0]].
:- end_tests(na_range8).

% Tests for na_spread4/2.
:- begin_tests(na_spread4).
test(spread4_3x3) :- g3(G), na_spread4(G, S), S = [[2,3,2],[3,4,3],[2,3,2]].
test(spread4_1x1) :- g1(G), na_spread4(G, S), S = [[0]].
test(spread4_uniform) :- g3u(G), na_spread4(G, S), S = [[1,1,1],[1,1,1],[1,1,1]].
:- end_tests(na_spread4).

% Tests for na_spread8/2.
:- begin_tests(na_spread8).
test(spread8_3x3) :- g3(G), na_spread8(G, S), S = [[3,5,3],[5,8,5],[3,5,3]].
test(spread8_1x1) :- g1(G), na_spread8(G, S), S = [[0]].
test(spread8_uniform) :- g3u(G), na_spread8(G, S), S = [[1,1,1],[1,1,1],[1,1,1]].
:- end_tests(na_spread8).

% Tests for na_diff4/2.
:- begin_tests(na_diff4).
test(diff4_3x3) :- g3(G), na_diff4(G, D), D = [[2,3,2],[3,4,3],[2,3,2]].
test(diff4_uniform) :- g3u(G), na_diff4(G, D), D = [[0,0,0],[0,0,0],[0,0,0]].
test(diff4_checker) :- g3b(G), na_diff4(G, D), D = [[2,3,2],[3,4,3],[2,3,2]].
:- end_tests(na_diff4).

% Tests for na_diff8/2.
:- begin_tests(na_diff8).
test(diff8_3x3) :- g3(G), na_diff8(G, D), D = [[3,5,3],[5,8,5],[3,5,3]].
test(diff8_uniform) :- g3u(G), na_diff8(G, D), D = [[0,0,0],[0,0,0],[0,0,0]].
test(diff8_checker) :- g3b(G), na_diff8(G, D), D = [[2,3,2],[3,4,3],[2,3,2]].
:- end_tests(na_diff8).
