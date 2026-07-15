% test_pivot.pl - PLUnit acceptance tests for the pivot pack (pv_* predicates).
% 42 tests: 3 per predicate for all 14 exported predicates.
:- use_module('../prolog/pivot.pl').

% Begin the pivot test suite.
:- begin_tests(pivot).

% --- pivot_centroid/2 ---

% pivot_centroid of a 2x2 block of cells returns the floor average.
test(centroid_block) :-
    % Cells forming a 2x2 block starting at (0,0).
    pivot_centroid([0-0, 0-1, 1-0, 1-1], PR-PC),
    % Floor average of rows: (0+0+1+1)//4 = 0; columns: same.
    PR =:= 0, PC =:= 0.

% pivot_centroid of a column gives the middle row.
test(centroid_column) :-
    % Three cells in column 2, rows 0, 2, 4.
    pivot_centroid([0-2, 2-2, 4-2], PR-PC),
    % Row average: (0+2+4)//3 = 2; col average: (2+2+2)//3 = 2.
    PR =:= 2, PC =:= 2.

% pivot_centroid of a single cell is the cell itself.
test(centroid_single) :-
    % Single cell at (3,5).
    pivot_centroid([3-5], PR-PC),
    % Centroid = the cell.
    PR =:= 3, PC =:= 5.

% --- pivot_to_rel/3 ---

% pivot_to_rel computes correct offsets for a cell above and left of pivot.
test(to_rel_above_left) :-
    % Pivot at (2,2), cell at (0,0): offsets are -2, -2.
    pivot_to_rel(2-2, 0-0, DR-DC),
    DR =:= -2, DC =:= -2.

% pivot_to_rel for a cell at the pivot itself returns 0-0.
test(to_rel_same) :-
    % Pivot and cell at (3,4).
    pivot_to_rel(3-4, 3-4, DR-DC),
    DR =:= 0, DC =:= 0.

% pivot_to_rel for a cell below and right of pivot.
test(to_rel_below_right) :-
    % Pivot at (1,1), cell at (3,4): offsets are 2, 3.
    pivot_to_rel(1-1, 3-4, DR-DC),
    DR =:= 2, DC =:= 3.

% --- pivot_from_rel/3 ---

% pivot_from_rel restores the original cell from offset 0-0.
test(from_rel_identity) :-
    % Pivot at (2,3), zero offset gives the pivot itself.
    pivot_from_rel(2-3, 0-0, R-C),
    R =:= 2, C =:= 3.

% pivot_from_rel converts a negative offset to a cell above the pivot.
test(from_rel_negative) :-
    % Pivot at (4,4), offset -2-(-1) gives cell at (2,3).
    pivot_from_rel(4-4, (-2)-(-1), R-C),
    R =:= 2, C =:= 3.

% pivot_to_rel and pivot_from_rel are inverses.
test(from_rel_round_trip) :-
    % Convert cell to relative then back should give original.
    pivot_to_rel(2-3, 5-7, DR-DC),
    pivot_from_rel(2-3, DR-DC, R-C),
    R =:= 5, C =:= 7.

% --- pivot_rotate_cell_cw/3 ---

% Rotating a cell one step to the right of pivot gives one step below pivot.
test(rotate_cw_right_to_down) :-
    % Pivot at (2,2), cell at (2,3): offset (0,1) -> CW -> (1,0) -> (3,2).
    pivot_rotate_cell_cw(2-2, 2-3, R2-C2),
    R2 =:= 3, C2 =:= 2.

% Rotating a cell one step above pivot gives one step to the right.
test(rotate_cw_up_to_right) :-
    % Pivot at (2,2), cell at (1,2): offset (-1,0) -> CW -> (0,1) -> (2,3).
    pivot_rotate_cell_cw(2-2, 1-2, R2-C2),
    R2 =:= 2, C2 =:= 3.

