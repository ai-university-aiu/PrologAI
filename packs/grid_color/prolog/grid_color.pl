:- module(grid_color, [
    grid_color_count/3,
    grid_color_histogram/2,
    grid_color_most_frequent/2,
    grid_color_least_frequent/2,
    grid_color_unique_colors/2,
    grid_color_color_cells/3,
    grid_color_contains/2,
    grid_color_recolor/4,
    grid_color_color_map/3,
    grid_color_threshold/5,
    grid_color_dominant/3,
    grid_color_fraction/3,
    grid_color_count_colors/2,
    grid_color_sorted_by_freq/2
]).
% gridcolor.pl - Layer 209: Grid Color Analysis - count, histogram, frequency,
% recolor, color mapping, threshold, dominant color, and frequency sorting (gc_* prefix).
% Operates on raw grid format: list of rows, each a list of color atoms, 0-indexed.
:- use_module(library(lists), [
    nth0/3, member/2, last/2
]).

% --- PRIVATE HELPERS ---

% Grid dimensions: H rows, W columns.
grid_color_dims_(Grid, H, W) :-
% Count rows.
    length(Grid, H),
% Count columns from first row.
    (H > 0 -> Grid = [FR|_], length(FR, W) ; W = 0).

% Cell value at row R, column C (0-indexed).
grid_color_cell_(Grid, R, C, V) :-
% Select row R.
    nth0(R, Grid, Row),
% Select column C.
    nth0(C, Row, V).

% Collect all cell values from Grid as a flat list in row-major order.
grid_color_all_cells_(Grid, Cells) :-
% Get dimensions.
    grid_color_dims_(Grid, H, W),
% Compute last row and column indices.
    H1 is H - 1,
% Compute last column index.
    W1 is W - 1,
% Collect all values.
    findall(V, (between(0, H1, R), between(0, W1, C), grid_color_cell_(Grid, R, C, V)), Cells).

% Build a new H x W grid using a lambda Goal(R, C, V).
grid_color_build_(H, W, Goal, Grid) :-
% Compute last row and column indices.
    H1 is H - 1,
% Compute last column index.
    W1 is W - 1,
% Collect rows.
    findall(Row,
        (between(0, H1, R),
         findall(V, (between(0, W1, C), call(Goal, R, C, V)), Row)),
        Grid).

% --- COLOR COUNTING AND ANALYSIS ---

% grid_color_count(+Grid, +Color, -N)
% N is the number of cells in Grid whose value equals Color.
grid_color_count(Grid, Color, N) :-
% Collect all cells with the matching color.
    grid_color_all_cells_(Grid, All),
% Count cells equal to Color by collecting matching ones.
    findall(1, member(Color, All), Ones),
% The count is the length of the ones list.
    length(Ones, N).

% grid_color_histogram(+Grid, -Pairs)
% Pairs is a list of Color-Count pairs for every distinct color in Grid,
% sorted alphabetically by Color name.
grid_color_histogram(Grid, Pairs) :-
% Get all cell values.
    grid_color_all_cells_(Grid, All),
% Find sorted list of distinct colors.
    sort(All, Colors),
% For each distinct color, count its occurrences.
    findall(C-N,
        (member(C, Colors),
         findall(1, member(C, All), Ones),
         length(Ones, N)),
        Pairs).

% grid_color_most_frequent(+Grid, -Color)
% Color is the most frequently occurring color in Grid.
% If multiple colors share the maximum count, returns one of them.
grid_color_most_frequent(Grid, Color) :-
% Build histogram.
    grid_color_histogram(Grid, Pairs),
% Require at least one color.
    Pairs = [_|_],
% Rearrange to N-C for numerical sort.
    findall(N-C, member(C-N, Pairs), NCPairs),
% Sort by count ascending; the maximum is last.
    msort(NCPairs, Sorted),
% Take the last element (maximum count).
    last(Sorted, _-Color).

% grid_color_least_frequent(+Grid, -Color)
% Color is the least frequently occurring color in Grid.
% If multiple colors share the minimum count, returns one of them.
grid_color_least_frequent(Grid, Color) :-
% Build histogram.
    grid_color_histogram(Grid, Pairs),
% Require at least one color.
    Pairs = [_|_],
% Rearrange to N-C for numerical sort.
    findall(N-C, member(C-N, Pairs), NCPairs),
% Sort by count ascending; the minimum is first.
    msort(NCPairs, [_-Color|_]).

% grid_color_unique_colors(+Grid, -Colors)
% Colors is the sorted list of distinct color atoms present in Grid.
grid_color_unique_colors(Grid, Colors) :-
% Get all cells.
    grid_color_all_cells_(Grid, All),
% sort/2 removes duplicates and gives sorted result.
    sort(All, Colors).

