% scan.pl - Layer 115: Grid Cell Enumeration and Manipulation (sn_* prefix).
% Provides predicates for enumerating grid cells in row-major, column-major,
% boustrophedon, spiral, border, and diagonal traversal orders; reading and
% writing individual cells or batches; mapping a goal over all cells;
% filtering cells by predicate; and reconstructing grids from sparse cell lists.
% Module declaration naming this file scan with its 14 exported predicates.
:- module(scan, [
    % Enumerate all R-C-V triples in row-major order (top-to-bottom, left-to-right).
    sn_row_major/2,
    % Enumerate all R-C-V triples in column-major order (left-to-right, top-to-bottom).
    sn_col_major/2,
    % List all R-C position pairs where the cell value equals V.
    sn_cells_of/3,
    % Return a new grid identical to Grid except cell (R,C) holds value V.
    sn_set_cell/5,
    % Apply Goal(R, C, OldV, NewV) to every cell, producing a transformed grid.
    sn_map_cells/3,
    % Collect all R-C-V triples satisfying Pred(R, C, V).
    sn_filter_cells/3,
    % Apply a list of R-C-V triples as batch cell updates, returning a new grid.
    sn_update_cells/3,
    % Enumerate cells in boustrophedon order: even rows left-to-right, odd rows right-to-left.
    sn_zigzag/2,
    % Enumerate cells in clockwise spiral order from the outer ring inward.
    sn_spiral_in/2,
    % Enumerate the outer border cells clockwise starting at the top-left corner.
    sn_border_traversal/2,
    % Enumerate cells along NE-going diagonals where R+C is constant.
    sn_diag_traversal_ne/2,
    % Enumerate cells along SE-going diagonals where C-R is constant.
    sn_diag_traversal_se/2,
    % Build an H-by-W grid from a sparse list of R-C-V triples, filling gaps with Bg.
    sn_grid_from_cells/5,
    % Find the first occurrence of value V in the grid in row-major order.
    sn_index_of/4
]).
% Import memberchk for membership test, nth0 for indexed access,
% append/3 for list concatenation, and reverse/2 for list reversal.
:- use_module(library(lists), [memberchk/2, nth0/3, append/3, reverse/2]).

% sn_row_major(+Grid, -Cells): all R-C-V triples enumerated in row-major order.
% Visits row 0 column 0..W-1, then row 1 column 0..W-1, and so on.
sn_row_major(Grid, Cells) :-
% Get the grid height.
    length(Grid, H), H1 is H - 1,
% Get the grid width from the first row, defaulting to 0 for an empty grid.
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
% Collect each triple with row enumerated in the outer loop.
    findall(R-C-V, (
% Enumerate row indices 0 to H-1.
        between(0, H1, R),
% Enumerate column indices 0 to W-1 for each row.
        between(0, W1, C),
% Retrieve the row.
        nth0(R, Grid, Row),
% Retrieve the cell value.
        nth0(C, Row, V)
    ), Cells).

% sn_col_major(+Grid, -Cells): all R-C-V triples enumerated in column-major order.
% Visits column 0 row 0..H-1, then column 1 row 0..H-1, and so on.
sn_col_major(Grid, Cells) :-
% Get the grid height.
    length(Grid, H), H1 is H - 1,
% Get the grid width from the first row, defaulting to 0 for an empty grid.
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
% Collect each triple with column enumerated in the outer loop.
    findall(R-C-V, (
% Enumerate column indices 0 to W-1.
        between(0, W1, C),
% Enumerate row indices 0 to H-1 for each column.
        between(0, H1, R),
% Retrieve the row.
        nth0(R, Grid, Row),
% Retrieve the cell value.
        nth0(C, Row, V)
    ), Cells).

% sn_cells_of(+Grid, +V, -Cells): list of all R-C pairs where the cell equals V.
% Each element of Cells is a pair R-C (row, column).
sn_cells_of(Grid, V, Cells) :-
% Get the grid height.
    length(Grid, H), H1 is H - 1,
