:- use_module('../prolog/griddist').
:- use_module(library(plunit)).

% Grid fixtures
% 3x3: background r, single b at center (1,1)
g3x3([[r,r,r],[r,b,r],[r,r,r]]).
% 5x5: background r, 3x3 b block occupying rows 1-3, cols 1-3
g5x5([[r,r,r,r,r],[r,b,b,b,r],[r,b,b,b,r],[r,b,b,b,r],[r,r,r,r,r]]).
% 3x3: b at all four corners, r elsewhere
g3x3_corners([[b,r,b],[r,r,r],[b,r,b]]).
% 3x3: all r (no b cells)
g3x3_uniform([[r,r,r],[r,r,r],[r,r,r]]).
% 3x3: b at (0,1) and (2,1), r elsewhere — top and bottom midpoints
g3x3_tb([[r,b,r],[r,r,r],[r,b,r]]).
% 3x3: two foreground colors; b at (1,0), g at (1,2), r background
g3x3_two([[r,r,r],[b,r,g],[r,r,r]]).
% 5x5: r background, single w (wall) at center (2,2)
g5x5_wall([[r,r,r,r,r],[r,r,r,r,r],[r,r,w,r,r],[r,r,r,r,r],[r,r,r,r,r]]).
% 2x2: r at (0,0) and (1,1); b at (0,1) and (1,0)
g2x2([[r,b],[b,r]]).
% 1x1: single b cell
g1x1([[b]]).
% 3x3: b at (0,0), g at (2,2), r elsewhere — opposite corners, two colors
g3x3_split([[b,r,r],[r,r,r],[r,r,g]]).

:- begin_tests(griddist).

% --- griddist_manhattan/5 ---

test(manhattan_same_cell) :-
% Distance from a cell to itself is 0.
    griddist_manhattan(0, 0, 0, 0, D),
    D =:= 0.

test(manhattan_adjacent_col) :-
% Adjacent cells in the same row have distance 1.
    griddist_manhattan(0, 0, 0, 1, D),
    D =:= 1.

test(manhattan_diagonal) :-
% Diagonal step has Manhattan distance 2 (not 1).
    griddist_manhattan(0, 0, 1, 1, D),
    D =:= 2.

test(manhattan_far) :-
% Large offset: |0-2| + |0-3| = 5.
    griddist_manhattan(0, 0, 2, 3, D),
    D =:= 5.

% --- griddist_chebyshev/5 ---

test(chebyshev_same_cell) :-
% Distance from a cell to itself is 0.
    griddist_chebyshev(0, 0, 0, 0, D),
    D =:= 0.

test(chebyshev_adjacent_col) :-
% Adjacent in same row: max(0,1) = 1.
    griddist_chebyshev(0, 0, 0, 1, D),
    D =:= 1.

test(chebyshev_diagonal) :-
% Diagonal step: max(1,1) = 1 (differs from Manhattan here).
    griddist_chebyshev(0, 0, 1, 1, D),
    D =:= 1.

test(chebyshev_far) :-
% max(|0-2|,|0-3|) = max(2,3) = 3.
    griddist_chebyshev(0, 0, 2, 3, D),
    D =:= 3.

% --- griddist_dist_map/3 ---

test(dist_map_center_zero) :-
% The b cell at center has distance 0 to itself.
    g3x3(G),
    griddist_dist_map(G, b, DMap),
    nth0(1, DMap, Row),
    nth0(1, Row, D),
    D =:= 0.

test(dist_map_corner_to_center) :-
% Corner (0,0) has Manhattan distance 2 to center b at (1,1).
    g3x3(G),
    griddist_dist_map(G, b, DMap),
    nth0(0, DMap, Row),
    nth0(0, Row, D),
    D =:= 2.

test(dist_map_no_color) :-
% When Color is absent all cells get distance 9999.
    g3x3_uniform(G),
    griddist_dist_map(G, b, DMap),
    DMap = [[9999,9999,9999],[9999,9999,9999],[9999,9999,9999]].

test(dist_map_5x5_center) :-
% Center (2,2) of g5x5 is itself b, so distance = 0.
    g5x5(G),
    griddist_dist_map(G, b, DMap),
    nth0(2, DMap, Row),
    nth0(2, Row, D),
    D =:= 0.

