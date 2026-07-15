:- module(grid_row_column, [
    grid_row_column_row/3,
    grid_row_column_col/3,
    grid_row_column_row_uniform/3,
    grid_row_column_col_uniform/3,
    grid_row_column_equal_rows/3,
    grid_row_column_equal_cols/3,
    grid_row_column_row_positions/3,
    grid_row_column_col_positions/3,
    grid_row_column_matching_rows/2,
    grid_row_column_matching_cols/2,
    grid_row_column_unique_rows/2,
    grid_row_column_unique_cols/2,
    grid_row_column_row_sort/2,
    grid_row_column_col_sort/2
]).
% gridrowcol.pl - Layer 219: Grid Row and Column Comparative Analysis (grc_* prefix).
% Provides predicates for extracting, comparing, sorting, and finding matching
% rows and columns in a raw grid. Rows and columns are treated as first-class
% list objects for direct comparison and lookup.
% Raw grid format: list of rows, each a list of color atoms, 0-indexed.
% No cross-pack dependencies.
:- use_module(library(lists), [nth0/3, member/2]).

% --- PRIVATE HELPERS ---

% Grid dimensions: H rows, W columns.
grid_row_column_dims_(Grid, H, W) :-
% Count the number of rows.
    length(Grid, H),
% Derive column count from the first row when the grid is non-empty.
    (H > 0 -> Grid = [FR|_], length(FR, W) ; W = 0).

% Extract column C as a top-to-bottom list by reading one cell per row.
grid_row_column_col_(Grid, C, Col) :-
% Collect the C-th element from each row in row order.
    findall(V, (member(Row, Grid), nth0(C, Row, V)), Col).

% --- PUBLIC PREDICATES ---

% grid_row_column_row(+Grid, +R, -Row)
% Row is the content of row R (0-indexed) as a list.
grid_row_column_row(Grid, R, Row) :-
% Select the R-th element from the grid's list of rows.
    nth0(R, Grid, Row).

% grid_row_column_col(+Grid, +C, -Col)
% Col is the content of column C (0-indexed) as a top-to-bottom list.
grid_row_column_col(Grid, C, Col) :-
% Delegate to the private column extractor.
    grid_row_column_col_(Grid, C, Col).

% grid_row_column_row_uniform(+Grid, +R, -Color)
% Succeeds if all cells in row R share the same Color.
grid_row_column_row_uniform(Grid, R, Color) :-
% Extract the row list.
    nth0(R, Grid, Row),
% Bind Color from the head and verify all remaining cells match.
    Row = [Color|Rest],
% Every tail cell must unify with Color.
    forall(member(V, Rest), V = Color).

% grid_row_column_col_uniform(+Grid, +C, -Color)
% Succeeds if all cells in column C share the same Color.
grid_row_column_col_uniform(Grid, C, Color) :-
% Extract the column as a list.
    grid_row_column_col_(Grid, C, Col),
% Bind Color from the head and verify all remaining cells match.
    Col = [Color|Rest],
% Every tail cell must unify with Color.
    forall(member(V, Rest), V = Color).

% grid_row_column_equal_rows(+Grid, +R1, +R2)
% Succeeds if rows R1 and R2 of Grid have identical content.
grid_row_column_equal_rows(Grid, R1, R2) :-
% Extract row R1 and bind its content.
    nth0(R1, Grid, Row),
% Row R2 must unify with the same content.
    nth0(R2, Grid, Row).

% grid_row_column_equal_cols(+Grid, +C1, +C2)
% Succeeds if columns C1 and C2 of Grid have identical content.
grid_row_column_equal_cols(Grid, C1, C2) :-
% Extract column C1 as a list.
    grid_row_column_col_(Grid, C1, Col),
% Column C2 must produce the same list.
    grid_row_column_col_(Grid, C2, Col).

% grid_row_column_row_positions(+Grid, +Pattern, -Positions)
% Positions is the list of row indices R where row R equals Pattern.
grid_row_column_row_positions(Grid, Pattern, Positions) :-
% Compute the valid row index range.
    length(Grid, H), H1 is H - 1,
