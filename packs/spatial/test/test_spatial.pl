% PLUnit tests for the spatial pack (sp_* predicates).
:- use_module(library(plunit)).
:- use_module(library(spatial)).

:- begin_tests(spatial_direction).

test(north) :-
    spatial_direction(r(3,2), r(1,2), Dir), Dir = north.

test(south) :-
    spatial_direction(r(1,2), r(3,2), Dir), Dir = south.

test(east) :-
    spatial_direction(r(2,1), r(2,4), Dir), Dir = east.

test(west) :-
    spatial_direction(r(2,4), r(2,1), Dir), Dir = west.

test(northeast) :-
    spatial_direction(r(3,1), r(1,3), Dir), Dir = northeast.

test(southwest) :-
    spatial_direction(r(1,3), r(3,1), Dir), Dir = southwest.

test(same) :-
    spatial_direction(r(2,2), r(2,2), Dir), Dir = same.

:- end_tests(spatial_direction).

:- begin_tests(spatial_manhattan).

test(adjacent_h) :-
    spatial_distance_manhattan(r(0,0), r(0,1), D), D =:= 1.

test(adjacent_v) :-
    spatial_distance_manhattan(r(0,0), r(1,0), D), D =:= 1.

test(diagonal) :-
    spatial_distance_manhattan(r(0,0), r(2,2), D), D =:= 4.

test(same_cell) :-
    spatial_distance_manhattan(r(1,1), r(1,1), D), D =:= 0.

:- end_tests(spatial_manhattan).

:- begin_tests(spatial_chebyshev).

test(adjacent_h) :-
    spatial_distance_chebyshev(r(0,0), r(0,3), D), D =:= 3.

test(diagonal_1) :-
    spatial_distance_chebyshev(r(0,0), r(1,1), D), D =:= 1.

test(diagonal_2) :-
    spatial_distance_chebyshev(r(0,0), r(3,2), D), D =:= 3.

test(same_cell) :-
    spatial_distance_chebyshev(r(2,2), r(2,2), D), D =:= 0.

:- end_tests(spatial_chebyshev).

:- begin_tests(spatial_neighbors4).

test(center_3x3) :-
    spatial_neighbors4(r(1,1), 3-3, N),
    msort(N, Sorted),
    Sorted = [r(0,1), r(1,0), r(1,2), r(2,1)].

test(corner_3x3) :-
    spatial_neighbors4(r(0,0), 3-3, N),
    msort(N, Sorted),
    Sorted = [r(0,1), r(1,0)].

test(edge_3x3) :-
    spatial_neighbors4(r(0,1), 3-3, N),
    msort(N, Sorted),
    Sorted = [r(0,0), r(0,2), r(1,1)].

:- end_tests(spatial_neighbors4).

:- begin_tests(spatial_neighbors8).

test(center_3x3) :-
    spatial_neighbors8(r(1,1), 3-3, N),
    length(N, L), L =:= 8.

test(corner_3x3) :-
    spatial_neighbors8(r(0,0), 3-3, N),
    msort(N, Sorted),
    Sorted = [r(0,1), r(1,0), r(1,1)].

test(edge_center_3x3) :-
    spatial_neighbors8(r(0,1), 3-3, N),
    length(N, L), L =:= 5.

:- end_tests(spatial_neighbors8).

:- begin_tests(spatial_adjacent4).

test(same_row) :-
    spatial_adjacent4(r(1,1), r(1,2)).

test(same_col) :-
    spatial_adjacent4(r(2,3), r(3,3)).

test(not_diagonal) :-
    \+ spatial_adjacent4(r(0,0), r(1,1)).

test(not_distance_2) :-
    \+ spatial_adjacent4(r(0,0), r(0,2)).

:- end_tests(spatial_adjacent4).

:- begin_tests(spatial_adjacent8).

test(diagonal) :-
    spatial_adjacent8(r(0,0), r(1,1)).

test(horizontal) :-
    spatial_adjacent8(r(1,1), r(1,2)).

test(not_distance_2) :-
    \+ spatial_adjacent8(r(0,0), r(0,2)).

