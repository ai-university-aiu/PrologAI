% test_distance.pl - 42 PLUnit tests for the distance pack (dt_* predicates).
:- use_module('../prolog/distance.pl').

% Shared test grids.
% G3: 3x3 uniform grid of 0s.
g3([[0,0,0],[0,0,0],[0,0,0]]).
% G3m: 3x3 border of 0s with 1 at center.
g3m([[0,0,0],[0,1,0],[0,0,0]]).
% G3c: 3x3 with two 1s at (0,0) and (2,2).
g3c([[1,0,0],[0,0,0],[0,0,1]]).
% G4: 4x4 with two 2s at top-left and one 3 at center.
g4([[2,0,0,0],[0,0,3,0],[0,3,0,0],[0,0,0,2]]).

% Tests for dt_manhattan/5.
:- begin_tests(dt_manhattan).
test(same_cell) :- dt_manhattan(0,0,0,0,D), D =:= 0.
test(adjacent) :- dt_manhattan(0,0,0,1,D), D =:= 1.
test(diagonal) :- dt_manhattan(0,0,2,2,D), D =:= 4.
:- end_tests(dt_manhattan).

% Tests for dt_chebyshev/5.
:- begin_tests(dt_chebyshev).
test(same_cell) :- dt_chebyshev(0,0,0,0,D), D =:= 0.
test(adjacent) :- dt_chebyshev(0,0,0,1,D), D =:= 1.
test(diagonal) :- dt_chebyshev(0,0,2,2,D), D =:= 2.
:- end_tests(dt_chebyshev).

% Tests for dt_euclidean_sq/5.
:- begin_tests(dt_euclidean_sq).
test(same_cell) :- dt_euclidean_sq(0,0,0,0,D), D =:= 0.
test(adjacent) :- dt_euclidean_sq(0,0,0,1,D), D =:= 1.
test(diagonal) :- dt_euclidean_sq(0,0,1,1,D), D =:= 2.
:- end_tests(dt_euclidean_sq).

% Tests for dt_nearest/4.
:- begin_tests(dt_nearest).
test(nearest_center) :-
    g3m(G), dt_nearest(G, 1, 0-0, R-C), R =:= 1, C =:= 1.
test(nearest_corner) :-
    g3c(G), dt_nearest(G, 1, 1-1, R-C), R-C = 0-0.
test(nearest_self) :-
    g3m(G), dt_nearest(G, 1, 1-1, R-C), R =:= 1, C =:= 1.
:- end_tests(dt_nearest).

% Tests for dt_farthest/4.
:- begin_tests(dt_farthest).
test(farthest_from_center) :-
    g3c(G), dt_farthest(G, 1, 1-1, R-C), R =:= 2, C =:= 2.
test(farthest_from_origin) :-
    g3c(G), dt_farthest(G, 1, 0-0, R-C), R =:= 2, C =:= 2.
test(farthest_from_corner) :-
    g3c(G), dt_farthest(G, 1, 2-2, R-C), R =:= 0, C =:= 0.
:- end_tests(dt_farthest).

% Tests for dt_all_at/5.
:- begin_tests(dt_all_at).
test(at_dist_zero) :-
    g3m(G), dt_all_at(G, 1, 1-1, 0, C), C = [1-1].
test(at_dist_one) :-
    g3c(G), dt_all_at(G, 1, 1-1, 1, C), C = [].
test(at_dist_two) :-
    g3c(G), dt_all_at(G, 1, 1-1, 2, C), length(C, N), N =:= 2.
:- end_tests(dt_all_at).

% Tests for dt_within_manhattan/5.
:- begin_tests(dt_within_manhattan).
test(within_zero) :-
    g3(G), dt_within_manhattan(G, 1, 1, 0, C), C = [1-1].
test(within_one) :-
    g3(G), dt_within_manhattan(G, 1, 1, 1, C), length(C, N), N =:= 5.
test(within_two) :-
    g3(G), dt_within_manhattan(G, 1, 1, 2, C), length(C, N), N =:= 9.
