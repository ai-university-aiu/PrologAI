/*  PrologAI — Grid Pack Test Suite  (PR 56)

    Acceptance tests for all gd_* predicates.

    Run with:
        swipl -g "run_tests, halt" test_grid.pl
*/

% Load the PLUnit test framework.
:- use_module(library(plunit)).

% Load the module under test.
:- use_module('../prolog/grid').

% ===========================================================================
% TEST FIXTURE DATA
% ===========================================================================

% A simple 3x3 grid used in many tests.
test_grid_3x3(
    [[0,1,2],
     [3,4,5],
     [6,7,8]]).

% A 2x4 grid for non-square tests.
test_grid_2x4(
    [[1,2,3,4],
     [5,6,7,8]]).

% A 4x4 grid with exactly 2 connected color-1 objects.
% Component 1: (0,0),(0,1),(1,0)  Component 2: (2,2),(2,3),(3,2)
test_grid_objects(
    [[1,1,0,0],
     [1,0,0,0],
     [0,0,1,1],
     [0,0,1,0]]).

% A 3x3 grid with horizontal symmetry.
test_grid_sym_h(
    [[1,2,3],
     [4,5,6],
     [1,2,3]]).

% A 3x3 grid with vertical symmetry.
test_grid_sym_v(
    [[1,4,1],
     [2,5,2],
     [3,6,3]]).

% A 3x3 grid with both h and v symmetry.
test_grid_sym_hv(
    [[1,2,1],
     [2,3,2],
     [1,2,1]]).

% ===========================================================================
% SECTION AC-GD-001 — SIZE AND ACCESSORS
% ===========================================================================
:- begin_tests(grid_size).

% AC-GD-001-a: gd_size on 3x3 grid.
test(size_3x3) :-
    % Get the test grid.
    test_grid_3x3(G),
    % Check dimensions.
    gd_size(G, 3, 3).

% AC-GD-001-b: gd_size on 2x4 grid.
test(size_2x4) :-
    % Get the test grid.
    test_grid_2x4(G),
    % Check dimensions.
    gd_size(G, 2, 4).

% AC-GD-001-c: gd_cell accesses correct element.
test(cell_access) :-
    % Get the test grid.
    test_grid_3x3(G),
    % Cell at (0,0) should be 0.
    gd_cell(G, 0, 0, 0),
    % Cell at (1,2) should be 5.
    gd_cell(G, 1, 2, 5),
    % Cell at (2,1) should be 7.
    gd_cell(G, 2, 1, 7).

% AC-GD-001-d: gd_row extracts a row.
test(row_access) :-
    % Get the test grid.
    test_grid_3x3(G),
    % Row 1 should be [3,4,5].
    gd_row(G, 1, [3,4,5]).

% AC-GD-001-e: gd_col extracts a column.
test(col_access) :-
    % Get the test grid.
    test_grid_3x3(G),
    % Column 2 should be [2,5,8].
    gd_col(G, 2, [2,5,8]).

:- end_tests(grid_size).

% ===========================================================================
% SECTION AC-GD-002 — COLOR OPERATIONS
% ===========================================================================
:- begin_tests(grid_color).

% AC-GD-002-a: gd_colors returns sorted unique color set.
test(colors_3x3) :-
    % Get the test grid.
    test_grid_3x3(G),
    % All 9 colors 0-8 are present.
    gd_colors(G, Colors),
    % Verify the set.
    Colors = [0,1,2,3,4,5,6,7,8].

% AC-GD-002-b: gd_color_count counts correctly.
test(color_count) :-
    % Build a simple grid with known color counts.
    G = [[1,1,0],[1,0,0]],
    % Color 1 appears 3 times.
    gd_color_count(G, 1, 3),
    % Color 0 appears 3 times.
    gd_color_count(G, 0, 3).

% AC-GD-002-c: gd_color_map substitutes colors.
test(color_map) :-
    % Start with a 2x2 grid.
    G = [[1,2],[2,1]],
    % Map 1->3, 2->4.
    gd_color_map(G, [1-3, 2-4], G2),
    % Result should be [[3,4],[4,3]].
    G2 = [[3,4],[4,3]].

% AC-GD-002-d: gd_color_map leaves unmapped colors unchanged.
test(color_map_passthrough) :-
    % Start with a grid.
    G = [[0,1],[2,3]],
    % Only map 1->5; rest pass through.
    gd_color_map(G, [1-5], G2),
    % Result should be [[0,5],[2,3]].
    G2 = [[0,5],[2,3]].

