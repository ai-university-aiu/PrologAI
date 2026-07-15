:- module(grid_symmetry, [
    grid_symmetry_sym_h/1,
    grid_symmetry_sym_v/1,
    grid_symmetry_sym_d1/1,
    grid_symmetry_sym_d2/1,
    grid_symmetry_sym_rot90/1,
    grid_symmetry_sym_rot180/1,
    grid_symmetry_symmetries/2,
    grid_symmetry_complete_h/3,
    grid_symmetry_complete_v/3,
    grid_symmetry_complete_rot180/3,
    grid_symmetry_violations_h/2,
    grid_symmetry_violations_v/2,
    grid_symmetry_violations_rot180/2,
    grid_symmetry_score/3
]).
% gridsymm.pl - Layer 208: Grid Symmetry - test horizontal, vertical, diagonal,
% and rotational symmetry; complete a grid to a target symmetry; enumerate
% cells that violate a symmetry; compute symmetry score (gsm_* prefix).
% Operates on raw grid format: list of rows, each a list of color atoms, 0-indexed.
:- use_module(library(lists), [nth0/3, member/2]).

% --- PRIVATE HELPERS ---

% Grid dimensions: H rows, W columns.
grid_symmetry_dims_(Grid, H, W) :-
% Count rows.
    length(Grid, H),
% Count columns from first row.
    (H > 0 -> Grid = [FR|_], length(FR, W) ; W = 0).

% Cell value at row R, column C (0-indexed).
grid_symmetry_cell_(Grid, R, C, V) :-
% Select row R.
    nth0(R, Grid, Row),
% Select column C.
    nth0(C, Row, V).

% Build a new H x W grid by calling Goal(R, C, V) for each cell.
grid_symmetry_build_(H, W, Goal, Grid) :-
% Compute last row and column indices.
    H1 is H - 1,
% Compute last column index.
    W1 is W - 1,
% Collect all rows.
    findall(Row,
        (between(0, H1, R),
         findall(V, (between(0, W1, C), call(Goal, R, C, V)), Row)),
        Grid).

% --- SYMMETRY TESTS ---

% grid_symmetry_sym_h(+Grid)
% Succeed if Grid is symmetric about its horizontal (left-right) axis,
% i.e., Grid[R][C] = Grid[H-1-R][C] for all R, C.
% This is called top-bottom or vertical-mirror symmetry.
grid_symmetry_sym_h(Grid) :-
% Get dimensions.
    grid_symmetry_dims_(Grid, H, W),
% Compute bounds.
    H1 is H - 1,
% Only need to check the top half of row pairs.
    MaxR is (H - 2) // 2,
% Precompute W-1 for column iteration.
    W1 is W - 1,
% Fail if any top-half row does not match its mirror.
    \+ (between(0, MaxR, R),
        between(0, W1, C),
        R2 is H1 - R,
        grid_symmetry_cell_(Grid, R, C, V1),
        grid_symmetry_cell_(Grid, R2, C, V2),
        V1 \= V2).

% grid_symmetry_sym_v(+Grid)
% Succeed if Grid is symmetric about its vertical (top-bottom) axis,
% i.e., Grid[R][C] = Grid[R][W-1-C] for all R, C.
% This is called left-right or horizontal-mirror symmetry.
grid_symmetry_sym_v(Grid) :-
% Get dimensions.
    grid_symmetry_dims_(Grid, H, W),
% Compute bounds.
    H1 is H - 1,
% Only need to check the left half of column pairs.
    MaxC is (W - 2) // 2,
% Precompute W-1.
    W1 is W - 1,
% Fail if any left-half column does not match its mirror.
    \+ (between(0, H1, R),
        between(0, MaxC, C),
        C2 is W1 - C,
        grid_symmetry_cell_(Grid, R, C, V1),
        grid_symmetry_cell_(Grid, R, C2, V2),
        V1 \= V2).

% grid_symmetry_sym_d1(+Grid)
% Succeed if Grid is symmetric about the main diagonal (transpose = self).
% Only meaningful for square grids; fails for non-square grids.
% Grid[R][C] = Grid[C][R] for all R, C.
grid_symmetry_sym_d1(Grid) :-
% Get dimensions.
    grid_symmetry_dims_(Grid, H, W),
