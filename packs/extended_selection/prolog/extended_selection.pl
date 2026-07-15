% xsel.pl - Layer 119: Extended Cell Selection by Value Comparison (xs_* prefix).
% Provides threshold tests, range queries, value ranking, and conditional
% replacement predicates for 2D integer grids.
:- module(extended_selection, [
    extended_selection_cells_lt/3, extended_selection_cells_gt/3, extended_selection_cells_le/3, extended_selection_cells_ge/3,
    extended_selection_cells_between/4, extended_selection_cells_ne/3,
    extended_selection_max_cells/2, extended_selection_min_cells/2,
    extended_selection_threshold/5, extended_selection_replace_lt/4, extended_selection_replace_gt/4,
    extended_selection_rank_vals/2, extended_selection_val_rank/3, extended_selection_rank_grid/2
]).
% Import list predicates for member, indexing, and extremes.
:- use_module(library(lists), [member/2, nth0/3, max_list/2, min_list/2]).
% Import maplist/3 for row-wise and cell-wise mapping.
:- use_module(library(apply), [maplist/3]).

% extended_selection_cells_lt(+Grid, +V, -Cells): sorted R-C pairs of cells with value strictly less than V.
extended_selection_cells_lt(Grid, V, Cells) :-
% compute the last row index
    length(Grid, H), H1 is H - 1,
% compute the last column index from the first row; 0 if Grid is empty
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
% collect all R-C positions where the cell value is less than V
    findall(R-C, (
        between(0, H1, R), between(0, W1, C),
        nth0(R, Grid, Row), nth0(C, Row, Val),
        Val < V
    ), Unsorted),
% sort to canonical order; also removes any duplicates
    sort(Unsorted, Cells).

% extended_selection_cells_gt(+Grid, +V, -Cells): sorted R-C pairs of cells with value strictly greater than V.
extended_selection_cells_gt(Grid, V, Cells) :-
% compute the last row index
    length(Grid, H), H1 is H - 1,
% compute the last column index from the first row; 0 if Grid is empty
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
% collect all R-C positions where the cell value is greater than V
    findall(R-C, (
        between(0, H1, R), between(0, W1, C),
        nth0(R, Grid, Row), nth0(C, Row, Val),
        Val > V
    ), Unsorted),
% sort to canonical order
    sort(Unsorted, Cells).

% extended_selection_cells_le(+Grid, +V, -Cells): sorted R-C pairs of cells with value =< V.
extended_selection_cells_le(Grid, V, Cells) :-
% compute the last row index
    length(Grid, H), H1 is H - 1,
% compute the last column index from the first row; 0 if Grid is empty
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
% collect all R-C positions where the cell value is less than or equal to V
    findall(R-C, (
        between(0, H1, R), between(0, W1, C),
        nth0(R, Grid, Row), nth0(C, Row, Val),
        Val =< V
    ), Unsorted),
% sort to canonical order
    sort(Unsorted, Cells).

% extended_selection_cells_ge(+Grid, +V, -Cells): sorted R-C pairs of cells with value >= V.
extended_selection_cells_ge(Grid, V, Cells) :-
% compute the last row index
    length(Grid, H), H1 is H - 1,
% compute the last column index from the first row; 0 if Grid is empty
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
% collect all R-C positions where the cell value is greater than or equal to V
    findall(R-C, (
        between(0, H1, R), between(0, W1, C),
        nth0(R, Grid, Row), nth0(C, Row, Val),
        Val >= V
    ), Unsorted),
% sort to canonical order
    sort(Unsorted, Cells).

% extended_selection_cells_between(+Grid, +Lo, +Hi, -Cells): cells with Lo =< value =< Hi.
extended_selection_cells_between(Grid, Lo, Hi, Cells) :-
% compute the last row index
    length(Grid, H), H1 is H - 1,
% compute the last column index from the first row; 0 if Grid is empty
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
% collect all R-C positions where the cell value is in the closed interval [Lo, Hi]
    findall(R-C, (
        between(0, H1, R), between(0, W1, C),
        nth0(R, Grid, Row), nth0(C, Row, Val),
        Val >= Lo, Val =< Hi
    ), Unsorted),
% sort to canonical order
    sort(Unsorted, Cells).

% extended_selection_cells_ne(+Grid, +V, -Cells): cells with value not structurally equal to V.
extended_selection_cells_ne(Grid, V, Cells) :-
% compute the last row index
    length(Grid, H), H1 is H - 1,
% compute the last column index from the first row; 0 if Grid is empty
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
% collect all R-C positions where the cell value differs from V
    findall(R-C, (
        between(0, H1, R), between(0, W1, C),
        nth0(R, Grid, Row), nth0(C, Row, Val),
        Val \== V
    ), Unsorted),
% sort to canonical order
    sort(Unsorted, Cells).

% extended_selection_max_cells(+Grid, -Cells): sorted R-C pairs of cells containing the maximum value.
extended_selection_max_cells(Grid, Cells) :-
% collect all cell values via nested member
    findall(Val, (member(Row, Grid), member(Val, Row)), Vals),
% find the largest value across all cells
    max_list(Vals, MaxV),
