% stripe.pl - Layer 97: Uniform Row and Column Stripe Operations (sr_* prefix).
% Detects uniform rows and columns, fills stripes, and computes row-column intersections.
:- module(stripe, [
    stripe_uniform_row/3,
    stripe_uniform_col/3,
    stripe_uniform_rows/3,
    stripe_uniform_cols/3,
    stripe_all_stripe_rows/2,
    stripe_all_stripe_cols/2,
    stripe_mixed_rows/2,
    stripe_mixed_cols/2,
    stripe_fill_row/4,
    stripe_fill_col/4,
    stripe_fill_rows/4,
    stripe_fill_cols/4,
    stripe_cross_cells/4,
    stripe_cross_fill/5
]).
% Import list utilities for membership, indexing, and filtering.
:- use_module(library(lists), [nth0/3, numlist/3, append/2]).
% Import higher-order utilities for row mapping and filtering.
:- use_module(library(apply), [maplist/2, maplist/3, include/3]).

% stripe_col_: internal helper to extract column C from Grid as a list of values.
stripe_col_(Grid, C, Col) :-
% For each row, take the cell at position C.
    maplist([Row, V]>>(nth0(C, Row, V)), Grid, Col).

% stripe_replace_nth_: replace the element at 0-based index N in List with Val.
% Uses a cut in the base case to ensure determinism.
stripe_replace_nth_(0, [_|T], Val, [Val|T]) :- !.
stripe_replace_nth_(N, [H|T], Val, [H|T2]) :-
% Decrement index and recurse on the tail.
    N1 is N - 1,
    stripe_replace_nth_(N1, T, Val, T2).

% stripe_fill_row_: replace row R in Grid with a row of all Color.
stripe_fill_row_(Grid, R, Color, Result) :-
% Determine the grid width from the first row.
    Grid = [FR|_], length(FR, Cols),
% Build a new row filled entirely with Color.
    length(FilledRow, Cols), maplist(=(Color), FilledRow),
% Replace the old row at index R with the filled row.
    stripe_replace_nth_(R, Grid, FilledRow, Result).

% stripe_fill_col_: replace column C in every row of Grid with Color.
stripe_fill_col_(Grid, C, Color, Result) :-
% In each row, replace the cell at index C with Color.
    maplist([Row, NewRow]>>(stripe_replace_nth_(C, Row, Color, NewRow)), Grid, Result).

% stripe_uniform_row(+Grid, +R, -Color): row R is all the same value Color.
% Succeeds if every cell in row R equals Color; fails otherwise.
stripe_uniform_row(Grid, R, Color) :-
% Extract row R.
    nth0(R, Grid, Row),
% Row must be non-empty.
    Row = [Color|_],
% All cells must equal Color.
    maplist(=(Color), Row).

% stripe_uniform_col(+Grid, +C, -Color): column C is all the same value Color.
% Succeeds if every cell in column C equals Color; fails otherwise.
stripe_uniform_col(Grid, C, Color) :-
% Extract column C.
    stripe_col_(Grid, C, Col),
% Column must be non-empty.
    Col = [Color|_],
% All cells must equal Color.
    maplist(=(Color), Col).

% stripe_uniform_rows(+Grid, +Color, -Rows): sorted list of row indices that are all Color.
stripe_uniform_rows(Grid, Color, Rows) :-
% Get the row count.
    length(Grid, NR),
    (NR > 0 -> NR1 is NR - 1, numlist(0, NR1, All) ; All = []),
% Keep only rows where every cell equals Color.
    include([R]>>(stripe_uniform_row(Grid, R, Color)), All, Rows).

% stripe_uniform_cols(+Grid, +Color, -Cols): sorted list of column indices that are all Color.
stripe_uniform_cols(Grid, Color, Cols) :-
% Get the column count.
    (Grid = [FR|_] -> length(FR, NC) ; NC = 0),
    (NC > 0 -> NC1 is NC - 1, numlist(0, NC1, All) ; All = []),
% Keep only columns where every cell equals Color.
    include([C]>>(stripe_uniform_col(Grid, C, Color)), All, Cols).

% stripe_all_stripe_rows(+Grid, -Pairs): R-Color pairs for all uniform rows.
% Pairs is in row-index order. Non-uniform rows are omitted.
stripe_all_stripe_rows(Grid, Pairs) :-
% Enumerate all row indices.
    length(Grid, NR),
    (NR > 0 -> NR1 is NR - 1, numlist(0, NR1, All) ; All = []),
% Collect R-Color pairs for rows that are uniform.
    stripe_stripe_row_pairs_(All, Grid, Pairs).

% stripe_stripe_row_pairs_: collect R-Color pairs for rows that are uniform.
stripe_stripe_row_pairs_([], _, []).
stripe_stripe_row_pairs_([R|Rs], Grid, Pairs) :-
% Check if row R is uniform; use if-then-else for determinism.
    (stripe_uniform_row(Grid, R, Color) ->
        Pairs = [R-Color | Rest]
    ;
        Pairs = Rest
    ),
    stripe_stripe_row_pairs_(Rs, Grid, Rest).

