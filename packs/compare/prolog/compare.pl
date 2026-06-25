% Module declaration: compare pack, Layer 57.
:- module(compare, [
    % cp_diff_cells/3: list of r(R,C) where Grid1 and Grid2 differ.
    cp_diff_cells/3,
    % cp_same_cells/3: list of r(R,C) where Grid1 and Grid2 are equal.
    cp_same_cells/3,
    % cp_added_color/4: cells that are Color in Grid2 but not in Grid1.
    cp_added_color/4,
    % cp_removed_color/4: cells that are Color in Grid1 but not in Grid2.
    cp_removed_color/4,
    % cp_changed_to/4: cells whose value changed to Color in Grid2.
    cp_changed_to/4,
    % cp_changed_from/4: cells whose value changed from Color in Grid1.
    cp_changed_from/4,
    % cp_diff_map/3: grid where equal cells = 0, different cells = 1.
    cp_diff_map/3,
    % cp_similarity/3: fraction of equal cells as N/Total (both integers).
    cp_similarity/3,
    % cp_region_diff/3: cells in Region1 but not Region2 (set difference).
    cp_region_diff/3,
    % cp_region_intersect/3: cells in both Region1 and Region2.
    cp_region_intersect/3,
    % cp_region_union/3: cells in either Region1 or Region2 (no duplicates).
    cp_region_union/3,
    % cp_region_equal/2: true when two regions contain the same cells.
    cp_region_equal/2,
    % cp_grids_equal/2: true when two grids are identical.
    cp_grids_equal/2,
    % cp_color_shift/3: list of (OldColor-NewColor) pairs for each changed cell.
    cp_color_shift/3
]).

% Import list and apply utilities.
:- use_module(library(lists),  [member/2, nth0/3, numlist/3, subtract/3,
                                 intersection/3, union/3]).
:- use_module(library(apply),  [maplist/2, maplist/3, maplist/4, include/3]).

% cp_grid_dims_(+Grid, -Rows, -Cols): measure grid dimensions.
cp_grid_dims_(Grid, Rows, Cols) :-
    % Count rows.
    length(Grid, Rows),
    % Count columns from first row.
    ( Rows > 0 -> Grid = [R0|_], length(R0, Cols) ; Cols = 0 ).

% cp_all_positions_(+Rows, +Cols, -Positions): all r(R,C) in row-major order.
cp_all_positions_(Rows, Cols, Positions) :-
    % Build row and column index lists.
    ( Rows > 0 -> R1 is Rows - 1, numlist(0, R1, RowIds) ; RowIds = [] ),
    ( Cols > 0 -> C1 is Cols - 1, numlist(0, C1, ColIds) ; ColIds = [] ),
    % Collect all (R,C) pairs.
    findall(r(R,C), (member(R, RowIds), member(C, ColIds)), Positions).

% cp_cell_val_(+Grid, +r(R,C), -V): get value at cell.
cp_cell_val_(Grid, r(R,C), V) :-
    nth0(R, Grid, Row), nth0(C, Row, V).

% cp_diff_cells(+Grid1, +Grid2, -Diffs): cells where values differ.
cp_diff_cells(Grid1, Grid2, Diffs) :-
    % Get all positions (assume same dimensions).
    cp_grid_dims_(Grid1, Rows, Cols),
    cp_all_positions_(Rows, Cols, All),
    % Keep those where values differ.
    include(cp_differs_(Grid1, Grid2), All, Diffs).

% cp_differs_(+G1, +G2, +Cell): cell values differ.
cp_differs_(G1, G2, Cell) :-
    cp_cell_val_(G1, Cell, V1),
    cp_cell_val_(G2, Cell, V2),
    V1 \= V2.

% cp_same_cells(+Grid1, +Grid2, -Sames): cells where values are equal.
cp_same_cells(Grid1, Grid2, Sames) :-
    % Get all positions.
    cp_grid_dims_(Grid1, Rows, Cols),
    cp_all_positions_(Rows, Cols, All),
    % Keep those where values match.
    include(cp_same_(Grid1, Grid2), All, Sames).

% cp_same_(+G1, +G2, +Cell): cell values are equal.
cp_same_(G1, G2, Cell) :-
    cp_cell_val_(G1, Cell, V1),
    cp_cell_val_(G2, Cell, V2),
    V1 =:= V2.

% cp_added_color(+Grid1, +Grid2, +Color, -Added): cells that became Color.
cp_added_color(Grid1, Grid2, Color, Added) :-
    % Cells where G2 has Color but G1 does not.
    cp_grid_dims_(Grid1, Rows, Cols),
    cp_all_positions_(Rows, Cols, All),
    include(cp_is_color_gain_(Grid1, Grid2, Color), All, Added).

% cp_is_color_gain_(+G1, +G2, +Color, +Cell): G2 has Color, G1 does not.
cp_is_color_gain_(G1, G2, Color, Cell) :-
    cp_cell_val_(G2, Cell, Color),
    cp_cell_val_(G1, Cell, V1),
    V1 \= Color.

% cp_removed_color(+Grid1, +Grid2, +Color, -Removed): cells that lost Color.
cp_removed_color(Grid1, Grid2, Color, Removed) :-
    % Cells where G1 had Color but G2 does not.
    cp_grid_dims_(Grid1, Rows, Cols),
    cp_all_positions_(Rows, Cols, All),
    include(cp_is_color_loss_(Grid1, Grid2, Color), All, Removed).

