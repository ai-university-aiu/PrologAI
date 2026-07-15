% varstat.pl - Layer 138: Mean, Sum, and Deviation Statistics for Integer Lists and 2D Grids (vt_* prefix).
% Provides integer sum, floor mean, rounded mean, signed deviation per element,
% absolute deviation per element, per-row and per-column sums and means,
% global mean, and position lists for cells above or below various means.
%
% All mean computations use integer arithmetic (floor division) unless the
% predicate name contains _round, which uses floating-point rounding.
:- module(varstat, [
    varstat_sum/2,
    varstat_mean_floor/2,
    varstat_mean_round/2,
    varstat_deviation/2,
    varstat_abs_deviation/2,
    varstat_row_sums/2,
    varstat_col_sums/2,
    varstat_row_means/2,
    varstat_col_means/2,
    varstat_global_mean/2,
    varstat_above_mean/2,
    varstat_below_mean/2,
    varstat_row_above_mean/2,
    varstat_col_above_mean/2
]).
% Import list utilities; sum_list/2 for summing, member/2 and nth0/3 for grid traversal.
% sort/2, length/2, between/3, findall/3 are SWI-Prolog built-ins; not imported.
:- use_module(library(lists), [member/2, nth0/3, sum_list/2]).

% varstat_sum(+List, -Sum): Sum is the integer total of all values in List.
% Delegates to sum_list/2 from library(lists).
varstat_sum(List, Sum) :-
% sum_list is the standard SWI-Prolog predicate for totaling a list of numbers.
    sum_list(List, Sum).

% varstat_mean_floor(+List, -Mean): Mean is the floor of the arithmetic mean of List.
% Computed as sum(List) // length(List). Fails when List is empty.
varstat_mean_floor(List, Mean) :-
% Sum the list values.
    sum_list(List, Sum),
% Count the elements.
    length(List, N),
% Guard against empty list; at least one element required.
    N > 0,
% Floor integer division: sum div count.
    Mean is Sum // N.

% varstat_mean_round(+List, -Mean): Mean is the rounded arithmetic mean of List.
% Uses floating-point division then SWI-Prolog round/1 (banker's rounding).
% Fails when List is empty.
varstat_mean_round(List, Mean) :-
% Sum the list.
    sum_list(List, Sum),
% Count the elements.
    length(List, N),
% Guard against empty list.
    N > 0,
% Compute float mean then round to nearest integer (half-to-even).
    Mean is round(float(Sum) / float(N)).

% varstat_deviation(+List, -Devs): Devs[I] = List[I] - floor_mean(List) for each I.
% Signed integer deviation; negative when below mean, positive when above.
varstat_deviation(List, Devs) :-
% Compute the floor mean of the list.
    varstat_mean_floor(List, Mean),
% For each element, subtract the mean.
    findall(D, (member(V, List), D is V - Mean), Devs).

% varstat_abs_deviation(+List, -AbsDevs): AbsDevs[I] = |List[I] - floor_mean(List)|.
% Non-negative integer absolute deviation from the floor mean.
varstat_abs_deviation(List, AbsDevs) :-
% Compute the floor mean.
    varstat_mean_floor(List, Mean),
% For each element compute absolute difference from mean.
    findall(D, (member(V, List), D is abs(V - Mean)), AbsDevs).

% varstat_row_sums(+Grid, -Sums): Sums[R] is the integer sum of all values in row R.
% Sums has the same length as Grid.
varstat_row_sums(Grid, Sums) :-
% Apply sum_list to every row and collect results in order.
    findall(S, (member(Row, Grid), sum_list(Row, S)), Sums).

% varstat_col_sums(+Grid, -Sums): Sums[C] is the integer sum of all values in column C.
% Sums has the same length as the number of columns. Returns [] on empty grid.
varstat_col_sums(Grid, Sums) :-
% Determine column count from the first row; default to 0 for empty grid.
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0),
% Highest valid column index.
    W1 is W - 1,