% Fail immediately for non-square grids.
    H =:= W,
% Compute H-1.
    H1 is H - 1,
% Check only upper-triangle cells (R < C).
    \+ (between(0, H1, R),
        between(0, H1, C),
        R < C,
        grid_symmetry_cell_(Grid, R, C, V1),
        grid_symmetry_cell_(Grid, C, R, V2),
        V1 \= V2).

% grid_symmetry_sym_d2(+Grid)
% Succeed if Grid is symmetric about the anti-diagonal.
% Only meaningful for square grids; fails for non-square grids.
% Grid[R][C] = Grid[H-1-C][H-1-R] for all R, C.
grid_symmetry_sym_d2(Grid) :-
% Get dimensions.
    grid_symmetry_dims_(Grid, H, W),
% Fail for non-square grids.
    H =:= W,
% Compute H-1.
    H1 is H - 1,
% Check only cells in the upper anti-triangle.
    \+ (between(0, H1, R),
        between(0, H1, C),
        R + C < H1,
        grid_symmetry_cell_(Grid, R, C, V1),
        R2 is H1 - C,
        C2 is H1 - R,
        grid_symmetry_cell_(Grid, R2, C2, V2),
        V1 \= V2).

% grid_symmetry_sym_rot90(+Grid)
% Succeed if Grid is invariant under 90-degree clockwise rotation.
% Only meaningful for square grids; fails for non-square grids.
% Grid[R][C] = Grid[H-1-C][R] for all R, C.
grid_symmetry_sym_rot90(Grid) :-
% Get dimensions.
    grid_symmetry_dims_(Grid, H, W),
% Require square grid.
    H =:= W,
% Compute H-1.
    H1 is H - 1,
% Check that each cell matches its 90-CW-rotated counterpart.
    \+ (between(0, H1, R),
        between(0, H1, C),
        grid_symmetry_cell_(Grid, R, C, V1),
        R2 is H1 - C,
        grid_symmetry_cell_(Grid, R2, R, V2),
        V1 \= V2).

% grid_symmetry_sym_rot180(+Grid)
% Succeed if Grid is invariant under 180-degree rotation.
% Works for any grid dimensions (not just square).
% Grid[R][C] = Grid[H-1-R][W-1-C] for all R, C.
grid_symmetry_sym_rot180(Grid) :-
% Get dimensions.
    grid_symmetry_dims_(Grid, H, W),
% Compute last indices.
    H1 is H - 1,
% Compute last column index.
    W1 is W - 1,
% Only need to check the first half of cells (linearized index < total/2).
    TotalHalf is (H * W) // 2,
% Check first half of cells in row-major order.
    \+ (between(0, H1, R),
        between(0, W1, C),
        Idx is R * W + C,
        Idx < TotalHalf,
        grid_symmetry_cell_(Grid, R, C, V1),
        R2 is H1 - R,
        C2 is W1 - C,
        grid_symmetry_cell_(Grid, R2, C2, V2),
        V1 \= V2).

% grid_symmetry_symmetries(+Grid, -Syms)
% Syms is the list of symmetry types that Grid possesses.
% Possible members: h (top-bottom), v (left-right), d1 (main diagonal),
% d2 (anti-diagonal), rot90 (90-CW rotation), rot180 (180-rotation).
% Non-applicable symmetries (d1, d2, rot90 for non-square grids) are omitted.
grid_symmetry_symmetries(Grid, Syms) :-
% Get dimensions to determine which tests apply.
    grid_symmetry_dims_(Grid, H, W),
% Check horizontal (top-bottom) symmetry.
    (grid_symmetry_sym_h(Grid) -> SH = [h] ; SH = []),
% Check vertical (left-right) symmetry.
    (grid_symmetry_sym_v(Grid) -> SV = [v] ; SV = []),
% Check diagonal symmetries only for square grids.
    (H =:= W ->
        (grid_symmetry_sym_d1(Grid) -> SD1 = [d1] ; SD1 = []),
        (grid_symmetry_sym_d2(Grid) -> SD2 = [d2] ; SD2 = []),
        (grid_symmetry_sym_rot90(Grid) -> SR90 = [rot90] ; SR90 = [])
    ;
        SD1 = [], SD2 = [], SR90 = []
    ),
