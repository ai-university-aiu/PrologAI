% rotation.pl - Layer 144: Grid Rotation and Rotational Symmetry Detection (ro_* prefix).
% Provides predicates for rotating 2D grids by multiples of 90 degrees clockwise,
% testing and detecting rotational symmetry, rotating cell coordinate sets, combining
% grids through rotation-based overlay (spin), and finding which rotation maps one
% grid to another. These predicates support visual reasoning tasks where objects or
% entire grids undergo quarter-turn transformations.
%
% Rotation conventions (all clockwise):
%   90 CW: (R,C) -> (C, H-1-R). Output dimensions: W rows, H cols.
%  180:   (R,C) -> (H-1-R, W-1-C). Output dimensions: H rows, W cols.
%  270 CW (= 90 CCW): (R,C) -> (W-1-C, R). Output dimensions: W rows, H cols.
:- module(rotation, [
    % rotation_rot90/2: rotate Grid 90 degrees clockwise.
    rotation_rot90/2,
    % rotation_rot180/2: rotate Grid 180 degrees.
    rotation_rot180/2,
    % rotation_rot270/2: rotate Grid 270 degrees clockwise (= 90 counter-clockwise).
    rotation_rot270/2,
    % rotation_rot_n/3: rotate Grid by N*90 degrees clockwise; N in 0..3.
    rotation_rot_n/3,
    % rotation_all/2: produce list of all four rotations [G0, G90, G180, G270].
    rotation_all/2,
    % rotation_canonical/2: lexicographically smallest of the four rotations (canonical form).
    rotation_canonical/2,
    % rotation_is_rot2/1: succeed if Grid is invariant under 180-degree rotation.
    rotation_is_rot2/1,
    % rotation_is_rot4/1: succeed if Grid is invariant under 90-degree rotation.
    rotation_is_rot4/1,
    % rotation_sym_order/2: smallest N in {1,2,4} such that Grid has N-fold rotational symmetry.
    rotation_sym_order/2,
    % rotation_rotate_cells/5: rotate a list of R-C cell coordinates by N*90 CW in an H x W box.
    rotation_rotate_cells/5,
    % rotation_spin2/3: overlay Grid with its 180-degree rotation; non-Bg wins.
    rotation_spin2/3,
    % rotation_spin4/3: overlay all four rotations of Grid; non-Bg wins.
    rotation_spin4/3,
    % rotation_match_rotation/3: find N in 0..3 such that rotation_rot_n(GridA, N, GridB).
    rotation_match_rotation/3,
    % rotation_equiv_rotation/2: succeed if any rotation of GridA equals GridB.
    rotation_equiv_rotation/2
]).

% Import list utilities for column extraction and row-level operations.
:- use_module(library(lists), [member/2, nth0/3, reverse/2]).
% Import maplist for row-level transformations.
:- use_module(library(apply), [maplist/2, maplist/3]).

% rotation_rot90(+Grid, -Out): rotate Grid 90 degrees clockwise.
% Out has W rows and H columns (dimensions are transposed).
% Each new row C of Out is column C of Grid read from the bottom row upward.
% Formula: Out[C][H-1-R] = Grid[R][C], equivalently Out[C] = col C of Grid reversed.
rotation_rot90(Grid, Out) :-
    % Get original height.
    length(Grid, H),
    % Get original width from the first row (0 if empty).
    ( Grid = [FR|_] -> length(FR, W) ; W = 0 ),
    % Maximum row index in the original grid.
    H1 is H - 1,
    % Maximum column index in the original grid (= number of new rows - 1).
    W1 is W - 1,
    % Build each new row by collecting column C of Grid from bottom to top.
    findall(NewRow, (
        between(0, W1, C),
        findall(V, (
            between(0, H1, R),
            % Read from bottom row upward: bottom = H1, top = 0.
            R2 is H1 - R,
            nth0(R2, Grid, GRow),
            nth0(C, GRow, V)
        ), NewRow)
    ), Out).

% rotation_rot180(+Grid, -Out): rotate Grid 180 degrees.
% Out has the same dimensions as Grid.
% Formula: Out[H-1-R][W-1-C] = Grid[R][C].
% Equivalent to reversing each row then reversing the row order.
rotation_rot180(Grid, Out) :-
    % Reverse each row to mirror horizontally.
    maplist(reverse, Grid, Temp),
    % Reverse the row order to complete the 180-degree rotation.
    reverse(Temp, Out).