% grid_color_color_cells(+Grid, +Color, -Cells)
% Cells is the list of R-C positions (in row-major order) where Grid[R][C] = Color.
grid_color_color_cells(Grid, Color, Cells) :-
% Get dimensions.
    grid_color_dims_(Grid, H, W),
% Compute last indices.
    H1 is H - 1,
% Compute last column index.
    W1 is W - 1,
% Collect all matching positions.
    findall(R-C,
        (between(0, H1, R),
         between(0, W1, C),
         grid_color_cell_(Grid, R, C, Color)),
        Cells).

% grid_color_contains(+Grid, +Color)
% Succeed if Grid contains at least one cell with value Color.
grid_color_contains(Grid, Color) :-
% Get all cells; check if Color is among them.
    grid_color_all_cells_(Grid, All),
% memberchk avoids choice points and searches efficiently.
    memberchk(Color, All).

% --- COLOR TRANSFORMATION ---

% grid_color_recolor(+Grid, +OldColor, +NewColor, -Result)
% Result is Grid with every occurrence of OldColor replaced by NewColor.
grid_color_recolor(Grid, OldColor, NewColor, Result) :-
% Get dimensions.
    grid_color_dims_(Grid, H, W),
% Build result: substitute OldColor with NewColor, keep others unchanged.
    grid_color_build_(H, W,
        [R, C, V]>>(grid_color_cell_(Grid, R, C, GV),
                    (GV = OldColor -> V = NewColor ; V = GV)),
        Result).

% grid_color_color_map(+Grid, +Map, -Result)
% Result applies the color mapping Map (list of OldColor-NewColor pairs) to Grid.
% Colors not present in Map are left unchanged.
grid_color_color_map(Grid, Map, Result) :-
% Get dimensions.
    grid_color_dims_(Grid, H, W),
% For each cell, look up its color in Map; use mapped color or keep original.
    grid_color_build_(H, W,
        [R, C, V]>>(grid_color_cell_(Grid, R, C, GV),
                    (member(GV-NV, Map) -> V = NV ; V = GV)),
        Result).

% grid_color_threshold(+Grid, +Colors, +FgColor, +BgColor, -Result)
% Result is a binary grid: cells whose color is in Colors become FgColor;
% all other cells become BgColor.
grid_color_threshold(Grid, Colors, FgColor, BgColor, Result) :-
% Get dimensions.
    grid_color_dims_(Grid, H, W),
% Build binary result using membership test.
    grid_color_build_(H, W,
        [R, C, V]>>(grid_color_cell_(Grid, R, C, GV),
                    (memberchk(GV, Colors) -> V = FgColor ; V = BgColor)),
        Result).

% --- DERIVED STATISTICS ---

% grid_color_dominant(+Grid, +BgColor, -Color)
% Color is the most frequent non-BgColor color in Grid.
% Fails if Grid contains no non-BgColor cells.
grid_color_dominant(Grid, BgColor, Color) :-
% Build histogram.
    grid_color_histogram(Grid, Pairs),
% Filter out the background color.
    findall(C-N, (member(C-N, Pairs), C \= BgColor), NonBgPairs),
% Require at least one non-background color.
    NonBgPairs = [_|_],
% Sort and find the maximum.
    findall(N-C, member(C-N, NonBgPairs), NCPairs),
% Sort ascending; maximum is last.
    msort(NCPairs, Sorted),
% Take the color with the highest count.
    last(Sorted, _-Color).

% grid_color_fraction(+Grid, +Color, -Frac)
% Frac is the fraction [0.0..1.0] of Grid cells whose value equals Color.
grid_color_fraction(Grid, Color, Frac) :-
% Get total cell count.
    grid_color_dims_(Grid, H, W),
% Total = H * W.
    Total is H * W,
% Count matching cells.
    grid_color_count(Grid, Color, N),
% Compute floating-point fraction.
    (Total =:= 0 -> Frac = 0.0 ; Frac is float(N) / Total).

% grid_color_count_colors(+Grid, -N)
% N is the number of distinct colors present in Grid.
grid_color_count_colors(Grid, N) :-
% Get unique colors.
    grid_color_unique_colors(Grid, Colors),
% Count them.
    length(Colors, N).

% grid_color_sorted_by_freq(+Grid, -Colors)
% Colors is the list of distinct colors in Grid sorted by frequency,
% most frequent first. Ties are broken by alphabetical order.
grid_color_sorted_by_freq(Grid, Colors) :-
% Build histogram.
    grid_color_histogram(Grid, Pairs),
% Negate counts so msort gives descending frequency order.
    findall(NegN-C, (member(C-N, Pairs), NegN is -N), NegNCPairs),
% Sort ascending on NegN: largest count (most negative NegN) comes first.
    msort(NegNCPairs, Sorted),
% Extract only the color atoms from the sorted list.
    findall(C, member(_-C, Sorted), Colors).
