:- use_module('../prolog/scan').

% Helper predicate for scan_map_cells: add 1 to every cell value.
add_one(_, _, V, NV) :- NV is V + 1.

% Helper predicate for scan_map_cells: multiply cell value by 2.
double_val(_, _, V, NV) :- NV is V * 2.

% Helper predicate for scan_map_cells: replace every cell with its row index.
row_index(R, _, _, R).

% Helper predicate for scan_filter_cells: keep cells where value is non-zero.
cell_nonzero(_, _, V) :- V \= 0.

% Helper predicate for scan_filter_cells: keep cells in row 0.
cell_top_row(0, _, _).

% Helper predicate for scan_filter_cells: keep cells where value > 2.
cell_gt2(_, _, V) :- V > 2.

:- begin_tests(scan).

% --- scan_row_major ---

test(row_major_2x2) :-
    scan_row_major([[1,2],[3,4]], Cells),
    Cells = [0-0-1, 0-1-2, 1-0-3, 1-1-4].

test(row_major_1x3) :-
    scan_row_major([[a,b,c]], Cells),
    Cells = [0-0-a, 0-1-b, 0-2-c].

test(row_major_empty) :-
    scan_row_major([], Cells),
    Cells = [].

% --- scan_col_major ---

test(col_major_2x2) :-
    scan_col_major([[1,2],[3,4]], Cells),
    Cells = [0-0-1, 1-0-3, 0-1-2, 1-1-4].

test(col_major_3x1) :-
    scan_col_major([[a],[b],[c]], Cells),
    Cells = [0-0-a, 1-0-b, 2-0-c].

test(col_major_1x1) :-
    scan_col_major([[9]], Cells),
    Cells = [0-0-9].

% --- scan_cells_of ---

test(cells_of_present) :-
    scan_cells_of([[1,0,1],[0,1,0]], 1, Cells),
    Cells = [0-0, 0-2, 1-1].

test(cells_of_absent) :-
    scan_cells_of([[1,2],[3,4]], 9, Cells),
    Cells = [].

test(cells_of_all_same) :-
    scan_cells_of([[a,a],[a,a]], a, Cells),
    Cells = [0-0, 0-1, 1-0, 1-1].

% --- scan_set_cell ---

test(set_cell_top_right) :-
    scan_set_cell([[1,2],[3,4]], 0, 1, 9, New),
    New = [[1,9],[3,4]].

test(set_cell_bottom_left) :-
    scan_set_cell([[1,2],[3,4]], 1, 0, 7, New),
    New = [[1,2],[7,4]].

test(set_cell_1x1) :-
    scan_set_cell([[0]], 0, 0, 5, New),
    New = [[5]].

% --- scan_map_cells ---

test(map_cells_add_one) :-
    scan_map_cells([[1,2],[3,4]], add_one, New),
    New = [[2,3],[4,5]].

test(map_cells_double) :-
    scan_map_cells([[1,2],[3,4]], double_val, New),
    New = [[2,4],[6,8]].

test(map_cells_row_index) :-
    scan_map_cells([[a,b],[c,d]], row_index, New),
    New = [[0,0],[1,1]].

% --- scan_filter_cells ---

test(filter_cells_gt2) :-
    scan_filter_cells([[1,2],[3,4]], cell_gt2, Cells),
    Cells = [1-0-3, 1-1-4].

test(filter_cells_top_row) :-
    scan_filter_cells([[a,b],[c,d]], cell_top_row, Cells),
    Cells = [0-0-a, 0-1-b].

test(filter_cells_none) :-
    scan_filter_cells([[1,2],[3,4]], cell_nonzero, Cells),
    length(Cells, 4).

% --- scan_update_cells ---

test(update_cells_two) :-
    scan_update_cells([[1,2],[3,4]], [0-1-9, 1-0-7], New),
    New = [[1,9],[7,4]].

test(update_cells_empty) :-
    scan_update_cells([[1,2],[3,4]], [], New),
    New = [[1,2],[3,4]].

