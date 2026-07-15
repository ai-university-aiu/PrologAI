:- use_module('../prolog/voronoi').
:- begin_tests(voronoi).

% Helper grids.
% g1: 3x3, Bg=0; colors 1 at (0,0), 2 at (2,2), background elsewhere.
% [[1,0,0],[0,0,0],[0,0,2]]
g1([[1,0,0],[0,0,0],[0,0,2]]).

% g2: 1x5, Bg=0; color a at (0,0), color b at (0,4).
% [[a,0,0,0,b]]
g2([[a,0,0,0,b]]).

% g3: 3x3 all background.
g3([[0,0,0],[0,0,0],[0,0,0]]).

% g4: 3x3 no background (all color 1).
g4([[1,1,1],[1,1,1],[1,1,1]]).

% g5: single cell, Bg=0; color red at (0,0).
g5([[red]]).

% g6: 3x3, Bg=0; color 1 at (1,1) only.
g6([[0,0,0],[0,1,0],[0,0,0]]).

% g7: 2x4, Bg=0; color a at (0,0), color b at (0,3).
% [[a,0,0,b],[0,0,0,0]]
g7([[a,0,0,b],[0,0,0,0]]).

% voronoi_non_bg_cells tests.

test(non_bg_cells_g1) :-
    g1(G), voronoi_non_bg_cells(G, 0, Cells),
    Cells == [r(0,0), r(2,2)].

test(non_bg_cells_g4_all) :-
    g4(G), voronoi_non_bg_cells(G, 0, Cells),
    length(Cells, 9).

test(non_bg_cells_g3_empty) :-
    g3(G), voronoi_non_bg_cells(G, 0, Cells),
    Cells == [].

test(non_bg_cells_g5) :-
    g5(G), voronoi_non_bg_cells(G, 0, Cells),
    Cells == [r(0,0)].

% voronoi_non_bg_colors tests.

test(non_bg_colors_g1) :-
    g1(G), voronoi_non_bg_colors(G, 0, Colors),
    Colors == [1, 2].

test(non_bg_colors_g2) :-
    g2(G), voronoi_non_bg_colors(G, 0, Colors),
    Colors == [a, b].

test(non_bg_colors_g3_empty) :-
    g3(G), voronoi_non_bg_colors(G, 0, Colors),
    Colors == [].

test(non_bg_colors_g4_one) :-
    g4(G), voronoi_non_bg_colors(G, 0, Colors),
    Colors == [1].

% voronoi_nearest_dist tests.

test(nearest_dist_g1_00) :-
    % r(0,0) is color 1, but we query nearest non-Bg from r(0,0); Bg=0.
    % r(0,0) itself is non-Bg (value 1) so dist to r(0,0) = 0.
    g1(G), voronoi_nearest_dist(G, 0, 0, 0, D), D == 0.

test(nearest_dist_g1_11) :-
    % r(1,1) is Bg; nearest non-Bg cells are r(0,0) and r(2,2).
    % Distance to r(0,0) = |1-0|+|1-0| = 2. To r(2,2) = |1-2|+|1-2| = 2.
    g1(G), voronoi_nearest_dist(G, 0, 1, 1, D), D == 2.

test(nearest_dist_g1_01) :-
    % r(0,1): to r(0,0)=1, to r(2,2)=|0-2|+|1-2|=3. Min=1.
    g1(G), voronoi_nearest_dist(G, 0, 0, 1, D), D == 1.

test(nearest_dist_g6_corners) :-
    % g6: color 1 at r(1,1). Corner r(0,0): dist = 1+1 = 2.
    g6(G), voronoi_nearest_dist(G, 0, 0, 0, D), D == 2.

% voronoi_nearest_color tests.

test(nearest_color_g2_center) :-
    % g2 = [[a,0,0,0,b]]. r(0,2): dist to a=2, dist to b=2 -> tie.
    % sort([2-a, 2-b], [2-a, 2-b]) -> Color = a (a < b in standard order).
    g2(G), voronoi_nearest_color(G, 0, 0, 2, Color),
    memberchk(Color, [a, b]).

test(nearest_color_g2_col1) :-
    % r(0,1): dist to a=1, dist to b=3 -> nearest is a.
    g2(G), voronoi_nearest_color(G, 0, 0, 1, Color), Color == a.

