:- use_module('../prolog/grid_morph').

% Grid fixtures
% 3x3 with r region in top-left corner
g3x3_rb([[r,r,x],[r,r,x],[x,x,x]]).
% Uniform grids
g3x3_all_r([[r,r,r],[r,r,r],[r,r,r]]).
g3x3_all_x([[x,x,x],[x,x,x],[x,x,x]]).
% 5x5 ring (r border, x interior - has a hole)
g5x5_ring([[r,r,r,r,r],[r,x,x,x,r],[r,x,x,x,r],[r,x,x,x,r],[r,r,r,r,r]]).
% 5x5 with r region (no hole)
g5x5_block([[x,x,x,x,x],[x,r,r,r,x],[x,r,r,r,x],[x,r,r,r,x],[x,x,x,x,x]]).
% Single r cell in x grid
g5x5_dot([[x,x,x,x,x],[x,x,x,x,x],[x,x,r,x,x],[x,x,x,x,x],[x,x,x,x,x]]).
% Grid with two small r regions
g5x5_two([[r,x,x,x,r],[x,x,x,x,x],[x,x,x,x,x],[x,x,x,x,x],[r,x,x,x,r]]).
% 1x1 grid
g1x1([[r]]).

:- begin_tests(grid_morph).

% --- grid_morph_dilate1 ---
test(dilate1_expands_rb, []) :-
    g3x3_rb(G),
    grid_morph_dilate1(G, r, R),
    % (0,0),(0,1),(1,0),(1,1) plus (0,2),(1,2),(2,0),(2,1) become r;
    % (2,2) stays x (its only neighbors in original are x cells)
    findall(RC, (nth0(Row,R,RowL), nth0(Col,RowL,r), RC=Row-Col), Cells),
    length(Cells, 8).

test(dilate1_uniform_unchanged, []) :-
    g3x3_all_r(G),
    grid_morph_dilate1(G, r, G).

test(dilate1_dot_grows, []) :-
    g5x5_dot(G),
    grid_morph_dilate1(G, r, R),
    % Center r at (2,2); neighbors (1,2),(3,2),(2,1),(2,3) become r: total 5 r cells
    findall(RC, (nth0(Row,R,RowL), nth0(Col,RowL,r), RC=Row-Col), Cells),
    length(Cells, 5).

% --- grid_morph_erode1 ---
test(erode1_shrinks_block, []) :-
    g5x5_block(G),
    grid_morph_erode1(G, r, R),
    % 3x3 r block minus border: only center (2,2) remains
    findall(RC, (nth0(Row,R,RowL), nth0(Col,RowL,r), RC=Row-Col), Cells),
    Cells = [2-2].

test(erode1_corner_survives, []) :-
    g3x3_rb(G),
    % (0,0) has only r in-bounds neighbors (0,1) and (1,0) -> NOT eroded
    % (0,1),(1,0),(1,1) all have x in-bounds neighbors -> eroded
    grid_morph_erode1(G, r, R),
    findall(RC, (nth0(Row,R,RowL), nth0(Col,RowL,r), RC=Row-Col), Cells),
    Cells = [0-0].

test(erode1_uniform_unchanged, []) :-
    g3x3_all_r(G),
    grid_morph_erode1(G, r, G).

% --- grid_morph_dilate ---
test(dilate_n1_same_as_dilate1, []) :-
    g3x3_rb(G),
    grid_morph_dilate(G, r, 1, R1),
    grid_morph_dilate1(G, r, R2),
    R1 = R2.

test(dilate_n0_identity, []) :-
    g3x3_rb(G),
    grid_morph_dilate(G, r, 0, G).

test(dilate_expands_by_two, []) :-
    g5x5_dot(G),
    grid_morph_dilate(G, r, 2, R),
    % Center r at (2,2) expands 2 layers: diamond of radius 2
    % After 2 dilations: cells within Manhattan distance 2 of (2,2)
    findall(RC, (nth0(Row,R,RowL), nth0(Col,RowL,r), RC=Row-Col), Cells),
    length(Cells, 13).  % 1 + 4 + 8 = 13 cells in Manhattan distance 2 diamond

% --- grid_morph_erode ---
test(erode_n0_identity, []) :-
    g5x5_block(G),
    grid_morph_erode(G, r, 0, G).

test(erode_n1_same_as_erode1, []) :-
    g5x5_block(G),
    grid_morph_erode(G, r, 1, R1),
    grid_morph_erode1(G, r, R2),
    R1 = R2.

test(erode_n2_block_to_empty, []) :-
    g5x5_block(G),
    % 3x3 r block: erode 2 steps -> center-only then empty
    grid_morph_erode(G, r, 2, R),
    findall(RC, (nth0(Row,R,RowL), nth0(Col,RowL,r), RC=Row-Col), Cells),
    Cells = [].

