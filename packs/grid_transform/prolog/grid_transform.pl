:- module(grid_transform, [
    grid_transform_rotate90/2,
    grid_transform_rotate180/2,
    grid_transform_rotate270/2,
    grid_transform_flip_h/2,
    grid_transform_flip_v/2,
    grid_transform_transpose/2,
    grid_transform_flip_d2/2,
    grid_transform_crop/6,
    grid_transform_crop_content/3,
    grid_transform_pad/7,
    grid_transform_scale/3,
    grid_transform_tile/4,
    grid_transform_d4_group/2,
    grid_transform_normalize/2
]).
% gridxform.pl - Layer 207: Grid Transformations - rotate, flip, transpose,
% crop, pad, scale, tile, and D4 canonical form (gx_* prefix).
% All predicates operate on raw grid format: list of rows, each a list of
% color atoms, 0-indexed (row 0 = top, col 0 = left).
:- use_module(library(lists), [
    nth0/3, member/2, min_list/2, max_list/2
]).

% --- PRIVATE HELPERS ---

% Grid dimensions: H rows, W columns.
grid_transform_dims_(Grid, H, W) :-
% Length of the row list gives the number of rows.
    length(Grid, H),
% If at least one row exists, its length is the column count.
    (H > 0 -> Grid = [FR|_], length(FR, W) ; W = 0).

% Cell value at row R, column C (0-indexed).
grid_transform_cell_(Grid, R, C, V) :-
% Select row R from the grid.
    nth0(R, Grid, Row),
% Select column C from the row.
    nth0(C, Row, V).

% Build a new grid with NewH rows and NewW columns using Goal(R,C,V).
% Goal is called as call(Goal, R, C, V) for each (R, C) position.
grid_transform_build_(NewH, NewW, Goal, Grid) :-
% Compute last row and column indices.
    NewH1 is NewH - 1,
% Compute last column index.
    NewW1 is NewW - 1,
% Collect all rows by ranging R over [0..NewH1].
    findall(Row,
        (between(0, NewH1, R),
% Collect cell values for each row by ranging C over [0..NewW1].
         findall(V, (between(0, NewW1, C), call(Goal, R, C, V)), Row)),
        Grid).

% --- ROTATIONS ---

% grid_transform_rotate90(+Grid, -Result)
% Rotate Grid 90 degrees clockwise. An H x W grid becomes W x H.
% result[R][C] = original[H-1-C][R].
grid_transform_rotate90(Grid, Result) :-
% Get original dimensions.
    grid_transform_dims_(Grid, H, W),
% Precompute H-1 for use in the lambda.
    H1 is H - 1,
% Build W x H result; map each (R,C) to original row H1-C, col R.
    grid_transform_build_(W, H,
        [R, C, V]>>(OR is H1 - C, grid_transform_cell_(Grid, OR, R, V)),
        Result).

% grid_transform_rotate180(+Grid, -Result)
% Rotate Grid 180 degrees. Result has same dimensions as Grid.
% result[R][C] = original[H-1-R][W-1-C].
grid_transform_rotate180(Grid, Result) :-
% Get original dimensions.
    grid_transform_dims_(Grid, H, W),
% Precompute H-1 and W-1 for use in the lambda.
    H1 is H - 1,
% Precompute W-1.
    W1 is W - 1,
% Build same-size result; flip both row and column indices.
    grid_transform_build_(H, W,
        [R, C, V]>>(OR is H1 - R, OC is W1 - C, grid_transform_cell_(Grid, OR, OC, V)),
        Result).

% grid_transform_rotate270(+Grid, -Result)
% Rotate Grid 270 degrees clockwise (equal to 90 degrees counter-clockwise).
% An H x W grid becomes W x H.
% result[R][C] = original[C][W-1-R].
grid_transform_rotate270(Grid, Result) :-
% Get original dimensions.
    grid_transform_dims_(Grid, H, W),
% Precompute W-1 for use in the lambda.
    W1 is W - 1,
% Build W x H result; map each (R,C) to original row C, col W1-R.
    grid_transform_build_(W, H,
        [R, C, V]>>(OC is W1 - R, grid_transform_cell_(Grid, C, OC, V)),
        Result).

