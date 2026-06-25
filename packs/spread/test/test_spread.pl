:- use_module('../prolog/spread').

:- begin_tests(spread).

% sd_dist_map/5 tests

% Single-source BFS on a 1x3 all-background grid; sort neutralises BFS order.
test(dist_map_basic) :-
    sd_dist_map([[0,0,0]], 0, 0, 0, DM),
    sort(DM, S),
    S = [(0-0)-0, (0-1)-1, (0-2)-2].

% Wall in the middle: source is at right end, only that cell is reachable.
test(dist_map_isolated) :-
    sd_dist_map([[0,1,0]], 0, 2, 0, DM),
    sort(DM, S),
    S = [(0-2)-0].

% Source cell has obstacle color: result is the empty distance map.
test(dist_map_nonbg_source) :-
    sd_dist_map([[0,1,0]], 0, 1, 0, DM),
    DM = [].

% sd_dist_multi/4 tests

% Two seeds at opposite ends of a 1x4 row; each half reachable from the nearest.
test(dist_multi_two_seeds) :-
    sd_dist_multi([[0,0,0,0]], [0-0, 0-3], 0, DM),
    sort(DM, S),
    S = [(0-0)-0, (0-1)-1, (0-2)-1, (0-3)-0].

% A single seed gives the same result as sd_dist_map.
test(dist_multi_single_seed) :-
    sd_dist_multi([[0,0,0]], [0-0], 0, DM),
    sort(DM, S),
    S = [(0-0)-0, (0-1)-1, (0-2)-2].

% Non-background seeds are silently filtered before BFS.
test(dist_multi_nonbg_filtered) :-
    sd_dist_multi([[0,1,0]], [0-0, 0-1], 0, DM),
    sort(DM, S),
    S = [(0-0)-0].

% sd_reachable/5 tests

% All cells on a 1x3 background row are reachable from the leftmost cell.
test(reachable_all) :-
    sd_reachable([[0,0,0]], 0, 0, 0, Cells),
    Cells = [0-0, 0-1, 0-2].

% A wall isolates the source; only the source itself is returned.
test(reachable_only_source) :-
    sd_reachable([[0,1,0]], 0, 0, 0, Cells),
    Cells = [0-0].

% A single-cell grid returns that cell.
test(reachable_single_cell) :-
    sd_reachable([[0]], 0, 0, 0, Cells),
    Cells = [0-0].

% sd_path_dist/7 tests

% Distance from left to right end of a 1x3 row is 2.
test(path_dist_basic) :-
    sd_path_dist([[0,0,0]], 0, 0, 0, 2, 0, D),
    D = 2.

% Distance from a cell to itself is zero.
test(path_dist_same_cell) :-
    sd_path_dist([[0,0,0]], 0, 1, 0, 1, 0, D),
    D = 0.

% A blocking wall makes the path nonexistent; the predicate fails.
test(path_dist_blocked, [fail]) :-
    sd_path_dist([[0,1,0]], 0, 0, 0, 2, 0, _).

% sd_path_exists/6 tests

% A clear 1x3 row connects left to right.
test(path_exists_true) :-
    sd_path_exists([[0,0,0]], 0, 0, 0, 2, 0).

% A wall in the middle blocks the path.
test(path_exists_false, [fail]) :-
    sd_path_exists([[0,1,0]], 0, 0, 0, 2, 0).

% Adjacent cells are always connected.
test(path_exists_adjacent) :-
    sd_path_exists([[0,0]], 0, 0, 0, 1, 0).

% sd_ring/6 tests

% Distance-1 ring around the center of a 3x3 all-background grid.
test(ring_dist1) :-
    sd_ring([[0,0,0],[0,0,0],[0,0,0]], 1, 1, 0, 1, Cells),
    Cells = [0-1, 1-0, 1-2, 2-1].

% Distance-0 ring is just the source cell.
test(ring_dist0) :-
    sd_ring([[0,0,0]], 0, 0, 0, 0, Cells),
    Cells = [0-0].

% Distance-2 ring around the center of a 3x3 grid gives the four corners.
test(ring_dist2) :-
    sd_ring([[0,0,0],[0,0,0],[0,0,0]], 1, 1, 0, 2, Cells),
    Cells = [0-0, 0-2, 2-0, 2-2].

% sd_zone/6 tests

% Zone up to distance 1 from (0,0) in a 1x3 row includes two cells.
test(zone_maxd1) :-
    sd_zone([[0,0,0]], 0, 0, 0, 1, Cells),
    Cells = [0-0, 0-1].

% Zone up to distance 0 is just the source.
test(zone_maxd0) :-
    sd_zone([[0,0,0]], 0, 0, 0, 0, Cells),
    Cells = [0-0].

% A large MaxD from the center of a 3x3 grid covers all 9 cells.
test(zone_covers_all) :-
    sd_zone([[0,0,0],[0,0,0],[0,0,0]], 1, 1, 0, 5, Cells),
    Cells = [0-0, 0-1, 0-2, 1-0, 1-1, 1-2, 2-0, 2-1, 2-2].

