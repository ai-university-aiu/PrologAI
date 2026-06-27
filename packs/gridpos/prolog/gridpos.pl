:- module(gridpos, [
    gps_top_half/2,
    gps_bottom_half/2,
    gps_left_half/2,
    gps_right_half/2,
    gps_quadrant/3,
    gps_even_rows/2,
    gps_odd_rows/2,
    gps_even_cols/2,
    gps_odd_cols/2,
    gps_checkerboard/3,
    gps_center_cell/3,
    gps_corners/2,
    gps_cross_h/3,
    gps_cross_v/3
]).
% gridpos.pl - Layer 222: Grid Positional Analysis (gps_* prefix).
% Fourteen predicates for extracting sub-grids and cell positions based on
% positional properties: halves, quadrants, even/odd rows and columns,
% checkerboard patterns, center cell, corner cells, and center cross.
% Raw grid format: list of rows, each a list of color atoms, 0-indexed.
% top_half = rows [0, H//2); bottom_half = rows [H//2, H).
% left_half = cols [0, W//2); right_half = cols [W//2, W).
% Even rows/cols are those whose 0-indexed position is divisible by 2.
% Checkerboard parity P: cells (R,C) where (R+C) mod 2 = P.
% No cross-pack dependencies.
:- use_module(library(lists), [nth0/3, member/2]).

% --- PRIVATE HELPERS ---

% Compute grid dimensions: H rows, W columns.
gps_dims_(Grid, H, W) :-
% Count rows.
    length(Grid, H),
% Count columns from first row when non-empty; 0 otherwise.
    (H > 0 -> Grid = [FR|_], length(FR, W) ; W = 0).

% Extract column C from Grid as a top-to-bottom list.
gps_col_(Grid, C, Col) :-
% Collect the C-th element from each row.
    findall(V, (member(Row, Grid), nth0(C, Row, V)), Col).

% Extract a rectangular sub-grid: rows [R0..R1], cols [C0..C1] inclusive.
gps_subgrid_(Grid, R0, R1, C0, C1, Sub) :-
% For each row index in range, extract the column slice.
    findall(Row,
        (between(R0, R1, R),
         nth0(R, Grid, GRow),
         findall(V, (between(C0, C1, C), nth0(C, GRow, V)), Row)),
        Sub).

% Extract cells at even or odd column indices from a single row.
gps_row_parity_(Row, Parity, SubRow) :-
    length(Row, W), W1 is W - 1,
% Keep only columns where C mod 2 = Parity.
    findall(V, (between(0, W1, C), Parity =:= C mod 2, nth0(C, Row, V)), SubRow).

% --- PUBLIC PREDICATES ---

% gps_top_half(+Grid, -TopGrid)
% TopGrid is the sub-grid consisting of rows [0, H//2).
% For odd H, this is the smaller half; for even H the halves are equal.
gps_top_half(Grid, TopGrid) :-
% Compute number of top rows.
    length(Grid, H), HMid is H // 2,
% Empty when H=0 or H=1 (midpoint is 0).
    (HMid =:= 0 -> TopGrid = [] ;
     HMid1 is HMid - 1,
     findall(Row, (between(0, HMid1, R), nth0(R, Grid, Row)), TopGrid)).

% gps_bottom_half(+Grid, -BotGrid)
% BotGrid is the sub-grid consisting of rows [H//2, H).
gps_bottom_half(Grid, BotGrid) :-
% Compute start row and last row index.
    length(Grid, H), HMid is H // 2, H1 is H - 1,
% Collect rows from the midpoint to the end.
    findall(Row, (between(HMid, H1, R), nth0(R, Grid, Row)), BotGrid).

% gps_left_half(+Grid, -LeftGrid)
% LeftGrid is the sub-grid consisting of columns [0, W//2).
gps_left_half(Grid, LeftGrid) :-
% Compute column midpoint.
    gps_dims_(Grid, _, W), WMid is W // 2,
% When WMid=0 the left half is empty columns; otherwise slice each row.
    (WMid =:= 0 ->
        length(Grid, H),
        findall([], between(1, H, _), LeftGrid)
    ;
        WMid1 is WMid - 1,
        findall(Row,
            (member(GRow, Grid),
             findall(V, (between(0, WMid1, C), nth0(C, GRow, V)), Row)),
            LeftGrid)).

% gps_right_half(+Grid, -RightGrid)
% RightGrid is the sub-grid consisting of columns [W//2, W).
gps_right_half(Grid, RightGrid) :-
% Compute start column and last column index.
    gps_dims_(Grid, _, W), WMid is W // 2, W1 is W - 1,
% Extract right-half columns from every row.
    findall(Row,
        (member(GRow, Grid),
         findall(V, (between(WMid, W1, C), nth0(C, GRow, V)), Row)),
        RightGrid).

% gps_quadrant(+Grid, +Quad, -SubGrid)
% SubGrid is one of four quadrants: tl, tr, bl, br.
% tl: rows [0,HMid), cols [0,WMid); tr: rows [0,HMid), cols [WMid,W).
% bl: rows [HMid,H), cols [0,WMid); br: rows [HMid,H), cols [WMid,W).
gps_quadrant(Grid, Quad, SubGrid) :-
% Compute half-points and last indices.
    gps_dims_(Grid, H, W),
    HMid is H // 2, WMid is W // 2,
    H1 is H - 1, W1 is W - 1,
% Map quadrant atom to row/col range.
    (Quad = tl -> R0=0, R1 is HMid-1, C0=0, C1 is WMid-1
    ;Quad = tr -> R0=0, R1 is HMid-1, C0=WMid, C1=W1
    ;Quad = bl -> R0=HMid, R1=H1, C0=0, C1 is WMid-1
    ;Quad = br -> R0=HMid, R1=H1, C0=WMid, C1=W1),
% Handle degenerate ranges (empty row or col span).
    (R0 > R1 -> SubGrid = [] ;
     C0 > C1 ->
        findall([], between(R0, R1, _), SubGrid)
     ;
        gps_subgrid_(Grid, R0, R1, C0, C1, SubGrid)).

% gps_even_rows(+Grid, -EvenGrid)
% EvenGrid contains only rows at even 0-indexed positions (0, 2, 4, ...).
gps_even_rows(Grid, EvenGrid) :-
% Determine last row index.
    length(Grid, H), H1 is H - 1,
% Keep rows where R mod 2 = 0.
    findall(Row, (between(0, H1, R), 0 =:= R mod 2, nth0(R, Grid, Row)), EvenGrid).

% gps_odd_rows(+Grid, -OddGrid)
% OddGrid contains only rows at odd 0-indexed positions (1, 3, 5, ...).
gps_odd_rows(Grid, OddGrid) :-
% Determine last row index.
    length(Grid, H), H1 is H - 1,
% Keep rows where R mod 2 = 1.
    findall(Row, (between(0, H1, R), 1 =:= R mod 2, nth0(R, Grid, Row)), OddGrid).

% gps_even_cols(+Grid, -EvenColGrid)
% EvenColGrid contains only columns at even 0-indexed positions (0, 2, 4, ...).
gps_even_cols(Grid, EvenColGrid) :-
% Apply even-parity column filter to every row.
    findall(Row, (member(GRow, Grid), gps_row_parity_(GRow, 0, Row)), EvenColGrid).

% gps_odd_cols(+Grid, -OddColGrid)
% OddColGrid contains only columns at odd 0-indexed positions (1, 3, 5, ...).
gps_odd_cols(Grid, OddColGrid) :-
% Apply odd-parity column filter to every row.
    findall(Row, (member(GRow, Grid), gps_row_parity_(GRow, 1, Row)), OddColGrid).

% gps_checkerboard(+Grid, +Parity, -Cells)
% Cells is the list of R-C pairs where (R+C) mod 2 = Parity.
% Parity must be bound to 0 or 1.
gps_checkerboard(Grid, Parity, Cells) :-
% Compute grid bounds.
    gps_dims_(Grid, H, W), H1 is H - 1, W1 is W - 1,
% Collect all positions matching the checkerboard parity.
    findall(R-C,
        (between(0, H1, R), between(0, W1, C), Parity =:= (R+C) mod 2),
        Cells).

% gps_center_cell(+Grid, -R, -C)
% R = H//2 and C = W//2 give the center cell coordinates.
% For odd dimensions this is the true center; for even it is the upper-left center.
gps_center_cell(Grid, R, C) :-
% Integer-divide to find center indices.
    gps_dims_(Grid, H, W),
    R is H // 2,
    C is W // 2.

% gps_corners(+Grid, -Corners)
% Corners is [R0-C0-V00, R0-CMax-V0W, RMax-C0-VH0, RMax-CMax-VHW].
% The four corner cells in order: top-left, top-right, bottom-left, bottom-right.
gps_corners(Grid, Corners) :-
% Compute last row and column indices.
    gps_dims_(Grid, H, W), H1 is H - 1, W1 is W - 1,
% Extract corner cell values.
    nth0(0, Grid, Row0), nth0(0, Row0, V00), nth0(W1, Row0, V0W),
    nth0(H1, Grid, RowH), nth0(0, RowH, VH0), nth0(W1, RowH, VHW),
% Assemble the list.
    Corners = [0-0-V00, 0-W1-V0W, H1-0-VH0, H1-W1-VHW].

% gps_cross_h(+Grid, -R, -Row)
% R is H//2 (center row index) and Row is its content.
gps_cross_h(Grid, R, Row) :-
% Compute center row index.
    length(Grid, H), R is H // 2,
% Retrieve the row.
    nth0(R, Grid, Row).

% gps_cross_v(+Grid, -C, -Col)
% C is W//2 (center column index) and Col is its content as a list.
gps_cross_v(Grid, C, Col) :-
% Compute center column index.
    (Grid = [FR|_] -> length(FR, W) ; W = 0), C is W // 2,
% Retrieve the column.
    gps_col_(Grid, C, Col).
