% test_neighbor.pl - PLUnit tests for the neighbor pack (Layer 93: nb_* predicates).
:- use_module('../prolog/neighbor').

% Tests for neighbor_4neighbors/4

:- begin_tests(neighbor_4neighbors).

test(center_of_three_by_three) :-
    neighbor_4neighbors([[0,0,0],[0,1,0],[0,0,0]], 1, 1, N),
    N = [nb(0,1,0), nb(2,1,0), nb(1,0,0), nb(1,2,0)].

test(corner_of_two_by_two) :-
    neighbor_4neighbors([[1,2],[3,4]], 0, 0, N),
    N = [nb(1,0,3), nb(0,1,2)].

test(edge_of_one_by_three) :-
    neighbor_4neighbors([[5,6,7]], 0, 1, N),
    N = [nb(0,0,5), nb(0,2,7)].

:- end_tests(neighbor_4neighbors).

% Tests for neighbor_8neighbors/4

:- begin_tests(neighbor_8neighbors).

test(corner_of_three_by_three) :-
    neighbor_8neighbors([[1,2,3],[4,5,6],[7,8,9]], 0, 0, N),
    N = [nb(0,1,2), nb(1,0,4), nb(1,1,5)].

test(center_of_three_by_three) :-
    neighbor_8neighbors([[1,0,1],[0,1,0],[1,0,1]], 1, 1, N),
    length(N, 8).

test(edge_cell_two_by_three) :-
    neighbor_8neighbors([[1,2,3],[4,5,6]], 0, 1, N),
    length(N, 5).

:- end_tests(neighbor_8neighbors).

% Tests for neighbor_is_boundary/4

:- begin_tests(neighbor_is_boundary).

test(center_of_single_in_bg) :-
    neighbor_is_boundary([[0,0,0],[0,1,0],[0,0,0]], 1, 1, 0).

test(corner_non_bg) :-
    neighbor_is_boundary([[1,1],[1,1]], 0, 0, 0).

test(interior_not_boundary) :-
    \+ neighbor_is_boundary([[1,1,1],[1,1,1],[1,1,1]], 1, 1, 0).

:- end_tests(neighbor_is_boundary).

% Tests for neighbor_is_interior/4

:- begin_tests(neighbor_is_interior).

test(solid_three_by_three_center_interior) :-
    neighbor_is_interior([[1,1,1],[1,1,1],[1,1,1]], 1, 1, 0).

test(surrounded_by_bg_not_interior) :-
    \+ neighbor_is_interior([[0,0,0],[0,1,0],[0,0,0]], 1, 1, 0).

test(larger_solid_center_interior) :-
    neighbor_is_interior([[2,2,2,2,2],[2,2,2,2,2],[2,2,2,2,2],[2,2,2,2,2],[2,2,2,2,2]], 2, 2, 0).

:- end_tests(neighbor_is_interior).

% Tests for neighbor_boundary_cells/3

:- begin_tests(neighbor_boundary_cells).

test(single_non_bg_cell) :-
    neighbor_boundary_cells([[0,0,0],[0,1,0],[0,0,0]], 0, [1-1]).

test(solid_two_by_two_all_boundary) :-
    neighbor_boundary_cells([[1,1],[1,1]], 0, [0-0, 0-1, 1-0, 1-1]).

test(no_non_bg_cells) :-
    neighbor_boundary_cells([[0,0],[0,0]], 0, []).

:- end_tests(neighbor_boundary_cells).

% Tests for neighbor_interior_cells/3

:- begin_tests(neighbor_interior_cells).

test(solid_three_by_three_center_only) :-
    neighbor_interior_cells([[1,1,1],[1,1,1],[1,1,1]], 0, [1-1]).

test(single_cell_no_interior) :-
    neighbor_interior_cells([[0,0,0],[0,1,0],[0,0,0]], 0, []).

test(larger_solid_interior) :-
    neighbor_interior_cells(
        [[1,1,1,1],[1,1,1,1],[1,1,1,1],[1,1,1,1]], 0,
        [1-1, 1-2, 2-1, 2-2]).

:- end_tests(neighbor_interior_cells).

% Tests for neighbor_count_same/4

:- begin_tests(neighbor_count_same).

test(center_of_solid_four_same) :-
    neighbor_count_same([[1,1,1],[1,1,1],[1,1,1]], 1, 1, 4).

test(center_of_bg_cross_zero_same) :-
    neighbor_count_same([[1,0,1],[0,1,0],[1,0,1]], 1, 1, 0).

