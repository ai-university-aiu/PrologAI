:- use_module('../prolog/ray').

:- begin_tests(ray).

% ray_in_bounds/3 tests

test(in_bounds_true) :-
    Grid = [[0,0,0],[0,0,0],[0,0,0]],
    ray_in_bounds(Grid, 0, 0).

test(in_bounds_row_oob) :-
    Grid = [[0,0,0],[0,0,0],[0,0,0]],
    \+ ray_in_bounds(Grid, 3, 0).

test(in_bounds_col_oob) :-
    Grid = [[0,0,0],[0,0,0],[0,0,0]],
    \+ ray_in_bounds(Grid, 0, 3).

% ray_cells_in_dir/6 tests

test(cells_in_dir_right) :-
    Grid = [[0,0,0],[0,0,0],[0,0,0]],
    ray_cells_in_dir(Grid, 0, 0, 0, 1, Cells),
    Cells = [0-1, 0-2].

test(cells_in_dir_down) :-
    Grid = [[0,0,0],[0,0,0],[0,0,0]],
    ray_cells_in_dir(Grid, 0, 2, 1, 0, Cells),
    Cells = [1-2, 2-2].

test(cells_in_dir_edge) :-
    Grid = [[0,0,0],[0,0,0],[0,0,0]],
    ray_cells_in_dir(Grid, 2, 2, 0, 1, Cells),
    Cells = [].

% ray_first_hit/7 tests

test(first_hit_right) :-
    Grid = [[0,0,1],[0,0,0],[0,0,0]],
    ray_first_hit(Grid, 0, 0, 0, 1, 0, Hit),
    Hit = 0-2.

test(first_hit_down) :-
    Grid = [[0,0,0],[0,0,0],[1,0,0]],
    ray_first_hit(Grid, 0, 0, 1, 0, 0, Hit),
    Hit = 2-0.

test(first_hit_fails) :-
    Grid = [[0,0,0],[0,0,0],[0,0,0]],
    \+ ray_first_hit(Grid, 0, 0, 0, 1, 0, _).

% ray_cast_clear/7 tests

test(cast_clear_stops) :-
    Grid = [[0,0,1]],
    ray_cast_clear(Grid, 0, 0, 0, 1, 0, Clear),
    Clear = [0-1].

test(cast_clear_all) :-
    Grid = [[0,0,0]],
    ray_cast_clear(Grid, 0, 0, 0, 1, 0, Clear),
    Clear = [0-1, 0-2].

test(cast_clear_empty) :-
    Grid = [[0,1,0]],
    ray_cast_clear(Grid, 0, 0, 0, 1, 0, Clear),
    Clear = [].

% ray_distance_to_hit/7 tests

test(dist_hit_one) :-
    Grid = [[0,1,0]],
    ray_distance_to_hit(Grid, 0, 0, 0, 1, 0, D),
    D = 1.

test(dist_hit_three) :-
    Grid = [[0,0,0,1]],
    ray_distance_to_hit(Grid, 0, 0, 0, 1, 0, D),
    D = 3.

test(dist_hit_fails) :-
    Grid = [[0,0,0]],
    \+ ray_distance_to_hit(Grid, 0, 0, 0, 1, 0, _).

% ray_distance_to_edge/6 tests

test(dist_edge_right) :-
    Grid = [[0,0,0],[0,0,0],[0,0,0]],
    ray_distance_to_edge(Grid, 0, 0, 0, 1, D),
    D = 2.

test(dist_edge_middle) :-
    Grid = [[0,0,0],[0,0,0],[0,0,0]],
    ray_distance_to_edge(Grid, 1, 1, 0, 1, D),
    D = 1.

test(dist_edge_zero) :-
    Grid = [[0,0,0],[0,0,0],[0,0,0]],
    ray_distance_to_edge(Grid, 0, 2, 0, 1, D),
    D = 0.

% ray_is_clear/6 tests

test(is_clear_yes) :-
    Grid = [[0,0,0]],
    ray_is_clear(Grid, 0, 0, 0, 1, 0).

