% objop.pl - Layer 148: Object-Level Manipulation within 2D Grids (oo_* prefix).
% Provides a unified workflow for identifying grid objects by color, analyzing
% their bounding boxes, and applying in-place transformations (rotation, mirroring,
% translation, copy) all within the dense 2D grid representation.
% Unlike cellset (sparse R-C lists) this pack accepts and returns full grids,
% making it directly usable without converting between representations.
:- module(objop, [
    % objop_cells_of/3: sorted R-C pairs where the grid holds value V.
    objop_cells_of/3,
    % objop_bbox/5: bounding box (R0, C0, R1, C1) of a list of R-C cells.
    objop_bbox/5,
    % objop_count/3: number of cells in Grid with value V.
    objop_count/3,
    % objop_size/4: bounding box height H and width W of V cells.
    objop_size/4,
    % objop_center/4: center row R and col C of the V cells bounding box (integer division).
    objop_center/4,
    % objop_erase/4: replace all V cells with background Bg.
    objop_erase/4,
    % objop_repaint/4: replace all V cells with new value NewV.
    objop_repaint/4,
    % objop_swap/4: exchange all V1 and V2 cells.
    objop_swap/4,
    % objop_move/6: translate V cells by (DR, DC), clipping cells that leave the grid.
    objop_move/6,
    % objop_copy/5: copy V cells to offset (DR, DC); original V cells remain.
    objop_copy/5,
    % objop_rotate90/4: rotate V cells 90 degrees CW around their bounding box top-left.
    objop_rotate90/4,
    % objop_rotate180/4: rotate V cells 180 degrees around their bounding box center.
    objop_rotate180/4,
    % objop_mirror_h/4: flip V cells horizontally within their bounding box.
    objop_mirror_h/4,
    % objop_mirror_v/4: flip V cells vertically within their bounding box.
    objop_mirror_v/4
]).

% Import list utilities; length/2, findall/3, between/3, sort/2 are built-ins.
:- use_module(library(lists), [member/2, memberchk/2, nth0/3, min_list/2, max_list/2]).

% objop_dims_(+Grid, -H, -W): dimensions of Grid.
objop_dims_(Grid, H, W) :-
% Row count via length.
    length(Grid, H),
% Column count from first row; 0 for empty grid.
    ( H > 0 -> Grid = [FR|_], length(FR, W) ; W = 0 ).

% objop_cells_of(+Grid, +V, -Cells): sorted list of R-C pairs where Grid[R][C] = V.
objop_cells_of(Grid, V, Cells) :-
% Get grid dimensions.
    objop_dims_(Grid, H, W),
% Compute inclusive upper bounds.
    H1 is H - 1,
    W1 is W - 1,
% Collect all matching positions.
    findall(R-C, (
        between(0, H1, R),
        between(0, W1, C),
        nth0(R, Grid, Row),
        nth0(C, Row, V)
    ), Unsorted),
% Sort to produce canonical order and remove any duplicates.
    sort(Unsorted, Cells).

% objop_bbox(+Cells, -R0, -C0, -R1, -C1): bounding box of a non-empty cell list.
objop_bbox(Cells, R0, C0, R1, C1) :-
% Extract all row indices.
    findall(R, member(R-_, Cells), Rs),
% Extract all column indices.
    findall(C, member(_-C, Cells), Cs),
% Bounding box corners.
    min_list(Rs, R0), max_list(Rs, R1),
    min_list(Cs, C0), max_list(Cs, C1).

% objop_count(+Grid, +V, -N): number of cells in Grid with value V.
objop_count(Grid, V, N) :-
% Collect matching cells.
    objop_cells_of(Grid, V, Cells),
% N = length of that list.
    length(Cells, N).

% objop_size(+Grid, +V, -H, -W): bounding box height H and width W of V cells.
objop_size(Grid, V, H, W) :-
% Get V cell positions.
    objop_cells_of(Grid, V, Cells),
% Get bounding box.
    objop_bbox(Cells, R0, C0, R1, C1),
% Compute height and width.
    H is R1 - R0 + 1,
    W is C1 - C0 + 1.

% objop_center(+Grid, +V, -R, -C): center row R and column C of V cells bbox.
% Uses integer division so the result is always an integer.
objop_center(Grid, V, R, C) :-
% Get V cell positions.
    objop_cells_of(Grid, V, Cells),
% Get bounding box.
    objop_bbox(Cells, R0, C0, R1, C1),
% Center via integer division.
    R is (R0 + R1) // 2,
    C is (C0 + C1) // 2.