% stripe_all_stripe_cols(+Grid, -Pairs): C-Color pairs for all uniform columns.
% Pairs is in column-index order. Non-uniform columns are omitted.
stripe_all_stripe_cols(Grid, Pairs) :-
% Enumerate all column indices.
    (Grid = [FR|_] -> length(FR, NC) ; NC = 0),
    (NC > 0 -> NC1 is NC - 1, numlist(0, NC1, All) ; All = []),
    stripe_stripe_col_pairs_(All, Grid, Pairs).

% stripe_stripe_col_pairs_: collect C-Color pairs for columns that are uniform.
stripe_stripe_col_pairs_([], _, []).
stripe_stripe_col_pairs_([C|Cs], Grid, Pairs) :-
% Check if column C is uniform; use if-then-else for determinism.
    (stripe_uniform_col(Grid, C, Color) ->
        Pairs = [C-Color | Rest]
    ;
        Pairs = Rest
    ),
    stripe_stripe_col_pairs_(Cs, Grid, Rest).

% stripe_mixed_rows(+Grid, -Rows): sorted row indices that are NOT uniform.
% A mixed row has at least two distinct cell values.
stripe_mixed_rows(Grid, Rows) :-
% Enumerate all row indices.
    length(Grid, NR),
    (NR > 0 -> NR1 is NR - 1, numlist(0, NR1, All) ; All = []),
% Keep rows where stripe_uniform_row fails (no single color covers all cells).
    include([R]>>(\+ stripe_uniform_row(Grid, R, _)), All, Rows).

% stripe_mixed_cols(+Grid, -Cols): sorted column indices that are NOT uniform.
% A mixed column has at least two distinct cell values.
stripe_mixed_cols(Grid, Cols) :-
% Enumerate all column indices.
    (Grid = [FR|_] -> length(FR, NC) ; NC = 0),
    (NC > 0 -> NC1 is NC - 1, numlist(0, NC1, All) ; All = []),
% Keep columns where stripe_uniform_col fails.
    include([C]>>(\+ stripe_uniform_col(Grid, C, _)), All, Cols).

% stripe_fill_row(+Grid, +R, +Color, -Result): return Grid with row R set to all Color.
stripe_fill_row(Grid, R, Color, Result) :-
% Delegate to the internal helper.
    stripe_fill_row_(Grid, R, Color, Result).

% stripe_fill_col(+Grid, +C, +Color, -Result): return Grid with column C set to all Color.
stripe_fill_col(Grid, C, Color, Result) :-
% Delegate to the internal helper.
    stripe_fill_col_(Grid, C, Color, Result).

% stripe_fill_rows(+Grid, +Rows, +Color, -Result): fill each row index in Rows with Color.
% Uses if-then-else for deterministic base and recursive cases.
stripe_fill_rows(Grid, Rows, Color, Result) :-
    (Rows = [] ->
% No rows to fill; return grid unchanged.
        Result = Grid
    ;
        Rows = [R|Rs],
% Fill row R.
        stripe_fill_row_(Grid, R, Color, G2),
% Continue with remaining rows.
        stripe_fill_rows(G2, Rs, Color, Result)
    ).

% stripe_fill_cols(+Grid, +Cols, +Color, -Result): fill each column index in Cols with Color.
% Uses if-then-else for deterministic base and recursive cases.
stripe_fill_cols(Grid, Cols, Color, Result) :-
    (Cols = [] ->
% No columns to fill; return grid unchanged.
        Result = Grid
    ;
        Cols = [C|Cs],
% Fill column C.
        stripe_fill_col_(Grid, C, Color, G2),
% Continue with remaining columns.
        stripe_fill_cols(G2, Cs, Color, Result)
    ).

% stripe_cross_cells(+Grid, +Rows, +Cols, -Cells): r(R,C) terms at every Rows x Cols intersection.
% Returns a list of r(R,C) for each (R,C) pair where R is in Rows and C is in Cols.
stripe_cross_cells(_, Rows, Cols, Cells) :-
% Build the cross product of Rows x Cols as r(R,C) terms.
    stripe_cross_product_(Rows, Cols, Cells).

% stripe_cross_product_: produce r(R,C) for all R in Rows, C in Cols.
stripe_cross_product_([], _, []).
stripe_cross_product_([R|Rs], Cols, Cells) :-
% For this R, pair with every C.
    maplist([C, r(R,C)]>>true, Cols, RowCells),
% Recurse for remaining rows and append.
    stripe_cross_product_(Rs, Cols, RestCells),
    append(RowCells, RestCells, Cells).

% stripe_cross_fill(+Grid, +Rows, +Cols, +Color, -Result): fill all Rows x Cols cells with Color.
% Fills all listed rows with Color, then all listed columns with Color.
stripe_cross_fill(Grid, Rows, Cols, Color, Result) :-
% Fill all specified rows with Color.
    stripe_fill_rows(Grid, Rows, Color, G2),
% Fill all specified columns with Color in the row-filled grid.
    stripe_fill_cols(G2, Cols, Color, Result).
