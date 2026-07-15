% count.pl - Layer 96: Value Counting and Frequency Analysis Operations (cn_* prefix).
% Counts cell values, builds histograms, compares grids, and tallies region colors.
:- module(count, [
    count_by_value/3,
    count_color_count/3,
    count_histogram/3,
    count_max_color/2,
    count_min_color/2,
    count_color_rows/3,
    count_color_cols/3,
    count_row_distinct/3,
    count_col_distinct/3,
    count_grid_total/2,
    count_equal_cells/3,
    count_diff_cells/3,
    count_region_color/3,
    count_regions_per_color/3
]).
% Import list utilities for counting, sorting, and column extraction.
:- use_module(library(lists), [member/2, nth0/3, max_list/2, min_list/2,
                                numlist/3, sum_list/2, select/3]).
% Import higher-order utilities for row comparison and column filtering.
:- use_module(library(apply), [maplist/2, maplist/3, include/3, foldl/4]).

% count_grid_dims_: internal helper to measure grid rows and columns.
count_grid_dims_(Grid, Rows, Cols) :-
% Count the number of rows.
    length(Grid, Rows),
% Count the number of columns from the first row; return 0 for an empty grid.
    (Rows > 0 -> Grid = [R1|_], length(R1, Cols) ; Cols = 0).

% count_count_same_: internal helper to count a leading run of value V in a list.
% Returns 1 if V is first in an otherwise empty or non-matching list.
count_count_same_(_, [], 1, []) :- !.
count_count_same_(V, [V|Vs], N, Rem) :- !,
% V matches the head: consume it and accumulate one more.
    count_count_same_(V, Vs, N1, Rem),
    N is N1 + 1.
% Head does not match V: run ends here with count 1.
count_count_same_(_, Rest, 1, Rest).

% count_count_runs_: convert a msort-ed list into Val-Count pairs by run-length encoding.
count_count_runs_([], []).
count_count_runs_([V|Vs], [V-N|Rest]) :-
% Count how many consecutive leading V values exist.
    count_count_same_(V, Vs, N, Remaining),
% Recurse on the remainder (which starts with a different value).
    count_count_runs_(Remaining, Rest).

% count_split_pairs_: unzip a list of Key-Value pairs into parallel key and value lists.
count_split_pairs_([], [], []).
count_split_pairs_([K-V|T], [K|Ks], [V|Vs]) :-
% Take one pair and recurse.
    count_split_pairs_(T, Ks, Vs).

% count_compare_cell_: return 1 when two cell values are identical, 0 otherwise.
count_compare_cell_(V, V, 1) :- !.
% Values differ: return 0.
count_compare_cell_(_, _, 0).

% count_compare_row_: produce per-cell equality flags (0 or 1) for two rows.
count_compare_row_(Row1, Row2, Flags) :-
% Compare each pair of cells and collect the results.
    maplist(count_compare_cell_, Row1, Row2, Flags).

% count_tally_: increment the count for Color in a running tally association list.
% Tally is a list of Color-N pairs. Select finds and updates the existing entry,
% or adds Color-1 if not yet present.
count_tally_(C, Tallies0, Tallies) :-
    (select(C-N, Tallies0, Rest) ->
% Color already in tally: increment its count by 1.
        N1 is N + 1, Tallies = [C-N1|Rest]
    ;
% Color not yet in tally: add it with count 1.
        Tallies = [C-1|Tallies0]).

% count_extract_col_: internal helper to extract column C from Grid as a list of values.
count_extract_col_(Grid, C, Col) :-
% For each row take the element at index C.
    maplist([Row, V]>>(nth0(C, Row, V)), Grid, Col).

% count_by_value(+List, +V, -N): count occurrences of value V in a flat list.
% Uses unification; works for any value type.
count_by_value(List, V, N) :-
% Keep only elements equal to V.
    include(=(V), List, Matches),
% The count is the length of the matching list.
    length(Matches, N).

% count_color_count(+Grid, +Color, -N): count occurrences of Color across all cells.
% Flattens the grid to a single list and delegates to count_by_value.
count_color_count(Grid, Color, N) :-
% Flatten all rows into a single cell-value list.
    append(Grid, Flat),
% Count Color in the flat list.
    count_by_value(Flat, Color, N).

% count_histogram(+Grid, -Colors, -Counts): sorted parallel lists of distinct values
% and their occurrence counts. Colors and Counts have the same length.
count_histogram(Grid, Colors, Counts) :-
% Flatten grid to a single value list.
    append(Grid, Flat),
% Sort preserving duplicates so equal values are adjacent.
    msort(Flat, Sorted),