% objop_set_cells_(+Grid, +Cells, +Val, -Out): set all Cells positions to Val.
% Does a full grid scan and replaces matching positions. O(H*W*|Cells|).
objop_set_cells_(Grid, Cells, Val, Out) :-
% Get grid dimensions.
    objop_dims_(Grid, H, W),
% Compute upper bounds.
    H1 is H - 1,
    W1 is W - 1,
% Build output row by row.
    findall(NewRow, (
        between(0, H1, R),
        nth0(R, Grid, OldRow),
% Build each row cell by cell.
        findall(NewV, (
            between(0, W1, C),
            nth0(C, OldRow, OldV),
% Replace value if this cell is in Cells.
            ( memberchk(R-C, Cells) -> NewV = Val ; NewV = OldV )
        ), NewRow)
    ), Out).

% objop_erase(+Grid, +V, +Bg, -Out): replace all V cells in Grid with Bg.
objop_erase(Grid, V, Bg, Out) :-
% Collect all V cell positions.
    objop_cells_of(Grid, V, Cells),
% Set those positions to Bg.
    objop_set_cells_(Grid, Cells, Bg, Out).

% objop_repaint(+Grid, +V, +NewV, -Out): replace all V cells with NewV.
objop_repaint(Grid, V, NewV, Out) :-
% Collect all V cell positions.
    objop_cells_of(Grid, V, Cells),
% Set those positions to NewV.
    objop_set_cells_(Grid, Cells, NewV, Out).

% objop_swap(+Grid, +V1, +V2, -Out): exchange all V1 and V2 cells.
% V1 cells become V2 and V2 cells become V1. Non-overlapping colors only.
objop_swap(Grid, V1, V2, Out) :-
% Collect V1 positions.
    objop_cells_of(Grid, V1, Cells1),
% Collect V2 positions.
    objop_cells_of(Grid, V2, Cells2),
% First, set all V1 positions to V2.
    objop_set_cells_(Grid, Cells1, V2, Grid1),
% Then, set all V2 positions to V1.
    objop_set_cells_(Grid1, Cells2, V1, Out).

% objop_move(+Grid, +V, +DR, +DC, +Bg, -Out): translate V cells by (DR, DC).
% Old V cells are erased to Bg; new cells land at (R+DR, C+DC).
% Cells that would leave the grid bounds are clipped (not drawn).
objop_move(Grid, V, DR, DC, Bg, Out) :-
% Collect V cell positions.
    objop_cells_of(Grid, V, Cells),
% Erase original V cells.
    objop_set_cells_(Grid, Cells, Bg, Grid1),
% Compute new positions and keep only in-bounds cells.
    objop_dims_(Grid, H, W),
    H1 is H - 1, W1 is W - 1,
    findall(NewR-NewC, (
        member(R-C, Cells),
        NewR is R + DR, NewC is C + DC,
        between(0, H1, NewR), between(0, W1, NewC)
    ), NewCells),
% Paint V at new positions.
    objop_set_cells_(Grid1, NewCells, V, Out).

% objop_copy(+Grid, +V, +DR, +DC, -Out): copy V cells to offset (DR, DC).
% The original V cells remain; V is also painted at (R+DR, C+DC) for each V cell.
% Cells that would leave the grid bounds are clipped (not drawn).
objop_copy(Grid, V, DR, DC, Out) :-
% Collect V cell positions.
    objop_cells_of(Grid, V, Cells),
% Compute offset positions, keeping in-bounds cells.
    objop_dims_(Grid, H, W),
    H1 is H - 1, W1 is W - 1,
    findall(NewR-NewC, (
        member(R-C, Cells),
        NewR is R + DR, NewC is C + DC,
        between(0, H1, NewR), between(0, W1, NewC)
    ), NewCells),
% Paint V at the offset positions (original cells already have V).
    objop_set_cells_(Grid, NewCells, V, Out).

% objop_rotate90_cells_(+Cells, +R0, +C0, +H1, -NewCells): apply 90 CW rotation.
% Formula (normalized): (r, c) -> (c, H-1-r) where r=R-R0, c=C-C0.
% Denormalized: NewR = R0+c, NewC = C0+H1-r.
objop_rotate90_cells_(Cells, R0, C0, H1, NewCells) :-
    findall(NewR-NewC, (
        member(R-C, Cells),
        Nr is R - R0,
        Nc is C - C0,
        NewR is R0 + Nc,
        NewC is C0 + H1 - Nr
    ), NewCells).

% objop_rotate90(+Grid, +V, +Bg, -Out): rotate V cells 90 degrees CW.
% The rotation is around the top-left corner of V cells' bounding box.
% Old V cells are cleared to Bg; rotated cells are painted V.
objop_rotate90(Grid, V, Bg, Out) :-
% Collect V cell positions.
    objop_cells_of(Grid, V, Cells),
