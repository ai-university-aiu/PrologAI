:- use_module('../prolog/grid_path').

% Grid fixtures.
% g3x3_open: 3x3 all passable (color p = passable, no walls).
g3x3_open([[p,p,p],[p,p,p],[p,p,p]]).
% g3x3_wall_mid: 3x3 with wall (w) column splitting left and right.
g3x3_wall_mid([[p,w,p],[p,w,p],[p,w,p]]).
% g4x4_maze: maze with inner walls.
g4x4_maze([[p,p,p,p],[p,w,w,p],[p,w,p,p],[p,p,p,p]]).
% g3x3_blocked: start and target on same side but route blocked.
g3x3_blocked([[p,w,p],[w,w,w],[p,w,p]]).
% g1x1: single cell.
g1x1([[p]]).
% g5x1: horizontal strip.
g5x1([[a,a,a,a,a]]).
% g1x5: vertical strip.
g1x5([[a],[a],[a],[a],[a]]).
% g4x4_two_colors: Color1=r top-left, Color2=b bottom-right, wall w in middle.
g4x4_two_colors([[r,p,p,p],[p,p,p,p],[p,p,p,p],[p,p,p,b]]).
% g3x5_los: grid for line-of-sight tests.
g3x5_los([[p,p,p,p,p],[p,w,w,p,p],[p,p,p,p,p]]).
% g4x4_dist: open grid for distance map test.
g4x4_dist([[p,p,p,p],[p,p,p,p],[p,p,p,p],[p,p,p,p]]).

:- begin_tests(grid_path).

% --- grid_path_shortest_path tests ---

% Same start and end: path = [R-C].
test(path_same_cell) :-
    g3x3_open(G),
    grid_path_shortest_path(G, 1, 1, 1, 1, w, Path),
    Path = [1-1].

% Adjacent cells: path length 2.
test(path_adjacent) :-
    g3x3_open(G),
    grid_path_shortest_path(G, 0, 0, 0, 1, w, Path),
    Path = [0-0, 0-1].

% Corner to corner in 3x3 open grid: shortest path is 4 cells (2 moves right + 2 down).
test(path_corner_to_corner) :-
    g3x3_open(G),
    grid_path_shortest_path(G, 0, 0, 2, 2, w, Path),
    length(Path, 5).

% Blocked: wall separates left and right, no path.
test(path_blocked_fails, [fail]) :-
    g3x3_wall_mid(G),
    grid_path_shortest_path(G, 0, 0, 0, 2, w, _).

% Path in maze: must go around inner walls.
test(path_maze) :-
    g4x4_maze(G),
    grid_path_shortest_path(G, 0, 0, 2, 2, w, Path),
    Path = [0-0|_],
    last(Path, 2-2).

% Start cell is obstacle: fails.
test(path_start_obstacle_fails, [fail]) :-
    g3x3_wall_mid(G),
    grid_path_shortest_path(G, 0, 1, 0, 2, w, _).

% End cell is obstacle: fails.
test(path_end_obstacle_fails, [fail]) :-
    g3x3_wall_mid(G),
    grid_path_shortest_path(G, 0, 0, 0, 1, w, _).

% 1x1 grid, same start and end.
test(path_1x1) :-
    g1x1(G),
    grid_path_shortest_path(G, 0, 0, 0, 0, w, Path),
    Path = [0-0].

% --- grid_path_path_length tests ---

% Adjacent: length 1.
test(path_length_adjacent) :-
    g3x3_open(G),
    grid_path_path_length(G, 0, 0, 0, 1, w, N),
    N = 1.

% Same cell: length 0.
test(path_length_same) :-
    g3x3_open(G),
    grid_path_path_length(G, 1, 1, 1, 1, w, N),
    N = 0.

% Corner to corner 3x3: Manhattan distance 4.
test(path_length_corner) :-
    g3x3_open(G),
    grid_path_path_length(G, 0, 0, 2, 2, w, N),
    N = 4.

% Blocked: fails.
test(path_length_blocked_fails, [fail]) :-
    g3x3_wall_mid(G),
    grid_path_path_length(G, 0, 0, 0, 2, w, _).

% --- grid_path_reachable tests ---

% Open grid: corner to corner reachable.
test(reachable_open) :-
    g3x3_open(G),
    grid_path_reachable(G, 0, 0, 2, 2, w).

% Wall separating: not reachable.
test(reachable_blocked_fails, [fail]) :-
    g3x3_wall_mid(G),
    grid_path_reachable(G, 0, 0, 0, 2, w).

