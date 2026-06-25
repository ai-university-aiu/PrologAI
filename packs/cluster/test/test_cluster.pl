:- use_module('../prolog/cluster').

:- begin_tests(cluster).

% cl_chebyshev/5 tests

test(chebyshev_basic) :-
    cl_chebyshev(0, 0, 2, 3, D), D = 3.

test(chebyshev_same_cell) :-
    cl_chebyshev(2, 2, 2, 2, D), D = 0.

test(chebyshev_diagonal) :-
    cl_chebyshev(0, 0, 4, 4, D), D = 4.

% cl_manhattan/5 tests

test(manhattan_basic) :-
    cl_manhattan(0, 0, 2, 3, D), D = 5.

test(manhattan_same_cell) :-
    cl_manhattan(1, 1, 1, 1, D), D = 0.

test(manhattan_row_only) :-
    cl_manhattan(0, 0, 3, 0, D), D = 3.

% cl_euclidean_sq/5 tests

test(euclidean_sq_basic) :-
    cl_euclidean_sq(0, 0, 3, 4, D), D = 25.

test(euclidean_sq_same_cell) :-
    cl_euclidean_sq(2, 2, 2, 2, D), D = 0.

test(euclidean_sq_unit) :-
    cl_euclidean_sq(0, 0, 1, 1, D), D = 2.

% cl_within/5 tests

test(within_basic) :-
    cl_within(2, 2, 1, [1-1,2-2,2-3,4-4], Near),
    sort(Near, S), S = [1-1,2-2,2-3].

test(within_none) :-
    cl_within(0, 0, 0, [1-0,0-1,1-1], []).

test(within_all) :-
    cl_within(0, 0, 10, [0-0,1-1,2-2], Near), Near = [0-0,1-1,2-2].

% cl_nearest/4 tests

test(nearest_basic) :-
    cl_nearest(0, 0, [3-3,1-1,5-5], Nearest), Nearest = 1-1.

test(nearest_single) :-
    cl_nearest(0, 0, [2-3], Nearest), Nearest = 2-3.

test(nearest_tie_first) :-
    cl_nearest(0, 0, [1-0,0-1], Nearest), Nearest = 1-0.

% cl_farthest/4 tests

test(farthest_basic) :-
    cl_farthest(0, 0, [1-1,3-3,2-2], Farthest), Farthest = 3-3.

test(farthest_single) :-
    cl_farthest(5, 5, [0-0], Farthest), Farthest = 0-0.

test(farthest_row) :-
    cl_farthest(0, 0, [2-0,4-0,1-0], Farthest), Farthest = 4-0.

% cl_center/3 tests

test(center_square) :-
    cl_center([0-0,0-2,2-0,2-2], CR, CC), CR = 1, CC = 1.

test(center_single) :-
    cl_center([3-5], CR, CC), CR = 3, CC = 5.

test(center_line) :-
    cl_center([0-0,0-2,0-4], CR, CC), CR = 0, CC = 2.

% cl_diameter/2 tests

test(diameter_basic) :-
    cl_diameter([0-0,0-4,3-0,3-4], D), D = 4.

test(diameter_single) :-
    cl_diameter([2-3], D), D = 0.

test(diameter_line) :-
    cl_diameter([0-0,0-3], D), D = 3.

% cl_spread/3 tests

test(spread_square) :-
    cl_spread([0-0,2-4], DR, DC), DR = 2, DC = 4.

test(spread_single) :-
    cl_spread([3-3], DR, DC), DR = 0, DC = 0.

test(spread_row) :-
    cl_spread([1-0,1-5,1-3], DR, DC), DR = 0, DC = 5.

% cl_group_by_color/4 tests

test(group_by_color_basic) :-
    Grid = [[1,2],[1,1]],
    cl_group_by_color(Grid, [0-0,0-1,1-0,1-1], Colors, Groups),
    Colors = [1,2],
    Groups = [[0-0,1-0,1-1],[0-1]].

test(group_by_color_single) :-
    Grid = [[5,5],[5,5]],
    cl_group_by_color(Grid, [0-0,1-1], Colors, Groups),
    Colors = [5], Groups = [[0-0,1-1]].

test(group_by_color_three) :-
    Grid = [[1,2,3]],
    cl_group_by_color(Grid, [0-0,0-1,0-2], Colors, _Groups),
    Colors = [1,2,3].

% cl_sort_by_dist/4 tests

test(sort_by_dist_basic) :-
    cl_sort_by_dist(0, 0, [3-3,1-1,2-2], Sorted),
    Sorted = [1-1,2-2,3-3].

test(sort_by_dist_single) :-
    cl_sort_by_dist(0, 0, [4-4], Sorted), Sorted = [4-4].

test(sort_by_dist_equal_first) :-
    cl_sort_by_dist(0, 0, [0-2,2-0,1-1], Sorted),
    Sorted = [1-1,0-2,2-0].

% cl_nearest_pair/3 tests

test(nearest_pair_basic) :-
    cl_nearest_pair([0-0,0-1,5-5], C1, C2),
    C1 = 0-0, C2 = 0-1.

test(nearest_pair_line) :-
    cl_nearest_pair([0-0,0-3,0-1], C1, C2),
    C1 = 0-0, C2 = 0-1.

test(nearest_pair_two) :-
    cl_nearest_pair([1-1,4-4], C1, C2),
    C1 = 1-1, C2 = 4-4.

% cl_farthest_pair/3 tests

test(farthest_pair_basic) :-
    cl_farthest_pair([0-0,0-1,5-5], C1, C2),
    C1 = 0-0, C2 = 5-5.

test(farthest_pair_line) :-
    cl_farthest_pair([0-0,0-3,0-1], C1, C2),
    C1 = 0-0, C2 = 0-3.

test(farthest_pair_two) :-
    cl_farthest_pair([1-1,4-4], C1, C2),
    C1 = 1-1, C2 = 4-4.

% cl_cells_in_band/6 tests

test(band_basic) :-
    cl_cells_in_band(1, 3, 1, 3, [0-0,1-1,2-2,4-4,3-3], Band),
    sort(Band, S), S = [1-1,2-2,3-3].

test(band_empty) :-
    cl_cells_in_band(5, 7, 5, 7, [0-0,1-1], []).

test(band_all) :-
    cl_cells_in_band(0, 4, 0, 4, [0-0,2-2,4-4], Band),
    Band = [0-0,2-2,4-4].

:- end_tests(cluster).
