:- use_module('../prolog/gridflood').

% Grid fixtures used across tests.
% g3x3_r: 3x3 all-red.
g3x3_r([[r,r,r],[r,r,r],[r,r,r]]).
% g3x3_rb: 3x3 top-left 2x2 red, rest blue.
g3x3_rb([[r,r,b],[r,r,b],[b,b,b]]).
% g3x3_check: checkerboard r/b.
g3x3_check([[r,b,r],[b,r,b],[r,b,r]]).
% g3x3_diag: diagonal blue on red (8-connected but not 4-connected blue chain).
g3x3_diag([[b,r,r],[r,b,r],[r,r,b]]).
% g4x4_ring: ring of r with b inside (enclosed).
g4x4_ring([[r,r,r,r],[r,b,b,r],[r,b,b,r],[r,r,r,r]]).
% g4x4_open: b region open to left border.
g4x4_open([[r,r,r,r],[b,b,b,r],[r,b,r,r],[r,r,r,r]]).
% g3x3_two_regions: two separate r regions separated by b.
g3x3_two_regions([[r,b,r],[b,b,b],[r,b,r]]).
% g1x1_r: single red cell.
g1x1_r([[r]]).
% g2x2_r: 2x2 all red.
g2x2_r([[r,r],[r,r]]).
% g3x3_multi: three colors.
g3x3_multi([[r,g,r],[g,b,g],[r,g,r]]).
% g5x5_hole: 5x5 red frame with 3x3 blue interior, 1x1 red center (hole within hole structure).
g5x5_hole([[r,r,r,r,r],
           [r,b,b,b,r],
           [r,b,r,b,r],
           [r,b,b,b,r],
           [r,r,r,r,r]]).

:- begin_tests(gridflood).

% --- gridflood_fill tests ---

% Fill a 3x3 all-red grid; already same color so no change.
test(fill_same_color) :-
    g3x3_r(G),
    gridflood_fill(G, 0, 0, r, R),
    R = G.

% Fill top-left r region of g3x3_rb to g (should only fill the 4-connected r block).
test(fill_connected_region) :-
    g3x3_rb(G),
    gridflood_fill(G, 0, 0, g, R),
    R = [[g,g,b],[g,g,b],[b,b,b]].

% Fill b region in g3x3_rb from (0,2) to g.
test(fill_single_cell_region) :-
    g3x3_rb(G),
    gridflood_fill(G, 0, 2, g, R),
    R = [[r,r,g],[r,r,g],[g,g,g]].

% Fill a 1x1 grid.
test(fill_1x1) :-
    g1x1_r(G),
    gridflood_fill(G, 0, 0, b, R),
    R = [[b]].

% Fill one r island in checkerboard (should fill only that one cell).
test(fill_checkerboard_island) :-
    g3x3_check(G),
    gridflood_fill(G, 0, 0, g, R),
    R = [[g,b,r],[b,r,b],[r,b,r]].

% --- gridflood_fill8 tests ---

% 8-connected fill on diagonal: all three diagonal b cells become g.
test(fill8_diagonal_connected) :-
    g3x3_diag(G),
    gridflood_fill8(G, 0, 0, g, R),
    R = [[g,r,r],[r,g,r],[r,r,g]].

% 8-connected fill in 2x2: all same color, fill all.
test(fill8_2x2) :-
    g2x2_r(G),
    gridflood_fill8(G, 0, 0, b, R),
    R = [[b,b],[b,b]].

% 8-connected same-color no-op.
test(fill8_same_color_noop) :-
    g3x3_r(G),
    gridflood_fill8(G, 1, 1, r, R),
    R = G.

% --- gridflood_recolor tests ---

% Global recolor r -> g in 3x3 rb grid.
test(recolor_changes_all) :-
    g3x3_rb(G),
    gridflood_recolor(G, r, g, R),
    R = [[g,g,b],[g,g,b],[b,b,b]].

% Recolor a color not present: grid unchanged.
test(recolor_absent_color) :-
    g3x3_r(G),
    gridflood_recolor(G, b, g, R),
    R = G.

% Recolor to same color: grid unchanged.
test(recolor_to_same) :-
    g3x3_rb(G),
    gridflood_recolor(G, r, r, R),
    R = G.

% Recolor disconnected cells: both r islands in g3x3_two_regions become g.
test(recolor_disconnected) :-
    g3x3_two_regions(G),
    gridflood_recolor(G, r, g, R),
    R = [[g,b,g],[b,b,b],[g,b,g]].

% --- gridflood_isolate tests ---

% Isolate 2x2 r block in g3x3_rb onto b background.
test(isolate_region) :-
    g3x3_rb(G),
    gridflood_isolate(G, 0, 0, x, R),
    R = [[r,r,x],[r,r,x],[x,x,x]].

