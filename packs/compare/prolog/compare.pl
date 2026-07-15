% Module declaration: compare pack, Layer 57.
:- module(compare, [
    % compare_diff_cells/3: list of r(R,C) where Grid1 and Grid2 differ.
    compare_diff_cells/3,
    % compare_same_cells/3: list of r(R,C) where Grid1 and Grid2 are equal.
    compare_same_cells/3,
    % compare_added_color/4: cells that are Color in Grid2 but not in Grid1.
    compare_added_color/4,
    % compare_removed_color/4: cells that are Color in Grid1 but not in Grid2.
    compare_removed_color/4,
    % compare_changed_to/4: cells whose value changed to Color in Grid2.
    compare_changed_to/4,
    % compare_changed_from/4: cells whose value changed from Color in Grid1.
    compare_changed_from/4,
    % compare_diff_map/3: grid where equal cells = 0, different cells = 1.
    compare_diff_map/3,
    % compare_similarity/3: fraction of equal cells as N/Total (both integers).
    compare_similarity/3,
    % compare_region_diff/3: cells in Region1 but not Region2 (set difference).
    compare_region_diff/3,
    % compare_region_intersect/3: cells in both Region1 and Region2.
    compare_region_intersect/3,
    % compare_region_union/3: cells in either Region1 or Region2 (no duplicates).
    compare_region_union/3,
    % compare_region_equal/2: true when two regions contain the same cells.
    compare_region_equal/2,
    % compare_grids_equal/2: true when two grids are identical.
    compare_grids_equal/2,
    % compare_color_shift/3: list of (OldColor-NewColor) pairs for each changed cell.
    compare_color_shift/3
]).

% Import list and apply utilities.
:- use_module(library(lists),  [member/2, nth0/3, numlist/3, subtract/3,
                                 intersection/3, union/3]).
:- use_module(library(apply),  [maplist/2, maplist/3, maplist/4, include/3]).

% compare_grid_dims_(+Grid, -Rows, -Cols): measure grid dimensions.
compare_grid_dims_(Grid, Rows, Cols) :-
    % Count rows.
    length(Grid, Rows),
    % Count columns from first row.
    ( Rows > 0 -> Grid = [R0|_], length(R0, Cols) ; Cols = 0 ).

% compare_all_positions_(+Rows, +Cols, -Positions): all r(R,C) in row-major order.
compare_all_positions_(Rows, Cols, Positions) :-
    % Build row and column index lists.
    ( Rows > 0 -> R1 is Rows - 1, numlist(0, R1, RowIds) ; RowIds = [] ),
    ( Cols > 0 -> C1 is Cols - 1, numlist(0, C1, ColIds) ; ColIds = [] ),
    % Collect all (R,C) pairs.
    findall(r(R,C), (member(R, RowIds), member(C, ColIds)), Positions).

% compare_cell_val_(+Grid, +r(R,C), -V): get value at cell.
compare_cell_val_(Grid, r(R,C), V) :-
    nth0(R, Grid, Row), nth0(C, Row, V).

% compare_diff_cells(+Grid1, +Grid2, -Diffs): cells where values differ.
compare_diff_cells(Grid1, Grid2, Diffs) :-
    % Get all positions (assume same dimensions).
    compare_grid_dims_(Grid1, Rows, Cols),
    compare_all_positions_(Rows, Cols, All),
    % Keep those where values differ.
    include(compare_differs_(Grid1, Grid2), All, Diffs).

% compare_differs_(+G1, +G2, +Cell): cell values differ.
compare_differs_(G1, G2, Cell) :-
    compare_cell_val_(G1, Cell, V1),
    compare_cell_val_(G2, Cell, V2),
    V1 \= V2.

% compare_same_cells(+Grid1, +Grid2, -Sames): cells where values are equal.
compare_same_cells(Grid1, Grid2, Sames) :-
    % Get all positions.
    compare_grid_dims_(Grid1, Rows, Cols),
    compare_all_positions_(Rows, Cols, All),
    % Keep those where values match.
    include(compare_same_(Grid1, Grid2), All, Sames).

% compare_same_(+G1, +G2, +Cell): cell values are equal.
compare_same_(G1, G2, Cell) :-
    compare_cell_val_(G1, Cell, V1),
    compare_cell_val_(G2, Cell, V2),
    V1 =:= V2.

% compare_added_color(+Grid1, +Grid2, +Color, -Added): cells that became Color.
compare_added_color(Grid1, Grid2, Color, Added) :-
    % Cells where G2 has Color but G1 does not.
    compare_grid_dims_(Grid1, Rows, Cols),
    compare_all_positions_(Rows, Cols, All),
    include(compare_is_color_gain_(Grid1, Grid2, Color), All, Added).

% compare_is_color_gain_(+G1, +G2, +Color, +Cell): G2 has Color, G1 does not.
compare_is_color_gain_(G1, G2, Color, Cell) :-
    compare_cell_val_(G2, Cell, Color),
    compare_cell_val_(G1, Cell, V1),
    V1 \= Color.

% compare_removed_color(+Grid1, +Grid2, +Color, -Removed): cells that lost Color.
compare_removed_color(Grid1, Grid2, Color, Removed) :-
    % Cells where G1 had Color but G2 does not.
    compare_grid_dims_(Grid1, Rows, Cols),
    compare_all_positions_(Rows, Cols, All),
    include(compare_is_color_loss_(Grid1, Grid2, Color), All, Removed).