% --- griddist_dist_map8/3 ---

test(dist_map8_corner_chebyshev) :-
% Corner (0,0): Chebyshev distance to center b (1,1) = max(1,1) = 1.
    g3x3(G),
    griddist_dist_map8(G, b, DMap8),
    nth0(0, DMap8, Row),
    nth0(0, Row, D),
    D =:= 1.

test(dist_map8_no_color) :-
% Absent Color gives all 9999.
    g3x3_uniform(G),
    griddist_dist_map8(G, b, DMap8),
    DMap8 = [[9999,9999,9999],[9999,9999,9999],[9999,9999,9999]].

test(dist_map8_corners_grid) :-
% g3x3_corners: b at all four corners. Center (1,1) Chebyshev dist to nearest b = max(1,1) = 1.
    g3x3_corners(G),
    griddist_dist_map8(G, b, DMap8),
    nth0(1, DMap8, Row),
    nth0(1, Row, D),
    D =:= 1.

% --- griddist_nearest_coord/5 ---

test(nearest_coord_center) :-
% From (0,0) in g3x3, the nearest b is at center (1,1).
    g3x3(G),
    griddist_nearest_coord(G, 0, 0, b, Coord),
    Coord = [1, 1].

test(nearest_coord_corners) :-
% From (1,0) in g3x3_corners, nearest b is at (0,0) or (2,0); dist=1 each.
% msort on dist-R-C pairs gives (0,0) first.
    g3x3_corners(G),
    griddist_nearest_coord(G, 1, 0, b, Coord),
    Coord = [0, 0].

test(nearest_coord_no_color, [fail]) :-
% No b cells: predicate should fail.
    g3x3_uniform(G),
    griddist_nearest_coord(G, 0, 0, b, _).

% --- griddist_zone/4 ---

test(zone_n0_no_change) :-
% N=0: only Color cells themselves are at distance 0; non-Color cells untouched.
    g3x3(G),
    griddist_zone(G, b, 0, ZG),
    ZG = [[r,r,r],[r,b,r],[r,r,r]].

test(zone_n1_cross) :-
% N=1: r cells adjacent to center b become zone.
    g3x3(G),
    griddist_zone(G, b, 1, ZG),
    ZG = [[r,zone,r],[zone,b,zone],[r,zone,r]].

test(zone_n2_all) :-
% N=2: all r cells in g3x3 are within dist 2 of center b; all become zone.
    g3x3(G),
    griddist_zone(G, b, 2, ZG),
    ZG = [[zone,zone,zone],[zone,b,zone],[zone,zone,zone]].

test(zone_no_color_unchanged) :-
% No b cells: no cells are within any distance; grid unchanged.
    g3x3_uniform(G),
    griddist_zone(G, b, 1, ZG),
    ZG = [[r,r,r],[r,r,r],[r,r,r]].

% --- griddist_ring/5 ---

test(ring_d0_center) :-
% Ring at distance 0 is just the center cell itself.
    g3x3(G),
    griddist_ring(G, 1, 1, 0, Coords),
    Coords = [[1,1]].

test(ring_d1_cardinal) :-
% Ring at distance 1 from center in g3x3 = 4 cardinal neighbors.
    g3x3(G),
    griddist_ring(G, 1, 1, 1, Coords),
    length(Coords, 4),
    memberchk([0,1], Coords),
    memberchk([1,0], Coords),
    memberchk([1,2], Coords),
    memberchk([2,1], Coords).

test(ring_d2_corners) :-
% Ring at distance 2 from center = the 4 corners (in a 3x3).
    g3x3(G),
    griddist_ring(G, 1, 1, 2, Coords),
    length(Coords, 4),
    memberchk([0,0], Coords),
    memberchk([0,2], Coords),
    memberchk([2,0], Coords),
    memberchk([2,2], Coords).

test(ring_d1_corner_clipped) :-
% Ring at distance 1 from corner (0,0) clips to 2 in-bounds cells.
    g3x3(G),
    griddist_ring(G, 0, 0, 1, Coords),
    length(Coords, 2),
    memberchk([0,1], Coords),
    memberchk([1,0], Coords).