% --- REFLECTIONS ---

% grid_transform_flip_h(+Grid, -Result)
% Flip Grid horizontally (left-right mirror). Same dimensions.
% result[R][C] = original[R][W-1-C].
grid_transform_flip_h(Grid, Result) :-
% Get original dimensions.
    grid_transform_dims_(Grid, H, W),
% Precompute W-1 for column reversal.
    W1 is W - 1,
% Build same-size result; mirror each column index.
    grid_transform_build_(H, W,
        [R, C, V]>>(OC is W1 - C, grid_transform_cell_(Grid, R, OC, V)),
        Result).

% grid_transform_flip_v(+Grid, -Result)
% Flip Grid vertically (top-bottom mirror). Same dimensions.
% result[R][C] = original[H-1-R][C].
grid_transform_flip_v(Grid, Result) :-
% Get original dimensions.
    grid_transform_dims_(Grid, H, W),
% Precompute H-1 for row reversal.
    H1 is H - 1,
% Build same-size result; mirror each row index.
    grid_transform_build_(H, W,
        [R, C, V]>>(OR is H1 - R, grid_transform_cell_(Grid, OR, C, V)),
        Result).

% grid_transform_transpose(+Grid, -Result)
% Transpose Grid along the main diagonal: (r,c) -> (c,r).
% An H x W grid becomes W x H.
% result[R][C] = original[C][R].
grid_transform_transpose(Grid, Result) :-
% Get original dimensions.
    grid_transform_dims_(Grid, H, W),
% Build W x H result; swap row and column in the lookup.
    grid_transform_build_(W, H,
        [R, C, V]>>grid_transform_cell_(Grid, C, R, V),
        Result).

% grid_transform_flip_d2(+Grid, -Result)
% Flip Grid along the anti-diagonal: (r,c) -> (W-1-c, H-1-r).
% An H x W grid becomes W x H.
% result[R][C] = original[H-1-C][W-1-R].
grid_transform_flip_d2(Grid, Result) :-
% Get original dimensions.
    grid_transform_dims_(Grid, H, W),
% Precompute H-1 and W-1 for anti-diagonal mapping.
    H1 is H - 1,
% Precompute W-1.
    W1 is W - 1,
% Build W x H result; map each (R,C) to original row H1-C, col W1-R.
    grid_transform_build_(W, H,
        [R, C, V]>>(OR is H1 - C, OC is W1 - R, grid_transform_cell_(Grid, OR, OC, V)),
        Result).

% --- CROP AND PAD ---

% grid_transform_crop(+Grid, +R0, +C0, +R1, +C1, -Result)
% Extract a rectangular sub-grid spanning rows [R0..R1] x cols [C0..C1].
% Both bounds are inclusive. Result has (R1-R0+1) rows and (C1-C0+1) cols.
grid_transform_crop(Grid, R0, C0, R1, C1, Result) :-
% Compute output dimensions.
    NewH is R1 - R0 + 1,
% Compute output column count.
    NewW is C1 - C0 + 1,
% Build output; each (R,C) maps to original (R0+R, C0+C).
    grid_transform_build_(NewH, NewW,
        [R, C, V]>>(OR is R0 + R, OC is C0 + C, grid_transform_cell_(Grid, OR, OC, V)),
        Result).

% grid_transform_crop_content(+Grid, +BgColor, -Result)
% Auto-crop Grid to the tight bounding box of all non-BgColor cells.
% If Grid contains no non-BgColor cells, Result = Grid unchanged.
grid_transform_crop_content(Grid, BgColor, Result) :-
% Get grid dimensions.
    grid_transform_dims_(Grid, H, W),
% Compute last row and column indices.
    H1 is H - 1,
% Compute last column index.
    W1 is W - 1,
% Collect all (R,C) positions whose cell value differs from BgColor.
    findall(R-C,
        (between(0, H1, R), between(0, W1, C),
         grid_transform_cell_(Grid, R, C, V), V \= BgColor),
        Cells),