% Group equal values into Color-Count pairs by run-length encoding.
    count_count_runs_(Sorted, Pairs),
% Unzip to parallel lists for the caller.
    count_split_pairs_(Pairs, Colors, Counts).

% count_max_color(+Grid, -Color): the value appearing most often in Grid.
% When counts are tied, returns the first (lowest-sorted) value.
count_max_color(Grid, Color) :-
% Build parallel histogram lists.
    count_histogram(Grid, Colors, Counts),
% Find the maximum occurrence count.
    max_list(Counts, MaxCount),
% Locate the first index at which MaxCount appears.
    nth0(Idx, Counts, MaxCount), !,
% Return the corresponding color.
    nth0(Idx, Colors, Color).

% count_min_color(+Grid, -Color): the value appearing least often in Grid.
% When counts are tied, returns the first (lowest-sorted) value.
count_min_color(Grid, Color) :-
% Build parallel histogram lists.
    count_histogram(Grid, Colors, Counts),
% Find the minimum occurrence count.
    min_list(Counts, MinCount),
% Locate the first index at which MinCount appears.
    nth0(Idx, Counts, MinCount), !,
% Return the corresponding color.
    nth0(Idx, Colors, Color).

% count_color_rows(+Grid, +Color, -N): number of rows that contain Color.
count_color_rows(Grid, Color, N) :-
% Keep only rows in which Color is a member.
    include([Row]>>(member(Color, Row)), Grid, Matching),
% The count is the number of matching rows.
    length(Matching, N).

% count_color_cols(+Grid, +Color, -N): number of columns that contain Color.
count_color_cols(Grid, Color, N) :-
% Determine the column count.
    count_grid_dims_(Grid, _, Cols),
    (Cols > 0 -> Cols1 is Cols - 1, numlist(0, Cols1, ColIds) ; ColIds = []),
% Keep only column indices in which Color appears.
    include([C]>>(count_extract_col_(Grid, C, Col), member(Color, Col)), ColIds, Matching),
% The count is the number of matching column indices.
    length(Matching, N).

% count_row_distinct(+Grid, +R, -N): number of distinct cell values in row R.
count_row_distinct(Grid, R, N) :-
% Retrieve row R by 0-based index.
    nth0(R, Grid, Row),
% Remove duplicates using sort (sort always removes duplicates).
    sort(Row, Unique),
% The count is the length of the deduplicated list.
    length(Unique, N).

% count_col_distinct(+Grid, +C, -N): number of distinct cell values in column C.
count_col_distinct(Grid, C, N) :-
% Extract all values in column C.
    count_extract_col_(Grid, C, Col),
% Remove duplicates.
    sort(Col, Unique),
% The count is the length of the deduplicated list.
    length(Unique, N).

% count_grid_total(+Grid, -N): total number of cells = number of rows times number of columns.
count_grid_total(Grid, N) :-
% Get the grid dimensions.
    count_grid_dims_(Grid, Rows, Cols),
% Multiply rows by columns.
    N is Rows * Cols.

% count_equal_cells(+Grid1, +Grid2, -N): count cells where both grids have the same value.
% Both grids must have identical dimensions.
count_equal_cells(Grid1, Grid2, N) :-
% Produce per-row lists of 1 (equal) and 0 (different) flags.
    maplist(count_compare_row_, Grid1, Grid2, RowFlags),
% Flatten all row flag lists into one list.
    append(RowFlags, Flat),
% Sum the flags to get the total number of equal cells.
    sum_list(Flat, N).

% count_diff_cells(+Grid1, +Grid2, -N): count cells where the grids have different values.
% Computed as total cells minus equal cells.
count_diff_cells(Grid1, Grid2, N) :-
% Count total cells in Grid1.
    count_grid_total(Grid1, Total),
% Count equal cells.
    count_equal_cells(Grid1, Grid2, Equal),
% Difference is the total minus equal.
    N is Total - Equal.

% count_region_color(+Grid, +Region, -Color): color of the first cell of Region.
% Region is a list of r(R,C) terms as produced by the connect pack.
count_region_color(Grid, [r(R,C)|_], Color) :-
% Look up row R.
    nth0(R, Grid, Row),
% Look up column C within that row.
    nth0(C, Row, Color).

% count_regions_per_color(+Grid, +Regions, -Pairs): Color-Count tally for a list of regions.
% Pairs is a list of Color-N terms where N is how many regions have that color.
count_regions_per_color(Grid, Regions, Pairs) :-
% Determine the color of each region from the grid.
    maplist(count_region_color(Grid), Regions, Colors),
% Fold over the color list to build the tally association list.
    foldl(count_tally_, Colors, [], Pairs).
