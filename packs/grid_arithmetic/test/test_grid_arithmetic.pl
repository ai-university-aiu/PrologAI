% PLUnit tests for the arith pack (ar_* predicates).
:- use_module(library(plunit)).
:- use_module(library(grid_arithmetic)).

:- begin_tests(arithmetic_ar_cell_add).

test(add_basic) :-
    % [1,2;3,4] + [5,6;7,8] = [6,8;10,12].
    grid_arithmetic_cell_add([[1,2],[3,4]], [[5,6],[7,8]], G3),
    G3 = [[6,8],[10,12]].

test(add_zeros) :-
    % Adding zeros leaves the grid unchanged.
    grid_arithmetic_cell_add([[1,2],[3,4]], [[0,0],[0,0]], G3),
    G3 = [[1,2],[3,4]].

test(add_symmetric) :-
    % Addition is symmetric: A+B = B+A.
    grid_arithmetic_cell_add([[1,2]], [[3,4]], G1),
    grid_arithmetic_cell_add([[3,4]], [[1,2]], G2),
    G1 = G2.

:- end_tests(arithmetic_ar_cell_add).

:- begin_tests(arithmetic_ar_cell_sub).

test(sub_basic) :-
    % [5,6;7,8] - [1,2;3,4] = [4,4;4,4].
    grid_arithmetic_cell_sub([[5,6],[7,8]], [[1,2],[3,4]], G3),
    G3 = [[4,4],[4,4]].

test(sub_self) :-
    % Subtracting a grid from itself gives all zeros.
    grid_arithmetic_cell_sub([[3,4],[5,6]], [[3,4],[5,6]], G3),
    G3 = [[0,0],[0,0]].

test(sub_produces_negative) :-
    % Subtraction can produce negative values.
    grid_arithmetic_cell_sub([[1,2]], [[3,4]], G3),
    G3 = [[-2,-2]].

:- end_tests(arithmetic_ar_cell_sub).

:- begin_tests(arithmetic_ar_cell_mul).

test(mul_basic) :-
    % [1,2;3,4] * [2,3;4,5] = [2,6;12,20].
    grid_arithmetic_cell_mul([[1,2],[3,4]], [[2,3],[4,5]], G3),
    G3 = [[2,6],[12,20]].

test(mul_by_ones) :-
    % Multiplying by 1s leaves the grid unchanged.
    grid_arithmetic_cell_mul([[3,4],[5,6]], [[1,1],[1,1]], G3),
    G3 = [[3,4],[5,6]].

test(mul_by_zeros) :-
    % Multiplying by 0s gives all zeros.
    grid_arithmetic_cell_mul([[7,8],[9,10]], [[0,0],[0,0]], G3),
    G3 = [[0,0],[0,0]].

:- end_tests(arithmetic_ar_cell_mul).

:- begin_tests(arithmetic_ar_cell_mod).

test(mod_basic) :-
    % [5,6;7,8] mod 3 = [2,0;1,2].
    grid_arithmetic_cell_mod([[5,6],[7,8]], 3, G2),
    G2 = [[2,0],[1,2]].

test(mod_one) :-
    % Any value mod 1 = 0.
    grid_arithmetic_cell_mod([[4,9],[2,7]], 1, G2),
    G2 = [[0,0],[0,0]].

test(mod_large) :-
    % Modulo larger than all values: unchanged.
    grid_arithmetic_cell_mod([[1,2],[3,4]], 10, G2),
    G2 = [[1,2],[3,4]].

:- end_tests(arithmetic_ar_cell_mod).

:- begin_tests(arithmetic_ar_scalar_add).

test(scalar_add_basic) :-
    % Add 5 to every cell.
    grid_arithmetic_scalar_add([[1,2],[3,4]], 5, G2),
    G2 = [[6,7],[8,9]].

test(scalar_add_zero) :-
    % Adding 0 leaves the grid unchanged.
    grid_arithmetic_scalar_add([[1,2],[3,4]], 0, G2),
    G2 = [[1,2],[3,4]].

test(scalar_add_negative) :-
    % Adding a negative value subtracts.
    grid_arithmetic_scalar_add([[5,6],[7,8]], -3, G2),
    G2 = [[2,3],[4,5]].

:- end_tests(arithmetic_ar_scalar_add).

:- begin_tests(arithmetic_ar_scalar_mul).

test(scalar_mul_basic) :-
    % Multiply every cell by 3.
    grid_arithmetic_scalar_mul([[1,2],[3,4]], 3, G2),
    G2 = [[3,6],[9,12]].

test(scalar_mul_zero) :-
    % Multiplying by 0 gives all zeros.
    grid_arithmetic_scalar_mul([[5,6],[7,8]], 0, G2),
    G2 = [[0,0],[0,0]].

test(scalar_mul_one) :-
    % Multiplying by 1 leaves the grid unchanged.
    grid_arithmetic_scalar_mul([[2,3],[4,5]], 1, G2),
    G2 = [[2,3],[4,5]].

:- end_tests(arithmetic_ar_scalar_mul).

:- begin_tests(arithmetic_ar_row_sum).