% compare_is_color_loss_(+G1, +G2, +Color, +Cell): G1 had Color, G2 does not.
compare_is_color_loss_(G1, G2, Color, Cell) :-
    compare_cell_val_(G1, Cell, Color),
    compare_cell_val_(G2, Cell, V2),
    V2 \= Color.

% compare_changed_to(+Grid1, +Grid2, +Color, -Changed): cells that changed to Color.
compare_changed_to(Grid1, Grid2, Color, Changed) :-
    % Like compare_added_color but also requires the value actually changed.
    compare_grid_dims_(Grid1, Rows, Cols),
    compare_all_positions_(Rows, Cols, All),
    include(compare_is_change_to_(Grid1, Grid2, Color), All, Changed).

% compare_is_change_to_(+G1, +G2, +Color, +Cell): value changed to Color.
compare_is_change_to_(G1, G2, Color, Cell) :-
    compare_cell_val_(G2, Cell, Color),
    compare_cell_val_(G1, Cell, Old),
    Old \= Color.

% compare_changed_from(+Grid1, +Grid2, +Color, -Changed): cells that changed from Color.
compare_changed_from(Grid1, Grid2, Color, Changed) :-
    % Cells where G1 had Color and G2 has a different value.
    compare_grid_dims_(Grid1, Rows, Cols),
    compare_all_positions_(Rows, Cols, All),
    include(compare_is_change_from_(Grid1, Grid2, Color), All, Changed).

% compare_is_change_from_(+G1, +G2, +Color, +Cell): value changed from Color.
compare_is_change_from_(G1, G2, Color, Cell) :-
    compare_cell_val_(G1, Cell, Color),
    compare_cell_val_(G2, Cell, New),
    New \= Color.

% compare_diff_row_(+Row1, +Row2, +ColIds, -DiffRow): row of 0/1 difference flags.
compare_diff_row_(Row1, Row2, ColIds, DiffRow) :-
    maplist(compare_diff_flag_(Row1, Row2), ColIds, DiffRow).

% compare_diff_flag_(+Row1, +Row2, +C, -Flag): 1 if values differ, 0 if same.
compare_diff_flag_(Row1, Row2, C, Flag) :-
    nth0(C, Row1, V1),
    nth0(C, Row2, V2),
    ( V1 =:= V2 -> Flag = 0 ; Flag = 1 ).

% compare_diff_map(+Grid1, +Grid2, -Map): 0/1 difference grid.
compare_diff_map(Grid1, Grid2, Map) :-
    % Get column indices.
    compare_grid_dims_(Grid1, _, Cols),
    ( Cols > 0 -> C1 is Cols - 1, numlist(0, C1, ColIds) ; ColIds = [] ),
    % Map each row pair to a diff-flag row.
    maplist(compare_diff_row_flag_cols_(ColIds), Grid1, Grid2, Map).

% compare_diff_row_flag_cols_(+ColIds, +Row1, +Row2, -DiffRow): row difference flags.
compare_diff_row_flag_cols_(ColIds, Row1, Row2, DiffRow) :-
    maplist(compare_diff_flag_(Row1, Row2), ColIds, DiffRow).

% compare_similarity(+Grid1, +Grid2, -EqCount-Total): equal-cell count and total.
compare_similarity(Grid1, Grid2, EqCount-Total) :-
    % Count same and total cells.
    compare_grid_dims_(Grid1, Rows, Cols),
    Total is Rows * Cols,
    compare_same_cells(Grid1, Grid2, Sames),
    length(Sames, EqCount).

% compare_region_diff(+Region1, +Region2, -Diff): cells in R1 not in R2.
compare_region_diff(Region1, Region2, Diff) :-
    % subtract/3 from library(lists) does list set difference.
    subtract(Region1, Region2, Diff).

% compare_region_intersect(+Region1, +Region2, -Inter): cells in both.
compare_region_intersect(Region1, Region2, Inter) :-
    % intersection/3 from library(lists).
    intersection(Region1, Region2, Inter).

% compare_region_union(+Region1, +Region2, -Union): cells in either, no dups.
compare_region_union(Region1, Region2, Union) :-
    % union/3 from library(lists).
    union(Region1, Region2, Union).

% compare_region_equal(+Region1, +Region2): same cell sets (order-independent).
compare_region_equal(Region1, Region2) :-
    % Both sorted versions must match.
    msort(Region1, S1),
    msort(Region2, S2),
    S1 = S2.

% compare_grids_equal(+Grid1, +Grid2): grids are structurally identical.
compare_grids_equal(Grid1, Grid2) :-
    Grid1 = Grid2.

% compare_shift_pair_(+G1, +G2, +Cell, -Pair): Old-New pair if changed.
compare_shift_pair_(G1, G2, Cell, Old-New) :-
    compare_cell_val_(G1, Cell, Old),
    compare_cell_val_(G2, Cell, New),
    Old \= New.

% compare_color_shift(+Grid1, +Grid2, -Pairs): Old-New pairs for changed cells.
compare_color_shift(Grid1, Grid2, Pairs) :-
    % Find all cells that differ and collect their Old-New pairs.
    compare_grid_dims_(Grid1, Rows, Cols),
    compare_all_positions_(Rows, Cols, All),
    include(compare_differs_(Grid1, Grid2), All, Diffs),
    maplist(compare_shift_pair_(Grid1, Grid2), Diffs, Pairs).