% Isolate b in g3x3_rb.
test(isolate_b_region) :-
    g3x3_rb(G),
    gridflood_isolate(G, 0, 2, x, R),
    R = [[x,x,b],[x,x,b],[b,b,b]].

% Isolate single cell in 1x1.
test(isolate_1x1) :-
    g1x1_r(G),
    gridflood_isolate(G, 0, 0, x, R),
    R = [[r]].

% --- gridflood_region_cells tests ---

% Cells of 2x2 r block in g3x3_rb.
test(region_cells_block) :-
    g3x3_rb(G),
    gridflood_region_cells(G, 0, 0, Cells),
    msort(Cells, S),
    msort([0-0,0-1,1-0,1-1], Expected),
    S = Expected.

% Single cell region (island) in checkerboard.
test(region_cells_single) :-
    g3x3_check(G),
    gridflood_region_cells(G, 0, 0, Cells),
    Cells = [0-0].

% All cells in 3x3 all-red.
test(region_cells_all) :-
    g3x3_r(G),
    gridflood_region_cells(G, 1, 1, Cells),
    length(Cells, 9).

% --- gridflood_region_size tests ---

% 2x2 red block.
test(region_size_4) :-
    g3x3_rb(G),
    gridflood_region_size(G, 0, 0, N),
    N = 4.

% Single cell.
test(region_size_1) :-
    g3x3_check(G),
    gridflood_region_size(G, 0, 0, N),
    N = 1.

% Whole 3x3 all-red.
test(region_size_9) :-
    g3x3_r(G),
    gridflood_region_size(G, 0, 0, N),
    N = 9.

% --- gridflood_region_bbox tests ---

% 2x2 red block in g3x3_rb: bbox rows 0-1, cols 0-1.
test(region_bbox_block) :-
    g3x3_rb(G),
    gridflood_region_bbox(G, 0, 0, MinR, MinC, MaxR, MaxC),
    MinR = 0, MinC = 0, MaxR = 1, MaxC = 1.

% All-red 3x3: bbox 0-2, 0-2.
test(region_bbox_full) :-
    g3x3_r(G),
    gridflood_region_bbox(G, 0, 0, MinR, MinC, MaxR, MaxC),
    MinR = 0, MinC = 0, MaxR = 2, MaxC = 2.

% b region in g3x3_rb is an L-shape spanning rows 0-2, cols 0-2.
test(region_bbox_l_shape) :-
    g3x3_rb(G),
    gridflood_region_bbox(G, 0, 2, MinR, MinC, MaxR, MaxC),
    MinR = 0, MinC = 0, MaxR = 2, MaxC = 2.

% --- gridflood_enclosed_cells tests ---

% b cells inside the ring in g4x4_ring are enclosed.
test(enclosed_cells_ring) :-
    g4x4_ring(G),
    gridflood_enclosed_cells(G, b, Enclosed),
    msort(Enclosed, S),
    msort([1-1,1-2,2-1,2-2], S).

% b cells in g4x4_open are NOT enclosed (reachable from border).
test(enclosed_cells_open_border) :-
    g4x4_open(G),
    gridflood_enclosed_cells(G, b, Enclosed),
    Enclosed = [].

% In 3x3 all-red there are no b cells to enclose.
test(enclosed_cells_none) :-
    g3x3_r(G),
    gridflood_enclosed_cells(G, b, Enclosed),
    Enclosed = [].

% Center r cell in g5x5_hole is enclosed by b ring.
test(enclosed_cells_center) :-
    g5x5_hole(G),
    gridflood_enclosed_cells(G, r, Enclosed),
    Enclosed = [2-2].

% --- gridflood_fill_enclosed tests ---

% Fill enclosed b cells in g4x4_ring with r.
test(fill_enclosed_fills_holes) :-
    g4x4_ring(G),
    gridflood_fill_enclosed(G, b, r, R),
    R = [[r,r,r,r],[r,r,r,r],[r,r,r,r],[r,r,r,r]].

% Fill enclosed in open-border grid: no change since nothing is enclosed.
test(fill_enclosed_no_change) :-
    g4x4_open(G),
    gridflood_fill_enclosed(G, b, r, R),
    R = G.

% --- gridflood_components tests ---

% Two separate r islands in g3x3_two_regions.
test(components_two_islands) :-
    g3x3_two_regions(G),
    gridflood_components(G, r, Comps),
    length(Comps, 4).

% Single monolithic r region in g3x3_r.
test(components_single_region) :-
    g3x3_r(G),
    gridflood_components(G, r, Comps),
    Comps = [_], Comps = [C], length(C, 9).

