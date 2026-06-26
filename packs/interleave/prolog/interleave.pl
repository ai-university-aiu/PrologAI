% interleave.pl - Layer 113: Row and Column Interleaving, Weaving, and Stride Selection (il_* prefix).
% Provides predicates for merging two grids by alternating rows or columns,
% splitting an interleaved grid back into its component grids, inserting separator
% rows or columns (weaving), removing them (unweaving), extracting every Nth row or
% column (stride), selecting rows or columns by index list, round-robin interleaving
% of N grids, and partitioning rows into consecutive blocks of equal size.
% Module declaration naming this file interleave with its 14 exported predicates.
:- module(interleave, [
    % Merge two same-width grids by alternating rows: A0, B0, A1, B1, ...
    il_rows/3,
    % Merge two same-height grids by alternating columns: col(A,0), col(B,0), col(A,1), ...
    il_cols/3,
    % Split a grid into even-indexed rows (0,2,4,...) and odd-indexed rows (1,3,5,...).
    il_derows/3,
    % Split a grid into even-indexed columns and odd-indexed columns.
    il_decols/3,
    % Insert a background row between every pair of adjacent rows.
    il_weave_rows/3,
    % Insert a background value between every pair of adjacent column values in each row.
    il_weave_cols/3,
    % Remove odd-indexed rows, keeping only even-indexed rows.
    il_unweave_rows/2,
    % Remove odd-indexed columns, keeping only even-indexed columns.
    il_unweave_cols/2,
    % Extract every Step-th row starting at Start0, as a new grid.
    il_stride_rows/4,
    % Extract every Step-th column starting at Start0, as a new grid.
    il_stride_cols/4,
    % Extract rows at a given 0-based index list, in index order.
    il_select_rows/3,
    % Extract columns at a given 0-based index list, in index order.
    il_select_cols/3,
    % Round-robin interleave rows from a list of equal-height grids.
    il_rows_n/2,
    % Partition rows into consecutive groups of N; last group may be partial.
    il_block_rows/3
]).
% Import list utilities for member/2, nth0/3, and append variants.
:- use_module(library(lists), [member/2, nth0/3, append/2, append/3]).
% Import higher-order utilities for maplist/3 and maplist/4.
:- use_module(library(apply), [maplist/3, maplist/4]).

% il_rows(+GridA, +GridB, -Result): merge GridA and GridB by alternating rows.
% Row 0 of Result is row 0 of GridA; row 1 is row 0 of GridB; row 2 is row 1 of GridA, etc.
% Both grids must have the same number of rows; Result has twice that many rows.
% Base case: both grids are empty, Result is empty.
il_rows([], [], []) :- !.
% Recursive case: take one row from each grid and prepend both to the result.
il_rows([RA|RestA], [RB|RestB], [RA,RB|Rest]) :-
% Recurse over remaining rows of both grids.
    il_rows(RestA, RestB, Rest).

% il_cols(+GridA, +GridB, -Result): merge GridA and GridB by alternating columns.
% For each pair of corresponding rows, the row elements are interleaved: A[0], B[0], A[1], B[1], ...
% Both grids must have the same dimensions; Result has the same height and twice the width.
il_cols(GridA, GridB, Result) :-
% Apply il_zip_row_ to each pair of corresponding rows using 4-argument maplist.
    maplist(il_zip_row_, GridA, GridB, Result).

% il_zip_row_(+RowA, +RowB, -ZippedRow): interleave elements of two equal-length rows.
% Base case: both rows empty.
il_zip_row_([], [], []) :- !.
% Recursive case: take one element from each row and prepend both.
il_zip_row_([A|RestA], [B|RestB], [A,B|Rest]) :-
% Recurse over remaining elements.
    il_zip_row_(RestA, RestB, Rest).

% il_derows(+Grid, -Even, -Odd): split Grid into even-indexed and odd-indexed rows.
% Even contains rows at indices 0, 2, 4, ...; Odd contains rows at indices 1, 3, 5, ...
% This is the inverse of il_rows/3 when GridA and GridB have equal height.
il_derows(Grid, Even, Odd) :-
% Delegate to the index-accumulating helper starting at index 0.
    il_derows_(Grid, 0, Even, Odd).

% il_derows_(+Grid, +I, -Even, -Odd): accumulate even and odd rows with index counter I.
% Base case: empty grid.
il_derows_([], _, [], []) :- !.
% Even-index case: I mod 2 = 0; cut prevents backtracking to odd-index clause.
il_derows_([R|Rest], I, [R|Even], Odd) :-
    0 is I mod 2, !,