:- end_tests(grid_color).

% ===========================================================================
% SECTION AC-GD-003 — OBJECT EXTRACTION
% ===========================================================================
:- begin_tests(grid_objects).

% AC-GD-003-a: gd_objects finds connected components of color 1.
test(objects_count) :-
    % Get the test grid.
    test_grid_objects(G),
    % Find objects of color 1.
    gd_objects(G, 1, Objects),
    % There should be exactly 2 components.
    length(Objects, 2).

% AC-GD-003-b: gd_objects returns correct cell sets.
test(objects_cells) :-
    % A simple L-shaped object.
    G = [[1,0],[1,1]],
    % Find the one component of color 1.
    gd_objects(G, 1, [Comp]),
    % It should contain 3 cells.
    length(Comp, 3).

% AC-GD-003-c: gd_bounding_box on a cell set.
test(bounding_box) :-
    % A diagonal of cells.
    Cells = [r(1,1), r(2,3), r(3,2)],
    % Bounding box should be r(1,1) to r(3,3).
    gd_bounding_box(Cells, r(1,1), r(3,3)).

:- end_tests(grid_objects).

% ===========================================================================
% SECTION AC-GD-004 — ROTATIONS
% ===========================================================================
:- begin_tests(grid_rotate).

% AC-GD-004-a: 90-degree rotation of 2x3 grid.
test(rotate90) :-
    % A 2x3 input.
    G = [[1,2,3],[4,5,6]],
    % After 90 CW: rows become columns from bottom.
    gd_rotate90(G, G2),
    % Expected: [[4,1],[5,2],[6,3]].
    G2 = [[4,1],[5,2],[6,3]].

% AC-GD-004-b: 180-degree rotation.
test(rotate180) :-
    % Start with a 2x2 grid.
    G = [[1,2],[3,4]],
    % After 180: rows and columns reversed.
    gd_rotate180(G, G2),
    % Expected: [[4,3],[2,1]].
    G2 = [[4,3],[2,1]].

% AC-GD-004-c: 4 rotations return to original.
test(rotate360) :-
    % Any grid rotated 4 times returns to original.
    test_grid_3x3(G),
    % Rotate 4 times.
    gd_rotate90(G, R1),
    gd_rotate90(R1, R2),
    gd_rotate90(R2, R3),
    gd_rotate90(R3, G2),
    % Must equal original.
    gd_equal(G, G2).

:- end_tests(grid_rotate).

% ===========================================================================
% SECTION AC-GD-005 — REFLECTIONS
% ===========================================================================
:- begin_tests(grid_reflect).

% AC-GD-005-a: reflect_h flips rows.
test(reflect_h) :-
    % A 3-row grid.
    G = [[1,2],[3,4],[5,6]],
    % Horizontal flip reverses row order.
    gd_reflect_h(G, G2),
    % Expected: rows reversed.
    G2 = [[5,6],[3,4],[1,2]].

% AC-GD-005-b: reflect_v flips columns.
test(reflect_v) :-
    % A 2x3 grid.
    G = [[1,2,3],[4,5,6]],
    % Vertical flip reverses each row.
    gd_reflect_v(G, G2),
    % Expected: each row reversed.
    G2 = [[3,2,1],[6,5,4]].

% AC-GD-005-c: reflect_d1 transposes the grid.
test(reflect_d1) :-
    % A 2x3 grid.
    G = [[1,2,3],[4,5,6]],
    % Main diagonal flip transposes.
    gd_reflect_d1(G, G2),
    % Expected: 3x2 transposed.
    G2 = [[1,4],[2,5],[3,6]].

% AC-GD-005-d: double reflect_h returns original.
test(reflect_h_twice) :-
    % Any grid reflected twice returns to original.
    test_grid_3x3(G),
    gd_reflect_h(G, G2),
    gd_reflect_h(G2, G3),
    gd_equal(G, G3).

:- end_tests(grid_reflect).

% ===========================================================================
% SECTION AC-GD-006 — TRANSLATE AND CROP
% ===========================================================================
:- begin_tests(grid_transform).

% AC-GD-006-a: translate shifts cells and fills background.
test(translate) :-
    % A 3x3 grid.
    G = [[1,1,1],[1,1,1],[1,1,1]],
    % Translate right by 1; background = 0.
    gd_translate(G, 0, 1, 0, G2),
    % First column should now be 0.
    gd_col(G2, 0, [0,0,0]).

