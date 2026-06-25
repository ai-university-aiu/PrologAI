% Module declaration: arith pack, Layer 68.
:- module(arith, [
    % ar_cell_add/3: cell-wise addition of two grids.
    ar_cell_add/3,
    % ar_cell_sub/3: cell-wise subtraction of two grids.
    ar_cell_sub/3,
    % ar_cell_mul/3: cell-wise multiplication of two grids.
    ar_cell_mul/3,
    % ar_cell_mod/3: cell-wise modulo of a grid by a scalar.
    ar_cell_mod/3,
    % ar_scalar_add/3: add a scalar to every cell in a grid.
    ar_scalar_add/3,
    % ar_scalar_mul/3: multiply every cell in a grid by a scalar.
    ar_scalar_mul/3,
    % ar_row_sum/3: sum of all cell values in one row.
    ar_row_sum/3,
    % ar_col_sum/3: sum of all cell values in one column.
    ar_col_sum/3,
    % ar_row_sums/2: list of row sums for every row.
    ar_row_sums/2,
    % ar_col_sums/2: list of column sums for every column.
    ar_col_sums/2,
    % ar_cell_max/2: maximum cell value across the entire grid.
    ar_cell_max/2,
    % ar_cell_min/2: minimum cell value across the entire grid.
    ar_cell_min/2,
    % ar_cell_clamp/4: clamp every cell value to a given range.
    ar_cell_clamp/4,
    % ar_cell_abs_diff/3: cell-wise absolute difference of two grids.
    ar_cell_abs_diff/3
]).

% Import list utilities; msort/length/forall are built-ins, not imported.
:- use_module(library(lists), [member/2, nth0/3, numlist/3, append/3,
                                min_list/2, max_list/2]).
% Import higher-order apply utilities.
:- use_module(library(apply), [maplist/2, maplist/3]).

% ar_cell_add(+Grid1, +Grid2, -Grid3).
% Grid3[R][C] = Grid1[R][C] + Grid2[R][C] for every cell.
% Grid1 and Grid2 must have identical dimensions.
ar_cell_add(Grid1, Grid2, Grid3) :-
    % Pairwise combine corresponding rows from Grid1 and Grid2.
    maplist(ar_add_row_, Grid1, Grid2, Grid3).

% ar_add_row_(+Row1, +Row2, -Row3): cell-wise add one pair of rows.
ar_add_row_(Row1, Row2, Row3) :-
    % Pairwise add corresponding cells.
    maplist(ar_add_cell_, Row1, Row2, Row3).

% ar_add_cell_(+V1, +V2, -V3): V3 = V1 + V2.
ar_add_cell_(V1, V2, V3) :-
    % Arithmetic addition.
    V3 is V1 + V2.

% ar_cell_sub(+Grid1, +Grid2, -Grid3).
% Grid3[R][C] = Grid1[R][C] - Grid2[R][C] for every cell.
ar_cell_sub(Grid1, Grid2, Grid3) :-
    % Pairwise combine corresponding rows.
    maplist(ar_sub_row_, Grid1, Grid2, Grid3).

% ar_sub_row_(+Row1, +Row2, -Row3): cell-wise subtract one pair of rows.
ar_sub_row_(Row1, Row2, Row3) :-
    % Pairwise subtract corresponding cells.
    maplist(ar_sub_cell_, Row1, Row2, Row3).

% ar_sub_cell_(+V1, +V2, -V3): V3 = V1 - V2.
ar_sub_cell_(V1, V2, V3) :-
    % Arithmetic subtraction.
    V3 is V1 - V2.

% ar_cell_mul(+Grid1, +Grid2, -Grid3).
% Grid3[R][C] = Grid1[R][C] * Grid2[R][C] for every cell.
ar_cell_mul(Grid1, Grid2, Grid3) :-
    % Pairwise combine corresponding rows.
    maplist(ar_mul_row_, Grid1, Grid2, Grid3).

% ar_mul_row_(+Row1, +Row2, -Row3): cell-wise multiply one pair of rows.
ar_mul_row_(Row1, Row2, Row3) :-
    % Pairwise multiply corresponding cells.
    maplist(ar_mul_cell_, Row1, Row2, Row3).

% ar_mul_cell_(+V1, +V2, -V3): V3 = V1 * V2.
ar_mul_cell_(V1, V2, V3) :-
    % Arithmetic multiplication.
    V3 is V1 * V2.

% ar_cell_mod(+Grid, +N, -Grid2).
% Grid2[R][C] = Grid[R][C] mod N for every cell.
ar_cell_mod(Grid, N, Grid2) :-
    % Apply modulo N to every cell in every row.
    maplist(maplist(ar_mod_cell_(N)), Grid, Grid2).

% ar_mod_cell_(+N, +V, -V2): V2 = V mod N.
ar_mod_cell_(N, V, V2) :-
    % Arithmetic modulo.
    V2 is V mod N.