% Get the grid width from the first row, defaulting to 0 for an empty grid.
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
% Collect every R-C pair where the cell value unifies with V.
    findall(R-C, (
% Enumerate row and column indices.
        between(0, H1, R), between(0, W1, C),
% Retrieve the row.
        nth0(R, Grid, Row),
% Unify the cell value with V.
        nth0(C, Row, V)
    ), Cells).

% sn_set_cell(+Grid, +R, +C, +V, -New): new grid with cell (R,C) set to V.
% All other cells are unchanged. R and C are 0-based.
sn_set_cell(Grid, R, C, V, New) :-
% Compute the maximum valid row index.
    length(Grid, H), H1 is H - 1,
% Build the new grid row by row.
    findall(NewRow, (
% Enumerate row indices.
        between(0, H1, Ri),
% Retrieve the original row.
        nth0(Ri, Grid, OldRow),
% Replace the target row; copy all other rows unchanged.
        (   Ri =:= R
        ->  sn_set_elem_(OldRow, C, V, NewRow)
        ;   NewRow = OldRow
        )
    ), New).

% sn_set_elem_(+Row, +C, +V, -New): list with position C replaced by V.
sn_set_elem_(Row, C, V, New) :-
% Compute the maximum valid column index.
    length(Row, Len), Len1 is Len - 1,
% Build the new row element by element.
    findall(Cell, (
% Enumerate column indices.
        between(0, Len1, Ci),
% Retrieve the original value.
        nth0(Ci, Row, OldV),
% Replace the target cell; copy all other cells unchanged.
        (Ci =:= C -> Cell = V ; Cell = OldV)
    ), New).

% sn_map_cells(+Grid, :Goal, -New): apply Goal(R, C, OldV, NewV) to every cell.
% New is the grid produced by replacing each cell value with the NewV from Goal.
sn_map_cells(Grid, Goal, New) :-
% Get the grid height.
    length(Grid, H), H1 is H - 1,
% Get the grid width from the first row, defaulting to 0 for an empty grid.
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
% Build each transformed row.
    findall(NewRow, (
% Enumerate row indices.
        between(0, H1, R),
% Build each transformed cell within the row.
        findall(NV, (
% Enumerate column indices.
            between(0, W1, C),
% Retrieve the original row.
            nth0(R, Grid, Row),
% Retrieve the original cell value.
            nth0(C, Row, OV),
% Apply the user-supplied 4-argument goal to compute the new value.
            call(Goal, R, C, OV, NV)
        ), NewRow)
    ), New).

% sn_filter_cells(+Grid, :Pred, -Cells): R-C-V triples satisfying Pred(R, C, V).
% Pred is called as call(Pred, R, C, V) and must succeed for a cell to be kept.
sn_filter_cells(Grid, Pred, Cells) :-
% Get the grid height.
    length(Grid, H), H1 is H - 1,
% Get the grid width from the first row, defaulting to 0 for an empty grid.
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
% Collect every R-C-V triple for which Pred succeeds.
    findall(R-C-V, (
% Enumerate row and column indices.
        between(0, H1, R), between(0, W1, C),
% Retrieve the row.
        nth0(R, Grid, Row),
% Retrieve the cell value.
        nth0(C, Row, V),
% Test the user-supplied predicate.
        call(Pred, R, C, V)
    ), Cells).

% sn_update_cells(+Grid, +Updates, -New): apply batch R-C-V cell updates.
% Updates is a list of R-C-V triples. Cells listed in Updates get the new value;
% all other cells are unchanged. If a cell appears multiple times, the first match wins.
sn_update_cells(Grid, Updates, New) :-
% Get the grid height.
    length(Grid, H), H1 is H - 1,
% Get the grid width from the first row, defaulting to 0 for an empty grid.
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
% Build each updated row.
    findall(NewRow, (
% Enumerate row indices.
        between(0, H1, R),
% Build each updated cell within the row.
        findall(NV, (
% Enumerate column indices.
            between(0, W1, C),
% Retrieve the original row.
            nth0(R, Grid, Row),
% Retrieve the original cell value.
            nth0(C, Row, OV),
% Use the update value if R-C is in Updates, otherwise keep the original.
            (   memberchk(R-C-NV, Updates)
            ->  true
            ;   NV = OV
            )
        ), NewRow)
    ), New).