% AC-GD-006-b: crop extracts sub-grid.
test(crop) :-
    % A 3x3 grid.
    test_grid_3x3(G),
    % Crop rows 0-1, cols 1-2.
    gd_crop(G, 0, 1, 1, 2, G2),
    % Expected: [[1,2],[4,5]].
    G2 = [[1,2],[4,5]].

% AC-GD-006-c: overlay puts patch onto base.
test(overlay) :-
    % Base is all zeros.
    Base = [[0,0,0],[0,0,0],[0,0,0]],
    % Patch is a 2x2 grid.
    Patch = [[1,2],[3,4]],
    % Overlay at offset (1,1).
    gd_overlay(Base, Patch, 1, 1, G2),
    % Center should now have patch values.
    gd_cell(G2, 1, 1, 1),
    gd_cell(G2, 2, 2, 4).

:- end_tests(grid_transform).

% ===========================================================================
% SECTION AC-GD-007 — DIFF AND EQUALITY
% ===========================================================================
:- begin_tests(grid_compare).

% AC-GD-007-a: gd_equal succeeds for identical grids.
test(equal_same) :-
    % Any grid equals itself.
    test_grid_3x3(G),
    gd_equal(G, G).

% AC-GD-007-b: gd_diff finds changed cells.
test(diff_cells) :-
    % Two grids differing in one cell.
    G1 = [[0,0],[0,0]],
    G2 = [[0,0],[0,1]],
    % Diff should find one change.
    gd_diff(G1, G2, Diffs),
    % One diff at (1,1).
    Diffs = [r(1,1,0,1)].

% AC-GD-007-c: gd_diff returns empty list for equal grids.
test(diff_empty) :-
    % Same grid twice.
    test_grid_3x3(G),
    gd_diff(G, G, []).

:- end_tests(grid_compare).

% ===========================================================================
% SECTION AC-GD-008 — SYMMETRY
% ===========================================================================
:- begin_tests(grid_symmetry).

% AC-GD-008-a: grid with horizontal symmetry detected.
test(symmetry_h) :-
    % Get the h-symmetric test grid.
    test_grid_sym_h(G),
    % Detect symmetry axes.
    gd_symmetry(G, Axes),
    % Must include h.
    member(h, Axes).

% AC-GD-008-b: grid with vertical symmetry detected.
test(symmetry_v) :-
    % Get the v-symmetric test grid.
    test_grid_sym_v(G),
    % Detect symmetry axes.
    gd_symmetry(G, Axes),
    % Must include v.
    member(v, Axes).

% AC-GD-008-c: hv-symmetric grid has both axes.
test(symmetry_hv, nondet) :-
    % Get the hv-symmetric test grid.
    test_grid_sym_hv(G),
    % Detect symmetry axes.
    gd_symmetry(G, Axes),
    % Must include both h and v.
    member(h, Axes),
    member(v, Axes).

:- end_tests(grid_symmetry).

% ===========================================================================
% SECTION AC-GD-009 — FLOOD FILL AND MAKE
% ===========================================================================
:- begin_tests(grid_fill).

% AC-GD-009-a: gd_make creates uniform grid.
test(make_grid) :-
    % Make a 2x3 grid of color 5.
    gd_make(2, 3, 5, G),
    % All cells should be 5.
    gd_color_count(G, 5, 6).

% AC-GD-009-b: gd_set_cell modifies one cell.
test(set_cell) :-
    % Start with uniform grid.
    gd_make(3, 3, 0, G),
    % Set center cell to 7.
    gd_set_cell(G, 1, 1, 7, G2),
    % Center should be 7.
    gd_cell(G2, 1, 1, 7),
    % All other cells should still be 0.
    gd_color_count(G2, 0, 8).

% AC-GD-009-c: gd_fill replaces a connected region.
test(flood_fill) :-
    % A grid with a connected region of color 1.
    G = [[1,1,0],[1,0,0],[0,0,0]],
    % Fill the connected 1-region with color 3.
    gd_fill(G, 0, 0, 3, G2),
    % The three 1-cells should now be 3.
    gd_color_count(G2, 3, 3),
    % Color 1 should be gone.
    gd_color_count(G2, 1, 0).

:- end_tests(grid_fill).