% Rotating the pivot cell itself returns the pivot unchanged.
test(rotate_cw_pivot_unchanged) :-
    % Offset (0,0) rotated CW is still (0,0).
    pivot_rotate_cell_cw(3-3, 3-3, R2-C2),
    R2 =:= 3, C2 =:= 3.

% --- pivot_rotate_cells_cw/3 ---

% pivot_rotate_cells_cw rotates all four cardinal neighbors 90 degrees CW.
test(rotate_cells_cw_cardinals) :-
    % Pivot at (2,2), four cardinal neighbors.
    pivot_rotate_cells_cw(2-2, [1-2, 2-3, 3-2, 2-1], Cells2),
    % up->right, right->down, down->left, left->up.
    Cells2 = [2-3, 3-2, 2-1, 1-2].

% pivot_rotate_cells_cw on an empty list returns empty.
test(rotate_cells_cw_empty) :-
    % No cells to rotate.
    pivot_rotate_cells_cw(0-0, [], Cells2),
    Cells2 = [].

% pivot_rotate_cells_cw: four CW rotations return to original.
test(rotate_cells_cw_4x) :-
    % One cell offset (1,0) below pivot.
    pivot_rotate_cells_cw(0-0, [1-0], C1),
    pivot_rotate_cells_cw(0-0, C1, C2),
    pivot_rotate_cells_cw(0-0, C2, C3),
    pivot_rotate_cells_cw(0-0, C3, C4),
    % After 4 CW rotations must return to original.
    C4 = [1-0].

% --- pivot_rotate_cells_180/3 ---

% Rotating 180 around pivot at origin negates both offsets.
test(rotate_180_negate) :-
    % Cell at (1,2) rotated 180 around (0,0) gives (-1,-2).
    pivot_rotate_cells_180(0-0, [1-2], [R2-C2]),
    R2 =:= -1, C2 =:= -2.

% pivot_rotate_cells_180 twice returns the original.
test(rotate_180_double) :-
    % Two 180-degree rotations restore the original.
    pivot_rotate_cells_180(3-3, [1-1, 5-5], Step1),
    pivot_rotate_cells_180(3-3, Step1, Step2),
    Step2 = [1-1, 5-5].

% pivot_rotate_cells_180 of the pivot cell is itself.
test(rotate_180_pivot) :-
    % The pivot rotated 180 around itself stays put.
    pivot_rotate_cells_180(2-2, [2-2], [R2-C2]),
    R2 =:= 2, C2 =:= 2.

% --- pivot_rotate_cells_ccw/3 ---

% Rotating one step to the right CCW gives one step above pivot.
test(rotate_ccw_right_to_up) :-
    % Pivot at (2,2), cell at (2,3): offset (0,1) -> CCW -> (-1,0) -> (1,2).
    pivot_rotate_cells_ccw(2-2, [2-3], [R2-C2]),
    R2 =:= 1, C2 =:= 2.

% CW and CCW of the same cell return different positions.
test(rotate_ccw_vs_cw) :-
    % A cell to the right of the pivot.
    pivot_rotate_cells_cw(0-0, [0-1], [CW]),
    pivot_rotate_cells_ccw(0-0, [0-1], [CCW]),
    % CW goes below, CCW goes above.
    CW = 1-0, CCW = (-1)-0.

% One CW and one CCW rotation cancel each other.
test(rotate_ccw_cw_cancel) :-
    % Apply CW then CCW: must return to original.
    pivot_rotate_cells_cw(1-1, [1-3], Step1),
    pivot_rotate_cells_ccw(1-1, Step1, Step2),
    Step2 = [1-3].

% --- pivot_reflect_cells_h/3 ---

% Reflecting a cell right of pivot gives same cell left of pivot.
test(reflect_h_right_to_left) :-
    % Cell at (2,4) reflected around pivot column 2 gives (2,0).
    pivot_reflect_cells_h(2-2, [2-4], [R2-C2]),
    R2 =:= 2, C2 =:= 0.

