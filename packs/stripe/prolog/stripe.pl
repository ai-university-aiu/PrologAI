% stripe.pl - Layer 97: Uniform Row and Column Stripe Operations (sr_* prefix).
% Detects uniform rows and columns, fills stripes, and computes row-column intersections.
:- module(stripe, [
    sr_uniform_row/3,
    sr_uniform_col/3,
    sr_uniform_rows/3,
    sr_uniform_cols/3,
    sr_all_stripe_rows/2,
    sr_all_stripe_cols/2,
    sr_mixed_rows/2,
    sr_mixed_cols/2,
    sr_fill_row/4,
    sr_fill_col/4,
    sr_fill_rows/4,
    sr_fill_cols/4,
    sr_cross_cells/4,
    sr_cross_fill/5
]).
% Import list utilities for membership, indexing, and filtering.
:- use_module(library(lists), [nth0/3, numlist/3, append/2]).
% Import higher-order utilities for row mapping and filtering.
:- use_module(library(apply), [maplist/2, maplist/3, include/3]).

% sr_col_: internal helper to extract column C from Grid as a list of values.
sr_col_(Grid, C, Col) :-
% For each row, take the cell at position C.
    maplist([Row, V]>>(nth0(C, Row, V)), Grid, Col).

% sr_replace_nth_: replace the element at 0-based index N in List with Val.
% Uses a cut in the base case to ensure determinism.
sr_replace_nth_(0, [_|T], Val, [Val|T]) :- !.
sr_replace_nth_(N, [H|T], Val, [H|T2]) :-
% Decrement index and recurse on the tail.
    N1 is N - 1,
    sr_replace_nth_(N1, T, Val, T2).

% sr_fill_row_: replace row R in Grid with a row of all Color.
sr_fill_row_(Grid, R, Color, Result) :-
% Determine the grid width from the first row.
    Grid = [FR|_], length(FR, Cols),
% Build a new row filled entirely with Color.
    length(FilledRow, Cols), maplist(=(Color), FilledRow),
% Replace the old row at index R with the filled row.
    sr_replace_nth_(R, Grid, FilledRow, Result).

% sr_fill_col_: replace column C in every row of Grid with Color.
sr_fill_col_(Grid, C, Color, Result) :-
% In each row, replace the cell at index C with Color.
    maplist([Row, NewRow]>>(sr_replace_nth_(C, Row, Color, NewRow)), Grid, Result).

% sr_uniform_row(+Grid, +R, -Color): row R is all the same value Color.
% Succeeds if every cell in row R equals Color; fails otherwise.
sr_uniform_row(Grid, R, Color) :-
% Extract row R.
    nth0(R, Grid, Row),
% Row must be non-empty.
    Row = [Color|_],
% All cells must equal Color.
    maplist(=(Color), Row).

% sr_uniform_col(+Grid, +C, -Color): column C is all the same value Color.
% Succeeds if every cell in column C equals Color; fails otherwise.
sr_uniform_col(Grid, C, Color) :-
% Extract column C.
    sr_col_(Grid, C, Col),
% Column must be non-empty.
    Col = [Color|_],
% All cells must equal Color.
    maplist(=(Color), Col).

% sr_uniform_rows(+Grid, +Color, -Rows): sorted list of row indices that are all Color.
sr_uniform_rows(Grid, Color, Rows) :-
% Get the row count.
    length(Grid, NR),
    (NR > 0 -> NR1 is NR - 1, numlist(0, NR1, All) ; All = []),
% Keep only rows where every cell equals Color.
    include([R]>>(sr_uniform_row(Grid, R, Color)), All, Rows).

% sr_uniform_cols(+Grid, +Color, -Cols): sorted list of column indices that are all Color.
sr_uniform_cols(Grid, Color, Cols) :-
% Get the column count.
    (Grid = [FR|_] -> length(FR, NC) ; NC = 0),
    (NC > 0 -> NC1 is NC - 1, numlist(0, NC1, All) ; All = []),
% Keep only columns where every cell equals Color.
    include([C]>>(sr_uniform_col(Grid, C, Color)), All, Cols).

% sr_all_stripe_rows(+Grid, -Pairs): R-Color pairs for all uniform rows.
% Pairs is in row-index order. Non-uniform rows are omitted.
sr_all_stripe_rows(Grid, Pairs) :-
% Enumerate all row indices.
    length(Grid, NR),
    (NR > 0 -> NR1 is NR - 1, numlist(0, NR1, All) ; All = []),
% Collect R-Color pairs for rows that are uniform.
    sr_stripe_row_pairs_(All, Grid, Pairs).

% sr_stripe_row_pairs_: collect R-Color pairs for rows that are uniform.
sr_stripe_row_pairs_([], _, []).
sr_stripe_row_pairs_([R|Rs], Grid, Pairs) :-
% Check if row R is uniform; use if-then-else for determinism.
    (sr_uniform_row(Grid, R, Color) ->
        Pairs = [R-Color | Rest]
    ;
        Pairs = Rest
    ),
    sr_stripe_row_pairs_(Rs, Grid, Rest).

