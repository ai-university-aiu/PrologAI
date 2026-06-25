% count.pl - Layer 96: Value Counting and Frequency Analysis Operations (cn_* prefix).
% Counts cell values, builds histograms, compares grids, and tallies region colors.
:- module(count, [
    cn_by_value/3,
    cn_color_count/3,
    cn_histogram/3,
    cn_max_color/2,
    cn_min_color/2,
    cn_color_rows/3,
    cn_color_cols/3,
    cn_row_distinct/3,
    cn_col_distinct/3,
    cn_grid_total/2,
    cn_equal_cells/3,
    cn_diff_cells/3,
    cn_region_color/3,
    cn_regions_per_color/3
]).
% Import list utilities for counting, sorting, and column extraction.
:- use_module(library(lists), [member/2, nth0/3, max_list/2, min_list/2,
                                numlist/3, sum_list/2, select/3]).
% Import higher-order utilities for row comparison and column filtering.
:- use_module(library(apply), [maplist/2, maplist/3, include/3, foldl/4]).

% cn_grid_dims_: internal helper to measure grid rows and columns.
cn_grid_dims_(Grid, Rows, Cols) :-
% Count the number of rows.
    length(Grid, Rows),
% Count the number of columns from the first row; return 0 for an empty grid.
    (Rows > 0 -> Grid = [R1|_], length(R1, Cols) ; Cols = 0).

% cn_count_same_: internal helper to count a leading run of value V in a list.
% Returns 1 if V is first in an otherwise empty or non-matching list.
cn_count_same_(_, [], 1, []) :- !.
cn_count_same_(V, [V|Vs], N, Rem) :- !,
% V matches the head: consume it and accumulate one more.
    cn_count_same_(V, Vs, N1, Rem),
    N is N1 + 1.
% Head does not match V: run ends here with count 1.
cn_count_same_(_, Rest, 1, Rest).

% cn_count_runs_: convert a msort-ed list into Val-Count pairs by run-length encoding.
cn_count_runs_([], []).
cn_count_runs_([V|Vs], [V-N|Rest]) :-
% Count how many consecutive leading V values exist.
    cn_count_same_(V, Vs, N, Remaining),
% Recurse on the remainder (which starts with a different value).
    cn_count_runs_(Remaining, Rest).

% cn_split_pairs_: unzip a list of Key-Value pairs into parallel key and value lists.
cn_split_pairs_([], [], []).
cn_split_pairs_([K-V|T], [K|Ks], [V|Vs]) :-
% Take one pair and recurse.
    cn_split_pairs_(T, Ks, Vs).

% cn_compare_cell_: return 1 when two cell values are identical, 0 otherwise.
cn_compare_cell_(V, V, 1) :- !.
% Values differ: return 0.
cn_compare_cell_(_, _, 0).

% cn_compare_row_: produce per-cell equality flags (0 or 1) for two rows.
cn_compare_row_(Row1, Row2, Flags) :-
% Compare each pair of cells and collect the results.
    maplist(cn_compare_cell_, Row1, Row2, Flags).

% cn_tally_: increment the count for Color in a running tally association list.
% Tally is a list of Color-N pairs. Select finds and updates the existing entry,
% or adds Color-1 if not yet present.
cn_tally_(C, Tallies0, Tallies) :-
    (select(C-N, Tallies0, Rest) ->
% Color already in tally: increment its count by 1.
        N1 is N + 1, Tallies = [C-N1|Rest]
    ;
% Color not yet in tally: add it with count 1.
        Tallies = [C-1|Tallies0]).

% cn_extract_col_: internal helper to extract column C from Grid as a list of values.
cn_extract_col_(Grid, C, Col) :-
% For each row take the element at index C.
    maplist([Row, V]>>(nth0(C, Row, V)), Grid, Col).

% cn_by_value(+List, +V, -N): count occurrences of value V in a flat list.
% Uses unification; works for any value type.
cn_by_value(List, V, N) :-
% Keep only elements equal to V.
    include(=(V), List, Matches),
% The count is the length of the matching list.
    length(Matches, N).

% cn_color_count(+Grid, +Color, -N): count occurrences of Color across all cells.
% Flattens the grid to a single list and delegates to cn_by_value.
cn_color_count(Grid, Color, N) :-
% Flatten all rows into a single cell-value list.
    append(Grid, Flat),
% Count Color in the flat list.
    cn_by_value(Flat, Color, N).

% cn_histogram(+Grid, -Colors, -Counts): sorted parallel lists of distinct values
% and their occurrence counts. Colors and Counts have the same length.
cn_histogram(Grid, Colors, Counts) :-
% Flatten grid to a single value list.
    append(Grid, Flat),
% Sort preserving duplicates so equal values are adjacent.
    msort(Flat, Sorted),