:- end_tests(spatial_adjacent8).

:- begin_tests(spatial_bbox_contains).

test(inside) :-
    spatial_bbox_contains(bbox(1,1,3,3), r(2,2)).

test(on_boundary) :-
    spatial_bbox_contains(bbox(0,0,2,2), r(0,0)).

test(outside_row) :-
    \+ spatial_bbox_contains(bbox(1,1,3,3), r(0,2)).

test(outside_col) :-
    \+ spatial_bbox_contains(bbox(1,1,3,3), r(2,4)).

:- end_tests(spatial_bbox_contains).

:- begin_tests(spatial_in_region).

test(present) :-
    spatial_in_region(r(1,1), [r(0,0), r(1,1), r(2,2)]).

test(absent) :-
    \+ spatial_in_region(r(3,3), [r(0,0), r(1,1)]).

:- end_tests(spatial_in_region).

:- begin_tests(spatial_row_between).

test(filter_rows) :-
    Region = [r(0,0), r(1,0), r(2,0), r(3,0)],
    spatial_row_between(Region, 1, 2, F),
    F = [r(1,0), r(2,0)].

test(inclusive_boundary) :-
    Region = [r(0,0), r(5,0)],
    spatial_row_between(Region, 0, 5, F),
    F = [r(0,0), r(5,0)].

test(empty_result) :-
    Region = [r(0,0), r(1,0)],
    spatial_row_between(Region, 5, 6, F),
    F = [].

:- end_tests(spatial_row_between).

:- begin_tests(spatial_col_between).

test(filter_cols) :-
    Region = [r(0,0), r(0,1), r(0,2), r(0,3)],
    spatial_col_between(Region, 1, 2, F),
    F = [r(0,1), r(0,2)].

test(inclusive_boundary) :-
    Region = [r(0,0), r(0,5)],
    spatial_col_between(Region, 0, 5, F),
    F = [r(0,0), r(0,5)].

test(empty_result) :-
    Region = [r(0,0), r(0,1)],
    spatial_col_between(Region, 3, 4, F),
    F = [].

:- end_tests(spatial_col_between).

:- begin_tests(spatial_closest).

test(closest_to_origin) :-
    Region = [r(5,5), r(1,1), r(3,3)],
    spatial_closest(r(0,0), Region, Closest),
    Closest = r(1,1).

test(closest_single) :-
    spatial_closest(r(0,0), [r(2,2)], Closest),
    Closest = r(2,2).

test(closest_tie_takes_first) :-
    % r(1,0) and r(0,1) both at distance 1; returns first in list.
    spatial_closest(r(0,0), [r(1,0), r(0,1)], Closest),
    Closest = r(1,0).

:- end_tests(spatial_closest).

:- begin_tests(spatial_farthest).

test(farthest_from_origin) :-
    Region = [r(1,1), r(5,5), r(2,2)],
    spatial_farthest(r(0,0), Region, Farthest),
    Farthest = r(5,5).

test(farthest_single) :-
    spatial_farthest(r(0,0), [r(3,3)], Farthest),
    Farthest = r(3,3).

:- end_tests(spatial_farthest).

:- begin_tests(spatial_centroid).

test(centroid_3x3_region) :-
    % 3x3 all-cells region: centroid is (1,1).
    Region = [r(0,0),r(0,1),r(0,2),
              r(1,0),r(1,1),r(1,2),
              r(2,0),r(2,1),r(2,2)],
    spatial_centroid(Region, R, C),
    R =:= 1, C =:= 1.

test(centroid_single_cell) :-
    spatial_centroid([r(3,4)], R, C),
    R =:= 3, C =:= 4.

test(centroid_two_cells) :-
    % Average of (0,0) and (2,2) = (1,1).
    spatial_centroid([r(0,0), r(2,2)], R, C),
    R =:= 1, C =:= 1.

test(centroid_truncated) :-
    % Average of (0,0) and (1,0) = (0.5, 0) -> truncated to (0, 0).
    spatial_centroid([r(0,0), r(1,0)], R, C),
    R =:= 0, C =:= 0.

:- end_tests(spatial_centroid).