% For each column index, collect column values and sum them.
    findall(S, (between(0, W1, C),
        findall(V, (member(Row, Grid), nth0(C, Row, V)), ColVals),
        sum_list(ColVals, S)), Sums).

% varstat_row_means(+Grid, -Means): Means[R] is the floor mean of row R.
% Each mean is computed independently by varstat_mean_floor.
varstat_row_means(Grid, Means) :-
% Compute floor mean of every row and collect in order.
    findall(M, (member(Row, Grid), varstat_mean_floor(Row, M)), Means).

% varstat_col_means(+Grid, -Means): Means[C] is the floor mean of column C.
% Each column mean is computed from all values in that column.
varstat_col_means(Grid, Means) :-
% Determine column count.
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0),
% Highest valid column index.
    W1 is W - 1,
% For each column, collect values and compute floor mean.
    findall(M, (between(0, W1, C),
        findall(V, (member(Row, Grid), nth0(C, Row, V)), ColVals),
        varstat_mean_floor(ColVals, M)), Means).

% varstat_global_mean(+Grid, -Mean): Mean is the floor mean of all cell values in Grid.
% All cells across all rows contribute to a single pooled mean.
varstat_global_mean(Grid, Mean) :-
% Flatten all cell values into one list.
    findall(V, (member(Row, Grid), member(V, Row)), Vals),
% Compute the floor mean of the pooled list.
    varstat_mean_floor(Vals, Mean).

% varstat_above_mean(+Grid, -Cells): Cells is the sorted R-C list of positions
% whose value is strictly greater than the global floor mean.
% Cells are enumerated in row-major order (R outer, C inner).
varstat_above_mean(Grid, Cells) :-
% Compute global floor mean.
    varstat_global_mean(Grid, Mean),
% Determine grid dimensions.
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
% Collect R-C pairs where value strictly exceeds mean, in row-major order.
    findall(R-C, (between(0, H1, R), between(0, W1, C),
        nth0(R, Grid, Row), nth0(C, Row, V),
        V > Mean), Cells).

% varstat_below_mean(+Grid, -Cells): Cells is the sorted R-C list of positions
% whose value is strictly less than the global floor mean.
% Cells are enumerated in row-major order.
varstat_below_mean(Grid, Cells) :-
% Compute global floor mean.
    varstat_global_mean(Grid, Mean),
% Determine grid dimensions.
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
% Collect R-C pairs where value is strictly below mean, in row-major order.
    findall(R-C, (between(0, H1, R), between(0, W1, C),
        nth0(R, Grid, Row), nth0(C, Row, V),
        V < Mean), Cells).

% varstat_row_above_mean(+Grid, -Cells): Cells is the sorted R-C list of positions
% whose value is strictly greater than the floor mean of their own row.
% Each row's mean is computed independently.
varstat_row_above_mean(Grid, Cells) :-
% Determine grid dimensions.
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
% For each row, compute the row mean, then collect cells above it.
    findall(R-C, (between(0, H1, R),
        nth0(R, Grid, Row),
        varstat_mean_floor(Row, RowMean),
        between(0, W1, C),
        nth0(C, Row, V),
        V > RowMean), Cells).

% varstat_col_above_mean(+Grid, -Cells): Cells is the sorted R-C list of positions
% whose value is strictly greater than the floor mean of their own column.
% Each column's mean is computed from all rows; cells returned in row-major order.
varstat_col_above_mean(Grid, Cells) :-
% Determine grid dimensions.
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
% Enumerate in row-major order; for each (R,C), compute column mean and compare.
    findall(R-C, (between(0, H1, R),
        between(0, W1, C),
        findall(CV, (member(Row2, Grid), nth0(C, Row2, CV)), ColVals),
        varstat_mean_floor(ColVals, ColMean),
        nth0(R, Grid, Row),
        nth0(C, Row, V),
        V > ColMean), Cells).