% Increment the index counter.
    I1 is I + 1,
% Recurse; this row goes to Even.
    il_derows_(Rest, I1, Even, Odd).
% Odd-index case: I mod 2 != 0; this row goes to Odd.
il_derows_([R|Rest], I, Even, [R|Odd]) :-
% Increment the index counter.
    I1 is I + 1,
% Recurse; this row goes to Odd.
    il_derows_(Rest, I1, Even, Odd).

% il_decols(+Grid, -Even, -Odd): split each row into even-indexed and odd-indexed elements.
% Even contains column indices 0, 2, 4, ...; Odd contains column indices 1, 3, 5, ...
il_decols(Grid, Even, Odd) :-
% Apply il_decols_row_ to each row; collect even and odd columns for each row.
    maplist(il_decols_row_, Grid, Even, Odd).

% il_decols_row_(+Row, -Even, -Odd): split row elements by even/odd index.
il_decols_row_(Row, Even, Odd) :-
% Delegate to the index-accumulating helper starting at index 0.
    il_decols_list_(Row, 0, Even, Odd).

% il_decols_list_(+List, +I, -Even, -Odd): accumulate even and odd elements with counter I.
% Base case: empty list.
il_decols_list_([], _, [], []) :- !.
% Even-index case: element goes to Even; cut prevents backtracking.
il_decols_list_([V|Rest], I, [V|Even], Odd) :-
    0 is I mod 2, !,
% Increment the index.
    I1 is I + 1,
% Recurse.
    il_decols_list_(Rest, I1, Even, Odd).
% Odd-index case: element goes to Odd.
il_decols_list_([V|Rest], I, Even, [V|Odd]) :-
% Increment the index.
    I1 is I + 1,
% Recurse.
    il_decols_list_(Rest, I1, Even, Odd).

% il_weave_rows(+Grid, +Bg, -Woven): insert a background row between every pair of rows.
% A grid of H rows becomes a grid of 2*H-1 rows. An empty grid stays empty.
% Base case: empty grid.
il_weave_rows([], _, []) :- !.
% Base case: single-row grid needs no separator; return as-is.
il_weave_rows([Row], _, [Row]) :- !.
% Recursive case: insert a background row after the first row, then recurse.
il_weave_rows([Row|Rest], Bg, [Row, BgRow|Woven]) :-
% Determine grid width from the first row.
    length(Row, W),
% Build a background row of width W filled with Bg.
    findall(Bg, between(1, W, _), BgRow),
% Recurse over the remaining rows.
    il_weave_rows(Rest, Bg, Woven).

% il_weave_cols(+Grid, +Bg, -Woven): insert Bg between every pair of column values in each row.
% Each row of width W becomes a row of width 2*W-1. An empty row stays empty.
il_weave_cols(Grid, Bg, Woven) :-
% Apply il_weave_row_ to every row, capturing Bg via partial application.
    maplist(il_weave_row_(Bg), Grid, Woven).

% il_weave_row_(+Bg, +Row, -Woven): insert Bg between adjacent elements of a list.
% Base case: empty row.
il_weave_row_(_, [], []) :- !.
% Base case: single-element row; no separator needed.
il_weave_row_(_, [V], [V]) :- !.
% Recursive case: append Bg after the first element, then recurse.
il_weave_row_(Bg, [V|Rest], [V, Bg|Woven]) :-
% Recurse over the remaining elements.
    il_weave_row_(Bg, Rest, Woven).

% il_unweave_rows(+Grid, -Core): remove odd-indexed rows, keeping even-indexed rows.
% This reverses il_weave_rows when the odd-indexed rows are uniform background rows.
il_unweave_rows(Grid, Core) :-
% Delegate to il_derows, discarding the odd-indexed rows.
    il_derows(Grid, Core, _).

% il_unweave_cols(+Grid, -Core): remove odd-indexed columns, keeping even-indexed columns.
% This reverses il_weave_cols when the odd-indexed columns are uniform background values.
il_unweave_cols(Grid, Core) :-
% Delegate to il_decols, discarding the odd-indexed columns.
    il_decols(Grid, Core, _).

% il_stride_rows(+Grid, +Step, +Start0, -SubGrid): extract every Step-th row starting at Start0.
% Row indices included are Start0, Start0+Step, Start0+2*Step, ... up to the last row.
% Step must be >= 1; Start0 is 0-based.
il_stride_rows(Grid, Step, Start0, SubGrid) :-
% Compute the inclusive upper bound of valid row indices.
    length(Grid, H), H1 is H - 1,
