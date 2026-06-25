% pivot.pl - Layer 87: Pivot-Relative Cell Transformations (pv_* prefix).
% Provides D4 operations (rotation and reflection) on lists of R-C cells
% centered at an arbitrary pivot cell, plus centroid, coordinate conversion,
% D4 orbit, symmetry closure, and grid stamping at a pivot position.
:- module(pivot, [
    pv_centroid/2,
    pv_to_rel/3,
    pv_from_rel/3,
    pv_rotate_cell_cw/3,
    pv_rotate_cells_cw/3,
    pv_rotate_cells_180/3,
    pv_rotate_cells_ccw/3,
    pv_reflect_cells_h/3,
    pv_reflect_cells_v/3,
    pv_reflect_cells_diag/3,
    pv_reflect_cells_antidiag/3,
    pv_orbit/3,
    pv_sym_closure/3,
    pv_stamp_at/5
]).

% Import list operations used throughout this module.
:- use_module(library(lists), [member/2, nth0/3, numlist/3, append/3, reverse/2]).
% Import higher-order operations for maplist/3 and foldl/4.
:- use_module(library(apply), [maplist/3, foldl/4]).

% pv_sum_rc_: accumulate R and C sums for foldl in pv_centroid.
pv_sum_rc_(R-C, SR0-SC0, SR1-SC1) :-
    % Add R to row sum and C to column sum.
    SR1 is SR0 + R,
    SC1 is SC0 + C.

% pv_centroid(+Cells, -PR-PC): integer centroid of a non-empty R-C cell list.
% PR = floor(mean(R)), PC = floor(mean(C)). Fails for an empty list.
pv_centroid(Cells, PR-PC) :-
    % Count cells; fail if list is empty.
    length(Cells, N), N > 0,
    % Sum all R and C values.
    foldl(pv_sum_rc_, Cells, 0-0, SR-SC),
    % Integer division gives floor mean for non-negative coordinates.
    PR is SR // N,
    PC is SC // N.

% pv_to_rel(+PR-PC, +R-C, -DR-DC): convert absolute cell to pivot-relative offset.
% DR = R - PR, DC = C - PC. Negative offsets are valid.
pv_to_rel(PR-PC, R-C, DR-DC) :-
    % Subtract pivot from cell coordinates.
    DR is R - PR,
    DC is C - PC.

% pv_from_rel(+PR-PC, +DR-DC, -R-C): convert pivot-relative offset to absolute cell.
% R = PR + DR, C = PC + DC. Inverse of pv_to_rel.
pv_from_rel(PR-PC, DR-DC, R-C) :-
    % Add pivot to relative coordinates.
    R is PR + DR,
    C is PC + DC.

% pv_rotate_cell_cw(+PR-PC, +R-C, -R2-C2): rotate one cell 90 degrees CW around pivot.
% (DR,DC) -> (DC,-DR). Up becomes right, right becomes down.
pv_rotate_cell_cw(PR-PC, R-C, R2-C2) :-
    % Compute offset from pivot.
    DR is R - PR, DC is C - PC,
    % Apply CW rotation formula: new row = pivot row + old DC; new col = pivot col - old DR.
    R2 is PR + DC,
    C2 is PC - DR.

% pv_rotate_cell_180_(+Pivot, +Cell, -Cell2): rotate one cell 180 degrees around pivot.
% (DR,DC) -> (-DR,-DC). Negate both components.
pv_rotate_cell_180_(PR-PC, R-C, R2-C2) :-
    % 180 degrees: reflect through the pivot.
    R2 is 2*PR - R,
    C2 is 2*PC - C.

% pv_rotate_cells_cw(+Pivot, +Cells, -Cells2): rotate a list of cells 90 CW around pivot.
% Applies pv_rotate_cell_cw to each cell in Cells.
pv_rotate_cells_cw(Pivot, Cells, Cells2) :-
    % Map the CW rotation over all cells.
    maplist(pv_rotate_cell_cw(Pivot), Cells, Cells2).