% rotation_rot270(+Grid, -Out): rotate Grid 270 degrees clockwise (= 90 counter-clockwise).
% Out has W rows and H columns (dimensions are transposed).
% Formula: Out[W-1-C][R] = Grid[R][C], equivalently Out[W1-C] = col C of Grid top to bottom.
rotation_rot270(Grid, Out) :-
    % Get original height.
    length(Grid, H),
    % Get original width.
    ( Grid = [FR|_] -> length(FR, W) ; W = 0 ),
    % Maximum row index.
    H1 is H - 1,
    % Maximum column index (= number of new rows - 1).
    W1 is W - 1,
    % Build each new row by collecting column (W1-C) of Grid from top to bottom.
    findall(NewRow, (
        between(0, W1, C),
        % New row C corresponds to original column W1-C (reversed column index).
        C2 is W1 - C,
        findall(V, (
            between(0, H1, R),
            nth0(R, Grid, GRow),
            nth0(C2, GRow, V)
        ), NewRow)
    ), Out).

% rotation_rot_n(+Grid, +N, -Out): rotate Grid by N*90 degrees clockwise; N in 0..3.
% N=0: identity. N=1: 90 CW. N=2: 180. N=3: 270 CW.
% Uses cuts to prevent choicepoints when N is ground.
rotation_rot_n(Grid, 0, Grid) :- !.
% N=1: delegate to rotation_rot90.
rotation_rot_n(Grid, 1, Out) :-
    !,
    rotation_rot90(Grid, Out).
% N=2: delegate to rotation_rot180.
rotation_rot_n(Grid, 2, Out) :-
    !,
    rotation_rot180(Grid, Out).
% N=3: delegate to rotation_rot270.
rotation_rot_n(Grid, 3, Out) :-
    rotation_rot270(Grid, Out).

% rotation_all(+Grid, -Rots): produce all four rotations as [G0, G90, G180, G270].
% Rots[0] = Grid itself; Rots[1] = 90 CW; Rots[2] = 180; Rots[3] = 270 CW.
rotation_all(Grid, [Grid, G90, G180, G270]) :-
    % Compute 90-degree rotation.
    rotation_rot90(Grid, G90),
    % Compute 180-degree rotation.
    rotation_rot180(Grid, G180),
    % Compute 270-degree rotation.
    rotation_rot270(Grid, G270).

% rotation_canonical(+Grid, -Canon): lexicographically smallest of the four rotations.
% Uses SWI-Prolog's standard term ordering to compare grids as nested lists.
% The canonical form is unique up to the 4-element rotation equivalence class.
rotation_canonical(Grid, Canon) :-
    % Collect all four rotations.
    rotation_all(Grid, Rots),
    % Sort by standard term order; smallest (lexicographically first) comes first.
    msort(Rots, [Canon|_]).

% rotation_is_rot2(+Grid): succeed if Grid is invariant under 180-degree rotation.
% Equivalently: Grid == rotation_rot180(Grid).
rotation_is_rot2(Grid) :-
    % Compute 180-degree rotation.
    rotation_rot180(Grid, Grid180),
    % Check structural equality with original.
    Grid == Grid180.

% rotation_is_rot4(+Grid): succeed if Grid is invariant under 90-degree rotation.
% Equivalently: Grid == rotation_rot90(Grid). Requires Grid to be square (H == W).
rotation_is_rot4(Grid) :-
    % Compute 90-degree rotation.
    rotation_rot90(Grid, Grid90),
    % Check structural equality with original.
    Grid == Grid90.

% rotation_sym_order(+Grid, -N): smallest N in {1, 2, 4} such that Grid has N-fold symmetry.
% N=4 means Grid is invariant under 90 CW (4-fold). N=2 means invariant under 180
% but not 90 (2-fold). N=1 means no rotational symmetry (only full 360 = identity).
rotation_sym_order(Grid, 4) :-
    % 4-fold check first: invariant under 90 CW.
    rotation_is_rot4(Grid),
    % Cut: no need to check weaker orders.
    !.
rotation_sym_order(Grid, 2) :-
    % 2-fold check: invariant under 180 degrees.
    rotation_is_rot2(Grid),
    % Cut: no need to fall through to order 1.
    !.
% Fallback: no non-trivial rotational symmetry.
rotation_sym_order(_, 1).

% rotation_rotate_cells(+Cells, +H, +W, +N, -Out): rotate a list of R-C pairs by N*90 CW.
% H and W are the bounding box dimensions of the coordinate space.
% N=0: identity. N=1: (R,C) -> (C, H-1-R). N=2: (R,C) -> (H-1-R, W-1-C).
% N=3: (R,C) -> (W-1-C, R).
% For N=1 and N=3, the new coordinate space has dimensions W x H (transposed).
rotation_rotate_cells(Cells, H, W, N, Out) :-
    % Compute one-less-than indices for boundary calculations.
    H1 is H - 1,
    W1 is W - 1,
    % Map each input cell to its rotated position.
    findall(NR-NC, (
        member(R-C, Cells),
        rotation_apply_cell_(N, R, C, H1, W1, NR, NC)
    ), Out).