% Check 180-rotation symmetry.
    (grid_symmetry_sym_rot180(Grid) -> SR180 = [rot180] ; SR180 = []),
% Concatenate all present symmetries.
    append([SH, SV, SD1, SD2, SR90, SR180], Syms).

% --- SYMMETRY COMPLETION ---

% grid_symmetry_complete_h(+Grid, +Dir, -Result)
% Complete Grid to be horizontally (top-bottom) symmetric.
% Dir = top: copy the top half to the bottom (result[R][C] = Grid[min(R, H-1-R)][C]).
% Dir = bottom: copy the bottom half to the top (result[R][C] = Grid[max(R, H-1-R)][C]).
grid_symmetry_complete_h(Grid, Dir, Result) :-
% Get grid dimensions.
    grid_symmetry_dims_(Grid, H, W),
% Compute H-1.
    H1 is H - 1,
% Build result using min/max row index depending on direction.
    grid_symmetry_build_(H, W,
        [R, C, V]>>(R2 is H1 - R,
                    (Dir = top -> OR is min(R, R2) ; OR is max(R, R2)),
                    grid_symmetry_cell_(Grid, OR, C, V)),
        Result).

% grid_symmetry_complete_v(+Grid, +Dir, -Result)
% Complete Grid to be vertically (left-right) symmetric.
% Dir = left: copy the left half to the right.
% Dir = right: copy the right half to the left.
grid_symmetry_complete_v(Grid, Dir, Result) :-
% Get grid dimensions.
    grid_symmetry_dims_(Grid, H, W),
% Compute W-1.
    W1 is W - 1,
% Build result using min/max column index depending on direction.
    grid_symmetry_build_(H, W,
        [R, C, V]>>(C2 is W1 - C,
                    (Dir = left -> OC is min(C, C2) ; OC is max(C, C2)),
                    grid_symmetry_cell_(Grid, R, OC, V)),
        Result).

% grid_symmetry_complete_rot180(+Grid, +BgColor, -Result)
% Complete Grid to be 180-rotationally symmetric.
% Non-BgColor cells are kept. BgColor cells take the color of their rotational
% mirror if the mirror cell is non-BgColor; otherwise remain BgColor.
grid_symmetry_complete_rot180(Grid, BgColor, Result) :-
% Get grid dimensions.
    grid_symmetry_dims_(Grid, H, W),
% Compute last indices.
    H1 is H - 1,
% Compute last column index.
    W1 is W - 1,
% For each cell: keep non-BgColor; for BgColor cells, use rotational mirror.
    grid_symmetry_build_(H, W,
        [R, C, V]>>(grid_symmetry_cell_(Grid, R, C, GV),
                    (GV \= BgColor ->
                        V = GV
                    ;
                        R2 is H1 - R,
                        C2 is W1 - C,
                        grid_symmetry_cell_(Grid, R2, C2, MV),
                        (MV \= BgColor -> V = MV ; V = BgColor))),
        Result).

% --- VIOLATION DETECTION ---

% grid_symmetry_violations_h(+Grid, -Cells)
% Cells is the list of R-C positions in the top half of Grid where Grid[R][C]
% differs from Grid[H-1-R][C]. An empty list means the grid is h-symmetric.
grid_symmetry_violations_h(Grid, Cells) :-
% Get grid dimensions.
    grid_symmetry_dims_(Grid, H, W),
% Compute last row index.
    H1 is H - 1,
% Compute the maximum row in the top half to check.
    MaxR is (H - 2) // 2,
% Compute last column index.
    W1 is W - 1,
% Collect violating (R, C) pairs.
    findall(R-C,
        (between(0, MaxR, R),
         between(0, W1, C),
         R2 is H1 - R,
         grid_symmetry_cell_(Grid, R, C, V1),
         grid_symmetry_cell_(Grid, R2, C, V2),
         V1 \= V2),
        Cells).

% grid_symmetry_violations_v(+Grid, -Cells)
% Cells is the list of R-C positions in the left half of Grid where Grid[R][C]
% differs from Grid[R][W-1-C]. An empty list means the grid is v-symmetric.
grid_symmetry_violations_v(Grid, Cells) :-
% Get grid dimensions.
    grid_symmetry_dims_(Grid, H, W),
