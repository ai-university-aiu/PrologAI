% window - Layer 79: sliding window and neighborhood operations.
% Module window exports 14 wn_* predicates covering 4-connected and 8-connected
% neighbor enumeration, sub-grid extraction, sliding windows, grid padding,
% local extrema detection, halo computation, convolution, center finding,
% Manhattan distance, and distance-based cell enumeration.
:- module(window, [
    % List R2-C2-Val triples for in-bounds 4-connected neighbors of (R,C).
    window_neighbors4/4,
    % List R2-C2-Val triples for in-bounds 8-connected neighbors of (R,C).
    window_neighbors8/4,
    % Count 4-connected neighbors equal to Val.
    window_count4/5,
    % Count 8-connected neighbors equal to Val.
    window_count8/5,
    % Extract an H x W sub-grid starting at (R0,C0).
    window_extract/6,
    % Enumerate all H x W windows as R0-C0-Sub triples.
    window_slide/4,
    % Pad all sides of a grid with N layers of PadVal.
    window_pad/4,
    % True if Grid[R,C] is >= all in-bounds 4-connected neighbor values.
    window_local_max4/3,
    % True if Grid[R,C] is =< all in-bounds 4-connected neighbor values.
    window_local_min4/3,
    % List R-C cells adjacent (4-connected) to a Val cell but not equal to Val.
    window_halo4/3,
    % Integer convolution: sum of element-wise products of grid window and kernel.
    window_convolve/3,
    % Floor-center coordinates of a grid.
    window_center/3,
    % Manhattan distance between two grid positions.
    window_manhattan/5,
    % In-bounds cells at exactly Manhattan distance D from (R,C).
    window_cells_at_dist/5
]).

% Load list utilities for neighbor enumeration and index arithmetic.
:- use_module(library(lists), [member/2, nth0/3, numlist/3, append/3]).
% Load apply utilities for window and row mapping.
:- use_module(library(apply), [maplist/2, maplist/3, maplist/4, include/3, foldl/4]).

% window_neighbors4(+Grid, +R, +C, -Ns)
% Ns is a list of R2-C2-V triples for all in-bounds 4-connected neighbors of (R,C).
window_neighbors4(Grid, R, C, Ns) :-
    % Get grid dimensions for bounds checking.
    length(Grid, NRows),
    Grid = [FirstRow|_],
    length(FirstRow, NCols),
    NRowsM1 is NRows - 1,
    NColsM1 is NCols - 1,
    % 4 direction offsets: up, down, left, right.
    findall(R2-C2-V,
        (member(DR-DC, [-1-0, 1-0, 0-(-1), 0-1]),
         R2 is R + DR,
         C2 is C + DC,
         R2 >= 0, R2 =< NRowsM1,
         C2 >= 0, C2 =< NColsM1,
         nth0(R2, Grid, Row2),
         nth0(C2, Row2, V)),
        Ns).

% window_neighbors8(+Grid, +R, +C, -Ns)
% Ns is a list of R2-C2-V triples for all in-bounds 8-connected neighbors of (R,C).
window_neighbors8(Grid, R, C, Ns) :-
    % Get grid dimensions.
    length(Grid, NRows),
    Grid = [FirstRow|_],
    length(FirstRow, NCols),
    NRowsM1 is NRows - 1,
    NColsM1 is NCols - 1,
    % 8 direction offsets: all combinations of -1, 0, 1 except 0-0.
    findall(R2-C2-V,
        (member(DR-DC, [-1-(-1), -1-0, -1-1, 0-(-1), 0-1, 1-(-1), 1-0, 1-1]),
         R2 is R + DR,
         C2 is C + DC,
         R2 >= 0, R2 =< NRowsM1,
         C2 >= 0, C2 =< NColsM1,
         nth0(R2, Grid, Row2),
         nth0(C2, Row2, V)),
        Ns).

% window_count4(+Grid, +R, +C, +Val, -N)
% N is the number of in-bounds 4-connected neighbors of (R,C) whose value equals Val.
window_count4(Grid, R, C, Val, N) :-
    % Get all 4-connected neighbors.
    window_neighbors4(Grid, R, C, Ns),
    % Filter to those matching Val.
    include([_-_-V]>>(V == Val), Ns, Matches),
    % Count the matches.
    length(Matches, N).