% rotation_apply_cell_(+N, +R, +C, +H1, +W1, -NR, -NC): apply rotation N to one cell.
% H1 = H-1, W1 = W-1 (precomputed for efficiency).
% N=0: identity.
rotation_apply_cell_(0, R, C, _, _, R, C).
% N=1 (90 CW): new row = old col C; new col = H-1 - old row.
rotation_apply_cell_(1, R, C, H1, _, C, NC) :-
    NC is H1 - R.
% N=2 (180): new row = H-1 - old row; new col = W-1 - old col.
rotation_apply_cell_(2, R, C, H1, W1, NR, NC) :-
    NR is H1 - R,
    NC is W1 - C.
% N=3 (270 CW = 90 CCW): new row = W-1 - old col; new col = old row R.
rotation_apply_cell_(3, R, C, _, W1, NR, R) :-
    NR is W1 - C.

% rotation_overlay_bg_(+Bg, +VA, +VB, -V): overlay two cell values with background priority.
% If VA is not background then VA wins; otherwise VB is used.
% This is the same semantics as fd_overlay_cell_ in the fold pack, implemented locally.
rotation_overlay_bg_(Bg, VA, _VB, VA) :-
    % Non-background A value takes priority.
    VA \= Bg,
    % Cut prevents the fallback clause.
    !.
% Fallback: A is background, so B value is used.
rotation_overlay_bg_(_Bg, _VA, VB, VB).

% rotation_overlay_grids_(+A, +B, +Bg, -Out): cell-by-cell overlay of two same-size grids.
% Uses rotation_overlay_bg_ for each cell. A takes priority over B.
rotation_overlay_grids_([], [], _, []).
% Process one row at a time.
rotation_overlay_grids_([RowA|RestA], [RowB|RestB], Bg, [RowOut|RestOut]) :-
    % Overlay the current pair of rows.
    rotation_overlay_rows_(RowA, RowB, Bg, RowOut),
    % Recurse for the remaining rows.
    rotation_overlay_grids_(RestA, RestB, Bg, RestOut).

% rotation_overlay_rows_(+RowA, +RowB, +Bg, -RowOut): overlay two rows cell by cell.
rotation_overlay_rows_([], [], _, []).
% Process one cell at a time.
rotation_overlay_rows_([VA|RestA], [VB|RestB], Bg, [V|RestOut]) :-
    % Apply background-priority overlay to this cell.
    rotation_overlay_bg_(Bg, VA, VB, V),
    % Recurse for remaining cells.
    rotation_overlay_rows_(RestA, RestB, Bg, RestOut).

% rotation_spin2(+Grid, +Bg, -Out): overlay Grid with its 180-degree rotation.
% Non-background cells of the original Grid take priority.
% Where both are background, the result is background.
rotation_spin2(Grid, Bg, Out) :-
    % Compute 180-degree rotation.
    rotation_rot180(Grid, Grid180),
    % Overlay original over rotated copy.
    rotation_overlay_grids_(Grid, Grid180, Bg, Out).

% rotation_spin4(+Grid, +Bg, -Out): overlay all four rotations of Grid.
% The original Grid takes highest priority; then 90, 180, 270 in order.
% Useful for completing a grid using 4-fold rotational symmetry.
rotation_spin4(Grid, Bg, Out) :-
    % Compute all rotations.
    rotation_rot90(Grid, G90),
    rotation_rot180(Grid, G180),
    rotation_rot270(Grid, G270),
    % Overlay Grid over G90.
    rotation_overlay_grids_(Grid, G90, Bg, Step1),
    % Overlay Step1 over G180.
    rotation_overlay_grids_(Step1, G180, Bg, Step2),
    % Overlay Step2 over G270.
    rotation_overlay_grids_(Step2, G270, Bg, Out).

% rotation_match_rotation(+GridA, +GridB, -N): find N in 0..3 such that rotation_rot_n(GridA,N) = GridB.
% Returns the first N found. Fails if no rotation of GridA equals GridB.
rotation_match_rotation(GridA, GridB, N) :-
    % Try each rotation index in order 0, 1, 2, 3.
    between(0, 3, N),
    rotation_rot_n(GridA, N, GridB),
    % Cut after the first match.
    !.

% rotation_equiv_rotation(+GridA, +GridB): succeed if any rotation of GridA equals GridB.
% Convenience wrapper around rotation_match_rotation/3 that discards the index.
rotation_equiv_rotation(GridA, GridB) :-
    rotation_match_rotation(GridA, GridB, _).