test(nearest_color_g2_col3) :-
    % r(0,3): dist to a=3, dist to b=1 -> nearest is b.
    g2(G), voronoi_nearest_color(G, 0, 0, 3, Color), Color == b.

test(nearest_color_g1_01) :-
    % r(0,1): dist to 1=1, dist to 2=|0-2|+|1-2|=3. Nearest = 1.
    g1(G), voronoi_nearest_color(G, 0, 0, 1, Color), Color == 1.

test(nearest_color_g1_21) :-
    % r(2,1): dist to 1=|2-0|+|1-0|=3, dist to 2=|2-2|+|1-2|=1. Nearest = 2.
    g1(G), voronoi_nearest_color(G, 0, 2, 1, Color), Color == 2.

% voronoi_paint_bg tests.

test(paint_bg_g6) :-
    % g6: 3x3, only r(1,1)=1. All Bg cells get color 1.
    g6(G), voronoi_paint_bg(G, 0, P),
    P == [[1,1,1],[1,1,1],[1,1,1]].

test(paint_bg_noop_g4) :-
    % g4: no Bg cells. Painted = Grid.
    g4(G), voronoi_paint_bg(G, 0, P),
    P == [[1,1,1],[1,1,1],[1,1,1]].

test(paint_bg_g5) :-
    % g5: [[red]]. No Bg cells. Painted = [[red]].
    g5(G), voronoi_paint_bg(G, 0, P),
    P == [[red]].

test(paint_bg_g2_splits) :-
    % g2 = [[a,0,0,0,b]]. Col 1->a, col 2->a or b (tie), col 3->b.
    % Center tie: sort([2-a,2-b]) = [2-a,2-b] -> a wins.
    g2(G), voronoi_paint_bg(G, 0, [[P0,P1,P2,P3,P4]]),
    P0 == a, P4 == b, P1 == a, P3 == b,
    memberchk(P2, [a, b]).

% voronoi_dist_map tests.

test(dist_map_g6) :-
    % g6: 3x3, only r(1,1)=1. Distance from r(R,C) to r(1,1) = |R-1|+|C-1|.
    % Row 0: [2,1,2], Row 1: [1,0,1], Row 2: [2,1,2].
    g6(G), voronoi_dist_map(G, 0, D),
    D == [[2,1,2],[1,0,1],[2,1,2]].

test(dist_map_g5) :-
    % Single non-Bg cell at (0,0). Distance = 0.
    g5(G), voronoi_dist_map(G, 0, D),
    D == [[0]].

test(dist_map_g4_all_zero) :-
    % No Bg cells. All distances = 0.
    g4(G), voronoi_dist_map(G, 0, D),
    D == [[0,0,0],[0,0,0],[0,0,0]].

% voronoi_region_cells tests.

test(region_cells_g2_a) :-
    % g2: color a is at col 0. Region of a = Bg cells nearer to a.
    g2(G), voronoi_region_cells(G, 0, a, Cells),
    % Col 1: dist to a=1, dist to b=3 -> a. Col 2: tied but a wins.
    memberchk(r(0,1), Cells).

test(region_cells_g2_b) :-
    g2(G), voronoi_region_cells(G, 0, b, Cells),
    memberchk(r(0,3), Cells).

test(region_cells_g6_all_to_1) :-
    % g6: only color 1. All 8 Bg cells are in region 1.
    g6(G), voronoi_region_cells(G, 0, 1, Cells),
    length(Cells, 8).

% voronoi_regions tests.

test(regions_g2_two_colors) :-
    g2(G), voronoi_regions(G, 0, Pairs),
    length(Pairs, 2).

test(regions_g6_one_color) :-
    g6(G), voronoi_regions(G, 0, Pairs),
    Pairs = [1-Cells],
    length(Cells, 8).

test(regions_g4_no_bg) :-
    % No Bg cells: each region is empty.
    g4(G), voronoi_regions(G, 0, Pairs),
    Pairs == [1-[]].

% voronoi_max_dist tests.

test(max_dist_g6) :-
    % Corners are farthest: dist = 2 (e.g. r(0,0) to r(1,1): 1+1=2).
    g6(G), voronoi_max_dist(G, 0, MaxD),
    MaxD == 2.