% window_count8(+Grid, +R, +C, +Val, -N)
% N is the number of in-bounds 8-connected neighbors of (R,C) whose value equals Val.
window_count8(Grid, R, C, Val, N) :-
    % Get all 8-connected neighbors.
    window_neighbors8(Grid, R, C, Ns),
    % Filter to those matching Val.
    include([_-_-V]>>(V == Val), Ns, Matches),
    % Count the matches.
    length(Matches, N).

% window_extract(+Grid, +R0, +C0, +H, +W, -Sub)
% Sub is the H x W sub-grid of Grid starting at row R0, column C0.
window_extract(Grid, R0, C0, H, W, Sub) :-
    % Enumerate row offsets 0 .. H-1.
    HM1 is H - 1,
    numlist(0, HM1, DRs),
    % Enumerate column offsets 0 .. W-1.
    WM1 is W - 1,
    numlist(0, WM1, DCs),
    % Build each sub-row by extracting W cells starting at C0.
    maplist([DR, SubRow]>>(
        RR is R0 + DR,
        nth0(RR, Grid, GRow),
        maplist([DC, V]>>(CC is C0 + DC, nth0(CC, GRow, V)), DCs, SubRow)
    ), DRs, Sub).

% window_slide(+Grid, +H, +W, -Windows)
% Windows is a list of R0-C0-Sub triples, one for each valid H x W window placement.
window_slide(Grid, H, W, Windows) :-
    % Determine maximum start row and column.
    length(Grid, NRows),
    Grid = [FirstRow|_],
    length(FirstRow, NCols),
    MaxR is NRows - H,
    MaxC is NCols - W,
    % If grid is too small, no windows fit.
    (MaxR < 0 -> Windows = []
    ; MaxC < 0 -> Windows = []
    % Enumerate all valid start positions.
    ; findall(R0-C0-Sub,
          (between(0, MaxR, R0),
           between(0, MaxC, C0),
           window_extract(Grid, R0, C0, H, W, Sub)),
          Windows)).

% window_pad(+Grid, +PadVal, +N, -Padded)
% Padded is Grid with N layers of PadVal added on all four sides.
% When N = 0, Padded = Grid.
window_pad(Grid, PadVal, N, Padded) :-
    % Determine original grid width.
    (Grid = [] -> NCols = 0 ; Grid = [FR|_], length(FR, NCols)),
    % New width after adding N cells on each side.
    NewNCols is NCols + 2 * N,
    % Build a horizontal padding row of NewNCols PadVal cells.
    length(PadRow, NewNCols),
    maplist(=(PadVal), PadRow),
    % Build N top padding rows.
    findall(PadRow, between(1, N, _), TopPad),
    % Build N bottom padding rows.
    findall(PadRow, between(1, N, _), BotPad),
    % Pad each original row by adding N PadVal cells on each side.
    maplist(window_pad_row_(PadVal, N), Grid, PaddedRows),
    % Assemble top padding + padded rows + bottom padding.
    append(TopPad, PaddedRows, TopAndMiddle),
    append(TopAndMiddle, BotPad, Padded).

% window_pad_row_(+PadVal, +N, +Row, -PaddedRow): add N PadVal cells on each side.
window_pad_row_(PadVal, N, Row, PaddedRow) :-
    % Build left padding.
    findall(PadVal, between(1, N, _), LeftPad),
    % Build right padding.
    findall(PadVal, between(1, N, _), RightPad),
    % Concatenate left + row + right.
    append(LeftPad, Row, LRow),
    append(LRow, RightPad, PaddedRow).

% window_local_max4(+Grid, +R, +C)
% True if Grid[R,C] is numerically >= all in-bounds 4-connected neighbor values.
window_local_max4(Grid, R, C) :-
    % Get the center cell value.
    nth0(R, Grid, Row),
    nth0(C, Row, CellVal),
    % Get all 4-connected neighbors.
    window_neighbors4(Grid, R, C, Ns),
    % Check cell is >= each neighbor value.
    forall(member(_-_-V, Ns), CellVal >= V).

% window_local_min4(+Grid, +R, +C)
% True if Grid[R,C] is numerically =< all in-bounds 4-connected neighbor values.
window_local_min4(Grid, R, C) :-
    % Get the center cell value.
    nth0(R, Grid, Row),
    nth0(C, Row, CellVal),
    % Get all 4-connected neighbors.
    window_neighbors4(Grid, R, C, Ns),
    % Check cell is =< each neighbor value.
    forall(member(_-_-V, Ns), CellVal =< V).