% pv_rotate_cells_180(+Pivot, +Cells, -Cells2): rotate a list of cells 180 degrees around pivot.
% Applies pv_rotate_cell_180_ to each cell.
pv_rotate_cells_180(Pivot, Cells, Cells2) :-
    % Map 180-degree rotation over all cells.
    maplist(pv_rotate_cell_180_(Pivot), Cells, Cells2).

% pv_rotate_cell_ccw_(+Pivot, +Cell, -Cell2): rotate one cell 90 CCW around pivot.
% (DR,DC) -> (-DC,DR). Up becomes left, right becomes up.
pv_rotate_cell_ccw_(PR-PC, R-C, R2-C2) :-
    % Compute offset from pivot.
    DR is R - PR, DC is C - PC,
    % Apply CCW rotation: new row = pivot row - old DC; new col = pivot col + old DR.
    R2 is PR - DC,
    C2 is PC + DR.

% pv_rotate_cells_ccw(+Pivot, +Cells, -Cells2): rotate a list of cells 90 CCW around pivot.
% Applies pv_rotate_cell_ccw_ to each cell.
pv_rotate_cells_ccw(Pivot, Cells, Cells2) :-
    % Map the CCW rotation over all cells.
    maplist(pv_rotate_cell_ccw_(Pivot), Cells, Cells2).

% pv_reflect_cell_h_(+Pivot, +Cell, -Cell2): reflect one cell horizontally around pivot column.
% R stays the same; C -> 2*PC - C. Left and right are swapped across column PC.
% PR (pivot row) is not used; only pivot column PC is needed.
pv_reflect_cell_h_(_PR-PC, R-C, R2-C2) :-
    % Row is unchanged.
    R2 = R,
    % Column is mirrored around the pivot column.
    C2 is 2*PC - C.

% pv_reflect_cells_h(+Pivot, +Cells, -Cells2): reflect a list of cells horizontally.
% Maps pv_reflect_cell_h_ over each cell.
pv_reflect_cells_h(Pivot, Cells, Cells2) :-
    % Map horizontal reflection over all cells.
    maplist(pv_reflect_cell_h_(Pivot), Cells, Cells2).

% pv_reflect_cell_v_(+Pivot, +Cell, -Cell2): reflect one cell vertically around pivot row.
% R -> 2*PR - R; C stays the same. Top and bottom are swapped across row PR.
% PC (pivot column) is not used; only pivot row PR is needed.
pv_reflect_cell_v_(PR-_PC, R-C, R2-C2) :-
    % Row is mirrored around the pivot row.
    R2 is 2*PR - R,
    % Column is unchanged.
    C2 = C.

% pv_reflect_cells_v(+Pivot, +Cells, -Cells2): reflect a list of cells vertically.
% Maps pv_reflect_cell_v_ over each cell.
pv_reflect_cells_v(Pivot, Cells, Cells2) :-
    % Map vertical reflection over all cells.
    maplist(pv_reflect_cell_v_(Pivot), Cells, Cells2).

% pv_reflect_cell_diag_(+Pivot, +Cell, -Cell2): reflect one cell across the main diagonal through pivot.
% (DR,DC) -> (DC,DR). Absolute: (PR+DC, PC+DR).
pv_reflect_cell_diag_(PR-PC, R-C, R2-C2) :-
    % Compute offset from pivot.
    DR is R - PR, DC is C - PC,
    % Diagonal reflection swaps DR and DC.
    R2 is PR + DC,
    C2 is PC + DR.

% pv_reflect_cells_diag(+Pivot, +Cells, -Cells2): reflect a list of cells across main diagonal.
% Maps pv_reflect_cell_diag_ over each cell.
pv_reflect_cells_diag(Pivot, Cells, Cells2) :-
    % Map main-diagonal reflection over all cells.
    maplist(pv_reflect_cell_diag_(Pivot), Cells, Cells2).

