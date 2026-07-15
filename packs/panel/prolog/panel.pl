% panel.pl - Layer 114: Grid Panel Detection, Splitting, and Column Slicing (pn_* prefix).
% Provides predicates for detecting rows and columns that are entirely background
% (dividers), splitting a grid at given or auto-detected divider positions,
% removing divider rows/columns, splitting into quadrants, partitioning columns
% into N equal-width strips or custom-width slices, and testing for any divider.
% Module declaration naming this file panel with its 14 exported predicates.
:- module(panel, [
    % Test whether row R of Grid consists entirely of Bg values.
    panel_is_divider_row/3,
    % Test whether column C of Grid consists entirely of Bg values.
    panel_is_divider_col/3,
    % List all 0-based row indices that are entirely Bg.
    panel_divider_rows/3,
    % List all 0-based column indices that are entirely Bg.
    panel_divider_cols/3,
    % Split a grid at given row indices, excluding the divider rows themselves.
    panel_split_rows/3,
    % Split a grid at given column indices, excluding the divider columns.
    panel_split_cols/3,
    % Detect all-Bg rows and split the grid at them.
    panel_auto_split_rows/3,
    % Detect all-Bg columns and split the grid at them.
    panel_auto_split_cols/3,
    % Remove all all-Bg rows from a grid.
    panel_strip_rows/3,
    % Remove all all-Bg columns from a grid.
    panel_strip_cols/3,
    % Split a grid at its row/column midpoints into four quadrants TL, TR, BL, BR.
    panel_quadrants/5,
    % Split columns into N equal-width strips (width must be divisible by N).
    panel_n_col_parts/3,
    % Split columns according to a list of widths summing to total grid width.
    panel_col_slices/3,
    % Succeed if the grid has at least one all-Bg row or all-Bg column.
    panel_has_dividers/2
]).
% Import list utilities for memberchk/2, nth0/3, and append variants.
:- use_module(library(lists), [memberchk/2, nth0/3, append/2, append/3]).
% Import higher-order utilities for maplist/3 and forall/2 (forall is a built-in).
:- use_module(library(apply), [maplist/3]).

% panel_is_divider_row(+Grid, +R, +Bg): row R of Grid is entirely Bg.
% Uses forall/2 to assert that every element of the row equals Bg.
panel_is_divider_row(Grid, R, Bg) :-
% Extract the row at 0-based index R.
    nth0(R, Grid, Row),
% Verify that every element in the row equals Bg.
    forall(member(V, Row), V == Bg).

% panel_is_divider_col(+Grid, +C, +Bg): column C of Grid is entirely Bg.
% Uses forall to check every row's element at position C.
panel_is_divider_col(Grid, C, Bg) :-
% Verify that for every row in Grid, the element at column C equals Bg.
    forall(member(Row, Grid), (nth0(C, Row, V), V == Bg)).

% panel_divider_rows(+Grid, +Bg, -Rows): sorted list of all-Bg row indices.
panel_divider_rows(Grid, Bg, Rows) :-
% Compute the highest valid row index.
    length(Grid, H), H1 is H - 1,
% Collect every index where panel_is_divider_row succeeds.
    findall(R, (between(0, H1, R), panel_is_divider_row(Grid, R, Bg)), Rows).

% panel_divider_cols(+Grid, +Bg, -Cols): sorted list of all-Bg column indices.
panel_divider_cols(Grid, Bg, Cols) :-
% Get column count from the first row.
    (Grid = [First|_] -> length(First, W) ; W = 0),
% Compute the highest valid column index.
    W1 is W - 1,
% Collect every column index where panel_is_divider_col succeeds.
    findall(C, (between(0, W1, C), panel_is_divider_col(Grid, C, Bg)), Cols).

% panel_split_rows(+Grid, +RowIdxs, -Parts): split at given row indices.
% Each element of RowIdxs is excluded from all parts; parts are the row bands
% between consecutive dividers. A part may be empty if two dividers are adjacent.
panel_split_rows(Grid, RowIdxs, Parts) :-
% Get grid height for the upper bound.
    length(Grid, H),
% Delegate to the recursive helper starting before the first row.
    panel_split_rows_(Grid, RowIdxs, 0, H, Parts).

% panel_split_rows_(+Grid, +Divs, +Start, +End, -Parts): accumulate row bands.
% Base case: no more dividers; extract the final band from Start to End.
panel_split_rows_(Grid, [], Start, End, [Part]) :- !,
% Extract all rows from Start (inclusive) to End (exclusive).
    panel_extract_rows_(Grid, Start, End, Part).
