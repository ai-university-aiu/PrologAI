% walk.pl - Layer 85: Grid Traversal Patterns (wk_* prefix).
% Provides row-major, column-major, zigzag, diagonal, anti-diagonal,
% spiral, border, and inner-cell traversal; diagonal extraction; cell painting.
:- module(walk, [
    walk_row_scan/2,
    walk_col_scan/2,
    walk_zigzag_scan/2,
    walk_diag_scan/2,
    walk_antidiag_scan/2,
    walk_spiral_in/2,
    walk_border_walk/2,
    walk_diag_extract/3,
    walk_antidiag_extract/3,
    walk_diag_of/2,
    walk_antidiag_of/2,
    walk_cells_to_vals/3,
    walk_vals_to_cells/4,
    walk_inner_cells/2
]).

% Import list operations used throughout this module.
:- use_module(library(lists), [member/2, nth0/3, numlist/3, append/3, reverse/2]).
% Import higher-order operations used throughout this module.
:- use_module(library(apply), [maplist/2, maplist/3, maplist/4]).

% walk_dims_(+Grid, -NR, -NC): measure grid row and column counts.
walk_dims_(Grid, NR, NC) :-
    % Count rows.
    length(Grid, NR),
    % Count columns from first row; 0 for empty grid.
    (NR > 0 -> Grid = [FR|_], length(FR, NC) ; NC = 0).

% walk_row_scan(+Grid, -Cells): all cells as R-C pairs in row-major order.
% Row 0 left-to-right, then Row 1 left-to-right, and so on.
walk_row_scan(Grid, Cells) :-
    % Get grid dimensions.
    walk_dims_(Grid, NR, NC),
    NR1 is NR - 1, NC1 is NC - 1,
    % Collect every (R,C) pair with R varying slowest.
    findall(R-C, (between(0, NR1, R), between(0, NC1, C)), Cells).

% walk_col_scan(+Grid, -Cells): all cells as R-C pairs in column-major order.
% Column 0 top-to-bottom, then Column 1 top-to-bottom, and so on.
walk_col_scan(Grid, Cells) :-
    % Get grid dimensions.
    walk_dims_(Grid, NR, NC),
    NR1 is NR - 1, NC1 is NC - 1,
    % Collect every (R,C) pair with C varying slowest.
    findall(R-C, (between(0, NC1, C), between(0, NR1, R)), Cells).

% walk_zigzag_row_(+R, +NC, -Cells): cells for row R in zigzag order.
% Even-numbered rows go left-to-right; odd-numbered rows go right-to-left.
walk_zigzag_row_(R, NC, Cells) :-
    % Compute the rightmost column index.
    NC1 is NC - 1,
    % Build left-to-right cell list for this row.
    findall(R-C, between(0, NC1, C), Fwd),
    % Reverse for odd rows; keep for even rows.
    (R mod 2 =:= 0 -> Cells = Fwd ; reverse(Fwd, Cells)).

% walk_zigzag_scan(+Grid, -Cells): cells in zigzag (boustrophedon) order.
% Alternates left-to-right and right-to-left on successive rows.
walk_zigzag_scan(Grid, Cells) :-
    % Get grid dimensions.
    walk_dims_(Grid, NR, NC),
    NR1 is NR - 1,
    % Build a cell list for each row then concatenate.
    numlist(0, NR1, RowIdxs),
    maplist([R, RowCells]>>(walk_zigzag_row_(R, NC, RowCells)), RowIdxs, AllRows),
    append(AllRows, Cells).

% walk_diag_scan(+Grid, -Cells): cells grouped by main diagonal (D = C - R).
% Diagonals from D = -(NR-1) to D = NC-1; within each diagonal, top to bottom.
walk_diag_scan(Grid, Cells) :-
    % Get grid dimensions and diagonal range.
    walk_dims_(Grid, NR, NC),
    NR1 is NR - 1, NC1 is NC - 1,
    DMin is -NR1, DMax is NC1,
    % Collect diagonals in order.
    numlist(DMin, DMax, Diags),
    maplist([D, DiagCells]>>(
        % Row range for this diagonal.
        RMin is max(0, -D), RMax is min(NR1, NC1 - D),
        (RMin > RMax ->
            DiagCells = []
        ;
            numlist(RMin, RMax, Rs),
            maplist([R, R-C]>>(C is R + D), Rs, DiagCells)
        )
    ), Diags, AllDiags),
    % Flatten diagonal lists into one list.
    append(AllDiags, Cells).