% Collect every R whose row content unifies with Pattern.
    findall(R, (between(0, H1, R), nth0(R, Grid, Pattern)), Positions).

% grid_row_column_col_positions(+Grid, +Pattern, -Positions)
% Positions is the list of column indices C where column C equals Pattern.
grid_row_column_col_positions(Grid, Pattern, Positions) :-
% Compute the valid column index range.
    grid_row_column_dims_(Grid, _, W), W1 is W - 1,
% Collect every C whose column content equals Pattern.
    findall(C, (between(0, W1, C), grid_row_column_col_(Grid, C, Pattern)), Positions).

% grid_row_column_matching_rows(+Grid, -Pairs)
% Pairs is the list of R1-R2 pairs with R1 < R2 where rows R1 and R2 are identical.
grid_row_column_matching_rows(Grid, Pairs) :-
% Compute the valid row index range.
    length(Grid, H), H1 is H - 1,
% Find all ordered pairs (R1 < R2) sharing the same row content.
    findall(R1-R2,
        (between(0, H1, R1),
         R1N is R1 + 1,
         between(R1N, H1, R2),
         nth0(R1, Grid, Row),
         nth0(R2, Grid, Row)),
        Pairs).

% grid_row_column_matching_cols(+Grid, -Pairs)
% Pairs is the list of C1-C2 pairs with C1 < C2 where columns C1 and C2 are identical.
grid_row_column_matching_cols(Grid, Pairs) :-
% Compute the valid column index range.
    grid_row_column_dims_(Grid, _, W), W1 is W - 1,
% Find all ordered pairs (C1 < C2) sharing the same column content.
    findall(C1-C2,
        (between(0, W1, C1),
         C1N is C1 + 1,
         between(C1N, W1, C2),
         grid_row_column_col_(Grid, C1, Col),
         grid_row_column_col_(Grid, C2, Col)),
        Pairs).

% grid_row_column_unique_rows(+Grid, -Rows)
% Rows is the list of row indices whose content appears exactly once in Grid.
grid_row_column_unique_rows(Grid, Rows) :-
% Compute the valid row index range.
    length(Grid, H), H1 is H - 1,
% A row R is unique if no other row R2 has the same content.
    findall(R,
        (between(0, H1, R),
         nth0(R, Grid, RowR),
         \+ (between(0, H1, R2), R2 \= R, nth0(R2, Grid, RowR))),
        Rows).

% grid_row_column_unique_cols(+Grid, -Cols)
% Cols is the list of column indices whose content appears exactly once in Grid.
grid_row_column_unique_cols(Grid, Cols) :-
% Compute the valid column index range.
    grid_row_column_dims_(Grid, _, W), W1 is W - 1,
% A column C is unique if no other column C2 has the same content.
    findall(C,
        (between(0, W1, C),
         grid_row_column_col_(Grid, C, ColC),
         \+ (between(0, W1, C2), C2 \= C, grid_row_column_col_(Grid, C2, ColC))),
        Cols).

% grid_row_column_row_sort(+Grid, -Sorted)
% Sorted is Grid with its rows arranged in standard order (preserving duplicates).
grid_row_column_row_sort(Grid, Sorted) :-
% Sort rows using msort to keep all duplicates.
    msort(Grid, Sorted).

% grid_row_column_col_sort(+Grid, -Sorted)
% Sorted is a grid whose columns are reordered in lexicographic order of their content.
grid_row_column_col_sort(Grid, Sorted) :-
% Determine grid dimensions.
    grid_row_column_dims_(Grid, H, W),
    W1 is W - 1,
% Extract all columns as a list of lists.
    findall(Col, (between(0, W1, C), grid_row_column_col_(Grid, C, Col)), Cols),
% Sort columns lexicographically, keeping duplicates.
    msort(Cols, SortedCols),
    H1 is H - 1,
% Rebuild each row by reading position R from each sorted column in order.
    findall(Row,
        (between(0, H1, R),
         findall(V, (member(Col, SortedCols), nth0(R, Col, V)), Row)),
        Sorted).