% cp_is_color_loss_(+G1, +G2, +Color, +Cell): G1 had Color, G2 does not.
cp_is_color_loss_(G1, G2, Color, Cell) :-
    cp_cell_val_(G1, Cell, Color),
    cp_cell_val_(G2, Cell, V2),
    V2 \= Color.

% cp_changed_to(+Grid1, +Grid2, +Color, -Changed): cells that changed to Color.
cp_changed_to(Grid1, Grid2, Color, Changed) :-
    % Like cp_added_color but also requires the value actually changed.
    cp_grid_dims_(Grid1, Rows, Cols),
    cp_all_positions_(Rows, Cols, All),
    include(cp_is_change_to_(Grid1, Grid2, Color), All, Changed).

% cp_is_change_to_(+G1, +G2, +Color, +Cell): value changed to Color.
cp_is_change_to_(G1, G2, Color, Cell) :-
    cp_cell_val_(G2, Cell, Color),
    cp_cell_val_(G1, Cell, Old),
    Old \= Color.

% cp_changed_from(+Grid1, +Grid2, +Color, -Changed): cells that changed from Color.
cp_changed_from(Grid1, Grid2, Color, Changed) :-
    % Cells where G1 had Color and G2 has a different value.
    cp_grid_dims_(Grid1, Rows, Cols),
    cp_all_positions_(Rows, Cols, All),
    include(cp_is_change_from_(Grid1, Grid2, Color), All, Changed).

% cp_is_change_from_(+G1, +G2, +Color, +Cell): value changed from Color.
cp_is_change_from_(G1, G2, Color, Cell) :-
    cp_cell_val_(G1, Cell, Color),
    cp_cell_val_(G2, Cell, New),
    New \= Color.

% cp_diff_row_(+Row1, +Row2, +ColIds, -DiffRow): row of 0/1 difference flags.
cp_diff_row_(Row1, Row2, ColIds, DiffRow) :-
    maplist(cp_diff_flag_(Row1, Row2), ColIds, DiffRow).

% cp_diff_flag_(+Row1, +Row2, +C, -Flag): 1 if values differ, 0 if same.
cp_diff_flag_(Row1, Row2, C, Flag) :-
    nth0(C, Row1, V1),
    nth0(C, Row2, V2),
    ( V1 =:= V2 -> Flag = 0 ; Flag = 1 ).

% cp_diff_map(+Grid1, +Grid2, -Map): 0/1 difference grid.
cp_diff_map(Grid1, Grid2, Map) :-
    % Get column indices.
    cp_grid_dims_(Grid1, _, Cols),
    ( Cols > 0 -> C1 is Cols - 1, numlist(0, C1, ColIds) ; ColIds = [] ),
    % Map each row pair to a diff-flag row.
    maplist(cp_diff_row_flag_cols_(ColIds), Grid1, Grid2, Map).

% cp_diff_row_flag_cols_(+ColIds, +Row1, +Row2, -DiffRow): row difference flags.
cp_diff_row_flag_cols_(ColIds, Row1, Row2, DiffRow) :-
    maplist(cp_diff_flag_(Row1, Row2), ColIds, DiffRow).

% cp_similarity(+Grid1, +Grid2, -EqCount-Total): equal-cell count and total.
cp_similarity(Grid1, Grid2, EqCount-Total) :-
    % Count same and total cells.
    cp_grid_dims_(Grid1, Rows, Cols),
    Total is Rows * Cols,
    cp_same_cells(Grid1, Grid2, Sames),
    length(Sames, EqCount).

% cp_region_diff(+Region1, +Region2, -Diff): cells in R1 not in R2.
cp_region_diff(Region1, Region2, Diff) :-
    % subtract/3 from library(lists) does list set difference.
    subtract(Region1, Region2, Diff).

% cp_region_intersect(+Region1, +Region2, -Inter): cells in both.
cp_region_intersect(Region1, Region2, Inter) :-
    % intersection/3 from library(lists).
    intersection(Region1, Region2, Inter).

% cp_region_union(+Region1, +Region2, -Union): cells in either, no dups.
cp_region_union(Region1, Region2, Union) :-
    % union/3 from library(lists).
    union(Region1, Region2, Union).

% cp_region_equal(+Region1, +Region2): same cell sets (order-independent).
cp_region_equal(Region1, Region2) :-
    % Both sorted versions must match.
    msort(Region1, S1),
    msort(Region2, S2),
    S1 = S2.

% cp_grids_equal(+Grid1, +Grid2): grids are structurally identical.
cp_grids_equal(Grid1, Grid2) :-
    Grid1 = Grid2.

% cp_shift_pair_(+G1, +G2, +Cell, -Pair): Old-New pair if changed.
cp_shift_pair_(G1, G2, Cell, Old-New) :-
    cp_cell_val_(G1, Cell, Old),
    cp_cell_val_(G2, Cell, New),
    Old \= New.

% cp_color_shift(+Grid1, +Grid2, -Pairs): Old-New pairs for changed cells.
cp_color_shift(Grid1, Grid2, Pairs) :-
    % Find all cells that differ and collect their Old-New pairs.
    cp_grid_dims_(Grid1, Rows, Cols),
    cp_all_positions_(Rows, Cols, All),
    include(cp_differs_(Grid1, Grid2), All, Diffs),
    maplist(cp_shift_pair_(Grid1, Grid2), Diffs, Pairs).