% --- grid_morph_open ---
test(open_removes_dot, []) :-
    g5x5_dot(G),
    % Small 1-cell region: erode 1 removes it, dilate 1 adds nothing
    grid_morph_open(G, r, 1, R),
    findall(RC, (nth0(Row,R,RowL), nth0(Col,RowL,r), RC=Row-Col), Cells),
    Cells = [].

test(open_preserves_large_region, []) :-
    g5x5_block(G),
    % 3x3 r block: erode 1 -> center only; dilate 1 -> center + 4 neighbors = 5 cells
    grid_morph_open(G, r, 1, R),
    findall(RC, (nth0(Row,R,RowL), nth0(Col,RowL,r), RC=Row-Col), Cells),
    length(Cells, 5).

% --- grid_morph_close ---
test(close_fills_ring_hole, []) :-
    g5x5_ring(G),
    % r ring with x hole: dilate 1 fills hole; erode 1 restores boundary
    grid_morph_close(G, r, 1, R),
    findall(RC, (nth0(Row,R,RowL), nth0(Col,RowL,r), RC=Row-Col), Cells),
    % The hole should be filled; result should have more r cells than original
    findall(RC0, (nth0(Row0,G,RowL0), nth0(Col0,RowL0,r), RC0=Row0-Col0), OrigCells),
    length(Cells, NC), length(OrigCells, NO),
    NC >= NO.

test(close_n0_identity, []) :-
    g3x3_rb(G),
    grid_morph_close(G, r, 0, G).

% --- grid_morph_boundary_inner ---
test(boundary_inner_rb, []) :-
    g3x3_rb(G),
    grid_morph_boundary_inner(G, r, Cells),
    % (0,1),(1,0),(1,1) are inner boundary r cells; (0,0) has only r neighbors
    length(Cells, 3).

test(boundary_inner_uniform_none, []) :-
    g3x3_all_r(G),
    grid_morph_boundary_inner(G, r, []).

% --- grid_morph_boundary_outer ---
test(boundary_outer_rb, []) :-
    g3x3_rb(G),
    grid_morph_boundary_outer(G, r, Cells),
    % x cells adjacent to r: (0,2),(1,2),(2,0),(2,1)
    length(Cells, 4).

test(boundary_outer_uniform_none, []) :-
    g3x3_all_r(G),
    grid_morph_boundary_outer(G, r, []).

% --- grid_morph_gradient_cells ---
test(gradient_cells_rb, []) :-
    g3x3_rb(G),
    grid_morph_gradient_cells(G, r, Cells),
    % inner (3) + outer (4) = 7 gradient cells
    length(Cells, 7).

% --- grid_morph_top_hat ---
test(top_hat_removes_protrusion, []) :-
    g5x5_dot(G),
    % Single r cell removed by open(1) -> top-hat highlights it
    grid_morph_top_hat(G, r, 1, Cells),
    Cells = [2-2].

test(top_hat_zero_for_large, []) :-
    g5x5_block(G),
    % 3x3 block: after open(2) nothing remains, top-hat = all r cells
    % Actually open(1) preserves some cells, so top-hat = removed cells
    grid_morph_top_hat(G, r, 2, Cells),
    % erode 2 removes everything; dilate 2 on empty = empty; all r cells are in top-hat
    length(Cells, 9).

% --- grid_morph_bottom_hat ---
test(bottom_hat_highlights_hole, []) :-
    g5x5_ring(G),
    % close(N=2) expands r two layers (fills entire hole), then shrinks two layers
    % bottom-hat = new r cells from hole not in original
    grid_morph_bottom_hat(G, r, 2, Cells),
    % close(2): dilate fills all x including center; erode(2) removes border effects
    % result has some new r cells from the filled hole
    length(Cells, NCells), NCells > 0.

test(bottom_hat_empty_for_no_holes, []) :-
    g5x5_block(G),
    % N=0: close(0) = identity; bottom-hat = empty
    grid_morph_bottom_hat(G, r, 0, Cells),
    Cells = [].

% --- grid_morph_fill_holes ---
test(fill_holes_ring, []) :-
    g5x5_ring(G),
    grid_morph_fill_holes(G, r, x, R),
    % x hole filled with r; border x cells remain x
    findall(RC, (nth0(Row,R,RowL), nth0(Col,RowL,r), RC=Row-Col), RCells),
    % Original 16 r cells + 9 hole cells = 25... wait ring has border cells
    % g5x5_ring: outer ring of r (5*4=16 cells), inner 9 are x
    % After fill_holes: 16+9=25 r cells (entire grid)... no that's too many.
    % g5x5_ring: [[r,r,r,r,r],[r,x,x,x,r],[r,x,x,x,r],[r,x,x,x,r],[r,r,r,r,r]]
    % r cells: row0=5, row1=2, row2=2, row3=2, row4=5 = 16 total
    % x cells: 9 (interior hole)
    % After fill_holes: all 25 cells become r
    length(RCells, 25).

test(fill_holes_no_hole, []) :-
    g5x5_block(G),
    grid_morph_fill_holes(G, r, x, G).  % No holes to fill

