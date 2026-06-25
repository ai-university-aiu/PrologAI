% Module declaration: count pack, Layer 54.
:- module(count, [
    % cn_color_count/3: occurrences of a specific color in a grid.
    cn_color_count/3,
    % cn_histogram/3: sorted color histogram as parallel color and count lists.
    cn_histogram/3,
    % cn_max_color/2: most frequently occurring color in a grid.
    cn_max_color/2,
    % cn_min_color/2: least frequently occurring color in a grid.
    cn_min_color/2,
    % cn_color_rows/3: number of rows containing a specific color.
    cn_color_rows/3,
    % cn_color_cols/3: number of columns containing a specific color.
    cn_color_cols/3,
    % cn_row_distinct/3: number of distinct values in a specific row.
    cn_row_distinct/3,
    % cn_col_distinct/3: number of distinct values in a specific column.
    cn_col_distinct/3,
    % cn_grid_total/2: total number of cells in a grid.
    cn_grid_total/2,
    % cn_equal_cells/3: cells where two same-size grids share the same value.
    cn_equal_cells/3,
    % cn_diff_cells/3: cells where two same-size grids have different values.
    cn_diff_cells/3,
    % cn_region_color/3: the color of a region taken from the grid.
    cn_region_color/3,
    % cn_regions_per_color/3: count of regions per color as Color-Count pairs.
    cn_regions_per_color/3,
    % cn_by_value/3: occurrences of a value in a flat list.
    cn_by_value/3
]).

% Import list and apply utilities; append/2, nth0/3, msort/2 are built-ins.
:- use_module(library(lists),  [member/2, nth0/3, max_list/2, min_list/2,
                                 numlist/3, sum_list/2, select/3]).
:- use_module(library(apply),  [maplist/2, maplist/3, include/3, foldl/4]).

% cn_grid_dims_(+Grid, -Rows, -Cols): measure grid dimensions.
cn_grid_dims_(Grid, Rows, Cols) :-
    % Count rows.
    length(Grid, Rows),
    % Count columns from the first row; 0 if grid is empty.
    ( Rows > 0 -> Grid = [R1|_], length(R1, Cols) ; Cols = 0 ).

% cn_by_value(+List, +V, -N): count occurrences of V in a flat list.
cn_by_value(List, V, N) :-
    % Filter to exact matches then count.
    include(=(V), List, Matches),
    length(Matches, N).

% cn_color_count(+Grid, +Color, -N): total occurrences of Color across all cells.
cn_color_count(Grid, Color, N) :-
    % Flatten the grid to a single list of cell values.
    append(Grid, Flat),
    % Count matching cells.
    cn_by_value(Flat, Color, N).

% cn_count_same_(+V, +List, -Count, -Remaining): Count = 1 + leading V's in List.
cn_count_same_(_, [], 1, []) :- !.
cn_count_same_(V, [V|Vs], N, Rem) :- !,
    % Consume one more matching element.
    cn_count_same_(V, Vs, N1, Rem),
    N is N1 + 1.
cn_count_same_(_, Rest, 1, Rest).

% cn_count_runs_(+SortedList, -Pairs): group consecutive equal elements into V-N pairs.
cn_count_runs_([], []).
cn_count_runs_([V|Vs], [V-N|Rest]) :-
    % Count the run of V's starting here.
    cn_count_same_(V, Vs, N, Remaining),
    % Recurse on non-V remainder.
    cn_count_runs_(Remaining, Rest).

% cn_split_pairs_(+Pairs, -Keys, -Values): unzip a Key-Value pair list.
cn_split_pairs_([], [], []).
cn_split_pairs_([K-V|T], [K|Ks], [V|Vs]) :-
    % Take one pair and recurse.
    cn_split_pairs_(T, Ks, Vs).

% cn_histogram(+Grid, -Colors, -Counts): parallel lists of sorted colors and their counts.
cn_histogram(Grid, Colors, Counts) :-
    % Flatten grid to a single value list.
    append(Grid, Flat),
    % Sort preserving duplicates so equal values are adjacent.
    msort(Flat, Sorted),
    % Group equal values into Color-Count pairs.
    cn_count_runs_(Sorted, Pairs),
    % Unzip to parallel lists.
    cn_split_pairs_(Pairs, Colors, Counts).

% cn_max_color(+Grid, -Color): the color appearing most often.
cn_max_color(Grid, Color) :-
    % Build histogram.
    cn_histogram(Grid, Colors, Counts),
    % Identify the peak count.
    max_list(Counts, MaxCount),
    % Return the first color at that peak.
    nth0(Idx, Counts, MaxCount), !,
    nth0(Idx, Colors, Color).