:- end_tests(dt_within_manhattan).

% Tests for dt_within_chebyshev/5.
:- begin_tests(dt_within_chebyshev).
test(within_zero) :-
    g3(G), dt_within_chebyshev(G, 1, 1, 0, C), C = [1-1].
test(within_one) :-
    g3(G), dt_within_chebyshev(G, 1, 1, 1, C), length(C, N), N =:= 9.
test(within_one_corner) :-
    g3(G), dt_within_chebyshev(G, 0, 0, 1, C), length(C, N), N =:= 4.
:- end_tests(dt_within_chebyshev).

% Tests for dt_map_manhattan/3.
:- begin_tests(dt_map_manhattan).
test(center_one) :-
    g3m(G), dt_map_manhattan(G, 1, M),
    nth0(1, M, Row), nth0(1, Row, D), D =:= 0.
test(corner_dist_two) :-
    g3m(G), dt_map_manhattan(G, 1, M),
    nth0(0, M, Row), nth0(0, Row, D), D =:= 2.
test(adjacent_dist_one) :-
    g3m(G), dt_map_manhattan(G, 1, M),
    nth0(0, M, Row), nth0(1, Row, D), D =:= 1.
:- end_tests(dt_map_manhattan).

% Tests for dt_map_chebyshev/3.
:- begin_tests(dt_map_chebyshev).
test(center_zero) :-
    g3m(G), dt_map_chebyshev(G, 1, M),
    nth0(1, M, Row), nth0(1, Row, D), D =:= 0.
test(corner_dist_one) :-
    g3m(G), dt_map_chebyshev(G, 1, M),
    nth0(0, M, Row), nth0(0, Row, D), D =:= 1.
test(adjacent_dist_one) :-
    g3m(G), dt_map_chebyshev(G, 1, M),
    nth0(0, M, Row), nth0(1, Row, D), D =:= 1.
:- end_tests(dt_map_chebyshev).

% Tests for dt_ring_manhattan/5.
:- begin_tests(dt_ring_manhattan).
test(ring_zero) :-
    g3(G), dt_ring_manhattan(G, 1, 1, 0, C), C = [1-1].
test(ring_one) :-
    g3(G), dt_ring_manhattan(G, 1, 1, 1, C), length(C, N), N =:= 4.
test(ring_two) :-
    g3(G), dt_ring_manhattan(G, 1, 1, 2, C), length(C, N), N =:= 4.
:- end_tests(dt_ring_manhattan).

% Tests for dt_centroid/3.
:- begin_tests(dt_centroid).
test(center_one) :-
    g3m(G), dt_centroid(G, 1, RC), RC = 1-1.
test(two_ones) :-
    g3c(G), dt_centroid(G, 1, RC), RC = 1-1.
test(uniform) :-
    g3(G), dt_centroid(G, 0, RC), RC = 1-1.
:- end_tests(dt_centroid).

% Tests for dt_diameter_manhattan/3.
:- begin_tests(dt_diameter_manhattan).
test(two_cells) :-
    dt_diameter_manhattan([0-0,2-2], _Pair, D), D =:= 4.
test(three_cells) :-
    dt_diameter_manhattan([0-0,1-1,2-2], _Pair, D), D =:= 4.
test(adjacent_cells) :-
    dt_diameter_manhattan([0-0,0-1], _Pair, D), D =:= 1.
:- end_tests(dt_diameter_manhattan).

% Tests for dt_diameter_chebyshev/3.
:- begin_tests(dt_diameter_chebyshev).
test(two_cells) :-
    dt_diameter_chebyshev([0-0,2-2], _Pair, D), D =:= 2.
test(three_cells) :-
    dt_diameter_chebyshev([0-0,1-1,2-2], _Pair, D), D =:= 2.
test(adjacent_cells) :-
    dt_diameter_chebyshev([0-0,0-1], _Pair, D), D =:= 1.
:- end_tests(dt_diameter_chebyshev).
