% test_label.pl - Acceptance tests for the label pack (Layer 83).
% 42 PLUnit tests: 3 per predicate across 14 predicates.
:- use_module('../prolog/label.pl').

% Tests for lb_label/3: assign integer labels to connected components.
:- begin_tests(label_label).

% Four isolated corners each get a distinct label in raster order.
test(label_isolated_corners) :-
    lb_label([[1,0,1],[0,0,0],[1,0,1]], 0, LG),
    LG = [[1,0,2],[0,0,0],[3,0,4]].

% One fully connected 2x2 region gets label 1.
test(label_single_component) :-
    lb_label([[1,1],[1,1]], 0, LG),
    LG = [[1,1],[1,1]].

% All-background grid produces a label grid equal to itself.
test(label_all_background) :-
    lb_label([[0,0],[0,0]], 0, LG),
    LG = [[0,0],[0,0]].

:- end_tests(label_label).

% Tests for lb_components/3: list of cell lists per component.
:- begin_tests(label_components).

% Diagonal cells are not 4-connected; two separate 1-cell components.
test(components_two_isolated) :-
    lb_components([[1,0],[0,1]], 0, Comps),
    Comps = [[0-0],[1-1]].

% 2x2 block: BFS from (0,0) reaches all four cells in order.
test(components_one_block) :-
    lb_components([[1,1],[1,1]], 0, Comps),
    Comps = [[0-0,0-1,1-0,1-1]].

% All-background grid has no components.
test(components_empty) :-
    lb_components([[0,0],[0,0]], 0, Comps),
    Comps = [].

:- end_tests(label_components).

% Tests for lb_count/3: number of distinct connected components.
:- begin_tests(label_count).

% Four isolated corners.
test(count_four) :-
    lb_count([[1,0,1],[0,0,0],[1,0,1]], 0, N),
    N = 4.

% One 2x2 block.
test(count_one) :-
    lb_count([[1,1],[1,1]], 0, N),
    N = 1.

% No non-background cells.
test(count_zero) :-
    lb_count([[0,0],[0,0]], 0, N),
    N = 0.

:- end_tests(label_count).

% Tests for lb_size_of/3: cell count of a specific label.
:- begin_tests(label_size_of).

% Two cells with label 1 in a hand-constructed LabelGrid.
test(size_of_two) :-
    lb_size_of([[1,0,0],[0,0,0],[1,0,0]], 1, S),
    S = 2.

% All four cells carry label 1.
test(size_of_four) :-
    lb_size_of([[1,1],[1,1]], 1, S),
    S = 4.

% Single cell with label 2.
test(size_of_one) :-
    lb_size_of([[1,0],[0,2]], 2, S),
    S = 1.

:- end_tests(label_size_of).

% Tests for lb_sizes_all/3: list of Label-Size pairs.
:- begin_tests(label_sizes_all).

% Four labels each of size 1.
test(sizes_all_four_singles) :-
    lb_sizes_all([[1,0,2],[0,0,0],[3,0,4]], 0, Sizes),
    Sizes = [1-1, 2-1, 3-1, 4-1].

% One label of size 4.
test(sizes_all_one_block) :-
    lb_sizes_all([[1,1],[1,1]], 0, Sizes),
    Sizes = [1-4].

% No non-background cells; empty sizes list.
test(sizes_all_empty) :-
    lb_sizes_all([[0,0],[0,0]], 0, Sizes),
    Sizes = [].

:- end_tests(label_sizes_all).

% Tests for lb_cells_of/3: cells with a specific label value.
:- begin_tests(label_cells_of).

% Label 1 appears in two positions.
test(cells_of_two) :-
    lb_cells_of([[1,0,0],[0,0,0],[1,0,0]], 1, Cells),
    Cells = [0-0, 2-0].

% Label 1 fills the full 2x2 grid.
test(cells_of_all) :-
    lb_cells_of([[1,1],[1,1]], 1, Cells),
    Cells = [0-0, 0-1, 1-0, 1-1].

% Label 2 at a single corner.
test(cells_of_single) :-
    lb_cells_of([[1,0],[0,2]], 2, Cells),
    Cells = [1-1].

:- end_tests(label_cells_of).

% Tests for lb_bbox_of/4: bounding box corners of a labeled region.
:- begin_tests(label_bbox_of).

% Horizontal pair: same row, columns 0 and 2.
test(bbox_horizontal_pair) :-
    lb_bbox_of([[1,1,0],[0,0,0],[0,2,2]], 1, TL, BR),
    TL = 0-0, BR = 0-1.

% 2x2 block: bounding box is the whole grid.
test(bbox_block) :-
    lb_bbox_of([[1,1],[1,1]], 1, TL, BR),
    TL = 0-0, BR = 1-1.

% Plus-sign shape: bounding box spans full extent.
test(bbox_plus) :-
    lb_bbox_of([[0,1,0],[1,1,1],[0,1,0]], 1, TL, BR),
    TL = 0-0, BR = 2-2.

:- end_tests(label_bbox_of).

% Tests for lb_neighbors_of/4: foreground labels 4-adjacent to a given label.
:- begin_tests(label_neighbors_of).

% Top-left L-shape (label 1) is adjacent to bottom-right block (label 2).
test(neighbors_two_blocks) :-
    lb_neighbors_of([[1,1,0],[1,2,2],[0,2,0]], 1, 0, Ns),
    Ns = [2].