% Reflecting the pivot cell horizontally leaves it unchanged.
test(reflect_h_pivot) :-
    % The pivot column is the axis of reflection.
    pivot_reflect_cells_h(1-3, [1-3], [R2-C2]),
    R2 =:= 1, C2 =:= 3.

% Two horizontal reflections restore the original.
test(reflect_h_double) :-
    % Two reflections = identity.
    pivot_reflect_cells_h(0-2, [0-4, 0-0], Step1),
    pivot_reflect_cells_h(0-2, Step1, Step2),
    Step2 = [0-4, 0-0].

% --- pivot_reflect_cells_v/3 ---

% Reflecting a cell below pivot gives same cell above pivot.
test(reflect_v_below_to_above) :-
    % Cell at (4,2) reflected around pivot row 2 gives (0,2).
    pivot_reflect_cells_v(2-2, [4-2], [R2-C2]),
    R2 =:= 0, C2 =:= 2.

% Reflecting the pivot cell vertically leaves it unchanged.
test(reflect_v_pivot) :-
    % The pivot row is the axis of reflection.
    pivot_reflect_cells_v(3-1, [3-1], [R2-C2]),
    R2 =:= 3, C2 =:= 1.

% Two vertical reflections restore the original.
test(reflect_v_double) :-
    % Two reflections = identity.
    pivot_reflect_cells_v(2-0, [4-0, 0-0], Step1),
    pivot_reflect_cells_v(2-0, Step1, Step2),
    Step2 = [4-0, 0-0].

% --- pivot_reflect_cells_diag/3 ---

% Diagonal reflection swaps row and column offsets.
test(reflect_diag_swap_offsets) :-
    % Cell at (1,3) relative to pivot (0,0) has offsets (1,3).
    % Diagonal reflection swaps to (3,1).
    pivot_reflect_cells_diag(0-0, [1-3], [R2-C2]),
    R2 =:= 3, C2 =:= 1.

% Diagonal reflection is its own inverse.
test(reflect_diag_involution) :-
    % Two diagonal reflections = identity.
    pivot_reflect_cells_diag(2-2, [0-4], Step1),
    pivot_reflect_cells_diag(2-2, Step1, Step2),
    Step2 = [0-4].

% Cell on the diagonal (equal offsets) is unchanged by diagonal reflection.
test(reflect_diag_on_axis) :-
    % Cell at (3,3) relative to pivot (1,1): offset (2,2), which is on the diagonal.
    pivot_reflect_cells_diag(1-1, [3-3], [R2-C2]),
    R2 =:= 3, C2 =:= 3.

% --- pivot_reflect_cells_antidiag/3 ---

% Anti-diagonal reflection negates and swaps offsets.
test(reflect_antidiag_negate_swap) :-
    % Cell at (0,3) relative to pivot (1,1): offset (-1,2).
    % Anti-diag reflex_actors: (-DC,-DR) = (-2,1). Absolute: (1-2, 1+1) = (-1,2).
    pivot_reflect_cells_antidiag(1-1, [0-3], [R2-C2]),
    R2 =:= -1, C2 =:= 2.

% Anti-diagonal reflection is its own inverse.
test(reflect_antidiag_involution) :-
    % Two anti-diagonal reflections = identity.
    pivot_reflect_cells_antidiag(0-0, [2-1], Step1),
    pivot_reflect_cells_antidiag(0-0, Step1, Step2),
    Step2 = [2-1].

% Cell on the anti-diagonal (DR = -DC) is unchanged by anti-diag reflection.
test(reflect_antidiag_on_axis) :-
    % Cell at (0,2) relative to pivot (1,1): offset (-1,1); DR = -DC? -1 = -1 yes.
    % Anti-diag reflex_actors: (-DC,-DR) = (-1,1). Absolute: (1-1, 1+1) = (0,2).
    pivot_reflect_cells_antidiag(1-1, [0-2], [R2-C2]),
    R2 =:= 0, C2 =:= 2.

% --- pivot_orbit/3 ---