test(corner_cell_one_same_neighbor) :-
    neighbor_count_same([[1,0],[1,0]], 0, 0, 1).

:- end_tests(neighbor_count_same).

% Tests for neighbor_count_diff/4

:- begin_tests(neighbor_count_diff).

test(center_surrounded_by_diff) :-
    neighbor_count_diff([[0,0,0],[0,1,0],[0,0,0]], 1, 1, 4).

test(center_of_solid_zero_diff) :-
    neighbor_count_diff([[1,1,1],[1,1,1],[1,1,1]], 1, 1, 0).

test(top_edge_one_diff) :-
    neighbor_count_diff([[1,1,1],[1,0,1],[1,1,1]], 0, 1, 1).

:- end_tests(neighbor_count_diff).

% Tests for neighbor_adjacent_colors/4

:- begin_tests(neighbor_adjacent_colors).

test(center_single_distinct_color) :-
    neighbor_adjacent_colors([[0,0,0],[0,1,0],[0,0,0]], 1, 1, [0]).

test(center_mixed_colors) :-
    neighbor_adjacent_colors([[1,2,3],[4,5,6],[7,8,9]], 1, 1, [2,4,6,8]).

test(corner_two_neighbors) :-
    neighbor_adjacent_colors([[1,2],[3,4]], 0, 0, [2,3]).

:- end_tests(neighbor_adjacent_colors).

% Tests for neighbor_contour/3

:- begin_tests(neighbor_contour).

test(single_cell_contour) :-
    neighbor_contour([[0,0,0],[0,1,0],[0,0,0]], 1, [1-1]).

test(solid_two_by_two_contour_all_cells) :-
    neighbor_contour([[1,1],[1,1]], 1, [0-0, 0-1, 1-0, 1-1]).

test(solid_three_by_three_contour_only_border) :-
    neighbor_contour([[1,1,1],[1,1,1],[1,1,1]], 1, C),
    C = [0-0, 0-1, 0-2, 1-0, 1-2, 2-0, 2-1, 2-2].

:- end_tests(neighbor_contour).

% Tests for neighbor_color_touches/3

:- begin_tests(neighbor_color_touches).

test(one_touches_two) :-
    neighbor_color_touches([[1,2],[0,0]], 1, 2).

test(one_does_not_touch_two_diag_only) :-
    \+ neighbor_color_touches([[1,0],[0,2]], 1, 2).

test(color_touches_bg) :-
    neighbor_color_touches([[1,0],[0,0]], 1, 0).

:- end_tests(neighbor_color_touches).

% Tests for neighbor_touching_pairs/4

:- begin_tests(neighbor_touching_pairs).

test(one_pair_h) :-
    neighbor_touching_pairs([[1,2],[0,0]], 1, 2, [(0-0)-(0-1)]).

test(no_pairs_when_not_touching) :-
    neighbor_touching_pairs([[1,0],[0,2]], 1, 2, []).

test(two_pairs_vertical) :-
    neighbor_touching_pairs([[1,0],[2,0]], 1, 2, [(0-0)-(1-0)]).

:- end_tests(neighbor_touching_pairs).

% Tests for neighbor_flood_fill/5

:- begin_tests(neighbor_flood_fill).

test(fill_entire_grid) :-
    neighbor_flood_fill([[1,1],[1,1]], 0, 0, 9, R),
    R = [[9,9],[9,9]].

test(fill_one_region_not_other) :-
    neighbor_flood_fill([[1,0,1],[1,0,1]], 0, 0, 2, R),
    R = [[2,0,1],[2,0,1]].

test(same_fill_val_unchanged) :-
    neighbor_flood_fill([[1,1],[1,1]], 0, 0, 1, R),
    R = [[1,1],[1,1]].

:- end_tests(neighbor_flood_fill).

% Tests for neighbor_dilate/4

:- begin_tests(neighbor_dilate).

test(dilate_single_cell) :-
    neighbor_dilate([[0,0,0],[0,1,0],[0,0,0]], 0, 1, R),
    R = [[0,1,0],[1,1,1],[0,1,0]].

test(dilate_does_not_overwrite_other_colors) :-
    neighbor_dilate([[0,2,0],[0,1,0],[0,0,0]], 0, 1, R),
    nth0(0, R, Row0), nth0(1, Row0, V),
    V = 2.

test(dilate_full_row_expands) :-
    neighbor_dilate([[0,0,0],[1,1,1],[0,0,0]], 0, 1, R),
    R = [[1,1,1],[1,1,1],[1,1,1]].

:- end_tests(neighbor_dilate).