% pv_reflect_cell_antidiag_(+Pivot, +Cell, -Cell2): reflect one cell across anti-diagonal through pivot.
% (DR,DC) -> (-DC,-DR). Absolute: (PR-DC, PC-DR).
pv_reflect_cell_antidiag_(PR-PC, R-C, R2-C2) :-
    % Compute offset from pivot.
    DR is R - PR, DC is C - PC,
    % Anti-diagonal reflection negates and swaps DR and DC.
    R2 is PR - DC,
    C2 is PC - DR.

% pv_reflect_cells_antidiag(+Pivot, +Cells, -Cells2): reflect a list of cells across anti-diagonal.
% Maps pv_reflect_cell_antidiag_ over each cell.
pv_reflect_cells_antidiag(Pivot, Cells, Cells2) :-
    % Map anti-diagonal reflection over all cells.
    maplist(pv_reflect_cell_antidiag_(Pivot), Cells, Cells2).

% pv_orbit(+Pivot, +Cell, -Orbit): all distinct D4 orbit positions of Cell around Pivot.
% Orbit is a sorted, deduplicated list. For a general Cell, Orbit has 8 elements;
% for cells on symmetry lines through Pivot, it may have fewer.
pv_orbit(Pivot, Cell, Orbit) :-
    % Apply all 8 D4 transforms (identity + 3 rotations + 4 reflections).
    pv_rotate_cell_cw(Pivot, Cell, CW),
    pv_rotate_cell_180_(Pivot, Cell, C180),
    pv_rotate_cell_ccw_(Pivot, Cell, CCW),
    pv_reflect_cell_h_(Pivot, Cell, RH),
    pv_reflect_cell_v_(Pivot, Cell, RV),
    pv_reflect_cell_diag_(Pivot, Cell, RD),
    pv_reflect_cell_antidiag_(Pivot, Cell, RA),
    % Collect all 8 results including identity (Cell itself).
    sort([Cell, CW, C180, CCW, RH, RV, RD, RA], Orbit).

% pv_sym_closure(+Pivot, +Cells, -Closure): D4 symmetry closure of a cell list around Pivot.
% Closure = sorted unique union of all D4 orbits of every cell in Cells.
pv_sym_closure(Pivot, Cells, Closure) :-
    % For each cell compute its orbit, collect all orbit members.
    findall(OC, (member(C, Cells), pv_orbit(Pivot, C, Orb), member(OC, Orb)), All),
    % Deduplicate and sort.
    sort(All, Closure).

% pv_set_cell_: private helper to write Val at Grid[R][C].
pv_set_cell_(Grid, R, C, Val, Result) :-
    % Split grid into rows before and after row R.
    length(Pre, R),
    append(Pre, [Row|SufRows], Grid),
    % Split the target row at column C.
    length(PreC, C),
    append(PreC, [_|SufCols], Row),
    % Reassemble the row with the new value.
    append(PreC, [Val|SufCols], NewRow),
    % Reassemble the grid with the new row.
    append(Pre, [NewRow|SufRows], Result).

% pv_stamp_at(+Grid, +OffsetCells, +Val, +PR-PC, -Result):
% Paint Val at each position PR+DR-PC+DC for each DR-DC in OffsetCells.
% OffsetCells is a list of DR-DC pairs (relative to pivot PR-PC).
% Positions outside the grid are silently skipped.
pv_stamp_at(Grid, [], _, _, Grid) :- !.
pv_stamp_at(Grid0, [DR-DC|Rest], Val, PR-PC, Result) :-
    % Compute absolute grid position for this offset.
    R is PR + DR, C is PC + DC,
    % Get grid dimensions to check bounds.
    length(Grid0, NR), NR1 is NR - 1,
    (Grid0 = [FR|_] -> length(FR, NC) ; NC = 0),
    NC1 is NC - 1,
    % Paint only if in bounds; skip silently if out of bounds.
    (   between(0, NR1, R), between(0, NC1, C)
    ->  pv_set_cell_(Grid0, R, C, Val, Grid1)
    ;   Grid1 = Grid0
    ),
    % Continue with remaining offsets.
    pv_stamp_at(Grid1, Rest, Val, PR-PC, Result).