% Compute bounding box.
    objop_bbox(Cells, R0, C0, R1, _C1),
% Height of bounding box (needed for 90 CW formula).
    H is R1 - R0 + 1,
    H1 is H - 1,
% Compute rotated positions.
    objop_rotate90_cells_(Cells, R0, C0, H1, NewCells),
% Erase original cells.
    objop_set_cells_(Grid, Cells, Bg, Grid1),
% Paint rotated cells.
    objop_set_cells_(Grid1, NewCells, V, Out).

% objop_rotate180_cells_(+Cells, +R0, +C0, +H1, +W1, -NewCells): apply 180 rotation.
% Formula (normalized): (r, c) -> (H-1-r, W-1-c) where r=R-R0, c=C-C0.
% Denormalized: NewR = R0+H1-r, NewC = C0+W1-c.
objop_rotate180_cells_(Cells, R0, C0, H1, W1, NewCells) :-
    findall(NewR-NewC, (
        member(R-C, Cells),
        Nr is R - R0,
        Nc is C - C0,
        NewR is R0 + H1 - Nr,
        NewC is C0 + W1 - Nc
    ), NewCells).

% objop_rotate180(+Grid, +V, +Bg, -Out): rotate V cells 180 degrees in place.
% The bounding box stays the same; cells are repositioned within it.
objop_rotate180(Grid, V, Bg, Out) :-
% Collect V cell positions.
    objop_cells_of(Grid, V, Cells),
% Compute bounding box.
    objop_bbox(Cells, R0, C0, R1, C1),
% Compute bounding box dimensions minus 1.
    H1 is R1 - R0,
    W1 is C1 - C0,
% Compute rotated positions.
    objop_rotate180_cells_(Cells, R0, C0, H1, W1, NewCells),
% Erase original cells.
    objop_set_cells_(Grid, Cells, Bg, Grid1),
% Paint rotated cells.
    objop_set_cells_(Grid1, NewCells, V, Out).

% objop_mirror_h_cells_(+Cells, +R0, +C0, +W1, -NewCells): apply horizontal flip.
% Formula (normalized): (r, c) -> (r, W-1-c) where r=R-R0, c=C-C0.
% Denormalized: NewR = R, NewC = C0+W1-c.
objop_mirror_h_cells_(Cells, _R0, C0, W1, NewCells) :-
    findall(NewR-NewC, (
        member(R-C, Cells),
        Nc is C - C0,
        NewR is R,
        NewC is C0 + W1 - Nc
    ), NewCells).

% objop_mirror_h(+Grid, +V, +Bg, -Out): flip V cells left-right within their bounding box.
objop_mirror_h(Grid, V, Bg, Out) :-
% Collect V cell positions.
    objop_cells_of(Grid, V, Cells),
% Compute bounding box.
    objop_bbox(Cells, R0, C0, _R1, C1),
% Width of bounding box minus 1.
    W1 is C1 - C0,
% Compute flipped positions.
    objop_mirror_h_cells_(Cells, R0, C0, W1, NewCells),
% Erase original cells.
    objop_set_cells_(Grid, Cells, Bg, Grid1),
% Paint flipped cells.
    objop_set_cells_(Grid1, NewCells, V, Out).

% objop_mirror_v_cells_(+Cells, +R0, +C0, +H1, -NewCells): apply vertical flip.
% Formula (normalized): (r, c) -> (H-1-r, c) where r=R-R0.
% Denormalized: NewR = R0+H1-r, NewC = C.
objop_mirror_v_cells_(Cells, R0, _C0, H1, NewCells) :-
    findall(NewR-NewC, (
        member(R-C, Cells),
        Nr is R - R0,
        NewR is R0 + H1 - Nr,
        NewC is C
    ), NewCells).

% objop_mirror_v(+Grid, +V, +Bg, -Out): flip V cells top-bottom within their bounding box.
objop_mirror_v(Grid, V, Bg, Out) :-
% Collect V cell positions.
    objop_cells_of(Grid, V, Cells),
% Compute bounding box.
    objop_bbox(Cells, R0, C0, R1, _C1),
% Height of bounding box minus 1.
    H1 is R1 - R0,
% Compute flipped positions.
    objop_mirror_v_cells_(Cells, R0, C0, H1, NewCells),
% Erase original cells.
    objop_set_cells_(Grid, Cells, Bg, Grid1),
% Paint flipped cells.
    objop_set_cells_(Grid1, NewCells, V, Out).