% sd_dist_to_set/6 tests

% Single target at the far end of a 1x3 row; distance is 2.
test(dist_to_set_one_target) :-
    sd_dist_to_set([[0,0,0]], 0, 0, [0-2], 0, D),
    D = 2.

% Target is the source cell; distance is zero.
test(dist_to_set_source) :-
    sd_dist_to_set([[0,0,0]], 0, 0, [0-0], 0, D),
    D = 0.

% Two targets; predicate returns the minimum distance.
test(dist_to_set_nearest) :-
    sd_dist_to_set([[0,0,0,0]], 0, 0, [0-2, 0-3], 0, D),
    D = 2.

% sd_farthest/5 tests

% On a 1x3 row, the farthest cell from (0,0) is (0,2) at distance 2.
test(farthest_basic) :-
    sd_farthest([[0,0,0]], 0, 0, 0, Cell),
    Cell = 0-2.

% A single-cell grid returns that cell as farthest (distance 0).
test(farthest_single) :-
    sd_farthest([[0]], 0, 0, 0, Cell),
    Cell = 0-0.

% On a 1x4 row from (0,1), the farthest cell is (0,3) at distance 2.
test(farthest_from_middle) :-
    sd_farthest([[0,0,0,0]], 0, 1, 0, Cell),
    Cell = 0-3.

% sd_expand_once/5 tests

% One BFS step from (0,0) in a 1x3 row reveals (0,1).
test(expand_once_basic) :-
    sd_expand_once([[0,0,0]], [0-0], [0-0], 0, Next),
    Next = [0-1].

% One BFS step from a corner of a 2x2 grid reveals two neighbors.
test(expand_once_corner) :-
    sd_expand_once([[0,0],[0,0]], [0-0], [0-0], 0, Next),
    Next = [0-1, 1-0].

% A wall blocks expansion; empty frontier is returned.
test(expand_once_blocked) :-
    sd_expand_once([[0,1,0]], [0-0], [0-0], 0, Next),
    Next = [].

% sd_spread_color/5 tests

% Spread color 1 one step to the right into background cell (0,1).
test(spread_color_one_step) :-
    sd_spread_color([[1,0,0]], 1, 0, 1, Out),
    Out = [[1,1,0]].

% Spread color 1 two steps into a 1x4 row.
test(spread_color_two_steps) :-
    sd_spread_color([[1,0,0,0]], 1, 0, 2, Out),
    Out = [[1,1,1,0]].

% MaxD=0 means no spreading; grid is returned unchanged.
test(spread_color_zero_steps) :-
    sd_spread_color([[1,0,0]], 1, 0, 0, Out),
    Out = [[1,0,0]].

% sd_max_dist/5 tests

% Maximum BFS distance from (0,0) on a 1x3 row is 2.
test(max_dist_basic) :-
    sd_max_dist([[0,0,0]], 0, 0, 0, MaxD),
    MaxD = 2.

% Single isolated cell; maximum distance is 0.
test(max_dist_single) :-
    sd_max_dist([[0]], 0, 0, 0, MaxD),
    MaxD = 0.

% Maximum distance from (0,0) on a 1x4 row is 3.
test(max_dist_longer) :-
    sd_max_dist([[0,0,0,0]], 0, 0, 0, MaxD),
    MaxD = 3.

% sd_fill_dist/5 tests

% Fill a 1x3 row with distances from (0,0): 0, 1, 2.
test(fill_dist_basic) :-
    sd_fill_dist([[0,0,0]], 0, 0, 0, Out),
    Out = [[0,1,2]].

% An obstacle remains unchanged; the unreachable background cell also unchanged.
test(fill_dist_obstacle) :-
    sd_fill_dist([[0,0,1,0]], 0, 0, 0, Out),
    Out = [[0,1,1,0]].

% A single-cell grid is filled with distance 0.
test(fill_dist_single) :-
    sd_fill_dist([[0]], 0, 0, 0, Out),
    Out = [[0]].

% sd_voronoi/5 tests

% Two seeds at ends of a 1x3 row; middle cell (equidistant) goes to seed 1 (FIFO).
test(voronoi_two_seeds) :-
    sd_voronoi([[0,0,0]], [0-0, 0-2], 0, Assign),
    sort(Assign, S),
    S = [(0-0)-1, (0-1)-1, (0-2)-2].

% Single seed; every reachable cell belongs to seed 1.
test(voronoi_single_seed) :-
    sd_voronoi([[0,0]], [0-0], 0, Assign),
    sort(Assign, S),
    S = [(0-0)-1, (0-1)-1].

% Non-background seeds are filtered; only background seeds get indices.
test(voronoi_nonbg_filtered) :-
    sd_voronoi([[0,1,0]], [0-0, 0-1, 0-2], 0, Assign),
    sort(Assign, S),
    S = [(0-0)-1, (0-2)-2].

:- end_tests(spread).