% Same cell: reachable.
test(reachable_same_cell) :-
    g3x3_open(G),
    grid_path_reachable(G, 1, 1, 1, 1, w).

% --- grid_path_all_reachable tests ---

% 3x3 open: all 9 cells reachable from center.
test(all_reachable_open) :-
    g3x3_open(G),
    grid_path_all_reachable(G, 1, 1, w, Cells),
    length(Cells, 9).

% 3x3 wall-mid: left side only from (0,0): cells in column 0.
test(all_reachable_wall_mid) :-
    g3x3_wall_mid(G),
    grid_path_all_reachable(G, 0, 0, w, Cells),
    length(Cells, 3).

% 1x1 grid: only one cell reachable.
test(all_reachable_1x1) :-
    g1x1(G),
    grid_path_all_reachable(G, 0, 0, w, Cells),
    Cells = [0-0].

% Seed is obstacle: fails.
test(all_reachable_obstacle_seed_fails, [fail]) :-
    g3x3_wall_mid(G),
    grid_path_all_reachable(G, 0, 1, w, _).

% --- grid_path_distance_map tests ---

% 1x1 grid: map has one entry (0,0)=0.
test(distance_map_1x1) :-
    g1x1(G),
    grid_path_distance_map(G, 0, 0, w, Map),
    Map = [0-0-0].

% 4x4 open from (0,0): distance to (3,3) = 6.
test(distance_map_corner) :-
    g4x4_dist(G),
    grid_path_distance_map(G, 0, 0, w, Map),
    memberchk(3-3-6, Map).

% 4x4 open from (0,0): all 16 cells in map.
test(distance_map_all_cells) :-
    g4x4_dist(G),
    grid_path_distance_map(G, 0, 0, w, Map),
    length(Map, 16).

% Wall-mid: map from (0,0) has 3 entries (left column only).
test(distance_map_wall_mid) :-
    g3x3_wall_mid(G),
    grid_path_distance_map(G, 0, 0, w, Map),
    length(Map, 3).

% --- grid_path_nearest tests ---

% g4x4_two_colors: nearest r to (3,3) from b cell path (no obstacle).
test(nearest_r_from_corner) :-
    g4x4_two_colors(G),
    grid_path_nearest(G, 3, 3, r, w, 0-0).

% Nearest b from (0,0) in two-colors grid.
test(nearest_b_from_topleft) :-
    g4x4_two_colors(G),
    grid_path_nearest(G, 0, 0, b, w, 3-3).

% No target color reachable: fails.
test(nearest_absent_fails, [fail]) :-
    g3x3_wall_mid(G),
    grid_path_nearest(G, 0, 0, b, w, _).

% --- grid_path_flood_n tests ---

% Flood 0 steps from center: only the center cell.
test(flood_n_zero) :-
    g3x3_open(G),
    grid_path_flood_n(G, 1, 1, 0, w, Cells),
    Cells = [1-1].

% Flood 1 step from center of 3x3: center + 4 neighbors = 5 cells.
test(flood_n_one) :-
    g3x3_open(G),
    grid_path_flood_n(G, 1, 1, 1, w, Cells),
    length(Cells, 5).

% Flood 2 steps from center of 3x3: all 9 cells.
test(flood_n_two_all) :-
    g3x3_open(G),
    grid_path_flood_n(G, 1, 1, 2, w, Cells),
    length(Cells, 9).

% Flood across wall: only left side reachable.
test(flood_n_wall) :-
    g3x3_wall_mid(G),
    grid_path_flood_n(G, 0, 0, 10, w, Cells),
    length(Cells, 3).

% --- grid_path_wavefront tests ---

% Wavefront 0 from center: just center.
test(wavefront_zero) :-
    g3x3_open(G),
    grid_path_wavefront(G, 1, 1, 0, w, Cells),
    Cells = [1-1].

% Wavefront 1 from center: 4 direct neighbors.
test(wavefront_one) :-
    g3x3_open(G),
    grid_path_wavefront(G, 1, 1, 1, w, Cells),
    length(Cells, 4).

% Wavefront 2 from center of 3x3: 4 corners.
test(wavefront_two) :-
    g3x3_open(G),
    grid_path_wavefront(G, 1, 1, 2, w, Cells),
    length(Cells, 4).

% Wavefront beyond grid: empty.
test(wavefront_out_of_range) :-
    g3x3_open(G),
    grid_path_wavefront(G, 1, 1, 10, w, Cells),
    Cells = [].