% pivot_orbit of a cell at an offset of (1,0) from pivot has 4 elements.
test(orbit_cardinal) :-
    % A cell at (1,0) from pivot: orbit is (1,0), (0,-1), (-1,0), (0,1) and
    % reflections. For a cardinal neighbor all 8 D4 give 4 distinct positions.
    pivot_orbit(0-0, 1-0, Orbit),
    % Expect the 4 cardinal positions (reflections coincide with rotations here).
    length(Orbit, 4).

% pivot_orbit of the pivot cell itself has only 1 element.
test(orbit_pivot_single) :-
    % The pivot maps to itself under all 8 D4 transforms.
    pivot_orbit(2-2, 2-2, Orbit),
    Orbit = [2-2].

% pivot_orbit of a diagonal cell has 4 distinct positions.
test(orbit_diagonal) :-
    % Cell at (1,1) from pivot (0,0) has offsets (1,1).
    % D4 of (1,1): CW=(1,-1), 180=(-1,-1), CCW=(-1,1), ReflH=(1,-1), ReflV=(-1,1), Diag=(1,1), AntiD=(-1,-1).
    % Distinct: (1,1), (1,-1), (-1,-1), (-1,1) = 4 elements.
    pivot_orbit(0-0, 1-1, Orbit),
    length(Orbit, 4).

% --- pivot_sym_closure/3 ---

% pivot_sym_closure of a single cell equals its orbit.
test(symmetry_transform_closure_single) :-
    % Closure of one cell = its orbit.
    pivot_orbit(0-0, 1-0, Orbit),
    pivot_sym_closure(0-0, [1-0], Closure),
    % Must be the same set.
    msort(Orbit, S1), msort(Closure, S2),
    S1 = S2.

% pivot_sym_closure of a D4-symmetric set is the set itself.
test(symmetry_transform_closure_already_symmetric) :-
    % The 4 cardinal neighbors form a D4-symmetric set.
    pivot_sym_closure(0-0, [1-0, 0-1, (-1)-0, 0-(-1)], Closure),
    % Closure = same 4 cells.
    length(Closure, 4).

% pivot_sym_closure of an empty list is empty.
test(symmetry_transform_closure_empty) :-
    % No cells to close.
    pivot_sym_closure(0-0, [], Closure),
    Closure = [].

% --- pivot_stamp_at/5 ---

% pivot_stamp_at places a single offset cell into the grid.
test(stamp_at_single) :-
    % 3x3 all-zero grid; stamp value 5 at offset (0,0) from pivot (1,1).
    pivot_stamp_at([[0,0,0],[0,0,0],[0,0,0]], [0-0], 5, 1-1, Result),
    % Cell (1,1) should now be 5.
    nth0(1, Result, Row1), nth0(1, Row1, Val),
    Val =:= 5.

% pivot_stamp_at places multiple offset cells.
test(stamp_at_multiple) :-
    % Stamp offsets (-1,0), (0,0), (1,0) as value 7 at pivot (1,1) in 3x3 grid.
    pivot_stamp_at([[0,0,0],[0,0,0],[0,0,0]], [(-1)-0, 0-0, 1-0], 7, 1-1, Result),
    % Column 1 of Result should be [7,7,7].
    nth0(0, Result, R0), nth0(1, R0, V0),
    nth0(1, Result, R1), nth0(1, R1, V1),
    nth0(2, Result, R2), nth0(1, R2, V2),
    V0 =:= 7, V1 =:= 7, V2 =:= 7.

% pivot_stamp_at silently ignores out-of-bounds offsets.
test(stamp_at_oob) :-
    % Offset (0,-1) from pivot (0,0) gives column -1, which is out of bounds.
    pivot_stamp_at([[0,0],[0,0]], [0-(-1)], 9, 0-0, Result),
    % Grid should be unchanged.
    Result = [[0,0],[0,0]].

% End the pivot test suite.
:- end_tests(pivot).