% sr_all_stripe_cols(+Grid, -Pairs): C-Color pairs for all uniform columns.
% Pairs is in column-index order. Non-uniform columns are omitted.
sr_all_stripe_cols(Grid, Pairs) :-
% Enumerate all column indices.
    (Grid = [FR|_] -> length(FR, NC) ; NC = 0),
    (NC > 0 -> NC1 is NC - 1, numlist(0, NC1, All) ; All = []),
    sr_stripe_col_pairs_(All, Grid, Pairs).

% sr_stripe_col_pairs_: collect C-Color pairs for columns that are uniform.
sr_stripe_col_pairs_([], _, []).
sr_stripe_col_pairs_([C|Cs], Grid, Pairs) :-
% Check if column C is uniform; use if-then-else for determinism.
    (sr_uniform_col(Grid, C, Color) ->
        Pairs = [C-Color | Rest]
    ;
        Pairs = Rest
    ),
    sr_stripe_col_pairs_(Cs, Grid, Rest).

% sr_mixed_rows(+Grid, -Rows): sorted row indices that are NOT uniform.
% A mixed row has at least two distinct cell values.
sr_mixed_rows(Grid, Rows) :-
% Enumerate all row indices.
    length(Grid, NR),
    (NR > 0 -> NR1 is NR - 1, numlist(0, NR1, All) ; All = []),
% Keep rows where sr_uniform_row fails (no single color covers all cells).
    include([R]>>(\+ sr_uniform_row(Grid, R, _)), All, Rows).

% sr_mixed_cols(+Grid, -Cols): sorted column indices that are NOT uniform.
% A mixed column has at least two distinct cell values.
sr_mixed_cols(Grid, Cols) :-
% Enumerate all column indices.
    (Grid = [FR|_] -> length(FR, NC) ; NC = 0),
    (NC > 0 -> NC1 is NC - 1, numlist(0, NC1, All) ; All = []),
% Keep columns where sr_uniform_col fails.
    include([C]>>(\+ sr_uniform_col(Grid, C, _)), All, Cols).

% sr_fill_row(+Grid, +R, +Color, -Result): return Grid with row R set to all Color.
sr_fill_row(Grid, R, Color, Result) :-
% Delegate to the internal helper.
    sr_fill_row_(Grid, R, Color, Result).

% sr_fill_col(+Grid, +C, +Color, -Result): return Grid with column C set to all Color.
sr_fill_col(Grid, C, Color, Result) :-
% Delegate to the internal helper.
    sr_fill_col_(Grid, C, Color, Result).

% sr_fill_rows(+Grid, +Rows, +Color, -Result): fill each row index in Rows with Color.
% Uses if-then-else for deterministic base and recursive cases.
sr_fill_rows(Grid, Rows, Color, Result) :-
    (Rows = [] ->
% No rows to fill; return grid unchanged.
        Result = Grid
    ;
        Rows = [R|Rs],
% Fill row R.
        sr_fill_row_(Grid, R, Color, G2),
% Continue with remaining rows.
        sr_fill_rows(G2, Rs, Color, Result)
    ).

% sr_fill_cols(+Grid, +Cols, +Color, -Result): fill each column index in Cols with Color.
% Uses if-then-else for deterministic base and recursive cases.
sr_fill_cols(Grid, Cols, Color, Result) :-
    (Cols = [] ->
% No columns to fill; return grid unchanged.
        Result = Grid
    ;
        Cols = [C|Cs],
% Fill column C.
        sr_fill_col_(Grid, C, Color, G2),
% Continue with remaining columns.
        sr_fill_cols(G2, Cs, Color, Result)
    ).

% sr_cross_cells(+Grid, +Rows, +Cols, -Cells): r(R,C) terms at every Rows x Cols intersection.
% Returns a list of r(R,C) for each (R,C) pair where R is in Rows and C is in Cols.
sr_cross_cells(_, Rows, Cols, Cells) :-
% Build the cross product of Rows x Cols as r(R,C) terms.
    sr_cross_product_(Rows, Cols, Cells).

% sr_cross_product_: produce r(R,C) for all R in Rows, C in Cols.
sr_cross_product_([], _, []).
sr_cross_product_([R|Rs], Cols, Cells) :-
% For this R, pair with every C.
    maplist([C, r(R,C)]>>true, Cols, RowCells),
% Recurse for remaining rows and append.
    sr_cross_product_(Rs, Cols, RestCells),
    append(RowCells, RestCells, Cells).

% sr_cross_fill(+Grid, +Rows, +Cols, +Color, -Result): fill all Rows x Cols cells with Color.
% Fills all listed rows with Color, then all listed columns with Color.
sr_cross_fill(Grid, Rows, Cols, Color, Result) :-
% Fill all specified rows with Color.
    sr_fill_rows(Grid, Rows, Color, G2),
% Fill all specified columns with Color in the row-filled grid.
    sr_fill_cols(G2, Cols, Color, Result).