% Recursive case: extract band before the next divider, then recurse.
panel_split_rows_(Grid, [Div|Rest], Start, End, [Part|Parts]) :-
% Extract the band from Start up to (but not including) the divider row.
    panel_extract_rows_(Grid, Start, Div, Part),
% The next band starts after the divider row.
    Next is Div + 1,
% Recurse over remaining dividers.
    panel_split_rows_(Grid, Rest, Next, End, Parts).

% panel_extract_rows_(+Grid, +Start, +End, -Rows): extract rows [Start, End).
% Start is inclusive; End is exclusive. Returns [] when Start >= End.
panel_extract_rows_(Grid, Start, End, Rows) :-
% Compute the inclusive upper bound.
    End1 is End - 1,
% Use if-then-else to handle the empty range without a choicepoint.
    (   Start > End1
    ->  Rows = []
    ;   findall(Row, (between(Start, End1, I), nth0(I, Grid, Row)), Rows)
    ).

% panel_split_cols(+Grid, +ColIdxs, -Parts): split at given column indices.
% Each element of ColIdxs is excluded; parts are the column bands between dividers.
panel_split_cols(Grid, ColIdxs, Parts) :-
% Get column count from the first row.
    (Grid = [First|_] -> length(First, W) ; W = 0),
% Delegate to the recursive helper.
    panel_split_cols_(Grid, ColIdxs, 0, W, Parts).

% panel_split_cols_(+Grid, +Divs, +Start, +End, -Parts): accumulate column bands.
% Base case: extract the final column band.
panel_split_cols_(Grid, [], Start, End, [Part]) :- !,
% Extract columns from Start to End for every row.
    maplist(panel_slice_row_(Start, End), Grid, Part).
% Recursive case: extract band before divider, then recurse.
panel_split_cols_(Grid, [Div|Rest], Start, End, [Part|Parts]) :-
% Extract columns [Start, Div) for every row.
    maplist(panel_slice_row_(Start, Div), Grid, Part),
% Next band starts after the divider column.
    Next is Div + 1,
% Recurse.
    panel_split_cols_(Grid, Rest, Next, End, Parts).

% panel_slice_row_(+C0, +C1, +Row, -Sub): extract elements at columns [C0, C1).
% Skip the first C0 elements, then take C1-C0 elements.
panel_slice_row_(C0, C1, Row, Sub) :-
% Build a list of C0 anonymous variables to skip the first C0 elements.
    length(Skip, C0),
% Split Row into Skip and Suffix using append.
    append(Skip, Suffix, Row),
% Compute the number of elements to keep.
    Len is C1 - C0,
% Build a result list of exactly Len variables.
    length(Sub, Len),
% Unify Sub with the first Len elements of Suffix.
    append(Sub, _, Suffix).

% panel_auto_split_rows(+Grid, +Bg, -Parts): detect all-Bg rows and split at them.
panel_auto_split_rows(Grid, Bg, Parts) :-
% Find all divider row indices.
    panel_divider_rows(Grid, Bg, Divs),
% Split the grid at those positions.
    panel_split_rows(Grid, Divs, Parts).

% panel_auto_split_cols(+Grid, +Bg, -Parts): detect all-Bg columns and split at them.
panel_auto_split_cols(Grid, Bg, Parts) :-
% Find all divider column indices.
    panel_divider_cols(Grid, Bg, Divs),
% Split the grid at those positions.
    panel_split_cols(Grid, Divs, Parts).

% panel_strip_rows(+Grid, +Bg, -Stripped): remove all all-Bg rows.
% Stripped contains all rows whose index is not in the divider list.
panel_strip_rows(Grid, Bg, Stripped) :-
% Find all divider row indices.
    panel_divider_rows(Grid, Bg, Divs),
% Compute row count and max index.
    length(Grid, H), H1 is H - 1,
% Collect rows whose index is not a divider.
    findall(Row, (
% Enumerate all row indices.
        between(0, H1, I),
% Keep only non-divider rows.
        \+ memberchk(I, Divs),
% Retrieve the row.
        nth0(I, Grid, Row)
    ), Stripped).

% panel_strip_cols(+Grid, +Bg, -Stripped): remove all all-Bg columns.
% Each row in Stripped contains only non-divider column values.
panel_strip_cols(Grid, Bg, Stripped) :-
% Find all divider column indices.
    panel_divider_cols(Grid, Bg, Divs),
% Get column count from the first row.
    (Grid = [First|_] -> length(First, W) ; W = 0),
    W1 is W - 1,
% Build the list of kept column indices (non-dividers).
    findall(C, (between(0, W1, C), \+ memberchk(C, Divs)), Kept),
% For each row, extract only the kept columns.
    maplist(panel_select_cols_(Kept), Grid, Stripped).