test(update_cells_one) :-
    scan_update_cells([[0,0],[0,0]], [0-0-1], New),
    New = [[1,0],[0,0]].

% --- scan_zigzag ---

test(zigzag_2x3) :-
    scan_zigzag([[1,2,3],[4,5,6]], Cells),
    Cells = [0-0-1, 0-1-2, 0-2-3, 1-2-6, 1-1-5, 1-0-4].

test(zigzag_1x3) :-
    scan_zigzag([[a,b,c]], Cells),
    Cells = [0-0-a, 0-1-b, 0-2-c].

test(zigzag_3x1) :-
    scan_zigzag([[1],[2],[3]], Cells),
    Cells = [0-0-1, 1-0-2, 2-0-3].

% --- scan_spiral_in ---

test(spiral_in_3x3) :-
    scan_spiral_in([[1,2,3],[4,5,6],[7,8,9]], Cells),
    Cells = [0-0-1, 0-1-2, 0-2-3,
             1-2-6, 2-2-9, 2-1-8, 2-0-7,
             1-0-4, 1-1-5].

test(spiral_in_1x1) :-
    scan_spiral_in([[7]], Cells),
    Cells = [0-0-7].

test(spiral_in_1x3) :-
    scan_spiral_in([[1,2,3]], Cells),
    Cells = [0-0-1, 0-1-2, 0-2-3].

% --- scan_border_traversal ---

test(border_3x3) :-
    scan_border_traversal([[1,2,3],[4,5,6],[7,8,9]], Cells),
    Cells = [0-0-1, 0-1-2, 0-2-3,
             1-2-6, 2-2-9, 2-1-8, 2-0-7,
             1-0-4].

test(border_1x1) :-
    scan_border_traversal([[5]], Cells),
    Cells = [0-0-5].

test(border_2x2) :-
    scan_border_traversal([[1,2],[3,4]], Cells),
    Cells = [0-0-1, 0-1-2, 1-1-4, 1-0-3].

% --- scan_diag_traversal_ne ---

test(diag_ne_2x2) :-
    scan_diag_traversal_ne([[1,2],[3,4]], Cells),
    Cells = [0-0-1, 0-1-2, 1-0-3, 1-1-4].

test(diag_ne_1x3) :-
    scan_diag_traversal_ne([[1,2,3]], Cells),
    Cells = [0-0-1, 0-1-2, 0-2-3].

test(diag_ne_3x1) :-
    scan_diag_traversal_ne([[1],[2],[3]], Cells),
    Cells = [0-0-1, 1-0-2, 2-0-3].

% --- scan_diag_traversal_se ---

test(diag_se_2x2) :-
    scan_diag_traversal_se([[1,2],[3,4]], Cells),
    Cells = [1-0-3, 0-0-1, 1-1-4, 0-1-2].

test(diag_se_1x3) :-
    scan_diag_traversal_se([[1,2,3]], Cells),
    Cells = [0-0-1, 0-1-2, 0-2-3].

test(diag_se_3x1) :-
    scan_diag_traversal_se([[1],[2],[3]], Cells),
    Cells = [2-0-3, 1-0-2, 0-0-1].

% --- scan_grid_from_cells ---

test(grid_from_cells_sparse) :-
    scan_grid_from_cells(2, 2, [0-0-1, 1-1-4], 0, Grid),
    Grid = [[1,0],[0,4]].

test(grid_from_cells_empty) :-
    scan_grid_from_cells(2, 2, [], 7, Grid),
    Grid = [[7,7],[7,7]].

test(grid_from_cells_one) :-
    scan_grid_from_cells(1, 3, [0-1-9], 0, Grid),
    Grid = [[0,9,0]].

% --- scan_index_of ---

test(index_of_first) :-
    scan_index_of([[1,2],[3,1]], 1, R, C),
    R = 0, C = 0.

test(index_of_last) :-
    scan_index_of([[1,2],[3,4]], 4, R, C),
    R = 1, C = 1.

test(index_of_middle) :-
    scan_index_of([[1,2],[3,4]], 2, R, C),
    R = 0, C = 1.

:- end_tests(scan).