% compute grid dimensions
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
% collect all positions where the cell equals the maximum value
    findall(R-C, (
        between(0, H1, R), between(0, W1, C),
        nth0(R, Grid, Row), nth0(C, Row, MaxV)
    ), Unsorted),
% sort to canonical order
    sort(Unsorted, Cells).

% extended_selection_min_cells(+Grid, -Cells): sorted R-C pairs of cells containing the minimum value.
extended_selection_min_cells(Grid, Cells) :-
% collect all cell values via nested member
    findall(Val, (member(Row, Grid), member(Val, Row)), Vals),
% find the smallest value across all cells
    min_list(Vals, MinV),
% compute grid dimensions
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
% collect all positions where the cell equals the minimum value
    findall(R-C, (
        between(0, H1, R), between(0, W1, C),
        nth0(R, Grid, Row), nth0(C, Row, MinV)
    ), Unsorted),
% sort to canonical order
    sort(Unsorted, Cells).

% extended_selection_threshold(+Grid, +T, +OnV, +OffV, -Grid2): binary threshold.
% Each cell value V becomes OnV if V >= T, otherwise OffV.
extended_selection_threshold(Grid, T, OnV, OffV, Grid2) :-
% apply threshold transformation row by row via maplist
    maplist(extended_selection_thresh_row_(T, OnV, OffV), Grid, Grid2).

% extended_selection_thresh_row_: apply threshold to one row.
extended_selection_thresh_row_(T, OnV, OffV, Row, Row2) :-
% apply threshold to each cell in the row
    maplist(extended_selection_thresh_val_(T, OnV, OffV), Row, Row2).

% extended_selection_thresh_val_: apply threshold to one cell value.
extended_selection_thresh_val_(T, OnV, OffV, V, Out) :-
% V >= T maps to OnV; V < T maps to OffV
    (V >= T -> Out = OnV ; Out = OffV).

% extended_selection_replace_lt(+Grid, +V, +New, -Grid2): replace cells with value < V with New.
extended_selection_replace_lt(Grid, V, New, Grid2) :-
% process each row via maplist
    maplist(extended_selection_repl_row_lt_(V, New), Grid, Grid2).

% extended_selection_repl_row_lt_: replace values less than V in one row.
extended_selection_repl_row_lt_(V, New, Row, Row2) :-
% process each cell in the row
    maplist(extended_selection_repl_lt_(V, New), Row, Row2).

% extended_selection_repl_lt_: replace one cell value if it is strictly less than V.
extended_selection_repl_lt_(V, New, Val, Out) :-
% substitute New when Val < V; otherwise keep Val unchanged
    (Val < V -> Out = New ; Out = Val).

% extended_selection_replace_gt(+Grid, +V, +New, -Grid2): replace cells with value > V with New.
extended_selection_replace_gt(Grid, V, New, Grid2) :-
% process each row via maplist
    maplist(extended_selection_repl_row_gt_(V, New), Grid, Grid2).

% extended_selection_repl_row_gt_: replace values greater than V in one row.
extended_selection_repl_row_gt_(V, New, Row, Row2) :-
% process each cell in the row
    maplist(extended_selection_repl_gt_(V, New), Row, Row2).

% extended_selection_repl_gt_: replace one cell value if it is strictly greater than V.
extended_selection_repl_gt_(V, New, Val, Out) :-
% substitute New when Val > V; otherwise keep Val unchanged
    (Val > V -> Out = New ; Out = Val).

% extended_selection_rank_vals(+Grid, -Vals): sorted list of unique values appearing in Grid.
% Rank 0 is the smallest value, Rank N-1 is the largest.
extended_selection_rank_vals(Grid, Vals) :-
% collect every cell value using nested member/2
    findall(Val, (member(Row, Grid), member(Val, Row)), Unsorted),
% sort removes duplicates and orders ascending; result is the ranked value list
    sort(Unsorted, Vals).

% extended_selection_val_rank(+Grid, +V, -Rank): 0-based ordinal rank of value V among all unique grid values.
% Rank 0 = smallest, Rank N-1 = largest. Fails if V does not appear in Grid.
extended_selection_val_rank(Grid, V, Rank) :-
% get the sorted unique value list
    extended_selection_rank_vals(Grid, Vals),
% find the 0-based position of V; cut commits to the first (only) match
    nth0(Rank, Vals, V), !.

% extended_selection_rank_grid(+Grid, -RankGrid): replace each cell with its 0-based ordinal rank.
extended_selection_rank_grid(Grid, RankGrid) :-
% compute the sorted unique value list once for the whole grid
    extended_selection_rank_vals(Grid, Vals),
% replace every cell value with its rank using maplist
    maplist(extended_selection_rank_row_(Vals), Grid, RankGrid).

% extended_selection_rank_row_: replace cell values in one row with their ranks.
extended_selection_rank_row_(Vals, Row, RankRow) :-
% apply rank lookup to each cell in the row
    maplist(extended_selection_rank_val_(Vals), Row, RankRow).

% extended_selection_rank_val_: find the rank of a single cell value.
extended_selection_rank_val_(Vals, V, Rank) :-
% nth0 succeeds when Vals[Rank] = V; cut commits to the first (only) match
    nth0(Rank, Vals, V), !.