% No b cells in g3x3_r: empty components.
test(components_empty) :-
    g3x3_r(G),
    gridflood_components(G, b, Comps),
    Comps = [].

% 3x3_rb has one r region (4-connected 2x2 block).
test(components_rb_r) :-
    g3x3_rb(G),
    gridflood_components(G, r, Comps),
    length(Comps, 1).

% --- gridflood_n_components tests ---

% g3x3_two_regions: 4 corners each isolated.
test(n_components_four) :-
    g3x3_two_regions(G),
    gridflood_n_components(G, r, N),
    N = 4.

% Single region.
test(n_components_one) :-
    g3x3_r(G),
    gridflood_n_components(G, r, N),
    N = 1.

% Color not present.
test(n_components_zero) :-
    g3x3_r(G),
    gridflood_n_components(G, b, N),
    N = 0.

% Checkerboard: 5 r cells but none 4-adjacent, so 5 components.
test(n_components_checkerboard) :-
    g3x3_check(G),
    gridflood_n_components(G, r, N),
    N = 5.

% --- gridflood_largest tests ---

% In g3x3_rb the r block (4 cells) is larger than each individual b cell.
test(largest_is_r_block) :-
    g3x3_rb(G),
    gridflood_largest(G, r, Cells),
    length(Cells, 4).

% Single region: largest = only region.
test(largest_single) :-
    g3x3_r(G),
    gridflood_largest(G, r, Cells),
    length(Cells, 9).

% No color cells: fails.
test(largest_fails_when_absent, [fail]) :-
    g3x3_r(G),
    gridflood_largest(G, b, _).

% g3x3_two_regions: all r regions size 1, largest returns one of them.
test(largest_all_equal) :-
    g3x3_two_regions(G),
    gridflood_largest(G, r, Cells),
    length(Cells, 1).

% --- gridflood_is_connected tests ---

% 3x3 all-red is 4-connected.
test(is_connected_4_true) :-
    g3x3_r(G),
    gridflood_is_connected(G, r, 4).

% 3x3 two-region is NOT 4-connected.
test(is_connected_4_false, [fail]) :-
    g3x3_two_regions(G),
    gridflood_is_connected(G, r, 4).

% Diagonal b cells are NOT 4-connected.
test(is_connected_4_diag_false, [fail]) :-
    g3x3_diag(G),
    gridflood_is_connected(G, b, 4).

% Diagonal b cells ARE 8-connected.
test(is_connected_8_diag_true) :-
    g3x3_diag(G),
    gridflood_is_connected(G, b, 8).

% Color not present: vacuously connected.
test(is_connected_vacuous) :-
    g3x3_r(G),
    gridflood_is_connected(G, b, 4).

% 2x2 r block is 4-connected.
test(is_connected_4_block) :-
    g2x2_r(G),
    gridflood_is_connected(G, r, 4).

% --- gridflood_boundary_fill tests ---

% Fill r region at (0,0) bounded by b in g3x3_rb.
test(boundary_fill_r_region) :-
    g3x3_rb(G),
    gridflood_boundary_fill(G, 0, 0, b, g, R),
    R = [[g,g,b],[g,g,b],[b,b,b]].

% Seed cell color equals BoundaryColor: no-op.
test(boundary_fill_seed_is_boundary) :-
    g3x3_rb(G),
    gridflood_boundary_fill(G, 0, 0, r, g, R),
    R = G.

% Fill entire 3x3 all-red with g using x as boundary (no boundary present).
test(boundary_fill_no_walls) :-
    g3x3_r(G),
    gridflood_boundary_fill(G, 0, 0, x, g, R),
    R = [[g,g,g],[g,g,g],[g,g,g]].

% --- Combined tests ---

% Fill then verify region size drops to 0 for original color.
test(fill_then_n_components) :-
    g3x3_rb(G),
    gridflood_fill(G, 0, 0, b, R),
    gridflood_n_components(R, r, N),
    N = 0.

% fill_enclosed + is_connected: after filling the hole in ring, r is still connected.
test(fill_enclosed_then_connected) :-
    g4x4_ring(G),
    gridflood_fill_enclosed(G, b, r, R),
    gridflood_is_connected(R, r, 4).

% region_cells then fill from (0,0) fills those cells to new color.
test(region_cells_then_fill) :-
    g3x3_rb(G),
    gridflood_region_cells(G, 0, 0, Cells),
    length(Cells, 4),
    gridflood_fill(G, 0, 0, x, R),
    gridflood_n_components(R, r, 0),
    gridflood_n_components(R, x, 1).

:- end_tests(gridflood).

:- run_tests(gridflood).