% walk_antidiag_scan(+Grid, -Cells): cells grouped by anti-diagonal (D = R + C).
% Anti-diagonals from D = 0 to D = NR+NC-2; within each, top to bottom.
walk_antidiag_scan(Grid, Cells) :-
    % Get grid dimensions and anti-diagonal range.
    walk_dims_(Grid, NR, NC),
    NR1 is NR - 1, NC1 is NC - 1,
    DMax is NR1 + NC1,
    % Collect anti-diagonals in order.
    numlist(0, DMax, Diags),
    maplist([D, DiagCells]>>(
        % Row range for this anti-diagonal.
        RMin is max(0, D - NC1), RMax is min(NR1, D),
        (RMin > RMax ->
            DiagCells = []
        ;
            numlist(RMin, RMax, Rs),
            maplist([R, R-C]>>(C is D - R), Rs, DiagCells)
        )
    ), Diags, AllDiags),
    % Flatten anti-diagonal lists into one list.
    append(AllDiags, Cells).

% walk_ring_cells_(+R0, +C0, +NR, +NC, -Ring): clockwise border cells of sub-grid.
% Starting at (R0,C0) top-left, going right, down, left, up, stopping before start.
walk_ring_cells_(R0, C0, NR, NC, Ring) :-
    % Compute corners of the sub-grid.
    R1 is R0 + NR - 1, C1 is C0 + NC - 1,
    % Top row: left to right.
    findall(R0-C, between(C0, C1, C), Top),
    % Right column: below top-right corner.
    R0p1 is R0 + 1,
    (NR > 1 ->
        findall(R-C1, between(R0p1, R1, R), Right)
    ;
        Right = []
    ),
    % Bottom row: right to left, excluding bottom-right corner (end of Right).
    C1m1 is C1 - 1,
    (NR > 1, NC > 1 ->
        findall(R1-C, between(C0, C1m1, C), BottomFwd),
        reverse(BottomFwd, Bottom)
    ;
        Bottom = []
    ),
    % Left column: bottom to top, excluding both corner cells.
    R1m1 is R1 - 1,
    (NR > 1, NC > 1 ->
        findall(R-C0, between(R0p1, R1m1, R), LeftFwd),
        reverse(LeftFwd, Left)
    ;
        Left = []
    ),
    % Concatenate the four sides.
    append([Top, Right, Bottom, Left], Ring).

% walk_spiral_in_(+R0, +C0, +NR, +NC, -Cells): recursive ring peel for spiral.
walk_spiral_in_(_, _, NR, _, []) :- NR =< 0, !.
walk_spiral_in_(_, _, _, NC, []) :- NC =< 0, !.
walk_spiral_in_(R0, C0, NR, NC, Cells) :-
    % Peel the outermost ring.
    walk_ring_cells_(R0, C0, NR, NC, Ring),
    % Recurse on the inner sub-grid.
    R02 is R0 + 1, C02 is C0 + 1,
    NR2 is NR - 2, NC2 is NC - 2,
    walk_spiral_in_(R02, C02, NR2, NC2, Inner),
    % Outer ring before inner cells.
    append(Ring, Inner, Cells).

% walk_spiral_in(+Grid, -Cells): cells in clockwise inward spiral from top-left.
% Visits the outermost ring first, then the next inner ring, and so on.
walk_spiral_in(Grid, Cells) :-
    % Get grid dimensions.
    walk_dims_(Grid, NR, NC),
    % Start spiral at top-left (0,0) with full grid dimensions.
    walk_spiral_in_(0, 0, NR, NC, Cells).

% walk_border_walk(+Grid, -Cells): cells on the outer border in clockwise order.
% Starts at (0,0), goes right along top, down the right side, left along bottom,
% up the left side, stopping before returning to the start.
walk_border_walk(Grid, Cells) :-
    % Get grid dimensions.
    walk_dims_(Grid, NR, NC),
    % The border walk is exactly the outermost ring.
    walk_ring_cells_(0, 0, NR, NC, Cells).