% Collect all rows whose index satisfies the stride condition.
    findall(Row, (
% Enumerate all indices from Start0 to the last row.
        between(Start0, H1, I),
% Keep only indices that are multiples of Step away from Start0.
        0 is (I - Start0) mod Step,
% Retrieve the row at index I.
        nth0(I, Grid, Row)
    ), SubGrid).

% il_stride_cols(+Grid, +Step, +Start0, -SubGrid): extract every Step-th column starting at Start0.
% Column indices included are Start0, Start0+Step, Start0+2*Step, ...
% Step must be >= 1; Start0 is 0-based. Returns [] for an empty grid.
il_stride_cols(Grid, Step, Start0, SubGrid) :-
% Use if-then-else to handle empty grid without a choicepoint.
    (   Grid = [FirstRow|_]
    ->  length(FirstRow, W), W1 is W - 1,
% Collect all column indices satisfying the stride condition.
        findall(I, (
            between(Start0, W1, I),
            0 is (I - Start0) mod Step
        ), ColIdxs),
% Extract those columns from every row.
        maplist(il_pick_cols_(ColIdxs), Grid, SubGrid)
    ;   SubGrid = []
    ).

% il_pick_cols_(+Idxs, +Row, -SubRow): extract elements at given indices from Row.
il_pick_cols_(Idxs, Row, SubRow) :-
% Map il_nth0_ over each index to retrieve the corresponding element.
    maplist(il_nth0_(Row), Idxs, SubRow).

% il_nth0_(+List, +I, -V): retrieve element at 0-based index I from List.
il_nth0_(List, I, V) :-
% Delegate to built-in nth0/3.
    nth0(I, List, V).

% il_select_rows(+Grid, +Indices, -SubGrid): extract rows at given 0-based indices.
% Indices is a list of 0-based row numbers; SubGrid has length equal to length(Indices).
il_select_rows(Grid, Indices, SubGrid) :-
% Map il_nth0_ over the index list to retrieve each requested row.
    maplist(il_nth0_(Grid), Indices, SubGrid).

% il_select_cols(+Grid, +Indices, -SubGrid): extract columns at given 0-based indices.
% Each row of SubGrid is the projection of the corresponding row of Grid onto Indices.
il_select_cols(Grid, Indices, SubGrid) :-
% Apply il_pick_cols_ to each row of Grid, keeping only the columns in Indices.
    maplist(il_pick_cols_(Indices), Grid, SubGrid).

% il_rows_n(+Grids, -Result): round-robin interleave rows from a list of grids.
% If Grids = [G1, G2, G3] each with H rows, Result has rows:
% G1[0], G2[0], G3[0], G1[1], G2[1], G3[1], ..., G1[H-1], G2[H-1], G3[H-1].
% All grids must have the same number of rows. Empty list of grids yields empty result.
% Base case: empty grid list.
il_rows_n([], []) :- !.
% General case: compute row count from first grid, then gather rows in round-robin order.
il_rows_n(Grids, Result) :-
% Extract row count H from the first grid.
    Grids = [First|_],
    length(First, H),
% Compute 0-based maximum row index.
    H1 is H - 1,
% For each row index I, collect row I from each grid in list order.
    findall(Row, (
% Enumerate row indices 0 through H-1.
        between(0, H1, I),
% Iterate over grids in the order given.
        member(Grid, Grids),
% Retrieve row I from the current grid.
        nth0(I, Grid, Row)
    ), Result).

% il_block_rows(+Grid, +N, -Blocks): partition rows into consecutive groups of N.
% Blocks is a list of sub-grids, each with exactly N rows except possibly the last.
% Base case: empty grid yields no blocks.
il_block_rows([], _, []) :- !.
% Recursive case: extract a block of N rows (or the remaining rows if fewer than N).
il_block_rows(Grid, N, [Block|Rest]) :-
% Use if-then-else to distinguish full-sized blocks from a partial last block.
    (   length(Grid, L), L >= N
% Full block: create a list of exactly N variables and unify via append.
    ->  length(Block, N),
        append(Block, Remaining, Grid)
% Partial last block: take all remaining rows.
    ;   Block = Grid,
        Remaining = []
    ),
% Recurse over the remaining rows after the current block.
    il_block_rows(Remaining, N, Rest).