% --- grid_path_straight_h tests ---

% Single cell (C1 = C2).
test(straight_h_single) :-
    grid_path_straight_h(2, 3, 3, Cells),
    Cells = [2-3].

% Left to right.
test(straight_h_ltr) :-
    grid_path_straight_h(0, 0, 4, Cells),
    Cells = [0-0, 0-1, 0-2, 0-3, 0-4].

% Right to left.
test(straight_h_rtl) :-
    grid_path_straight_h(1, 3, 1, Cells),
    Cells = [1-3, 1-2, 1-1].

% --- grid_path_straight_v tests ---

% Single cell.
test(straight_v_single) :-
    grid_path_straight_v(2, 1, 1, Cells),
    Cells = [1-2].

% Top to bottom.
test(straight_v_ttb) :-
    grid_path_straight_v(0, 0, 3, Cells),
    Cells = [0-0, 1-0, 2-0, 3-0].

% Bottom to top.
test(straight_v_btt) :-
    grid_path_straight_v(1, 4, 2, Cells),
    Cells = [4-1, 3-1, 2-1].

% --- grid_path_line_of_sight tests ---

% Same row, no obstacle between: line of sight.
test(los_same_row_clear) :-
    g3x5_los(G),
    grid_path_line_of_sight(G, 0, 0, 0, 4, w).

% Same row, wall between: no line of sight.
test(los_same_row_blocked, [fail]) :-
    g3x5_los(G),
    grid_path_line_of_sight(G, 1, 0, 1, 4, w).

% Same column, clear.
test(los_same_col_clear) :-
    g3x5_los(G),
    grid_path_line_of_sight(G, 0, 0, 2, 0, w).

% Same column, wall between (col 1, rows 0-2: row 1 has w at col 1).
test(los_same_col_blocked, [fail]) :-
    g3x5_los(G),
    grid_path_line_of_sight(G, 0, 1, 2, 1, w).

% Different row and column: fails (diagonal).
test(los_diagonal_fails, [fail]) :-
    g3x5_los(G),
    grid_path_line_of_sight(G, 0, 0, 1, 1, w).

% Adjacent same-row cells: always clear (no cells between).
test(los_adjacent_cells) :-
    g3x5_los(G),
    grid_path_line_of_sight(G, 0, 0, 0, 1, w).

% --- grid_path_between_h tests ---

% Adjacent: no cells between.
test(between_h_adjacent) :-
    grid_path_between_h(0, 0, 1, Cells),
    Cells = [].

% Three cells: one between.
test(between_h_one) :-
    grid_path_between_h(0, 0, 2, Cells),
    Cells = [0-1].

% Five-cell range: three between.
test(between_h_three) :-
    grid_path_between_h(1, 0, 4, Cells),
    Cells = [1-1, 1-2, 1-3].

% C2 < C1: same result (ascending order).
test(between_h_reversed) :-
    grid_path_between_h(0, 4, 0, Cells),
    Cells = [0-1, 0-2, 0-3].

% --- grid_path_between_v tests ---

% Adjacent: no cells between.
test(between_v_adjacent) :-
    grid_path_between_v(0, 1, 2, Cells),
    Cells = [].

% One between.
test(between_v_one) :-
    grid_path_between_v(0, 2, 1, Cells),
    Cells = [1-1].

% Three between.
test(between_v_three) :-
    grid_path_between_v(0, 4, 2, Cells),
    Cells = [1-2, 2-2, 3-2].

% --- grid_path_region_path tests ---

% r at (0,0), b at (3,3) in open 4x4: path exists.
test(region_path_exists) :-
    g4x4_two_colors(G),
    grid_path_region_path(G, r, b, w, Path),
    Path = [0-0|_],
    last(Path, 3-3).

% r at (0,0), b at (3,3): shortest path length = 6.
test(region_path_length) :-
    g4x4_two_colors(G),
    grid_path_region_path(G, r, b, w, Path),
    length(Path, 7).

% Same color for Color1 and Color2: degenerate case - r to r, path length 0.
test(region_path_same_color) :-
    g4x4_two_colors(G),
    grid_path_region_path(G, r, r, w, Path),
    Path = [0-0].

% No Color1 present: fails.
test(region_path_no_color1_fails, [fail]) :-
    g3x3_open(G),
    grid_path_region_path(G, z, q, w, _).

:- end_tests(grid_path).

:- run_tests(gridpath).