% cn_min_color(+Grid, -Color): the color appearing least often.
cn_min_color(Grid, Color) :-
    % Build histogram.
    cn_histogram(Grid, Colors, Counts),
    % Identify the trough count.
    min_list(Counts, MinCount),
    % Return the first color at that trough.
    nth0(Idx, Counts, MinCount), !,
    nth0(Idx, Colors, Color).

% cn_row_has_color_(+Color, +Row): true when Color appears in Row.
cn_row_has_color_(Color, Row) :-
    member(Color, Row).

% cn_color_rows(+Grid, +Color, -N): number of rows that contain Color.
cn_color_rows(Grid, Color, N) :-
    % Keep rows containing Color.
    include(cn_row_has_color_(Color), Grid, Matching),
    % Count them.
    length(Matching, N).

% cn_extract_col_(+Grid, +C, -Col): list of values in column C.
cn_extract_col_(Grid, C, Col) :-
    % Extract the C-th element from each row.
    maplist([Row, V]>>(nth0(C, Row, V)), Grid, Col).

% cn_color_cols(+Grid, +Color, -N): number of columns that contain Color.
cn_color_cols(Grid, Color, N) :-
    % Determine column count.
    cn_grid_dims_(Grid, _, Cols),
    % Build column index list.
    ( Cols > 0 -> Cols1 is Cols - 1, numlist(0, Cols1, ColIds) ; ColIds = [] ),
    % Keep column indices where Color appears.
    include(
        [C]>>(cn_extract_col_(Grid, C, Col), member(Color, Col)),
        ColIds,
        Matching),
    length(Matching, N).

% cn_row_distinct(+Grid, +R, -N): number of distinct values in row R.
cn_row_distinct(Grid, R, N) :-
    % Retrieve the row.
    nth0(R, Grid, Row),
    % Deduplicate.
    sort(Row, Unique),
    % Count.
    length(Unique, N).

% cn_col_distinct(+Grid, +C, -N): number of distinct values in column C.
cn_col_distinct(Grid, C, N) :-
    % Retrieve the column.
    cn_extract_col_(Grid, C, Col),
    % Deduplicate.
    sort(Col, Unique),
    % Count.
    length(Unique, N).

% cn_grid_total(+Grid, -N): total cell count = Rows * Cols.
cn_grid_total(Grid, N) :-
    % Get dimensions.
    cn_grid_dims_(Grid, Rows, Cols),
    % Multiply.
    N is Rows * Cols.

% cn_compare_cell_(+V1, +V2, -Flag): 1 when equal, 0 otherwise.
cn_compare_cell_(V, V, 1) :- !.
cn_compare_cell_(_, _, 0).

% cn_compare_row_(+Row1, +Row2, -Flags): per-cell equality flags.
cn_compare_row_(Row1, Row2, Flags) :-
    maplist(cn_compare_cell_, Row1, Row2, Flags).

% cn_equal_cells(+Grid1, +Grid2, -N): cells with identical values.
cn_equal_cells(Grid1, Grid2, N) :-
    % Produce per-cell 1/0 flags.
    maplist(cn_compare_row_, Grid1, Grid2, RowFlags),
    % Flatten all flags.
    append(RowFlags, Flat),
    % Sum to count matches.
    sum_list(Flat, N).

% cn_diff_cells(+Grid1, +Grid2, -N): cells with different values.
cn_diff_cells(Grid1, Grid2, N) :-
    % Total cells minus equal cells.
    cn_grid_total(Grid1, Total),
    cn_equal_cells(Grid1, Grid2, Equal),
    N is Total - Equal.

% cn_region_color(+Grid, +Region, -Color): color of the first cell of Region.
cn_region_color(Grid, [r(R,C)|_], Color) :-
    % Look up the cell in the grid.
    nth0(R, Grid, Row),
    nth0(C, Row, Color).

% cn_tally_(+Color, +Tally0, -Tally): increment count for Color in tally list.
cn_tally_(C, Tallies0, Tallies) :-
    % If Color already in tally, increment; else add with count 1.
    ( select(C-N, Tallies0, Rest)
    -> N1 is N + 1, Tallies = [C-N1|Rest]
    ;  Tallies = [C-1|Tallies0] ).

% cn_regions_per_color(+Grid, +Regions, -Pairs): Color-Count pairs for each color.
cn_regions_per_color(Grid, Regions, Pairs) :-
    % Determine the color of each region from the grid.
    maplist(cn_region_color(Grid), Regions, Colors),
    % Fold over colors to build tally.
    foldl(cn_tally_, Colors, [], Pairs).
