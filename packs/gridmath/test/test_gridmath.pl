:- use_module('../prolog/gridmath').

:- begin_tests(gridmath).

% --- gridmath_add ---

test(add_2x2) :-
    gridmath_add([[1,2],[3,4]], [[5,6],[7,8]], C),
    C = [[6,8],[10,12]].

test(add_zeros) :-
    gridmath_add([[0,0],[0,0]], [[1,2],[3,4]], C),
    C = [[1,2],[3,4]].

test(add_negative) :-
    gridmath_add([[1,2],[3,4]], [[-1,-2],[-3,-4]], C),
    C = [[0,0],[0,0]].

% --- gridmath_sub ---

test(sub_2x2) :-
    gridmath_sub([[5,6],[7,8]], [[1,2],[3,4]], C),
    C = [[4,4],[4,4]].

test(sub_self) :-
    gridmath_sub([[3,3],[3,3]], [[3,3],[3,3]], C),
    C = [[0,0],[0,0]].

test(sub_negative_result) :-
    gridmath_sub([[1,2],[3,4]], [[5,6],[7,8]], C),
    C = [[-4,-4],[-4,-4]].

% --- gridmath_mul ---

test(mul_2x2) :-
    gridmath_mul([[1,2],[3,4]], [[5,6],[7,8]], C),
    C = [[5,12],[21,32]].

test(mul_zeros) :-
    gridmath_mul([[1,2],[3,4]], [[0,0],[0,0]], C),
    C = [[0,0],[0,0]].

test(mul_ones) :-
    gridmath_mul([[5,6],[7,8]], [[1,1],[1,1]], C),
    C = [[5,6],[7,8]].

% --- gridmath_max ---

test(max_2x2) :-
    gridmath_max([[1,5],[3,2]], [[4,2],[1,6]], C),
    C = [[4,5],[3,6]].

test(max_equal) :-
    gridmath_max([[3,3],[3,3]], [[3,3],[3,3]], C),
    C = [[3,3],[3,3]].

test(max_dominates) :-
    gridmath_max([[9,9],[9,9]], [[1,1],[1,1]], C),
    C = [[9,9],[9,9]].

% --- gridmath_min ---

test(min_2x2) :-
    gridmath_min([[1,5],[3,2]], [[4,2],[1,6]], C),
    C = [[1,2],[1,2]].

test(min_equal) :-
    gridmath_min([[3,3],[3,3]], [[3,3],[3,3]], C),
    C = [[3,3],[3,3]].

test(min_second_dominates) :-
    gridmath_min([[9,9],[9,9]], [[1,2],[3,4]], C),
    C = [[1,2],[3,4]].

% --- gridmath_scale ---

test(scale_by_two) :-
    gridmath_scale([[1,2],[3,4]], 2, G),
    G = [[2,4],[6,8]].

test(scale_by_zero) :-
    gridmath_scale([[5,6],[7,8]], 0, G),
    G = [[0,0],[0,0]].

test(scale_by_one) :-
    gridmath_scale([[1,2],[3,4]], 1, G),
    G = [[1,2],[3,4]].

% --- gridmath_offset ---

test(offset_positive) :-
    gridmath_offset([[1,2],[3,4]], 10, G),
    G = [[11,12],[13,14]].

test(offset_zero) :-
    gridmath_offset([[5,6],[7,8]], 0, G),
    G = [[5,6],[7,8]].

test(offset_negative) :-
    gridmath_offset([[5,6],[7,8]], -3, G),
    G = [[2,3],[4,5]].

% --- gridmath_abs ---

test(abs_mixed) :-
    gridmath_abs([[-1,2],[-3,4]], G),
    G = [[1,2],[3,4]].

test(abs_all_positive) :-
    gridmath_abs([[1,2],[3,4]], G),
    G = [[1,2],[3,4]].

test(abs_all_negative) :-
    gridmath_abs([[-5,-6],[-7,-8]], G),
    G = [[5,6],[7,8]].

% --- gridmath_eq_mask ---

test(eq_mask_partial) :-
    gridmath_eq_mask([[1,2],[3,4]], [[1,5],[3,6]], M),
    M = [[1,0],[1,0]].

test(eq_mask_all_equal) :-
    gridmath_eq_mask([[2,2],[2,2]], [[2,2],[2,2]], M),
    M = [[1,1],[1,1]].

test(eq_mask_none_equal) :-
    gridmath_eq_mask([[1,2],[3,4]], [[5,6],[7,8]], M),
    M = [[0,0],[0,0]].

% --- gridmath_diff_mask ---

test(diff_mask_partial) :-
    gridmath_diff_mask([[1,2],[3,4]], [[1,5],[3,6]], M),
    M = [[0,1],[0,1]].

test(diff_mask_all_equal) :-
    gridmath_diff_mask([[2,2],[2,2]], [[2,2],[2,2]], M),
    M = [[0,0],[0,0]].

test(diff_mask_all_different) :-
    gridmath_diff_mask([[1,2],[3,4]], [[5,6],[7,8]], M),
    M = [[1,1],[1,1]].

% --- gridmath_clamp ---

test(clamp_all_in_range) :-
    gridmath_clamp([[2,3],[4,5]], 1, 6, G),
    G = [[2,3],[4,5]].

test(clamp_below) :-
    gridmath_clamp([[0,-1],[2,3]], 1, 5, G),
    G = [[1,1],[2,3]].

test(clamp_above) :-
    gridmath_clamp([[3,6],[8,2]], 1, 5, G),
    G = [[3,5],[5,2]].

% --- gridmath_modulo ---

test(modulo_2) :-
    gridmath_modulo([[1,2],[3,4]], 2, G),
    G = [[1,0],[1,0]].

test(modulo_3) :-
    gridmath_modulo([[3,6],[9,1]], 3, G),
    G = [[0,0],[0,1]].

test(modulo_10) :-
    gridmath_modulo([[11,22],[33,44]], 10, G),
    G = [[1,2],[3,4]].

% --- gridmath_sum ---

test(sum_2x2) :-
    gridmath_sum([[1,2],[3,4]], S),
    S = 10.

test(sum_zeros) :-
    gridmath_sum([[0,0],[0,0]], S),
    S = 0.

test(sum_single) :-
    gridmath_sum([[5]], S),
    S = 5.

% --- gridmath_product ---

test(product_2x2) :-
    gridmath_product([[1,2],[3,4]], P),
    P = 24.

test(product_ones) :-
    gridmath_product([[1,1],[1,1]], P),
    P = 1.

test(product_with_zero) :-
    gridmath_product([[2,3],[0,4]], P),
    P = 0.

:- end_tests(gridmath).