test(row_sum_basic) :-
    % Row 1 of [[1,2,3],[4,5,6],[7,8,9]] sums to 15.
    grid_arithmetic_row_sum([[1,2,3],[4,5,6],[7,8,9]], 1, Sum),
    Sum =:= 15.

test(row_sum_zeros) :-
    % Sum of a row of zeros is 0.
    grid_arithmetic_row_sum([[0,0,0],[1,2,3]], 0, Sum),
    Sum =:= 0.

test(row_sum_single) :-
    % Sum of a single-element row.
    grid_arithmetic_row_sum([[7]], 0, Sum),
    Sum =:= 7.

:- end_tests(arithmetic_ar_row_sum).

:- begin_tests(arithmetic_ar_col_sum).

test(col_sum_basic) :-
    % Column 2 of [[1,2,3],[4,5,6],[7,8,9]] sums to 3+6+9=18.
    grid_arithmetic_col_sum([[1,2,3],[4,5,6],[7,8,9]], 2, Sum),
    Sum =:= 18.

test(col_sum_zeros) :-
    % Column 1 is all zeros.
    grid_arithmetic_col_sum([[1,0,3],[4,0,6]], 1, Sum),
    Sum =:= 0.

:- end_tests(arithmetic_ar_col_sum).

:- begin_tests(arithmetic_ar_row_sums).

test(row_sums_basic) :-
    % Row sums of [[1,2],[3,4],[5,6]] = [3, 7, 11].
    grid_arithmetic_row_sums([[1,2],[3,4],[5,6]], Sums),
    Sums = [3,7,11].

test(row_sums_single_row) :-
    % Single-row grid.
    grid_arithmetic_row_sums([[4,5,6]], Sums),
    Sums = [15].

:- end_tests(arithmetic_ar_row_sums).

:- begin_tests(arithmetic_ar_col_sums).

test(col_sums_basic) :-
    % Column sums of [[1,2,3],[4,5,6]] = [5,7,9].
    grid_arithmetic_col_sums([[1,2,3],[4,5,6]], Sums),
    Sums = [5,7,9].

test(col_sums_single_col) :-
    % Single-column grid.
    grid_arithmetic_col_sums([[2],[3],[4]], Sums),
    Sums = [9].

:- end_tests(arithmetic_ar_col_sums).

:- begin_tests(arithmetic_ar_cell_max).

test(max_basic) :-
    % Maximum of [[1,5],[3,2]] is 5.
    grid_arithmetic_cell_max([[1,5],[3,2]], Max),
    Max =:= 5.

test(max_uniform) :-
    % All same: max equals that value.
    grid_arithmetic_cell_max([[7,7],[7,7]], Max),
    Max =:= 7.

test(max_negative) :-
    % Maximum of negative values.
    grid_arithmetic_cell_max([[-3,-1],[-5,-2]], Max),
    Max =:= -1.

:- end_tests(arithmetic_ar_cell_max).

:- begin_tests(arithmetic_ar_cell_min).

test(min_basic) :-
    % Minimum of [[4,1],[3,2]] is 1.
    grid_arithmetic_cell_min([[4,1],[3,2]], Min),
    Min =:= 1.

test(min_uniform) :-
    % All same: min equals that value.
    grid_arithmetic_cell_min([[5,5],[5,5]], Min),
    Min =:= 5.

:- end_tests(arithmetic_ar_cell_min).

:- begin_tests(arithmetic_ar_cell_clamp).

test(clamp_basic) :-
    % Clamp [[0,3,7,10]] to [2,8]: 0->2, 3->3, 7->7, 10->8.
    grid_arithmetic_cell_clamp([[0,3,7,10]], 2, 8, G2),
    G2 = [[2,3,7,8]].

test(clamp_no_effect) :-
    % All values already in range: grid unchanged.
    grid_arithmetic_cell_clamp([[3,4],[5,6]], 2, 8, G2),
    G2 = [[3,4],[5,6]].

test(clamp_all_below) :-
    % All values below Lo: all become Lo.
    grid_arithmetic_cell_clamp([[1,2],[3,4]], 5, 9, G2),
    G2 = [[5,5],[5,5]].

test(clamp_all_above) :-
    % All values above Hi: all become Hi.
    grid_arithmetic_cell_clamp([[7,8],[9,10]], 1, 5, G2),
    G2 = [[5,5],[5,5]].

:- end_tests(arithmetic_ar_cell_clamp).

:- begin_tests(arithmetic_ar_cell_abs_diff).

test(abs_diff_basic) :-
    % |[1,5;3,2] - [4,2;1,7]| = [3,3;2,5].
    grid_arithmetic_cell_abs_diff([[1,5],[3,2]], [[4,2],[1,7]], G3),
    G3 = [[3,3],[2,5]].

test(abs_diff_same) :-
    % Absolute difference of a grid with itself is all zeros.
    grid_arithmetic_cell_abs_diff([[3,4],[5,6]], [[3,4],[5,6]], G3),
    G3 = [[0,0],[0,0]].

test(abs_diff_symmetric) :-
    % |A - B| = |B - A|.
    grid_arithmetic_cell_abs_diff([[5,1]], [[2,4]], G1),
    grid_arithmetic_cell_abs_diff([[2,4]], [[5,1]], G2),
    G1 = G2.

:- end_tests(arithmetic_ar_cell_abs_diff).
