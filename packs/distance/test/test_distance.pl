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

% Tests for distance_manhattan/5.
:- begin_tests(distance_manhattan).
test(same_cell) :- distance_manhattan(0,0,0,0,D), D =:= 0.
test(adjacent) :- distance_manhattan(0,0,0,1,D), D =:= 1.
test(diagonal) :- distance_manhattan(0,0,2,2,D), D =:= 4.
:- end_tests(distance_manhattan).

% Tests for distance_chebyshev/5.
:- begin_tests(distance_chebyshev).
test(same_cell) :- distance_chebyshev(0,0,0,0,D), D =:= 0.
test(adjacent) :- distance_chebyshev(0,0,0,1,D), D =:= 1.
test(diagonal) :- distance_chebyshev(0,0,2,2,D), D =:= 2.
:- end_tests(distance_chebyshev).

% Tests for distance_euclidean_sq/5.
:- begin_tests(distance_euclidean_sq).
test(same_cell) :- distance_euclidean_sq(0,0,0,0,D), D =:= 0.
test(adjacent) :- distance_euclidean_sq(0,0,0,1,D), D =:= 1.
test(diagonal) :- distance_euclidean_sq(0,0,1,1,D), D =:= 2.
:- end_tests(distance_euclidean_sq).

% Tests for distance_nearest/4.
:- begin_tests(distance_nearest).
test(nearest_center) :-
    g3m(G), distance_nearest(G, 1, 0-0, R-C), R =:= 1, C =:= 1.
test(nearest_corner) :-
    g3c(G), distance_nearest(G, 1, 1-1, R-C), R-C = 0-0.
test(nearest_self) :-
    g3m(G), distance_nearest(G, 1, 1-1, R-C), R =:= 1, C =:= 1.
:- end_tests(distance_nearest).

% Tests for distance_farthest/4.
:- begin_tests(distance_farthest).
test(farthest_from_center) :-
    g3c(G), distance_farthest(G, 1, 1-1, R-C), R =:= 2, C =:= 2.
test(farthest_from_origin) :-
    g3c(G), distance_farthest(G, 1, 0-0, R-C), R =:= 2, C =:= 2.
test(farthest_from_corner) :-
    g3c(G), distance_farthest(G, 1, 2-2, R-C), R =:= 0, C =:= 0.
:- end_tests(distance_farthest).

% Tests for distance_all_at/5.
:- begin_tests(distance_all_at).
test(at_dist_zero) :-
    g3m(G), distance_all_at(G, 1, 1-1, 0, C), C = [1-1].
test(at_dist_one) :-
    g3c(G), distance_all_at(G, 1, 1-1, 1, C), C = [].
test(at_dist_two) :-
    g3c(G), distance_all_at(G, 1, 1-1, 2, C), length(C, N), N =:= 2.
:- end_tests(distance_all_at).

% Tests for distance_within_manhattan/5.
:- begin_tests(distance_within_manhattan).
test(within_zero) :-
    g3(G), distance_within_manhattan(G, 1, 1, 0, C), C = [1-1].
test(within_one) :-
    g3(G), distance_within_manhattan(G, 1, 1, 1, C), length(C, N), N =:= 5.
test(within_two) :-
    g3(G), distance_within_manhattan(G, 1, 1, 2, C), length(C, N), N =:= 9.
:- end_tests(distance_within_manhattan).

% Tests for distance_within_chebyshev/5.
:- begin_tests(distance_within_chebyshev).
test(within_zero) :-
    g3(G), distance_within_chebyshev(G, 1, 1, 0, C), C = [1-1].
test(within_one) :-
    g3(G), distance_within_chebyshev(G, 1, 1, 1, C), length(C, N), N =:= 9.
test(within_one_corner) :-
    g3(G), distance_within_chebyshev(G, 0, 0, 1, C), length(C, N), N =:= 4.
:- end_tests(distance_within_chebyshev).

% Tests for distance_map_manhattan/3.
:- begin_tests(distance_map_manhattan).
test(center_one) :-
    g3m(G), distance_map_manhattan(G, 1, M),
    nth0(1, M, Row), nth0(1, Row, D), D =:= 0.
test(corner_dist_two) :-
    g3m(G), distance_map_manhattan(G, 1, M),
    nth0(0, M, Row), nth0(0, Row, D), D =:= 2.
test(adjacent_dist_one) :-
    g3m(G), distance_map_manhattan(G, 1, M),
    nth0(0, M, Row), nth0(1, Row, D), D =:= 1.
:- end_tests(distance_map_manhattan).

% Tests for distance_map_chebyshev/3.
:- begin_tests(distance_map_chebyshev).
test(center_zero) :-
    g3m(G), distance_map_chebyshev(G, 1, M),
    nth0(1, M, Row), nth0(1, Row, D), D =:= 0.
test(corner_dist_one) :-
    g3m(G), distance_map_chebyshev(G, 1, M),
    nth0(0, M, Row), nth0(0, Row, D), D =:= 1.
test(adjacent_dist_one) :-
    g3m(G), distance_map_chebyshev(G, 1, M),
    nth0(0, M, Row), nth0(1, Row, D), D =:= 1.
:- end_tests(distance_map_chebyshev).

% Tests for distance_ring_manhattan/5.
:- begin_tests(distance_ring_manhattan).
test(ring_zero) :-
    g3(G), distance_ring_manhattan(G, 1, 1, 0, C), C = [1-1].
test(ring_one) :-
    g3(G), distance_ring_manhattan(G, 1, 1, 1, C), length(C, N), N =:= 4.
test(ring_two) :-
    g3(G), distance_ring_manhattan(G, 1, 1, 2, C), length(C, N), N =:= 4.
:- end_tests(distance_ring_manhattan).

% Tests for distance_centroid/3.
:- begin_tests(distance_centroid).
test(center_one) :-
    g3m(G), distance_centroid(G, 1, RC), RC = 1-1.
test(two_ones) :-
    g3c(G), distance_centroid(G, 1, RC), RC = 1-1.
test(uniform) :-
    g3(G), distance_centroid(G, 0, RC), RC = 1-1.
:- end_tests(distance_centroid).

% Tests for distance_diameter_manhattan/3.
:- begin_tests(distance_diameter_manhattan).
test(two_cells) :-
    distance_diameter_manhattan([0-0,2-2], _Pair, D), D =:= 4.
test(three_cells) :-
    distance_diameter_manhattan([0-0,1-1,2-2], _Pair, D), D =:= 4.
test(adjacent_cells) :-
    distance_diameter_manhattan([0-0,0-1], _Pair, D), D =:= 1.
:- end_tests(distance_diameter_manhattan).

% Tests for distance_diameter_chebyshev/3.
:- begin_tests(distance_diameter_chebyshev).
test(two_cells) :-
    distance_diameter_chebyshev([0-0,2-2], _Pair, D), D =:= 2.
test(three_cells) :-
    distance_diameter_chebyshev([0-0,1-1,2-2], _Pair, D), D =:= 2.
test(adjacent_cells) :-
    distance_diameter_chebyshev([0-0,0-1], _Pair, D), D =:= 1.
:- end_tests(distance_diameter_chebyshev).