% If no non-background cells exist, return the grid unchanged.
    (Cells = [] ->
        Result = Grid
    ;
% Extract all row indices from the non-background cell list.
        findall(R, member(R-_, Cells), Rs),
% Extract all column indices from the non-background cell list.
        findall(C, member(_-C, Cells), Cs),
% Find minimum and maximum row values.
        min_list(Rs, MinR),
% Find maximum row value.
        max_list(Rs, MaxR),
% Find minimum column value.
        min_list(Cs, MinC),
% Find maximum column value.
        max_list(Cs, MaxC),
% Crop to the tight bounding box.
        grid_transform_crop(Grid, MinR, MinC, MaxR, MaxC, Result)
    ).

% grid_transform_pad(+Grid, +Top, +Bot, +Left, +Right, +BgColor, -Result)
% Pad Grid with BgColor: Top rows added above, Bot rows below,
% Left columns to the left, Right columns to the right.
grid_transform_pad(Grid, Top, Bot, Left, Right, BgColor, Result) :-
% Get original grid dimensions.
    grid_transform_dims_(Grid, H, W),
% Compute padded output dimensions.
    NewH is H + Top + Bot,
% Compute padded column count.
    NewW is W + Left + Right,
% Build padded grid: shift (R,C) by (Top,Left) to get original (OR,OC).
    grid_transform_build_(NewH, NewW,
        [R, C, V]>>(OR is R - Top, OC is C - Left,
                    (OR >= 0, OR < H, OC >= 0, OC < W ->
                        grid_transform_cell_(Grid, OR, OC, V)
                    ;
                        V = BgColor)),
        Result).

% --- SCALE AND TILE ---

% grid_transform_scale(+Grid, +N, -Result)
% Scale Grid up by integer factor N: each cell becomes an N x N block.
% An H x W grid becomes (H*N) x (W*N).
grid_transform_scale(Grid, N, Result) :-
% Get original grid dimensions.
    grid_transform_dims_(Grid, H, W),
% Compute scaled output dimensions.
    NewH is H * N,
% Compute scaled column count.
    NewW is W * N,
% Build scaled grid: divide (R,C) by N to find originating cell.
    grid_transform_build_(NewH, NewW,
        [R, C, V]>>(OR is R // N, OC is C // N, grid_transform_cell_(Grid, OR, OC, V)),
        Result).

% grid_transform_tile(+Grid, +H, +W, -Result)
% Tile Grid to fill an H x W output. Grid is the repeating unit.
% result[R][C] = original[R mod TileH][C mod TileW].
grid_transform_tile(Grid, H, W, Result) :-
% Get tile dimensions.
    grid_transform_dims_(Grid, TH, TW),
% Build tiled output using modular indexing into the tile.
    grid_transform_build_(H, W,
        [R, C, V]>>(OR is R mod TH, OC is C mod TW, grid_transform_cell_(Grid, OR, OC, V)),
        Result).

% --- D4 SYMMETRY GROUP ---

% grid_transform_d4_group(+Grid, -Transforms)
% Transforms is the list of all 8 D4 isometries of Grid in the order:
% [identity, rotate90, rotate180, rotate270, flip_h, flip_v, transpose, flip_d2].
grid_transform_d4_group(Grid, Transforms) :-
% Compute all three non-trivial rotations.
    grid_transform_rotate90(Grid, R90),
% Compute 180-degree rotation.
    grid_transform_rotate180(Grid, R180),
% Compute 270-degree rotation.
    grid_transform_rotate270(Grid, R270),
% Compute horizontal flip.
    grid_transform_flip_h(Grid, FH),
% Compute vertical flip.
    grid_transform_flip_v(Grid, FV),
% Compute main-diagonal transpose.
    grid_transform_transpose(Grid, T),
% Compute anti-diagonal flip.
    grid_transform_flip_d2(Grid, FD2),
% Assemble all 8 transforms in a fixed order.
    Transforms = [Grid, R90, R180, R270, FH, FV, T, FD2].

% grid_transform_normalize(+Grid, -Canon)
% Canon is the lexicographically smallest grid among all 8 D4 isometries.
% Two grids are equivalent under rotation/reflection iff they share the same Canon.
grid_transform_normalize(Grid, Canon) :-
% Compute all 8 D4 isometries.
    grid_transform_d4_group(Grid, Transforms),
% Sort using standard term order (lexicographic on lists of lists of atoms).
    msort(Transforms, [Canon|_]).
