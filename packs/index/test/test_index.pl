:- use_module('../prolog/index').
:- use_module(library(plunit)).

:- begin_tests(index).

% ix_row_grid: cell(R,C) = R.
test(row_grid_1) :-
    ix_row_grid(3, 3, G),
    G = [[0,0,0],[1,1,1],[2,2,2]].
test(row_grid_2) :-
    ix_row_grid(1, 4, G),
    G = [[0,0,0,0]].
test(row_grid_3) :-
    ix_row_grid(2, 2, G),
    G = [[0,0],[1,1]].

% ix_col_grid: cell(R,C) = C.
test(col_grid_1) :-
    ix_col_grid(3, 3, G),
    G = [[0,1,2],[0,1,2],[0,1,2]].
test(col_grid_2) :-
    ix_col_grid(2, 3, G),
    G = [[0,1,2],[0,1,2]].
test(col_grid_3) :-
    ix_col_grid(1, 1, G),
    G = [[0]].

% ix_sum_grid: cell(R,C) = R+C.
test(sum_grid_1) :-
    ix_sum_grid(3, 3, G),
    G = [[0,1,2],[1,2,3],[2,3,4]].
test(sum_grid_2) :-
    ix_sum_grid(2, 2, G),
    G = [[0,1],[1,2]].
test(sum_grid_3) :-
    ix_sum_grid(1, 3, G),
    G = [[0,1,2]].

% ix_diff_grid: cell(R,C) = R-C (may be negative).
test(diff_grid_1) :-
    ix_diff_grid(3, 3, G),
    G = [[0,-1,-2],[1,0,-1],[2,1,0]].
test(diff_grid_2) :-
    ix_diff_grid(2, 2, G),
    G = [[0,-1],[1,0]].
test(diff_grid_3) :-
    ix_diff_grid(2, 3, G),
    G = [[0,-1,-2],[1,0,-1]].

% ix_prod_grid: cell(R,C) = R*C.
test(prod_grid_1) :-
    ix_prod_grid(3, 3, G),
    G = [[0,0,0],[0,1,2],[0,2,4]].
test(prod_grid_2) :-
    ix_prod_grid(2, 2, G),
    G = [[0,0],[0,1]].
test(prod_grid_3) :-
    ix_prod_grid(2, 3, G),
    G = [[0,0,0],[0,1,2]].

% ix_manhattan_grid: cell(R,C) = |R-R0|+|C-C0|.
test(manhattan_1) :-
    ix_manhattan_grid(3, 3, 1, 1, G),
    G = [[2,1,2],[1,0,1],[2,1,2]].
test(manhattan_2) :-
    ix_manhattan_grid(3, 3, 0, 0, G),
    G = [[0,1,2],[1,2,3],[2,3,4]].
test(manhattan_3) :-
    ix_manhattan_grid(1, 1, 0, 0, G),
    G = [[0]].

% ix_chebyshev_grid: cell(R,C) = max(|R-R0|,|C-C0|).
test(chebyshev_1) :-
    ix_chebyshev_grid(3, 3, 1, 1, G),
    G = [[1,1,1],[1,0,1],[1,1,1]].
test(chebyshev_2) :-
    ix_chebyshev_grid(3, 3, 0, 0, G),
    G = [[0,1,2],[1,1,2],[2,2,2]].
test(chebyshev_3) :-
    ix_chebyshev_grid(5, 5, 2, 2, G),
    G = [[2,2,2,2,2],[2,1,1,1,2],[2,1,0,1,2],[2,1,1,1,2],[2,2,2,2,2]].

% ix_mod_grid: cell(R,C) = (R+C) mod N.
test(mod_grid_1) :-
    ix_mod_grid(3, 3, 3, G),
    G = [[0,1,2],[1,2,0],[2,0,1]].
test(mod_grid_2) :-
    ix_mod_grid(2, 4, 2, G),
    G = [[0,1,0,1],[1,0,1,0]].
test(mod_grid_3) :-
    ix_mod_grid(3, 3, 2, G),
    G = [[0,1,0],[1,0,1],[0,1,0]].

% ix_row_mod_grid: cell(R,C) = R mod N.
test(row_mod_1) :-
    ix_row_mod_grid(4, 3, 2, G),
    G = [[0,0,0],[1,1,1],[0,0,0],[1,1,1]].
test(row_mod_2) :-
    ix_row_mod_grid(3, 3, 3, G),
    G = [[0,0,0],[1,1,1],[2,2,2]].
test(row_mod_3) :-
    ix_row_mod_grid(2, 2, 1, G),
    G = [[0,0],[0,0]].

% ix_col_mod_grid: cell(R,C) = C mod N.
test(col_mod_1) :-
    ix_col_mod_grid(3, 4, 2, G),
    G = [[0,1,0,1],[0,1,0,1],[0,1,0,1]].
test(col_mod_2) :-
    ix_col_mod_grid(3, 3, 3, G),
    G = [[0,1,2],[0,1,2],[0,1,2]].
test(col_mod_3) :-
    ix_col_mod_grid(2, 2, 1, G),
    G = [[0,0],[0,0]].

% ix_mask_rows: keep rows in Is; fill others with Bg.
test(mask_rows_1) :-
    ix_mask_rows([[a,b],[c,d],[e,f]], [0,2], 9, G),
    G = [[a,b],[9,9],[e,f]].
test(mask_rows_2) :-
    ix_mask_rows([[1,2],[3,4],[5,6],[7,8]], [1,3], 0, G),
    G = [[0,0],[3,4],[0,0],[7,8]].
test(mask_rows_3) :-
    ix_mask_rows([[1,2,3],[4,5,6]], [0,1], 9, G),
    G = [[1,2,3],[4,5,6]].

% ix_mask_cols: keep cols in Js; fill others with Bg.
test(mask_cols_1) :-
    ix_mask_cols([[a,b,c],[d,e,f]], [1], 0, G),
    G = [[0,b,0],[0,e,0]].
test(mask_cols_2) :-
    ix_mask_cols([[1,2,3,4],[5,6,7,8]], [0,2], 9, G),
    G = [[1,9,3,9],[5,9,7,9]].
test(mask_cols_3) :-
    ix_mask_cols([[1,2],[3,4]], [], 0, G),
    G = [[0,0],[0,0]].

% ix_apply: elementwise binary operation between index grid and value grid.
test(apply_add_1) :-
    ix_row_grid(2, 3, IxG),
    ix_apply(IxG, add, [[10,10,10],[10,10,10]], Out),
    Out = [[10,10,10],[11,11,11]].
test(apply_mul_1) :-
    ix_col_grid(2, 3, IxG),
    ix_apply(IxG, mul, [[1,1,1],[1,1,1]], Out),
    Out = [[0,1,2],[0,1,2]].
test(apply_sub_1) :-
    ix_col_grid(2, 2, IxG),
    ix_apply(IxG, sub, [[5,5],[5,5]], Out),
    Out = [[5,4],[5,4]].

% ix_from: linear offset from reference point (R0,C0).
test(from_1) :-
    ix_from(3, 3, 0, 0, G),
    G = [[0,1,2],[3,4,5],[6,7,8]].
test(from_2) :-
    ix_from(3, 3, 1, 1, G),
    G = [[-4,-3,-2],[-1,0,1],[2,3,4]].
test(from_3) :-
    ix_from(2, 2, 0, 0, G),
    G = [[0,1],[2,3]].

:- end_tests(index).
