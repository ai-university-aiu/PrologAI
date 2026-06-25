% PLUnit tests for the fill pack (fl_* predicates).
:- use_module(library(plunit)).
:- use_module(library(fill)).

% Helper grids and regions.
% 3x3 all-zero grid.
g0([[0,0,0],[0,0,0],[0,0,0]]).
% 3x3 grid with a central 1.
gc([[0,0,0],[0,1,0],[0,0,0]]).
% 4x4 all-zero grid.
g4([[0,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]]).
% 3x3 region (all cells).
sq3([r(0,0),r(0,1),r(0,2),r(1,0),r(1,1),r(1,2),r(2,0),r(2,1),r(2,2)]).
% 2x2 region.
sq2([r(0,0),r(0,1),r(1,0),r(1,1)]).
% L-shape: 3 cells.
lshape([r(0,0),r(1,0),r(1,1)]).
% Stamp: 2x2 with BG=0.
stamp2([[0,1],[1,0]]).

:- begin_tests(fill_fill_region).

test(fill_region_all) :-
    g0(G), sq3(R), fl_fill_region(G, R, 5, Result),
    Result = [[5,5,5],[5,5,5],[5,5,5]].

test(fill_region_partial) :-
    g0(G), fl_fill_region(G, [r(0,0), r(1,1)], 3, Result),
    Result = [[3,0,0],[0,3,0],[0,0,0]].

test(fill_region_single) :-
    gc(G), fl_fill_region(G, [r(1,1)], 9, Result),
    Result = [[0,0,0],[0,9,0],[0,0,0]].

test(fill_region_empty_noop) :-
    g0(G), fl_fill_region(G, [], 5, Result),
    Result = [[0,0,0],[0,0,0],[0,0,0]].

:- end_tests(fill_fill_region).

:- begin_tests(fill_fill_bbox).

test(fill_bbox_single_cell) :-
    g0(G), fl_fill_bbox(G, bbox(1,1,1,1), 7, Result),
    Result = [[0,0,0],[0,7,0],[0,0,0]].

test(fill_bbox_full_grid) :-
    g0(G), fl_fill_bbox(G, bbox(0,0,2,2), 9, Result),
    Result = [[9,9,9],[9,9,9],[9,9,9]].

test(fill_bbox_row_range) :-
    g0(G), fl_fill_bbox(G, bbox(0,1,1,2), 4, Result),
    Result = [[0,4,4],[0,4,4],[0,0,0]].

test(fill_bbox_corner) :-
    g0(G), fl_fill_bbox(G, bbox(2,2,2,2), 1, Result),
    Result = [[0,0,0],[0,0,0],[0,0,1]].

:- end_tests(fill_fill_bbox).

:- begin_tests(fill_fill_row).

test(fill_row_0) :-
    g0(G), fl_fill_row(G, 0, 5, Result),
    Result = [[5,5,5],[0,0,0],[0,0,0]].

test(fill_row_last) :-
    g0(G), fl_fill_row(G, 2, 3, Result),
    Result = [[0,0,0],[0,0,0],[3,3,3]].

test(fill_row_middle) :-
    g0(G), fl_fill_row(G, 1, 9, Result),
    Result = [[0,0,0],[9,9,9],[0,0,0]].

:- end_tests(fill_fill_row).

:- begin_tests(fill_fill_col).

test(fill_col_0) :-
    g0(G), fl_fill_col(G, 0, 5, Result),
    Result = [[5,0,0],[5,0,0],[5,0,0]].

test(fill_col_last) :-
    g0(G), fl_fill_col(G, 2, 7, Result),
    Result = [[0,0,7],[0,0,7],[0,0,7]].

test(fill_col_middle) :-
    g0(G), fl_fill_col(G, 1, 3, Result),
    Result = [[0,3,0],[0,3,0],[0,3,0]].

:- end_tests(fill_fill_col).

:- begin_tests(fill_fill_cells).

test(fill_cells_two) :-
    g0(G), fl_fill_cells(G, [r(0,0), r(2,2)], 1, Result),
    Result = [[1,0,0],[0,0,0],[0,0,1]].

test(fill_cells_empty) :-
    g0(G), fl_fill_cells(G, [], 5, Result),
    Result = [[0,0,0],[0,0,0],[0,0,0]].

test(fill_cells_one) :-
    g0(G), fl_fill_cells(G, [r(1,2)], 8, Result),
    Result = [[0,0,0],[0,0,8],[0,0,0]].

:- end_tests(fill_fill_cells).

:- begin_tests(fill_fill_border).

test(fill_border_3x3) :-
    g0(G), fl_fill_border(G, 1, Result),
    Result = [[1,1,1],[1,0,1],[1,1,1]].

test(fill_border_4x4) :-
    g4(G), fl_fill_border(G, 2, Result),
    Result = [[2,2,2,2],[2,0,0,2],[2,0,0,2],[2,2,2,2]].

test(fill_border_over_existing) :-
    gc(G), fl_fill_border(G, 9, Result),
    Result = [[9,9,9],[9,1,9],[9,9,9]].

:- end_tests(fill_fill_border).

:- begin_tests(fill_outline_region).

test(outline_3x3) :-
    g0(G), sq3(R),
    % In a 3x3 region, only the center cell has all 4 neighbors in region.
    % Border cells are all except center; they get Color.
    fl_outline_region(G, R, 1, Result),
    % Center remains 0; border cells become 1.
    Result = [[1,1,1],[1,0,1],[1,1,1]].

