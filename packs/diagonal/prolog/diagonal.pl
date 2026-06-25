% diagonal.pl - Layer 98: Diagonal Line Extraction and Filling Operations (dg_* prefix).
% Extracts, tests, and fills diagonals and anti-diagonals of 2D grids.
:- module(diagonal, [
    dg_main_diag/2,
    dg_anti_diag/2,
    dg_nth_diag/3,
    dg_nth_anti_diag/3,
    dg_all_diags/2,
    dg_all_anti_diags/2,
    dg_fill_main/3,
    dg_fill_anti/3,
    dg_fill_nth_diag/4,
    dg_fill_nth_anti_diag/4,
    dg_cell_diag/3,
    dg_cell_anti_diag/3,
    dg_uniform_diag/3,
    dg_uniform_anti_diag/3
]).
% Import list utilities for indexing, filtering, and enumeration.
:- use_module(library(lists), [nth0/3, numlist/3, append/2]).
% Import higher-order utilities for cell extraction and row mapping.
:- use_module(library(apply), [maplist/2, maplist/3, include/3]).

% dg_dims_: extract the number of rows and columns from a grid.
dg_dims_(Grid, NR, NC) :-
% Count rows.
    length(Grid, NR),
% Count columns from the first row; 0 if grid is empty.
    (NR > 0 -> Grid = [FR|_], length(FR, NC) ; NC = 0).

% dg_cell_at_: get the value at row R, column C (0-based).
dg_cell_at_(Grid, R, C, V) :-
% Retrieve row R.
    nth0(R, Grid, Row),
% Retrieve cell C within that row.
    nth0(C, Row, V).

% dg_replace_cell_: return Grid with cell (R,C) replaced by V.
% Uses the deterministic sr_replace_nth_ pattern: cut on base case.
dg_replace_nth_list_(0, [_|T], V, [V|T]) :- !.
dg_replace_nth_list_(N, [H|T], V, [H|T2]) :-
% Decrement and recurse.
    N1 is N - 1,
    dg_replace_nth_list_(N1, T, V, T2).

dg_replace_cell_(Grid, R, C, V, Result) :-
% Extract row R; cut to prevent backtracking into nth0.
    nth0(R, Grid, OldRow), !,
% Replace cell C in that row.
    dg_replace_nth_list_(C, OldRow, V, NewRow),
% Replace row R in the grid.
    dg_replace_nth_list_(R, Grid, NewRow, Result).

% dg_fill_cells_: fill a list of (R,C) cell coordinates with Color in Grid.
% Uses if-then-else for deterministic dispatch.
dg_fill_cells_(Grid, CellList, Color, Result) :-
    (CellList = [] ->
% No cells left to fill; return grid unchanged.
        Result = Grid
    ;
        CellList = [R-C|Rest],
% Replace cell (R,C) with Color.
        dg_replace_cell_(Grid, R, C, Color, G2),
% Continue with remaining cells.
        dg_fill_cells_(G2, Rest, Color, Result)
    ).

% dg_diag_cells_: collect valid (R-C) pairs for the diagonal where C-R = Offset.
% Only includes cells within bounds: 0 <= R < NR and 0 <= C < NC.
dg_diag_cells_(NR, NC, Offset, Cells) :-
% Enumerate all possible row indices.
    (NR > 0 -> NR1 is NR - 1, numlist(0, NR1, AllR) ; AllR = []),
% Keep only rows where the corresponding column is in bounds.
    include([R]>>(C is R + Offset, C >= 0, C < NC), AllR, ValidR),
% Build R-C pairs.
    maplist([R, R-C]>>(C is R + Offset), ValidR, Cells).

% dg_anti_diag_cells_: collect valid (R-C) pairs for the anti-diagonal where R+C = Sum.
dg_anti_diag_cells_(NR, NC, Sum, Cells) :-
% Enumerate all possible row indices.
    (NR > 0 -> NR1 is NR - 1, numlist(0, NR1, AllR) ; AllR = []),
% Keep only rows where the corresponding column is in bounds.
    include([R]>>(C is Sum - R, C >= 0, C < NC), AllR, ValidR),
% Build R-C pairs.
    maplist([R, R-C]>>(C is Sum - R), ValidR, Cells).

% dg_main_diag(+Grid, -Diag): values on the main diagonal (cells where R == C).
% Diag is a list of cell values along the main diagonal, from top-left to bottom-right.
dg_main_diag(Grid, Diag) :-
% The main diagonal has offset 0 (C - R = 0).
    dg_dims_(Grid, NR, NC),
    dg_diag_cells_(NR, NC, 0, Cells),
% Extract the value at each (R,C) pair.
    maplist([R-C, V]>>(dg_cell_at_(Grid, R, C, V)), Cells, Diag).

% dg_anti_diag(+Grid, -Diag): values on the main anti-diagonal (R + C = NC - 1).
% The main anti-diagonal passes through the top-right corner (0, NC-1).
% Diag is a list of values from top-right to bottom-left.
dg_anti_diag(Grid, Diag) :-
% The main anti-diagonal sum is NC - 1 (column index of the top-right cell).
    dg_dims_(Grid, NR, NC),
    Sum is NC - 1,
    dg_anti_diag_cells_(NR, NC, Sum, Cells),
    maplist([R-C, V]>>(dg_cell_at_(Grid, R, C, V)), Cells, Diag).