% Compute last column index.
    W1 is W - 1,
% Compute the maximum column in the left half to check.
    MaxC is (W - 2) // 2,
% Compute last row index.
    H1 is H - 1,
% Collect violating (R, C) pairs.
    findall(R-C,
        (between(0, H1, R),
         between(0, MaxC, C),
         C2 is W1 - C,
         grid_symmetry_cell_(Grid, R, C, V1),
         grid_symmetry_cell_(Grid, R, C2, V2),
         V1 \= V2),
        Cells).

% grid_symmetry_violations_rot180(+Grid, -Cells)
% Cells is the list of R-C positions in the first half (by linearized index)
% of Grid where Grid[R][C] differs from Grid[H-1-R][W-1-C].
% An empty list means the grid is rot180-symmetric.
grid_symmetry_violations_rot180(Grid, Cells) :-
% Get grid dimensions.
    grid_symmetry_dims_(Grid, H, W),
% Compute last indices.
    H1 is H - 1,
% Compute last column.
    W1 is W - 1,
% Check only the first half of cells by linearized index.
    TotalHalf is (H * W) // 2,
% Collect violating cells.
    findall(R-C,
        (between(0, H1, R),
         between(0, W1, C),
         Idx is R * W + C,
         Idx < TotalHalf,
         grid_symmetry_cell_(Grid, R, C, V1),
         R2 is H1 - R,
         C2 is W1 - C,
         grid_symmetry_cell_(Grid, R2, C2, V2),
         V1 \= V2),
        Cells).

% grid_symmetry_score(+Grid, +Type, -Score)
% Score is the fraction [0.0..1.0] of symmetric pairs that match for Type.
% Type is one of: h (top-bottom), v (left-right), rot180.
% Score = 1.0 means fully symmetric; 0.0 means no matching pairs.
% For grids where there are no pairs to check (e.g. 1x1), Score = 1.0.
grid_symmetry_score(Grid, Type, Score) :-
% Dispatch based on Type to avoid multiple-clause choicepoints.
    (Type = h ->
% Compute top-bottom symmetry score.
        grid_symmetry_dims_(Grid, H, W),
        MaxR is (H - 2) // 2,
        H1 is H - 1,
        W1 is W - 1,
        (MaxR < 0 ->
            Score = 1.0
        ;
            findall(1, (between(0, MaxR, _), between(0, W1, _)), All),
            length(All, Total),
            findall(1,
                (between(0, MaxR, R),
                 between(0, W1, C),
                 R2 is H1 - R,
                 grid_symmetry_cell_(Grid, R, C, V),
                 grid_symmetry_cell_(Grid, R2, C, V)),
                Matches),
            length(Matches, MatchCount),
            Score is float(MatchCount) / Total
        )
    ; Type = v ->
% Compute left-right symmetry score.
        grid_symmetry_dims_(Grid, H, W),
        MaxC is (W - 2) // 2,
        H1 is H - 1,
        W1 is W - 1,
        (MaxC < 0 ->
            Score = 1.0
        ;
            findall(1, (between(0, H1, _), between(0, MaxC, _)), All),
            length(All, Total),
            findall(1,
                (between(0, H1, R),
                 between(0, MaxC, C),
                 C2 is W1 - C,
                 grid_symmetry_cell_(Grid, R, C, V),
                 grid_symmetry_cell_(Grid, R, C2, V)),
                Matches),
            length(Matches, MatchCount),
            Score is float(MatchCount) / Total
        )
    ;
% Compute 180-rotation symmetry score.
        Type = rot180,
        grid_symmetry_dims_(Grid, H, W),
        TotalHalf is (H * W) // 2,
        (TotalHalf =:= 0 ->
            Score = 1.0
        ;
            H1 is H - 1,
            W1 is W - 1,
            findall(1,
                (between(0, H1, R),
                 between(0, W1, C),
                 Idx is R * W + C,
                 Idx < TotalHalf,
                 grid_symmetry_cell_(Grid, R, C, V),
                 R2 is H1 - R,
                 C2 is W1 - C,
                 grid_symmetry_cell_(Grid, R2, C2, V)),
                Matches),
            length(Matches, MatchCount),
            Score is float(MatchCount) / TotalHalf
        )
    ).