% Group equal values into Color-Count pairs by run-length encoding.
    cn_count_runs_(Sorted, Pairs),
% Unzip to parallel lists for the caller.
    cn_split_pairs_(Pairs, Colors, Counts).

% cn_max_color(+Grid, -Color): the value appearing most often in Grid.
% When counts are tied, returns the first (lowest-sorted) value.
cn_max_color(Grid, Color) :-
% Build parallel histogram lists.
    cn_histogram(Grid, Colors, Counts),
% Find the maximum occurrence count.
    max_list(Counts, MaxCount),
% Locate the first index at which MaxCount appears.
    nth0(Idx, Counts, MaxCount), !,
% Return the corresponding color.
    nth0(Idx, Colors, Color).

% cn_min_color(+Grid, -Color): the value appearing least often in Grid.
% When counts are tied, returns the first (lowest-sorted) value.
cn_min_color(Grid, Color) :-
% Build parallel histogram lists.
    cn_histogram(Grid, Colors, Counts),
% Find the minimum occurrence count.
    min_list(Counts, MinCount),
% Locate the first index at which MinCount appears.
    nth0(Idx, Counts, MinCount), !,
% Return the corresponding color.
    nth0(Idx, Colors, Color).

% cn_color_rows(+Grid, +Color, -N): number of rows that contain Color.
cn_color_rows(Grid, Color, N) :-
% Keep only rows in which Color is a member.
    include([Row]>>(member(Color, Row)), Grid, Matching),
% The count is the number of matching rows.
    length(Matching, N).

% cn_color_cols(+Grid, +Color, -N): number of columns that contain Color.
cn_color_cols(Grid, Color, N) :-
% Determine the column count.
    cn_grid_dims_(Grid, _, Cols),
    (Cols > 0 -> Cols1 is Cols - 1, numlist(0, Cols1, ColIds) ; ColIds = []),
% Keep only column indices in which Color appears.
    include([C]>>(cn_extract_col_(Grid, C, Col), member(Color, Col)), ColIds, Matching),
% The count is the number of matching column indices.
    length(Matching, N).

% cn_row_distinct(+Grid, +R, -N): number of distinct cell values in row R.
cn_row_distinct(Grid, R, N) :-
% Retrieve row R by 0-based index.
    nth0(R, Grid, Row),
% Remove duplicates using sort (sort always removes duplicates).
    sort(Row, Unique),
% The count is the length of the deduplicated list.
    length(Unique, N).

% cn_col_distinct(+Grid, +C, -N): number of distinct cell values in column C.
cn_col_distinct(Grid, C, N) :-
% Extract all values in column C.
    cn_extract_col_(Grid, C, Col),
% Remove duplicates.
    sort(Col, Unique),
% The count is the length of the deduplicated list.
    length(Unique, N).

% cn_grid_total(+Grid, -N): total number of cells = number of rows times number of columns.
cn_grid_total(Grid, N) :-
% Get the grid dimensions.
    cn_grid_dims_(Grid, Rows, Cols),
% Multiply rows by columns.
    N is Rows * Cols.

% cn_equal_cells(+Grid1, +Grid2, -N): count cells where both grids have the same value.
% Both grids must have identical dimensions.
cn_equal_cells(Grid1, Grid2, N) :-
% Produce per-row lists of 1 (equal) and 0 (different) flags.
    maplist(cn_compare_row_, Grid1, Grid2, RowFlags),
% Flatten all row flag lists into one list.
    append(RowFlags, Flat),
% Sum the flags to get the total number of equal cells.
    sum_list(Flat, N).

% cn_diff_cells(+Grid1, +Grid2, -N): count cells where the grids have different values.
% Computed as total cells minus equal cells.
cn_diff_cells(Grid1, Grid2, N) :-
% Count total cells in Grid1.
    cn_grid_total(Grid1, Total),
% Count equal cells.
    cn_equal_cells(Grid1, Grid2, Equal),
% Difference is the total minus equal.
    N is Total - Equal.

% cn_region_color(+Grid, +Region, -Color): color of the first cell of Region.
% Region is a list of r(R,C) terms as produced by the connect pack.
cn_region_color(Grid, [r(R,C)|_], Color) :-
% Look up row R.
    nth0(R, Grid, Row),
% Look up column C within that row.
    nth0(C, Row, Color).

% cn_regions_per_color(+Grid, +Regions, -Pairs): Color-Count tally for a list of regions.
% Pairs is a list of Color-N terms where N is how many regions have that color.
cn_regions_per_color(Grid, Regions, Pairs) :-
% Determine the color of each region from the grid.
    maplist(cn_region_color(Grid), Regions, Colors),
% Fold over the color list to build the tally association list.
    foldl(cn_tally_, Colors, [], Pairs).