% --- griddist_voronoi/2 ---

test(voronoi_single_fg) :-
% Single b at center: all r background cells become b.
    g3x3(G),
    griddist_voronoi(G, VG),
    VG = [[b,b,b],[b,b,b],[b,b,b]].

test(voronoi_no_fg_unchanged) :-
% No foreground cells: grid is unchanged.
    g3x3_uniform(G),
    griddist_voronoi(G, VG),
    VG = [[r,r,r],[r,r,r],[r,r,r]].

test(voronoi_two_colors) :-
% g3x3_two: b at (1,0), g at (1,2). Equidistant cells get b (alphabetical tie-break).
    g3x3_two(G),
    griddist_voronoi(G, VG),
    VG = [[b,b,g],[b,b,g],[b,b,g]].

test(voronoi_2x2) :-
% 2x2: r at (0,0),(1,1); b at (0,1),(1,0). Counts tie (2 each).
% Alphabetical tie-break: b < r in standard order, so b is background.
% r cells at (0,0),(1,1) become foreground; b cells get assigned nearest r.
    g2x2(G),
    griddist_voronoi(G, VG),
    VG = [[r,r],[r,r]].

% --- griddist_bfs_flood/5 ---

test(bfs_flood_no_walls_corner) :-
% BFS from (0,0) with no walls in 3x3; (1,1) should be at distance 2.
    g3x3(G),
    griddist_bfs_flood(G, 0, 0, x, DistGrid),
    nth0(1, DistGrid, Row),
    nth0(1, Row, D),
    D =:= 2.

test(bfs_flood_no_walls_origin) :-
% BFS origin (0,0) always has distance 0.
    g3x3(G),
    griddist_bfs_flood(G, 0, 0, x, DistGrid),
    nth0(0, DistGrid, Row),
    nth0(0, Row, D),
    D =:= 0.

test(bfs_flood_with_wall_blocked) :-
% BFS from (0,0) treating b as wall in g3x3: b at (1,1) gets dist 9999.
    g3x3(G),
    griddist_bfs_flood(G, 0, 0, b, DistGrid),
    nth0(1, DistGrid, Row),
    nth0(1, Row, D),
    D =:= 9999.

test(bfs_flood_with_wall_detour) :-
% Path to (1,2) must detour around b at (1,1): (0,0)->(0,1)->(0,2)->(1,2) = 3 steps.
    g3x3(G),
    griddist_bfs_flood(G, 0, 0, b, DistGrid),
    nth0(1, DistGrid, Row),
    nth0(2, Row, D),
    D =:= 3.

test(bfs_flood_start_wall_fails, [fail]) :-
% Starting at a wall cell should fail.
    g3x3(G),
    griddist_bfs_flood(G, 1, 1, b, _).

% --- griddist_recolor_by_dist/4 ---

test(recolor_single_cell) :-
% g3x3: b at (1,1) has dist 1 from nearest r. Palette=[yellow] -> becomes yellow.
    g3x3(G),
    griddist_recolor_by_dist(G, b, [yellow], NewG),
    nth0(1, NewG, Row),
    nth0(1, Row, V),
    V = yellow.

test(recolor_no_color_unchanged) :-
% No b cells: NewGrid = Grid.
    g3x3_uniform(G),
    griddist_recolor_by_dist(G, b, [red], NewG),
    NewG = [[r,r,r],[r,r,r],[r,r,r]].

test(recolor_5x5_border_vs_center) :-
% g5x5: border b cells at dist 1 -> red; center b at (2,2) at dist 2 -> blue.
    g5x5(G),
    griddist_recolor_by_dist(G, b, [red, blue], NewG),
    nth0(2, NewG, Row),
    nth0(2, Row, Center),
    Center = blue,
    nth0(1, NewG, Row1),
    nth0(1, Row1, Border),
    Border = red.

test(recolor_beyond_palette) :-
% g5x5: Palette=[red] (length 1); center b at dist 2 > 1 -> keeps b.
    g5x5(G),
    griddist_recolor_by_dist(G, b, [red], NewG),
    nth0(2, NewG, Row),
    nth0(2, Row, V),
    V = b.