% panel_select_cols_(+Idxs, +Row, -Sub): extract elements at given column indices.
panel_select_cols_(Idxs, Row, Sub) :-
% Map nth0 over the index list to retrieve each element.
    maplist(panel_nth0_(Row), Idxs, Sub).

% panel_nth0_(+Row, +I, -V): retrieve element at 0-based index I from Row.
panel_nth0_(Row, I, V) :-
% Delegate to built-in nth0/3.
    nth0(I, Row, V).

% panel_quadrants(+Grid, -TL, -TR, -BL, -BR): split at midpoints into 4 quadrants.
% MidR = H // 2; MidC = W // 2.
% TL: rows [0, MidR), cols [0, MidC).
% TR: rows [0, MidR), cols [MidC, W).
% BL: rows [MidR, H), cols [0, MidC).
% BR: rows [MidR, H), cols [MidC, W).
panel_quadrants(Grid, TL, TR, BL, BR) :-
% Compute grid dimensions.
    length(Grid, H), MidR is H // 2,
    Grid = [FirstRow|_], length(FirstRow, W), MidC is W // 2,
% Extract top-left quadrant.
    panel_rect_(Grid, 0, 0, MidR, MidC, TL),
% Extract top-right quadrant.
    panel_rect_(Grid, 0, MidC, MidR, W, TR),
% Extract bottom-left quadrant.
    panel_rect_(Grid, MidR, 0, H, MidC, BL),
% Extract bottom-right quadrant.
    panel_rect_(Grid, MidR, MidC, H, W, BR).

% panel_rect_(+Grid, +R0, +C0, +R1, +C1, -Sub): extract rows [R0,R1) and cols [C0,C1).
panel_rect_(Grid, R0, C0, R1, C1, Sub) :-
% Compute inclusive row upper bound.
    R1a is R1 - 1,
% Collect each row in the range, sliced to [C0, C1).
    findall(SubRow, (
        between(R0, R1a, R),
        nth0(R, Grid, Row),
        panel_slice_row_(C0, C1, Row, SubRow)
    ), Sub).

% panel_n_col_parts(+Grid, +N, -Parts): split into N equal-width column strips.
% The grid width must be divisible by N. Each strip has width W // N.
panel_n_col_parts(Grid, N, Parts) :-
% Get grid width from the first row.
    Grid = [FirstRow|_], length(FirstRow, W),
% Compute each strip width.
    StepW is W // N,
% Compute the last part index (0-based).
    N1 is N - 1,
% Collect each column strip as a sub-grid.
    findall(Part, (
% Enumerate strip indices.
        between(0, N1, K),
% Compute column bounds for this strip.
        C0 is K * StepW,
        C1 is C0 + StepW,
% Extract the strip from every row.
        maplist(panel_slice_row_(C0, C1), Grid, Part)
    ), Parts).

% panel_col_slices(+Grid, +Widths, -Parts): split columns by a list of widths.
% The elements of Widths must sum to the total grid width.
panel_col_slices(Grid, Widths, Parts) :-
% Compute the cumulative column end positions from Widths.
    panel_cumsum_(Widths, 0, Ends),
% Build each slice using width and end position.
    panel_col_slices_(Grid, Widths, Ends, Parts).

% panel_cumsum_(+List, +Acc, -Ends): cumulative sum of List starting from Acc.
% Each element of Ends is the running total up to that point.
panel_cumsum_([], _, []).
% Compute the next cumulative end from the current accumulator and head width.
panel_cumsum_([W|Rest], Acc, [End|Ends]) :-
    End is Acc + W,
% Recurse with the updated accumulator.
    panel_cumsum_(Rest, End, Ends).

% panel_col_slices_(+Grid, +Widths, +Ends, -Parts): build slices from precomputed ends.
% Base case: empty widths list.
panel_col_slices_(_, [], [], []) :- !.
% Recursive case: extract one slice and recurse.
panel_col_slices_(Grid, [W|WRest], [End|ERest], [Part|Parts]) :-
% Compute start position as end minus width.
    Start is End - W,
% Extract the column band [Start, End) from every row.
    maplist(panel_slice_row_(Start, End), Grid, Part),
% Recurse over remaining slices.
    panel_col_slices_(Grid, WRest, ERest, Parts).

% panel_has_dividers(+Grid, +Bg): succeed if Grid has at least one all-Bg row or column.
% Tests row dividers first; only tests column dividers if no row dividers found.
panel_has_dividers(Grid, Bg) :-
% Find divider rows first.
    panel_divider_rows(Grid, Bg, Rows),
% If any divider row exists, succeed immediately; else check columns.
    (   Rows \= []
    ->  true
    ;   panel_divider_cols(Grid, Bg, Cols),
        Cols \= []
    ).
