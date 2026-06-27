:- module(gridmark, [
    gmk_mark_cell/5,
    gmk_mark_cells/4,
    gmk_mark_row/4,
    gmk_mark_col/4,
    gmk_mark_rect/7,
    gmk_mark_border/3,
    gmk_mark_diagonal/3,
    gmk_mark_anti_diagonal/3,
    gmk_mark_corners/3,
    gmk_mark_cross/3,
    gmk_marked_cells/3,
    gmk_is_marked/4,
    gmk_mark_checkerboard/3,
    gmk_erase/4
]).
% gridmark.pl - Layer 225: Grid Marking and Annotation (gmk_* prefix).
% Fourteen predicates for creating new grids with specific cells overwritten
% by a mark color. All predicates are non-destructive: Grid is unchanged and
% Marked is a fresh copy with the selected cells replaced.
% Raw grid format: list of rows, each a list of color atoms, 0-indexed.
% Anti-diagonal: cells where R + C = W - 1 (using column count).
% Center cross: center row (H//2) and center column (W//2).
% No cross-pack dependencies.
:- use_module(library(lists), [nth0/3, member/2, memberchk/2]).

% --- PRIVATE HELPERS ---

% Grid dimensions.
gmk_dims_(Grid, H, W) :-
    length(Grid, H),
    (H > 0 -> Grid = [FR|_], length(FR, W) ; W = 0).

% Build a marked row: replace cells at column positions in ColSet with MarkColor.
gmk_mark_row_(GRow, ColSet, MarkColor, NewRow) :-
    length(GRow, W), W1 is W - 1,
    findall(V2,
        (between(0, W1, C),
         (memberchk(C, ColSet) -> V2 = MarkColor ; nth0(C, GRow, V2))),
        NewRow).

% Rebuild a grid, replacing selected (R,C) pairs with MarkColor.
gmk_mark_positions_(Grid, PairSet, MarkColor, Marked) :-
    gmk_dims_(Grid, H, W),
    H1 is H - 1, W1 is W - 1,
    findall(NewRow,
        (between(0, H1, R),
         nth0(R, Grid, GRow),
         findall(V2,
             (between(0, W1, C),
              (memberchk(R-C, PairSet) -> V2 = MarkColor ; nth0(C, GRow, V2))),
             NewRow)),
        Marked).

% --- PUBLIC PREDICATES ---

% gmk_mark_cell(+Grid, +R, +C, +MarkColor, -Marked)
% Marked is Grid with the cell at (R, C) replaced by MarkColor.
gmk_mark_cell(Grid, R, C, MarkColor, Marked) :-
    gmk_mark_positions_(Grid, [R-C], MarkColor, Marked).

% gmk_mark_cells(+Grid, +Cells, +MarkColor, -Marked)
% Marked is Grid with every cell in Cells (a list of R-C pairs) replaced by MarkColor.
gmk_mark_cells(Grid, Cells, MarkColor, Marked) :-
    gmk_mark_positions_(Grid, Cells, MarkColor, Marked).

% gmk_mark_row(+Grid, +R, +MarkColor, -Marked)
% Marked is Grid with every cell in row R replaced by MarkColor.
gmk_mark_row(Grid, R, MarkColor, Marked) :-
    gmk_dims_(Grid, H, _),
    H1 is H - 1,
    findall(NewRow,
        (between(0, H1, Row),
         nth0(Row, Grid, GRow),
         (Row =:= R ->
             length(GRow, W),
             findall(MarkColor, between(1, W, _), NewRow)
         ;   NewRow = GRow)),
        Marked).

% gmk_mark_col(+Grid, +C, +MarkColor, -Marked)
% Marked is Grid with every cell in column C replaced by MarkColor.
gmk_mark_col(Grid, C, MarkColor, Marked) :-
    gmk_dims_(Grid, H, W),
    H1 is H - 1, W1 is W - 1,
    findall(NewRow,
        (between(0, H1, R),
         nth0(R, Grid, GRow),
         findall(V2,
             (between(0, W1, CC),
              (CC =:= C -> V2 = MarkColor ; nth0(CC, GRow, V2))),
             NewRow)),
        Marked).

% gmk_mark_rect(+Grid, +R0, +C0, +R1, +C1, +MarkColor, -Marked)
% Marked is Grid with every cell in the rectangle rows [R0..R1], cols [C0..C1]
% replaced by MarkColor.
gmk_mark_rect(Grid, R0, C0, R1, C1, MarkColor, Marked) :-
    gmk_dims_(Grid, H, W),
    H1 is H - 1, W1 is W - 1,
    findall(NewRow,
        (between(0, H1, R),
         nth0(R, Grid, GRow),
         findall(V2,
             (between(0, W1, C),
              (R >= R0, R =< R1, C >= C0, C =< C1 ->
                  V2 = MarkColor
              ;   nth0(C, GRow, V2))),
             NewRow)),
        Marked).

% gmk_mark_border(+Grid, +MarkColor, -Marked)
% Marked is Grid with all border cells (outer ring) replaced by MarkColor.
% For a 1-row or 1-col grid every cell is a border cell.
gmk_mark_border(Grid, MarkColor, Marked) :-
    gmk_dims_(Grid, H, W),
    H1 is H - 1, W1 is W - 1,
% Mark top row, then bottom row, then left and right columns.
    gmk_mark_rect(Grid, 0, 0, 0, W1, MarkColor, M1),
    gmk_mark_rect(M1, H1, 0, H1, W1, MarkColor, M2),
    gmk_mark_col(M2, 0, MarkColor, M3),
    gmk_mark_col(M3, W1, MarkColor, Marked).

% gmk_mark_diagonal(+Grid, +MarkColor, -Marked)
% Marked is Grid with all main diagonal cells (R = C, both in range) replaced
% by MarkColor.
gmk_mark_diagonal(Grid, MarkColor, Marked) :-
    gmk_dims_(Grid, H, W),
    MinHW is min(H, W), MinHW1 is MinHW - 1,
    findall(R-R, between(0, MinHW1, R), Pairs),
    gmk_mark_positions_(Grid, Pairs, MarkColor, Marked).

% gmk_mark_anti_diagonal(+Grid, +MarkColor, -Marked)
% Marked is Grid with all anti-diagonal cells (R + C = W - 1) replaced
% by MarkColor.
gmk_mark_anti_diagonal(Grid, MarkColor, Marked) :-
    gmk_dims_(Grid, H, W),
    ASum is W - 1,
    H1 is H - 1,
    findall(R-C,
        (between(0, H1, R), C is ASum - R, C >= 0, C < W),
        Pairs),
    gmk_mark_positions_(Grid, Pairs, MarkColor, Marked).

% gmk_mark_corners(+Grid, +MarkColor, -Marked)
% Marked is Grid with the four corner cells replaced by MarkColor.
gmk_mark_corners(Grid, MarkColor, Marked) :-
    gmk_dims_(Grid, H, W),
    H1 is H - 1, W1 is W - 1,
    Pairs = [0-0, 0-W1, H1-0, H1-W1],
    gmk_mark_positions_(Grid, Pairs, MarkColor, Marked).

% gmk_mark_cross(+Grid, +MarkColor, -Marked)
% Marked is Grid with the center row (H//2) and center column (W//2) replaced
% by MarkColor. These cells form a cross pattern.
gmk_mark_cross(Grid, MarkColor, Marked) :-
    gmk_dims_(Grid, H, W),
    CenterR is H // 2, CenterC is W // 2,
    gmk_mark_row(Grid, CenterR, MarkColor, M1),
    gmk_mark_col(M1, CenterC, MarkColor, Marked).

% gmk_marked_cells(+Grid, +MarkColor, -Cells)
% Cells is the list of R-C pairs for all cells in Grid with color MarkColor.
% Order is row-major: R ascending, then C ascending within each row.
gmk_marked_cells(Grid, MarkColor, Cells) :-
    gmk_dims_(Grid, H, W),
    H1 is H - 1, W1 is W - 1,
    findall(R-C,
        (between(0, H1, R), between(0, W1, C),
         nth0(R, Grid, Row), nth0(C, Row, MarkColor)),
        Cells).

% gmk_is_marked(+Grid, +R, +C, +MarkColor)
% Succeeds if cell (R, C) in Grid has color MarkColor.
gmk_is_marked(Grid, R, C, MarkColor) :-
    nth0(R, Grid, Row),
    nth0(C, Row, MarkColor).

% gmk_mark_checkerboard(+Grid, +MarkColor, -Marked)
% Marked is Grid with all cells (R,C) where (R+C) mod 2 = 0 replaced by MarkColor.
gmk_mark_checkerboard(Grid, MarkColor, Marked) :-
    gmk_dims_(Grid, H, W),
    H1 is H - 1, W1 is W - 1,
    findall(R-C,
        (between(0, H1, R), between(0, W1, C), 0 =:= (R+C) mod 2),
        Pairs),
    gmk_mark_positions_(Grid, Pairs, MarkColor, Marked).

% gmk_erase(+Grid, +MarkColor, +BgColor, -Erased)
% Erased is Grid with every cell of color MarkColor replaced by BgColor.
% Equivalent to gc_recolor but framed as "erase the mark."
gmk_erase(Grid, MarkColor, BgColor, Erased) :-
    gmk_dims_(Grid, H, W),
    H1 is H - 1, W1 is W - 1,
    findall(NewRow,
        (between(0, H1, R),
         nth0(R, Grid, GRow),
         findall(V2,
             (between(0, W1, C),
              nth0(C, GRow, V),
              (V = MarkColor -> V2 = BgColor ; V2 = V)),
             NewRow)),
        Erased).