% dg_nth_diag(+Grid, +N, -Diag): values on the N-th diagonal, where C - R = N.
% N = 0 is the main diagonal; N > 0 is above and to the right; N < 0 is below.
dg_nth_diag(Grid, N, Diag) :-
% Collect cells on diagonal N.
    dg_dims_(Grid, NR, NC),
    dg_diag_cells_(NR, NC, N, Cells),
% Extract values.
    maplist([R-C, V]>>(dg_cell_at_(Grid, R, C, V)), Cells, Diag).

% dg_nth_anti_diag(+Grid, +N, -Diag): values on the N-th anti-diagonal, where R + C = N.
% N = 0 is the top-left corner; N = NR+NC-2 is the bottom-right corner.
dg_nth_anti_diag(Grid, N, Diag) :-
% Collect cells on anti-diagonal N.
    dg_dims_(Grid, NR, NC),
    dg_anti_diag_cells_(NR, NC, N, Cells),
% Extract values.
    maplist([R-C, V]>>(dg_cell_at_(Grid, R, C, V)), Cells, Diag).

% dg_all_diags(+Grid, -Diags): list of all diagonals sorted by C-R offset.
% Diags is a list of lists; the N-th element is the diagonal where C-R = Offset.
% Offsets range from -(NR-1) to NC-1.
dg_all_diags(Grid, Diags) :-
% Compute the range of valid offsets.
    dg_dims_(Grid, NR, NC),
    MinOff is -(NR - 1), MaxOff is NC - 1,
    (MinOff =< MaxOff -> numlist(MinOff, MaxOff, Offsets) ; Offsets = []),
% Extract each diagonal in offset order.
    maplist([Off, Diag]>>(dg_nth_diag(Grid, Off, Diag)), Offsets, Diags).

% dg_all_anti_diags(+Grid, -ADiags): list of all anti-diagonals sorted by R+C sum.
% ADiags is a list of lists; the N-th element is the anti-diagonal where R+C = N.
% Sums range from 0 to NR+NC-2.
dg_all_anti_diags(Grid, ADiags) :-
% Compute the range of valid sums.
    dg_dims_(Grid, NR, NC),
    MaxSum is NR + NC - 2,
    (MaxSum >= 0 -> numlist(0, MaxSum, Sums) ; Sums = []),
% Extract each anti-diagonal in sum order.
    maplist([Sum, Diag]>>(dg_nth_anti_diag(Grid, Sum, Diag)), Sums, ADiags).

% dg_fill_main(+Grid, +Color, -Result): fill the main diagonal with Color.
dg_fill_main(Grid, Color, Result) :-
% Collect main diagonal cells.
    dg_dims_(Grid, NR, NC),
    dg_diag_cells_(NR, NC, 0, Cells),
% Fill those cells.
    dg_fill_cells_(Grid, Cells, Color, Result).

% dg_fill_anti(+Grid, +Color, -Result): fill the main anti-diagonal with Color.
dg_fill_anti(Grid, Color, Result) :-
% The main anti-diagonal has sum NC - 1.
    dg_dims_(Grid, NR, NC),
    Sum is NC - 1,
% Collect anti-diagonal cells.
    dg_anti_diag_cells_(NR, NC, Sum, Cells),
% Fill those cells.
    dg_fill_cells_(Grid, Cells, Color, Result).

% dg_fill_nth_diag(+Grid, +N, +Color, -Result): fill the N-th diagonal with Color.
dg_fill_nth_diag(Grid, N, Color, Result) :-
% Collect diagonal N cells.
    dg_dims_(Grid, NR, NC),
    dg_diag_cells_(NR, NC, N, Cells),
% Fill those cells.
    dg_fill_cells_(Grid, Cells, Color, Result).

% dg_fill_nth_anti_diag(+Grid, +N, +Color, -Result): fill the N-th anti-diagonal with Color.
dg_fill_nth_anti_diag(Grid, N, Color, Result) :-
% Collect anti-diagonal N cells.
    dg_dims_(Grid, NR, NC),
    dg_anti_diag_cells_(NR, NC, N, Cells),
% Fill those cells.
    dg_fill_cells_(Grid, Cells, Color, Result).

% dg_cell_diag(+R, +C, -N): which diagonal does cell (R,C) belong to?
% N = C - R. All cells on the same diagonal share this value.
dg_cell_diag(R, C, N) :-
% Compute the offset.
    N is C - R.

% dg_cell_anti_diag(+R, +C, -N): which anti-diagonal does cell (R,C) belong to?
% N = R + C. All cells on the same anti-diagonal share this sum.
dg_cell_anti_diag(R, C, N) :-
% Compute the sum.
    N is R + C.

% dg_uniform_diag(+Grid, +N, -Color): succeed if the N-th diagonal is all Color.
% Fails if the diagonal is empty or contains two or more distinct values.
dg_uniform_diag(Grid, N, Color) :-
% Extract the N-th diagonal.
    dg_nth_diag(Grid, N, Diag),
% Diagonal must be non-empty.
    Diag = [Color|_],
% All values must equal Color.
    maplist(=(Color), Diag).

% dg_uniform_anti_diag(+Grid, +N, -Color): succeed if the N-th anti-diagonal is all Color.
% Fails if the anti-diagonal is empty or contains two or more distinct values.
dg_uniform_anti_diag(Grid, N, Color) :-
% Extract the N-th anti-diagonal.
    dg_nth_anti_diag(Grid, N, Diag),
% Anti-diagonal must be non-empty.
    Diag = [Color|_],
% All values must equal Color.
    maplist(=(Color), Diag).