% sn_zigzag(+Grid, -Cells): boustrophedon traversal (alternating row directions).
% Even rows (0, 2, 4, ...) are visited left-to-right; odd rows right-to-left.
sn_zigzag(Grid, Cells) :-
% Get the grid height.
    length(Grid, H), H1 is H - 1,
% Get the grid width from the first row, defaulting to 0 for an empty grid.
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
% Collect each triple with direction determined by row parity.
    findall(R-C-V, (
% Enumerate row indices.
        between(0, H1, R),
% Retrieve the row.
        nth0(R, Grid, Row),
% Enumerate a column offset 0..W-1.
        between(0, W1, Offset),
% Even rows go left-to-right; odd rows go right-to-left.
        (   0 is R mod 2
        ->  C = Offset
        ;   C is W1 - Offset
        ),
% Retrieve the cell value at the computed column.
        nth0(C, Row, V)
    ), Cells).

% sn_spiral_in(+Grid, -Cells): clockwise spiral from the outermost ring inward.
% Visits: top row left-to-right, right column top-to-bottom, bottom row
% right-to-left, left column bottom-to-top, then recurses on the inner ring.
sn_spiral_in(Grid, Cells) :-
% Compute grid dimensions.
    length(Grid, H), B0 is H - 1,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), R0 is W - 1,
% Delegate to the recursive ring helper.
    sn_spiral_(Grid, 0, B0, 0, R0, Cells).

% sn_spiral_(+Grid, +T, +B, +L, +R, -Cells): collect one ring then recurse.
% T, B, L, R are inclusive row/column bounds for the current ring.
% Terminates when T > B (no rows) or L > R (no columns).
sn_spiral_(Grid, T, B, L, R, Cells) :-
% Base case: the ring is empty when rows or columns are exhausted.
    (   T > B
    ->  Cells = []
    ;   L > R
    ->  Cells = []
    ;
% Compute inner ring bounds.
        T1 is T + 1, B1 is B - 1,
        L1 is L + 1, R1 is R - 1,
% Top row: traverse columns L to R from left to right.
        findall(T-C-V, (between(L, R, C), nth0(T, Grid, TRow), nth0(C, TRow, V)), TopC),
% Right column: traverse rows T+1 to B from top to bottom.
        findall(Ri-R-V, (between(T1, B, Ri), nth0(Ri, Grid, RRow), nth0(R, RRow, V)), RightC),
% Bottom row right-to-left (only when the ring has more than one row).
        (   T < B
        ->  R2 is R - 1,
            findall(B-C-V, (between(L, R2, C), nth0(B, Grid, BRow), nth0(C, BRow, V)), BotFwd),
% Reverse to get right-to-left order.
            reverse(BotFwd, BotC)
        ;   BotC = []
        ),
% Left column bottom-to-top (only when ring height >= 3 and width >= 2).
        (   T1 =< B1, L < R
        ->  findall(Ri-L-V, (between(T1, B1, Ri), nth0(Ri, Grid, LRow), nth0(L, LRow, V)), LeftFwd),
% Reverse to get bottom-to-top order.
            reverse(LeftFwd, LeftC)
        ;   LeftC = []
        ),
% Recurse on the inner ring with shrunk bounds.
        sn_spiral_(Grid, T1, B1, L1, R1, Rest),
% Concatenate: top, right, bottom-reversed, left-reversed, inner.
        append(TopC, RightC, P1),
        append(P1, BotC, P2),
        append(P2, LeftC, P3),
        append(P3, Rest, Cells)
    ).

% sn_border_traversal(+Grid, -Cells): outer border cells in clockwise order.
% Visits: top row left-to-right, right column (excluding top), bottom row
% right-to-left (excluding right corner), left column (excluding both corners).
sn_border_traversal(Grid, Cells) :-
% Compute grid dimensions.
    length(Grid, H),
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0),
    H1 is H - 1, W1 is W - 1,
% Top row: traverse all columns left to right.
    findall(0-C-V, (between(0, W1, C), nth0(0, Grid, TR0), nth0(C, TR0, V)), TopC),
