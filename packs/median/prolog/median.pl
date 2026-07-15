% median.pl - Layer 135: Integer Median Computation for Lists and 2D Grids (md_* prefix).
% Provides the lower (floor) median for integer lists, per-row and per-column medians,
% the grid-wide median, 4-connected and 8-connected median filters, and above/below
% median cell selection at the list, row, column, and grid level.
% The lower median is defined as the element at 0-based index (N-1)//2 of the msorted list,
% which equals the unique median for odd-length lists and the lower of the two middle
% values for even-length lists.
:- module(median, [
    median_median/2,
    median_row/3, median_col/3,
    median_row_medians/2, median_col_medians/2,
    median_grid/2,
    median_filter4/2, median_filter8/2,
    median_above/2, median_below/2,
    median_row_above/3, median_row_below/3,
    median_col_above/3, median_col_below/3
]).
% Import list utilities; msort/2, length/2, between/3, findall/3 are built-ins.
:- use_module(library(lists), [member/2, nth0/3]).

% median_median(+List, -M): M is the lower (floor) median of integer list List.
% Requires List to be non-empty. Uses msort/2 to preserve duplicates.
median_median(List, M) :-
% Sort preserving duplicates, then pick element at floor-median index.
    msort(List, Sorted),
    length(Sorted, N),
    MI is (N - 1) // 2,
    nth0(MI, Sorted, M).

% median_row(+Grid, +R, -M): M is the lower median of row R (0-based) of Grid.
median_row(Grid, R, M) :-
% Extract the row by index, then compute its median.
    nth0(R, Grid, Row),
    median_median(Row, M).

% median_col(+Grid, +C, -M): M is the lower median of column C (0-based) of Grid.
median_col(Grid, C, M) :-
% Collect the column values, then compute the median.
    findall(V, (member(Row, Grid), nth0(C, Row, V)), ColVals),
    median_median(ColVals, M).

% median_row_medians(+Grid, -Ms): Ms is the list of lower medians, one per row.
median_row_medians(Grid, Ms) :-
% Map median_median over each row of the grid.
    findall(M, (member(Row, Grid), median_median(Row, M)), Ms).

% median_col_medians(+Grid, -Ms): Ms is the list of lower medians, one per column.
median_col_medians(Grid, Ms) :-
% Enumerate column indices, collect each column, compute its median.
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(M, (between(0, W1, C), median_col(Grid, C, M)), Ms).

% median_grid(+Grid, -M): M is the lower median of all cell values in Grid.
median_grid(Grid, M) :-
% Flatten all cell values and compute the median of the flat list.
    findall(V, (member(Row, Grid), member(V, Row)), Vals),
    median_median(Vals, M).

% median_filter4(+Grid, -OutGrid): OutGrid[R][C] is the lower median of the cell value
% and all in-bounds 4-connected neighbor values. Shrinks large outliers.
median_filter4(Grid, OutGrid) :-
% Build output grid via nested findall; for each cell, collect self + 4-neighbors.
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(Row, (between(0, H1, R),
        findall(M, (between(0, W1, C),
            nth0(R, Grid, CRow), nth0(C, CRow, V),
            findall(NV, (member(DR-DC, [-1-0, 1-0, 0-(-1), 0-1]),
                NR is R+DR, NC is C+DC,
                NR >= 0, NR < H, NC >= 0, NC < W,
                nth0(NR, Grid, NRow), nth0(NC, NRow, NV)), NbrVals),
            median_median([V|NbrVals], M)), Row)), OutGrid).

% median_filter8(+Grid, -OutGrid): OutGrid[R][C] is the lower median of the cell value
% and all in-bounds 8-connected neighbor values.
median_filter8(Grid, OutGrid) :-
% Same structure as median_filter4 but with 8-directional offsets.
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(Row, (between(0, H1, R),
        findall(M, (between(0, W1, C),
            nth0(R, Grid, CRow), nth0(C, CRow, V),
            findall(NV, (
                member(DR-DC, [-1-(-1), -1-0, -1-1, 0-(-1), 0-1, 1-(-1), 1-0, 1-1]),
                NR is R+DR, NC is C+DC,
                NR >= 0, NR < H, NC >= 0, NC < W,
                nth0(NR, Grid, NRow), nth0(NC, NRow, NV)), NbrVals),
            median_median([V|NbrVals], M)), Row)), OutGrid).

% median_above(+Grid, -Cells): Cells is the sorted list of R-C positions whose value
% is strictly greater than the grid-wide lower median.
median_above(Grid, Cells) :-
% Compute the grid median, then collect all positions strictly above it.
    median_grid(Grid, Median),
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(R-C, (between(0, H1, R), between(0, W1, C),
        nth0(R, Grid, Row), nth0(C, Row, V), V > Median), Cells).

% median_below(+Grid, -Cells): Cells is the sorted list of R-C positions whose value
% is strictly less than the grid-wide lower median.
median_below(Grid, Cells) :-
% Compute the grid median, then collect all positions strictly below it.
    median_grid(Grid, Median),
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(R-C, (between(0, H1, R), between(0, W1, C),
        nth0(R, Grid, Row), nth0(C, Row, V), V < Median), Cells).

% median_row_above(+Grid, +R, -Cells): Cells is the list of R-C positions in row R
% whose value is strictly greater than that row's lower median.
median_row_above(Grid, R, Cells) :-
% Compute the row median, then collect positions in that row strictly above it.
    median_row(Grid, R, Median),
    nth0(R, Grid, Row),
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(R-C, (between(0, W1, C), nth0(C, Row, V), V > Median), Cells).

% median_row_below(+Grid, +R, -Cells): Cells is the list of R-C positions in row R
% whose value is strictly less than that row's lower median.
median_row_below(Grid, R, Cells) :-
% Compute the row median, then collect positions in that row strictly below it.
    median_row(Grid, R, Median),
    nth0(R, Grid, Row),
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(R-C, (between(0, W1, C), nth0(C, Row, V), V < Median), Cells).

% median_col_above(+Grid, +C, -Cells): Cells is the list of R-C positions in column C
% whose value is strictly greater than that column's lower median.
median_col_above(Grid, C, Cells) :-
% Compute the column median, then collect positions in that column strictly above it.
    median_col(Grid, C, Median),
    length(Grid, H), H1 is H - 1,
    findall(R-C, (between(0, H1, R),
        nth0(R, Grid, Row), nth0(C, Row, V), V > Median), Cells).

% median_col_below(+Grid, +C, -Cells): Cells is the list of R-C positions in column C
% whose value is strictly less than that column's lower median.
median_col_below(Grid, C, Cells) :-
% Compute the column median, then collect positions in that column strictly below it.
    median_col(Grid, C, Median),
    length(Grid, H), H1 is H - 1,
    findall(R-C, (between(0, H1, R),
        nth0(R, Grid, Row), nth0(C, Row, V), V < Median), Cells).