% ar_scalar_add(+Grid, +N, -Grid2).
% Grid2[R][C] = Grid[R][C] + N for every cell.
ar_scalar_add(Grid, N, Grid2) :-
    % Add scalar N to every cell in every row.
    maplist(maplist(ar_sadd_cell_(N)), Grid, Grid2).

% ar_sadd_cell_(+N, +V, -V2): V2 = V + N.
ar_sadd_cell_(N, V, V2) :-
    % Arithmetic addition with scalar.
    V2 is V + N.

% ar_scalar_mul(+Grid, +N, -Grid2).
% Grid2[R][C] = Grid[R][C] * N for every cell.
ar_scalar_mul(Grid, N, Grid2) :-
    % Multiply every cell in every row by scalar N.
    maplist(maplist(ar_smul_cell_(N)), Grid, Grid2).

% ar_smul_cell_(+N, +V, -V2): V2 = V * N.
ar_smul_cell_(N, V, V2) :-
    % Arithmetic multiplication with scalar.
    V2 is V * N.

% ar_row_sum(+Grid, +R, -Sum).
% Sum is the arithmetic sum of all cell values in row R (0-indexed).
ar_row_sum(Grid, R, Sum) :-
    % Extract row R by 0-indexed lookup.
    nth0(R, Grid, Row),
    % Sum all values in that row.
    ar_list_sum_(Row, Sum).

% ar_list_sum_(+List, -Sum): recursive sum of a list of numbers.
ar_list_sum_([], 0).
ar_list_sum_([V|Vs], Sum) :-
    % Recursively sum the tail, then add V.
    ar_list_sum_(Vs, Rest),
    Sum is V + Rest.

% ar_col_sum(+Grid, +C, -Sum).
% Sum is the arithmetic sum of all cell values in column C (0-indexed).
ar_col_sum(Grid, C, Sum) :-
    % Extract column C by mapping nth0(C) over each row.
    maplist(nth0(C), Grid, Col),
    % Sum all values in the column.
    ar_list_sum_(Col, Sum).

% ar_row_sums(+Grid, -Sums).
% Sums is a list where Sums[i] is the sum of row i.
ar_row_sums(Grid, Sums) :-
    % Map ar_list_sum_ over each row.
    maplist(ar_list_sum_, Grid, Sums).

% ar_col_sums(+Grid, -Sums).
% Sums is a list where Sums[j] is the sum of column j.
ar_col_sums(Grid, Sums) :-
    % Compute the number of columns from the first row.
    ( Grid = [FR|_] -> length(FR, Cols) ; Cols = 0 ),
    Cols1 is Cols - 1,
    % Build the list of column indices.
    numlist(0, Cols1, Cs),
    % Sum each column.
    maplist(ar_col_sum(Grid), Cs, Sums).

% ar_cell_max(+Grid, -Max).
% Max is the largest cell value anywhere in Grid.
ar_cell_max(Grid, Max) :-
    % Flatten the grid to a single list.
    append(Grid, Flat),
    % Find the maximum value.
    max_list(Flat, Max).

% ar_cell_min(+Grid, -Min).
% Min is the smallest cell value anywhere in Grid.
ar_cell_min(Grid, Min) :-
    % Flatten the grid to a single list.
    append(Grid, Flat),
    % Find the minimum value.
    min_list(Flat, Min).

% ar_cell_clamp(+Grid, +Lo, +Hi, -Grid2).
% Grid2[R][C] = max(Lo, min(Hi, Grid[R][C])) for every cell.
% Values below Lo become Lo; values above Hi become Hi.
ar_cell_clamp(Grid, Lo, Hi, Grid2) :-
    % Apply clamping to every cell in every row.
    maplist(maplist(ar_clamp_cell_(Lo, Hi)), Grid, Grid2).

% ar_clamp_cell_(+Lo, +Hi, +V, -V2): clamp V into [Lo, Hi].
ar_clamp_cell_(Lo, Hi, V, V2) :-
    % Use if-then-else for deterministic three-way clamping.
    ( V < Lo -> V2 = Lo
    ; V > Hi -> V2 = Hi
    ; V2 = V
    ).

% ar_cell_abs_diff(+Grid1, +Grid2, -Grid3).
% Grid3[R][C] = |Grid1[R][C] - Grid2[R][C]| for every cell.
ar_cell_abs_diff(Grid1, Grid2, Grid3) :-
    % Pairwise combine corresponding rows.
    maplist(ar_abs_diff_row_, Grid1, Grid2, Grid3).

% ar_abs_diff_row_(+Row1, +Row2, -Row3): cell-wise absolute difference.
ar_abs_diff_row_(Row1, Row2, Row3) :-
    % Pairwise absolute-difference of corresponding cells.
    maplist(ar_abs_diff_cell_, Row1, Row2, Row3).

% ar_abs_diff_cell_(+V1, +V2, -V3): V3 = |V1 - V2|.
ar_abs_diff_cell_(V1, V2, V3) :-
    % Compute absolute value of the difference.
    V3 is abs(V1 - V2).