test(outline_single_cell) :-
    g0(G), fl_outline_region(G, [r(1,1)], 5, Result),
    % Single cell is a border cell (no neighbor is in the region).
    Result = [[0,0,0],[0,5,0],[0,0,0]].

test(outline_hline) :-
    g0(G), fl_outline_region(G, [r(1,0), r(1,1), r(1,2)], 3, Result),
    % No cell in a line has all 4 neighbors in region, so all are border.
    Result = [[0,0,0],[3,3,3],[0,0,0]].

:- end_tests(fill_outline_region).

:- begin_tests(fill_fill_interior).

test(interior_3x3) :-
    g0(G), sq3(R),
    fl_fill_interior(G, R, 9, Result),
    % Only center cell (1,1) has all 4 neighbors in the 3x3 region.
    Result = [[0,0,0],[0,9,0],[0,0,0]].

test(interior_single_no_interior) :-
    g0(G), fl_fill_interior(G, [r(1,1)], 9, Result),
    % Single cell has no neighbors in region -> no interior cells.
    Result = [[0,0,0],[0,0,0],[0,0,0]].

test(interior_2x2_no_interior) :-
    g0(G), sq2(R),
    fl_fill_interior(G, R, 9, Result),
    % 2x2 square: no cell has all 4 neighbors in region.
    Result = [[0,0,0],[0,0,0],[0,0,0]].

:- end_tests(fill_fill_interior).

:- begin_tests(fill_solid_rect).

test(solid_rect_1x1) :-
    fl_solid_rect(1, 1, 5, G), G = [[5]].

test(solid_rect_2x3) :-
    fl_solid_rect(2, 3, 7, G), G = [[7,7,7],[7,7,7]].

test(solid_rect_zero_color) :-
    fl_solid_rect(2, 2, 0, G), G = [[0,0],[0,0]].

:- end_tests(fill_solid_rect).

:- begin_tests(fill_checkerboard).

test(checker_1x1) :-
    fl_checkerboard(1, 1, 0, 1, G), G = [[0]].

test(checker_2x2) :-
    fl_checkerboard(2, 2, 0, 1, G),
    G = [[0,1],[1,0]].

test(checker_3x3) :-
    fl_checkerboard(3, 3, 0, 1, G),
    G = [[0,1,0],[1,0,1],[0,1,0]].

test(checker_colors) :-
    fl_checkerboard(2, 2, 3, 7, G),
    G = [[3,7],[7,3]].

:- end_tests(fill_checkerboard).

:- begin_tests(fill_draw_hline).

test(hline_full_row) :-
    g0(G), fl_draw_hline(G, 1, 0, 2, 5, Result),
    Result = [[0,0,0],[5,5,5],[0,0,0]].

test(hline_partial) :-
    g0(G), fl_draw_hline(G, 0, 1, 2, 3, Result),
    Result = [[0,3,3],[0,0,0],[0,0,0]].

test(hline_single_cell) :-
    g0(G), fl_draw_hline(G, 2, 1, 1, 9, Result),
    Result = [[0,0,0],[0,0,0],[0,9,0]].

:- end_tests(fill_draw_hline).

:- begin_tests(fill_draw_vline).

test(vline_full_col) :-
    g0(G), fl_draw_vline(G, 1, 0, 2, 5, Result),
    Result = [[0,5,0],[0,5,0],[0,5,0]].

test(vline_partial) :-
    g0(G), fl_draw_vline(G, 2, 0, 1, 3, Result),
    Result = [[0,0,3],[0,0,3],[0,0,0]].

test(vline_single_cell) :-
    g0(G), fl_draw_vline(G, 0, 1, 1, 7, Result),
    Result = [[0,0,0],[7,0,0],[0,0,0]].

:- end_tests(fill_draw_vline).

:- begin_tests(fill_main_diag).

test(diag_3x3) :-
    g0(G), fl_fill_main_diag(G, 1, Result),
    Result = [[1,0,0],[0,1,0],[0,0,1]].

test(diag_1x1) :-
    fl_fill_main_diag([[0]], 5, Result),
    Result = [[5]].

test(diag_over_existing) :-
    gc(G), fl_fill_main_diag(G, 9, Result),
    % gc = [[0,0,0],[0,1,0],[0,0,0]]; diag colors (0,0),(1,1),(2,2).
    Result = [[9,0,0],[0,9,0],[0,0,9]].

:- end_tests(fill_main_diag).

:- begin_tests(fill_stamp).

test(stamp_top_left) :-
    g0(G), stamp2(S),
    % BG=0: stamp [[0,1],[1,0]] at (0,0); 0=transparent so only 1s stamped.
    fl_stamp(G, S, 0, 0, 0, Result),
    Result = [[0,1,0],[1,0,0],[0,0,0]].

test(stamp_center_offset) :-
    g0(G),
    % Stamp [[1]] at (1,1); no BG conflict.
    fl_stamp(G, [[1]], 1, 1, 0, Result),
    Result = [[0,0,0],[0,1,0],[0,0,0]].

test(stamp_no_transparency) :-
    g0(G),
    % BG=9 (no cell is 9), so all stamp cells applied.
    fl_stamp(G, [[1,2],[3,4]], 1, 1, 9, Result),
    Result = [[0,0,0],[0,1,2],[0,3,4]].

test(stamp_fully_transparent) :-
    g0(G),
    % BG=1; all cells in stamp are 1; nothing stamped.
    fl_stamp(G, [[1,1],[1,1]], 0, 0, 1, Result),
    Result = [[0,0,0],[0,0,0],[0,0,0]].

:- end_tests(fill_stamp).