% Isolated corner has no neighbors (background is excluded from result).
test(neighbors_isolated) :-
    lb_neighbors_of([[1,0,2],[0,0,0],[3,0,4]], 1, 0, Ns),
    Ns = [].

% Label 1 at (0,0) touches label 2 at (0,1); background 0 excluded.
test(neighbors_adjacent_pair) :-
    lb_neighbors_of([[1,2,0],[0,0,0]], 1, 0, Ns),
    Ns = [2].

:- end_tests(label_neighbors_of).

% Tests for lb_fill_label/4: replace all cells of a label with a value.
:- begin_tests(label_fill_label).

% Replace label 1 with 9.
test(fill_replace_one) :-
    lb_fill_label([[1,0,2],[0,0,0],[3,0,4]], 1, 9, G),
    G = [[9,0,2],[0,0,0],[3,0,4]].

% Fill entire 2x2 block with background.
test(fill_clear_block) :-
    lb_fill_label([[1,1],[1,1]], 1, 0, G),
    G = [[0,0],[0,0]].

% Fill label 2 (single cell).
test(fill_single_cell) :-
    lb_fill_label([[1,0],[0,2]], 2, 5, G),
    G = [[1,0],[0,5]].

:- end_tests(label_fill_label).

% Tests for lb_keep_largest/3: keep only the largest component.
:- begin_tests(label_keep_largest).

% Three components; largest has 3 cells at top-left.
test(keep_largest_three_comps) :-
    lb_keep_largest([[1,0,1],[1,1,0],[0,0,1]], 0, R),
    R = [[1,0,0],[1,1,0],[0,0,0]].

% Single large plus shape remains unchanged.
test(keep_largest_only_one) :-
    lb_keep_largest([[0,1,0],[1,1,1],[0,1,0]], 0, R),
    R = [[0,1,0],[1,1,1],[0,1,0]].

% All background stays all background.
test(keep_largest_background_only) :-
    lb_keep_largest([[0,0],[0,0]], 0, R),
    R = [[0,0],[0,0]].

:- end_tests(label_keep_largest).

% Tests for lb_remove_small/4: remove components smaller than MinSize.
:- begin_tests(label_remove_small).

% MinSize 3: keep the 3-cell component; remove 1-cell stragglers.
test(remove_small_keeps_large) :-
    lb_remove_small([[1,0,1],[1,1,0],[0,0,1]], 0, 3, R),
    R = [[1,0,0],[1,1,0],[0,0,0]].

% MinSize 5 removes a 4-cell block entirely.
test(remove_small_removes_all) :-
    lb_remove_small([[1,1],[1,1]], 0, 5, R),
    R = [[0,0],[0,0]].

% MinSize 1 keeps every component.
test(remove_small_keeps_all) :-
    lb_remove_small([[1,0,2],[0,0,0],[2,0,1]], 0, 1, R),
    R = [[1,0,2],[0,0,0],[2,0,1]].

:- end_tests(label_remove_small).

% Tests for lb_color_labels/4: color each label from a cycling palette.
:- begin_tests(label_color_labels).

% Four labels cycle through a 3-color palette.
test(color_four_labels_cycle) :-
    lb_color_labels([[1,0,2],[0,0,0],[3,0,4]], 0, [7,8,9], G),
    G = [[7,0,8],[0,0,0],[9,0,7]].

% Single label maps to the first color.
test(color_single_label) :-
    lb_color_labels([[1,1],[1,1]], 0, [5,6], G),
    G = [[5,5],[5,5]].

% All-background grid is unchanged.
test(color_all_background) :-
    lb_color_labels([[0,0],[0,0]], 0, [1,2], G),
    G = [[0,0],[0,0]].

:- end_tests(label_color_labels).

% Tests for lb_merge_two/4: merge label L2 into L1.
:- begin_tests(label_merge_two).

% Merge label 2 into label 1; all 2-cells become 1.
test(merge_two_basic) :-
    lb_merge_two([[1,0,2],[0,0,0],[3,0,4]], 1, 2, G),
    G = [[1,0,1],[0,0,0],[3,0,4]].

% Merge 2 into 1 in a 2-row grid.
test(merge_two_full_row) :-
    lb_merge_two([[1,1],[2,2]], 1, 2, G),
    G = [[1,1],[1,1]].

% Merging a label that is absent leaves the grid unchanged.
test(merge_two_absent_label) :-
    lb_merge_two([[1,0],[0,2]], 1, 3, G),
    G = [[1,0],[0,2]].

:- end_tests(label_merge_two).

% Tests for lb_select_label/4: extract original grid values for one component.
:- begin_tests(label_select_label).

% Select label 1: keep top-left cell of original, zero the rest.
test(select_label_corner) :-
    lb_select_label(
        [[1,0,2],[0,0,0],[2,0,1]],
        [[1,0,2],[0,0,0],[3,0,4]],
        1, Result),
    Result = [[1,0,0],[0,0,0],[0,0,0]].

% Select a label that covers the full grid.
test(select_label_full) :-
    lb_select_label([[5,5],[5,5]], [[1,1],[1,1]], 1, Result),
    Result = [[5,5],[5,5]].

% Select label 2 (two cells) from a mixed grid.
test(select_label_two_cells) :-
    lb_select_label(
        [[1,0,2],[0,0,0],[2,0,1]],
        [[1,0,2],[0,0,0],[2,0,1]],
        2, Result),
    Result = [[0,0,2],[0,0,0],[2,0,0]].

:- end_tests(label_select_label).