% Right column, bottom row, left column only when there is more than one row.
    (   H > 1
    ->
% Right column: rows 1..H-1 top to bottom.
        findall(Ri-W1-V, (between(1, H1, Ri), nth0(Ri, Grid, RC), nth0(W1, RC, V)), RightC),
% Bottom row right-to-left excluding the right corner.
        W2 is W1 - 1,
        findall(H1-C-V, (between(0, W2, C), nth0(H1, Grid, BC), nth0(C, BC, V)), BotFwd),
        reverse(BotFwd, BotC),
% Left column bottom-to-top excluding both corners (only when width > 1).
        (   W > 1
        ->  H2 is H1 - 1,
            findall(Ri-0-V, (between(1, H2, Ri), nth0(Ri, Grid, LC), nth0(0, LC, V)), LeftFwd),
            reverse(LeftFwd, LeftC)
        ;   LeftC = []
        )
    ;   RightC = [], BotC = [], LeftC = []
    ),
% Concatenate all four sides.
    append(TopC, RightC, P1),
    append(P1, BotC, P2),
    append(P2, LeftC, Cells).

% sn_diag_traversal_ne(+Grid, -Cells): cells along NE-going diagonals.
% Each diagonal has a constant sum D = R + C, traversed from D=0 to D=H+W-2.
% Within each diagonal, row increases and column decreases.
sn_diag_traversal_ne(Grid, Cells) :-
% Get grid dimensions.
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
% Maximum diagonal index.
    MaxD is H1 + W1,
% Collect each R-C-V triple in diagonal order.
    findall(R-C-V, (
% Enumerate diagonal indices 0 to H+W-2.
        between(0, MaxD, D),
% Enumerate row along this diagonal.
        between(0, D, R),
% Compute the column from the diagonal equation.
        C is D - R,
% Keep only cells within grid bounds.
        R =< H1, C >= 0, C =< W1,
% Retrieve the row.
        nth0(R, Grid, Row),
% Retrieve the cell value.
        nth0(C, Row, V)
    ), Cells).

% sn_diag_traversal_se(+Grid, -Cells): cells along SE-going diagonals.
% Each diagonal has a constant difference D = C - R, traversed from D=-(H-1) to D=W-1.
% Within each diagonal, both row and column increase.
sn_diag_traversal_se(Grid, Cells) :-
% Get grid dimensions.
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
% Diagonal range: from -(H-1) to W-1.
    MinD is -H1, MaxD is W1,
% Collect each R-C-V triple in SE diagonal order.
    findall(R-C-V, (
% Enumerate diagonal indices.
        between(MinD, MaxD, D),
% Enumerate row along this diagonal.
        between(0, H1, R),
% Compute the column from the diagonal equation.
        C is R + D,
% Keep only cells within grid bounds.
        C >= 0, C =< W1,
% Retrieve the row.
        nth0(R, Grid, Row),
% Retrieve the cell value.
        nth0(C, Row, V)
    ), Cells).

% sn_grid_from_cells(+H, +W, +Cells, +Bg, -Grid): build an H-by-W grid.
% Cells is a list of R-C-V triples. Each cell not mentioned in Cells gets Bg.
% If a cell appears multiple times, the first match in Cells is used.
sn_grid_from_cells(H, W, Cells, Bg, Grid) :-
% Compute the maximum valid row and column indices.
    H1 is H - 1, W1 is W - 1,
% Build each row.
    findall(Row, (
% Enumerate row indices.
        between(0, H1, R),
% Build each cell within the row.
        findall(V, (
% Enumerate column indices.
            between(0, W1, C),
% Use the update value if R-C appears in Cells, otherwise use Bg.
            (   memberchk(R-C-V, Cells)
            ->  true
            ;   V = Bg
            )
        ), Row)
    ), Grid).

% sn_index_of(+Grid, +V, -R, -C): row and column of the first occurrence of V.
% Searches in row-major order and commits to the first match via cut.
sn_index_of(Grid, V, R, C) :-
% Get grid dimensions.
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
% Enumerate in row-major order.
    between(0, H1, R),
    between(0, W1, C),
% Retrieve the row.
    nth0(R, Grid, Row),
% Check whether this cell holds V; commit to the first match.
    nth0(C, Row, V), !.