test(max_dist_g2) :-
    % g2 = [[a,0,0,0,b]]. Max Bg cell dist: center r(0,2) to a=2, to b=2. Max=2.
    g2(G), voronoi_max_dist(G, 0, MaxD),
    MaxD == 2.

% voronoi_at_dist tests.

test(at_dist_g6_d1) :-
    % Bg cells at dist 1 from r(1,1): r(0,1),r(1,0),r(1,2),r(2,1).
    g6(G), voronoi_at_dist(G, 0, 1, Cells),
    length(Cells, 4).

test(at_dist_g6_d2) :-
    % Bg cells at dist 2 from r(1,1): corners r(0,0),r(0,2),r(2,0),r(2,2).
    g6(G), voronoi_at_dist(G, 0, 2, Cells),
    length(Cells, 4).

test(at_dist_g6_d0_empty) :-
    % No Bg cells at dist 0 (r(1,1) is not Bg).
    g6(G), voronoi_at_dist(G, 0, 0, Cells),
    Cells == [].

% voronoi_within_dist tests.

test(within_dist_g6_d1) :-
    % Bg cells within dist 1: 4 cells.
    g6(G), voronoi_within_dist(G, 0, 1, Cells),
    length(Cells, 4).

test(within_dist_g6_d2) :-
    % Bg cells within dist 2: all 8 Bg cells.
    g6(G), voronoi_within_dist(G, 0, 2, Cells),
    length(Cells, 8).

test(within_dist_g6_d0_empty) :-
    % No Bg cells at dist 0 (they all have dist >= 1).
    g6(G), voronoi_within_dist(G, 0, 0, Cells),
    Cells == [].

% voronoi_medial tests.

test(medial_g2) :-
    % g2 = [[a,0,0,0,b]]. Center col 2 is equidistant (dist 2) from both a and b.
    g2(G), voronoi_medial(G, 0, Cells),
    memberchk(r(0,2), Cells).

test(medial_g6_empty) :-
    % g6 has only one color. No medial cells.
    g6(G), voronoi_medial(G, 0, Cells),
    Cells == [].

test(medial_g1_center) :-
    % g1: colors 1 at (0,0), 2 at (2,2). Center (1,1): dist to 1 = 2, to 2 = 2. Medial.
    g1(G), voronoi_medial(G, 0, Cells),
    memberchk(r(1,1), Cells).

% voronoi_expand1 tests.

test(expand1_g6) :-
    % g6: color 1 at (1,1). 4-neighbors in Bg: r(0,1),r(1,0),r(1,2),r(2,1).
    g6(G), voronoi_expand1(G, 0, 1, Cells),
    sort(Cells, S),
    S == [r(0,1),r(1,0),r(1,2),r(2,1)].

test(expand1_g2_a) :-
    % g2 = [[a,0,0,0,b]]. Color a at (0,0). 4-neighbor in Bg: r(0,1).
    g2(G), voronoi_expand1(G, 0, a, Cells),
    Cells == [r(0,1)].

test(expand1_g4_no_bg) :-
    % g4: no Bg cells. Expansion is empty.
    g4(G), voronoi_expand1(G, 0, 1, Cells),
    Cells == [].

% voronoi_expand_n tests.

test(expand_n_0) :-
    % N=0: no expansion.
    g6(G), voronoi_expand_n(G, 0, 1, 0, Cells),
    Cells == [].

test(expand_n_1_g6) :-
    % N=1: same as expand1.
    g6(G), voronoi_expand_n(G, 0, 1, 1, Cells),
    voronoi_expand1(G, 0, 1, E1),
    Cells == E1.

test(expand_n_2_g6) :-
    % N=2: within 2 Manhattan steps of r(1,1) in Bg = all 8 Bg cells.
    g6(G), voronoi_expand_n(G, 0, 1, 2, Cells),
    length(Cells, 8).

test(expand_n_1_g2) :-
    % g2 = [[a,0,0,0,b]]. N=1 from a: only r(0,1).
    g2(G), voronoi_expand_n(G, 0, a, 1, Cells),
    Cells == [r(0,1)].

test(expand_n_2_g2) :-
    % N=2 from a: r(0,1) and r(0,2) (both within dist 2 of col 0).
    g2(G), voronoi_expand_n(G, 0, a, 2, Cells),
    sort(Cells, S),
    S == [r(0,1),r(0,2)].

:- end_tests(voronoi).