test(is_clear_no) :-
    Grid = [[0,1,0]],
    \+ ray_is_clear(Grid, 0, 0, 0, 1, 0).

test(is_clear_empty_dir) :-
    Grid = [[0]],
    ray_is_clear(Grid, 0, 0, 0, 1, 0).

% ray_project/8 tests

test(project_two_right) :-
    Grid = [[0,0,0],[0,0,0],[0,0,0]],
    ray_project(Grid, 0, 0, 0, 1, 2, NR, NC),
    NR = 0, NC = 2.

test(project_one_down) :-
    Grid = [[0,0,0],[0,0,0],[0,0,0]],
    ray_project(Grid, 0, 0, 1, 0, 1, NR, NC),
    NR = 1, NC = 0.

test(project_oob) :-
    Grid = [[0,0,0],[0,0,0],[0,0,0]],
    \+ ray_project(Grid, 0, 0, 0, 1, 3, _, _).

% ray_dir_to_delta/3 tests

test(dir_up) :-
    ray_dir_to_delta(up, DR, DC),
    DR = -1, DC = 0.

test(dir_right) :-
    ray_dir_to_delta(right, DR, DC),
    DR = 0, DC = 1.

test(dir_dr) :-
    ray_dir_to_delta(dr, DR, DC),
    DR = 1, DC = 1.

% ray_reflect_h/4 tests

test(reflect_h_up) :-
    ray_reflect_h(-1, 0, RDR, RDC),
    RDR = 1, RDC = 0.

test(reflect_h_diag) :-
    ray_reflect_h(1, 1, RDR, RDC),
    RDR = -1, RDC = 1.

test(reflect_h_horizontal) :-
    ray_reflect_h(0, 1, RDR, RDC),
    RDR = 0, RDC = 1.

% ray_reflect_v/4 tests

test(reflect_v_right) :-
    ray_reflect_v(0, 1, RDR, RDC),
    RDR = 0, RDC = -1.

test(reflect_v_diag) :-
    ray_reflect_v(1, -1, RDR, RDC),
    RDR = 1, RDC = 1.

test(reflect_v_vertical) :-
    ray_reflect_v(-1, 0, RDR, RDC),
    RDR = -1, RDC = 0.

% ray_los/6 tests

test(los_clear) :-
    Grid = [[0,0,0]],
    ray_los(Grid, 0, 0, 0, 2, 0).

test(los_blocked) :-
    Grid = [[0,1,0]],
    \+ ray_los(Grid, 0, 0, 0, 2, 0).

test(los_adjacent) :-
    Grid = [[0,0]],
    ray_los(Grid, 0, 0, 0, 1, 0).

% ray_los_cells/6 tests

test(los_cells_horiz) :-
    ray_los_cells(_, 0, 0, 0, 3, Cells),
    Cells = [0-1, 0-2].

test(los_cells_vert) :-
    ray_los_cells(_, 0, 0, 3, 0, Cells),
    Cells = [1-0, 2-0].

test(los_cells_diag) :-
    ray_los_cells(_, 0, 0, 3, 3, Cells),
    Cells = [1-1, 2-2].

% ray_cast_all_4/5 tests

test(cast_all_4_hits) :-
    Grid = [[0,0,0],[1,0,1],[0,0,0]],
    ray_cast_all_4(Grid, 1, 1, 0, Hits),
    Hits = [up-none, down-none, left-(1-0), right-(1-2)].

test(cast_all_4_all_clear) :-
    Grid = [[0,0,0],[0,0,0],[0,0,0]],
    ray_cast_all_4(Grid, 1, 1, 0, Hits),
    Hits = [up-none, down-none, left-none, right-none].

test(cast_all_4_corner) :-
    Grid = [[0,1],[1,0]],
    ray_cast_all_4(Grid, 0, 0, 0, Hits),
    Hits = [up-none, down-(1-0), left-none, right-(0-1)].

:- end_tests(ray).