% walk_diag_extract(+Grid, +D, -Vals): values on main diagonal D (D = C - R).
% Returns values in top-to-bottom order (increasing R). Empty when D out of range.
walk_diag_extract(Grid, D, Vals) :-
    % Get grid dimensions and valid row range for this diagonal.
    walk_dims_(Grid, NR, NC),
    NR1 is NR - 1, NC1 is NC - 1,
    RMin is max(0, -D), RMax is min(NR1, NC1 - D),
    % Empty when diagonal does not intersect the grid.
    (RMin > RMax ->
        Vals = []
    ;
        numlist(RMin, RMax, Rs),
        maplist([R, V]>>(C is R + D, nth0(R, Grid, Row), nth0(C, Row, V)), Rs, Vals)
    ).

% walk_antidiag_extract(+Grid, +D, -Vals): values on anti-diagonal D (D = R + C).
% Returns values in top-to-bottom order (increasing R). Empty when D out of range.
walk_antidiag_extract(Grid, D, Vals) :-
    % Get grid dimensions and valid row range for this anti-diagonal.
    walk_dims_(Grid, NR, NC),
    NR1 is NR - 1, NC1 is NC - 1,
    RMin is max(0, D - NC1), RMax is min(NR1, D),
    % Empty when anti-diagonal does not intersect the grid.
    (RMin > RMax ->
        Vals = []
    ;
        numlist(RMin, RMax, Rs),
        maplist([R, V]>>(C is D - R, nth0(R, Grid, Row), nth0(C, Row, V)), Rs, Vals)
    ).

% walk_diag_of(+R-C, -D): main diagonal index D = C - R for cell (R,C).
% All cells with the same D lie on the same top-left-to-bottom-right diagonal.
walk_diag_of(R-C, D) :-
    % Compute the diagonal index.
    D is C - R.

% walk_antidiag_of(+R-C, -D): anti-diagonal index D = R + C for cell (R,C).
% All cells with the same D lie on the same top-right-to-bottom-left diagonal.
walk_antidiag_of(R-C, D) :-
    % Compute the anti-diagonal index.
    D is R + C.

% walk_cells_to_vals(+Grid, +Cells, -Vals): extract grid values at R-C positions.
% Vals[i] = Grid[Cells[i].R][Cells[i].C] for each cell in the list.
walk_cells_to_vals(Grid, Cells, Vals) :-
    % Map each R-C position to its grid value.
    maplist([R-C, V]>>(nth0(R, Grid, Row), nth0(C, Row, V)), Cells, Vals).

% walk_set_cell_(+Grid, +R, +C, +V, -Result): set one cell in a grid.
% Uses append/3 to split and reassemble rows and columns.
walk_set_cell_(Grid, R, C, V, Result) :-
    % Split grid at row R.
    length(PreRows, R),
    append(PreRows, [Row|SufRows], Grid),
    % Split row at column C.
    length(PreCols, C),
    append(PreCols, [_|SufCols], Row),
    % Reassemble row with new value.
    append(PreCols, [V|SufCols], NewRow),
    % Reassemble grid with new row.
    append(PreRows, [NewRow|SufRows], Result).

% walk_vals_to_cells(+Grid, +Cells, +Vals, -Result): paint values at R-C positions.
% Sets Grid[Cells[i].R][Cells[i].C] = Vals[i] for each pair, left to right.
walk_vals_to_cells(Grid, [], [], Grid) :- !.
walk_vals_to_cells(Grid0, [R-C|RestCells], [V|RestVals], Result) :-
    % Paint one cell.
    walk_set_cell_(Grid0, R, C, V, Grid1),
    % Continue with remaining cells.
    walk_vals_to_cells(Grid1, RestCells, RestVals, Result).

% walk_inner_cells(+Grid, -Cells): all non-border cells as R-C pairs.
% Inner cells are rows 1 to NR-2 and columns 1 to NC-2.
% Returns empty list when grid has fewer than 3 rows or 3 columns.
walk_inner_cells(Grid, Cells) :-
    % Get grid dimensions.
    walk_dims_(Grid, NR, NC),
    % Inner row bound is NR-2; inner column bound is NC-2.
    NR2 is NR - 2, NC2 is NC - 2,
    % If either inner bound is below 1 there are no inner cells.
    (   (NR2 < 1 ; NC2 < 1)
    ->  Cells = []
    ;   findall(R-C, (between(1, NR2, R), between(1, NC2, C)), Cells)
    ).