% window_halo4(+Grid, +Val, -Cells)
% Cells is the sorted list of R-C pairs that are not Val but are 4-adjacent to a Val cell.
window_halo4(Grid, Val, Cells) :-
    % Get grid dimensions.
    length(Grid, NRows),
    Grid = [FirstRow|_],
    length(FirstRow, NCols),
    NRowsM1 is NRows - 1,
    NColsM1 is NCols - 1,
    % Collect all non-Val cells that have at least one Val 4-neighbor.
    findall(R-C,
        (between(0, NRowsM1, R),
         between(0, NColsM1, C),
         nth0(R, Grid, GRow),
         nth0(C, GRow, Cell),
         Cell \== Val,
         window_neighbors4(Grid, R, C, Ns),
         member(_-_-Val, Ns)),
        CellsDup),
    % Remove duplicates (a halo cell may be near multiple Val cells).
    sort(CellsDup, Cells).

% window_convolve(+Grid, +Kernel, -Grid2)
% Grid2 is the valid convolution of Grid with Kernel.
% Output dimensions: (NRows-KH+1) x (NCols-KW+1).
% Each output cell is the sum of element-wise products of the window and kernel.
window_convolve(Grid, Kernel, Grid2) :-
    % Get kernel dimensions.
    length(Kernel, KH),
    Kernel = [KRow0|_],
    length(KRow0, KW),
    % Get input grid dimensions.
    length(Grid, NRows),
    Grid = [InRow0|_],
    length(InRow0, NCols),
    % Compute output dimensions.
    OutH is NRows - KH + 1,
    OutW is NCols - KW + 1,
    % If kernel is larger than grid, output is empty.
    (OutH =< 0 -> Grid2 = []
    ; OutW =< 0 -> Grid2 = []
    % Enumerate output positions.
    ; OutHM1 is OutH - 1,
      OutWM1 is OutW - 1,
      numlist(0, OutHM1, RIdxs),
      numlist(0, OutWM1, CIdxs),
      maplist([R0, OutRow]>>(
          maplist([C0, Val]>>(
              window_extract(Grid, R0, C0, KH, KW, Sub),
              window_dot_(Sub, Kernel, Val)
          ), CIdxs, OutRow)
      ), RIdxs, Grid2)).

% window_dot_(+Grid1, +Grid2, -Sum): compute element-wise dot product of two grids.
window_dot_(Grid1, Grid2, Sum) :-
    % Compute row-wise dot products.
    maplist(window_row_dot_, Grid1, Grid2, RowSums),
    % Sum all row products.
    foldl([X, Acc, NAcc]>>(NAcc is Acc + X), RowSums, 0, Sum).

% window_row_dot_(+Row1, +Row2, -RowSum): sum of element-wise products of two rows.
window_row_dot_(Row1, Row2, RowSum) :-
    % Multiply each pair of elements.
    maplist([V1, V2, P]>>(P is V1 * V2), Row1, Row2, Products),
    % Sum the products.
    foldl([X, Acc, NAcc]>>(NAcc is Acc + X), Products, 0, RowSum).

% window_center(+Grid, -R, -C)
% R and C are the floor-center coordinates of Grid: R = NRows//2, C = NCols//2.
window_center(Grid, R, C) :-
    % Count rows.
    length(Grid, NRows),
    % Count columns from first row.
    Grid = [FirstRow|_],
    length(FirstRow, NCols),
    % Integer division gives floor center.
    R is NRows // 2,
    C is NCols // 2.

% window_manhattan(+R1, +C1, +R2, +C2, -D)
% D is the Manhattan (L1) distance between grid positions (R1,C1) and (R2,C2).
window_manhattan(R1, C1, R2, C2, D) :-
    % Sum of absolute coordinate differences.
    D is abs(R1 - R2) + abs(C1 - C2).

% window_cells_at_dist(+Grid, +R, +C, +D, -Cells)
% Cells is the list of in-bounds R2-C2 pairs at Manhattan distance exactly D from (R,C).
window_cells_at_dist(Grid, R, C, D, Cells) :-
    % Get grid dimensions.
    length(Grid, NRows),
    Grid = [FirstRow|_],
    length(FirstRow, NCols),
    NRowsM1 is NRows - 1,
    NColsM1 is NCols - 1,
    % Collect cells at exactly distance D.
    findall(R2-C2,
        (between(0, NRowsM1, R2),
         between(0, NColsM1, C2),
         D =:= abs(R2 - R) + abs(C2 - C)),
        Cells).