% --- grid_morph_connected_border ---
test(connected_border_finds_border_x, []) :-
    g5x5_ring(G),
    grid_morph_connected_border(G, x, r, Cells),
    % The x cells reachable from border: NONE (all x is enclosed by r ring)
    % g5x5_ring has r on all borders, so no x is on the border
    % Actually no: the border cells of the 5x5 grid are row 0,4 and col 0,4 - all r
    % x cells are interior (rows 1-3, cols 1-3) - enclosed, not reachable from border
    Cells = [].

test(connected_border_block_border_x, []) :-
    g5x5_block(G),
    grid_morph_connected_border(G, x, r, Cells),
    % x cells reachable from border: all 5x5-3x3=16 x cells around the r block
    length(Cells, 16).

% --- grid_morph_remove_small ---
test(remove_small_removes_dots, []) :-
    g5x5_two(G),
    grid_morph_remove_small(G, r, x, 2, R),
    % Four corner r cells, each a 1-cell component (size 1 < 2) -> removed
    findall(RC, (nth0(Row,R,RowL), nth0(Col,RowL,r), RC=Row-Col), Cells),
    Cells = [].

test(remove_small_keeps_large, []) :-
    g5x5_block(G),
    grid_morph_remove_small(G, r, x, 9, R),
    % 3x3=9 r block: 9 >= 9 -> kept
    findall(RC, (nth0(Row,R,RowL), nth0(Col,RowL,r), RC=Row-Col), Cells),
    length(Cells, 9).

test(remove_small_removes_if_below_threshold, []) :-
    g5x5_block(G),
    grid_morph_remove_small(G, r, x, 10, R),
    % 3x3=9 cells, threshold=10 -> all removed
    findall(RC, (nth0(Row,R,RowL), nth0(Col,RowL,r), RC=Row-Col), Cells),
    Cells = [].

% --- Combined tests ---
test(erode_then_dilate_open, []) :-
    g5x5_block(G),
    grid_morph_erode(G, r, 1, E),
    grid_morph_dilate(E, r, 1, D),
    grid_morph_open(G, r, 1, O),
    D = O.

test(fill_holes_and_remove_small_combined, []) :-
    g5x5_ring(G),
    grid_morph_fill_holes(G, r, x, Filled),
    findall(RC, (nth0(Row,Filled,RowL), nth0(Col,RowL,r), RC=Row-Col), FCells),
    length(FCells, 25).

test(dilate_increases_fg_count, []) :-
    g3x3_rb(G),
    grid_morph_dilate1(G, r, D),
    findall(1, (member(Row,G), member(r,Row)), OrigR),
    findall(1, (member(Row,D), member(r,Row)), DilR),
    length(OrigR, NO), length(DilR, ND),
    ND > NO.

test(erode_decreases_fg_count, []) :-
    g5x5_block(G),
    grid_morph_erode1(G, r, E),
    findall(1, (member(Row,G), member(r,Row)), OrigR),
    findall(1, (member(Row,E), member(r,Row)), EroR),
    length(OrigR, NO), length(EroR, NE),
    NE < NO.

test(dilate_n2_dot_has_13_cells, []) :-
    g5x5_dot(G),
    grid_morph_dilate(G, r, 2, R),
    findall(RC, (nth0(Row,R,RowL), nth0(Col,RowL,r), RC=Row-Col), Cells),
    length(Cells, 13).

test(boundary_inner_ring, []) :-
    g5x5_ring(G),
    grid_morph_boundary_inner(G, r, Cells),
    % Corner r cells (0,0),(0,4),(4,0),(4,4) have only r in-bounds neighbors; 16-4=12
    length(Cells, 12).

test(boundary_outer_block, []) :-
    g5x5_block(G),
    grid_morph_boundary_outer(G, r, Cells),
    % x cells adjacent to the 3x3 r block: 12 cells
    length(Cells, 12).

test(gradient_cells_block, []) :-
    g5x5_block(G),
    grid_morph_gradient_cells(G, r, Cells),
    % inner (8: center (2,2) is smooth, all-r neighbors) + outer (12) = 20
    length(Cells, 20).

test(fill_holes_preserves_no_hole, []) :-
    g5x5_block(G),
    grid_morph_fill_holes(G, r, x, G).

test(erode1_preserves_full_grid, []) :-
    g3x3_all_r(G),
    grid_morph_erode1(G, r, G).

test(remove_small_size_equal_not_removed, []) :-
    G = [[r,r],[r,r]],
    % 4 r cells in one 4-cell component; threshold=4 -> component size >= 4 -> kept
    grid_morph_remove_small(G, r, x, 4, G).

test(connected_border_uniform_x, []) :-
    g3x3_all_x(G),
    % All x cells reachable from border (entire grid is x on border and interior)
    grid_morph_connected_border(G, x, r, Cells),
    length(Cells, 9).

:- end_tests(grid_morph).