% --- griddist_expand_n/4 ---

test(expand_n0_unchanged) :-
% N=0: grid is unchanged.
    g3x3(G),
    griddist_expand_n(G, b, 0, E),
    E = [[r,r,r],[r,b,r],[r,r,r]].

test(expand_n1_cross) :-
% N=1: expand center b by 1 step gives a cross pattern.
    g3x3(G),
    griddist_expand_n(G, b, 1, E),
    E = [[r,b,r],[b,b,b],[r,b,r]].

test(expand_n2_all) :-
% N=2: all cells within dist 2 of center b become b -> entire 3x3 grid.
    g3x3(G),
    griddist_expand_n(G, b, 2, E),
    E = [[b,b,b],[b,b,b],[b,b,b]].

test(expand_no_color_unchanged) :-
% No b cells: dist_map all 9999 -> nothing within N -> unchanged.
    g3x3_uniform(G),
    griddist_expand_n(G, b, 2, E),
    E = [[r,r,r],[r,r,r],[r,r,r]].

% --- griddist_shrink_n/4 ---

test(shrink_n0_unchanged) :-
% N=0: grid is unchanged.
    g3x3(G),
    griddist_shrink_n(G, b, 0, S),
    S = [[r,r,r],[r,b,r],[r,r,r]].

test(shrink_n1_removes_single_b) :-
% g3x3: b at (1,1) has dist 1 from r. Shrinking by 1 removes it.
    g3x3(G),
    griddist_shrink_n(G, b, 1, S),
    S = [[r,r,r],[r,r,r],[r,r,r]].

test(shrink_n1_5x5_leaves_center) :-
% g5x5: border b cells at dist 1 eroded; center b at dist 2 survives.
    g5x5(G),
    griddist_shrink_n(G, b, 1, S),
    nth0(2, S, Row),
    nth0(2, Row, V),
    V = b,
    nth0(1, S, Row1),
    nth0(1, Row1, V2),
    V2 = r.

test(shrink_n2_5x5_removes_all) :-
% N=2: center b at dist 2 is also eroded; all b become r.
    g5x5(G),
    griddist_shrink_n(G, b, 2, S),
    S = [[r,r,r,r,r],[r,r,r,r,r],[r,r,r,r,r],[r,r,r,r,r],[r,r,r,r,r]].

% --- griddist_equidistant/4 ---

test(equidistant_split_grid) :-
% g3x3_split: b at (0,0), g at (2,2). Cells on the main diagonal midpoint are equidist.
% (1,1): dist to b = 2, dist to g = 2 -> equidist.
    g3x3_split(G),
    griddist_equidistant(G, b, g, EqG),
    nth0(1, EqG, Row),
    nth0(1, Row, V),
    V = equidist.

test(equidistant_two_colors_asymmetric) :-
% g3x3_two: b at (1,0), g at (1,2). (0,2) is at dist 3 from b and 1 from g -> not equidist.
    g3x3_two(G),
    griddist_equidistant(G, b, g, EqG),
    nth0(0, EqG, Row),
    nth0(2, Row, V),
    V = r.

test(equidistant_same_color_all) :-
% ColorA = ColorB = b: every cell is equidistant (same map for both) -> all equidist.
    g3x3(G),
    griddist_equidistant(G, b, b, EqG),
    EqG = [[equidist,equidist,equidist],
            [equidist,equidist,equidist],
            [equidist,equidist,equidist]].

% --- griddist_max_dist/4 ---

test(max_dist_single_b_corner) :-
% g3x3: b at center (1,1). Farthest cell is a corner at dist 2. First in row-major = (0,0).
    g3x3(G),
    griddist_max_dist(G, b, R, C),
    R =:= 0,
    C =:= 0.

test(max_dist_corners_grid) :-
% g3x3_corners: b at all 4 corners. Center (1,1) is at dist 2 from each -> farthest.
    g3x3_corners(G),
    griddist_max_dist(G, b, R, C),
    R =:= 1,
    C =:= 1.

test(max_dist_no_color_fails, [fail]) :-
% No b cells: no finite distances -> predicate fails.
    g3x3_uniform(G),
    griddist_max_dist(G, b, _, _).

:- end_tests(griddist).
