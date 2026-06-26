:- use_module('../prolog/gridmath').

:- begin_tests(gridmath).

% --- gm_add ---

test(add_2x2) :-
    gm_add([[1,2],[3,4]], [[5,6],[7,8]], C),
    C = [[6,8],[10,12]].

test(add_zeros) :-
    gm_add([[0,0],[0,0]], [[1,2],[3,4]], C),
    C = [[1,2],[3,4]].

test(add_negative) :-
    gm_add([[1,2],[3,4]], [[-1,-2],[-3,-4]], C),
    C = [[0,0],[0,0]].

% --- gm_sub ---

test(sub_2x2) :-
    gm_sub([[5,6],[7,8]], [[1,2],[3,4]], C),
    C = [[4,4],[4,4]].

test(sub_self) :-
    gm_sub([[3,3],[3,3]], [[3,3],[3,3]], C),
    C = [[0,0],[0,0]].

test(sub_negative_result) :-
    gm_sub([[1,2],[3,4]], [[5,6],[7,8]], C),
    C = [[-4,-4],[-4,-4]].

% --- gm_mul ---

test(mul_2x2) :-
    gm_mul([[1,2],[3,4]], [[5,6],[7,8]], C),
    C = [[5,12],[21,32]].

test(mul_zeros) :-
    gm_mul([[1,2],[3,4]], [[0,0],[0,0]], C),
    C = [[0,0],[0,0]].

test(mul_ones) :-
    gm_mul([[5,6],[7,8]], [[1,1],[1,1]], C),
    C = [[5,6],[7,8]].

% --- gm_max ---

test(max_2x2) :-
    gm_max([[1,5],[3,2]], [[4,2],[1,6]], C),
    C = [[4,5],[3,6]].

test(max_equal) :-
    gm_max([[3,3],[3,3]], [[3,3],[3,3]], C),
    C = [[3,3],[3,3]].

test(max_dominates) :-
    gm_max([[9,9],[9,9]], [[1,1],[1,1]], C),
    C = [[9,9],[9,9]].

% --- gm_min ---

test(min_2x2) :-
    gm_min([[1,5],[3,2]], [[4,2],[1,6]], C),
    C = [[1,2],[1,2]].

test(min_equal) :-
    gm_min([[3,3],[3,3]], [[3,3],[3,3]], C),
    C = [[3,3],[3,3]].

test(min_second_dominates) :-
    gm_min([[9,9],[9,9]], [[1,2],[3,4]], C),
    C = [[1,2],[3,4]].

% --- gm_scale ---

test(scale_by_two) :-
    gm_scale([[1,2],[3,4]], 2, G),
    G = [[2,4],[6,8]].

test(scale_by_zero) :-
    gm_scale([[5,6],[7,8]], 0, G),
    G = [[0,0],[0,0]].

test(scale_by_one) :-
    gm_scale([[1,2],[3,4]], 1, G),
    G = [[1,2],[3,4]].

% --- gm_offset ---

test(offset_positive) :-
    gm_offset([[1,2],[3,4]], 10, G),
    G = [[11,12],[13,14]].

test(offset_zero) :-
    gm_offset([[5,6],[7,8]], 0, G),
    G = [[5,6],[7,8]].

test(offset_negative) :-
    gm_offset([[5,6],[7,8]], -3, G),
    G = [[2,3],[4,5]].

% --- gm_abs ---

test(abs_mixed) :-
    gm_abs([[-1,2],[-3,4]], G),
    G = [[1,2],[3,4]].

test(abs_all_positive) :-
    gm_abs([[1,2],[3,4]], G),
    G = [[1,2],[3,4]].

test(abs_all_negative) :-
    gm_abs([[-5,-6],[-7,-8]], G),
    G = [[5,6],[7,8]].

% --- gm_eq_mask ---

test(eq_mask_partial) :-
    gm_eq_mask([[1,2],[3,4]], [[1,5],[3,6]], M),
    M = [[1,0],[1,0]].

test(eq_mask_all_equal) :-
    gm_eq_mask([[2,2],[2,2]], [[2,2],[2,2]], M),
    M = [[1,1],[1,1]].

test(eq_mask_none_equal) :-
    gm_eq_mask([[1,2],[3,4]], [[5,6],[7,8]], M),
    M = [[0,0],[0,0]].

% --- gm_diff_mask ---

test(diff_mask_partial) :-
    gm_diff_mask([[1,2],[3,4]], [[1,5],[3,6]], M),
    M = [[0,1],[0,1]].

test(diff_mask_all_equal) :-
    gm_diff_mask([[2,2],[2,2]], [[2,2],[2,2]], M),
    M = [[0,0],[0,0]].

test(diff_mask_all_different) :-
    gm_diff_mask([[1,2],[3,4]], [[5,6],[7,8]], M),
    M = [[1,1],[1,1]].

% --- gm_clamp ---

test(clamp_all_in_range) :-
    gm_clamp([[2,3],[4,5]], 1, 6, G),
    G = [[2,3],[4,5]].

test(clamp_below) :-
    gm_clamp([[0,-1],[2,3]], 1, 5, G),
    G = [[1,1],[2,3]].

test(clamp_above) :-
    gm_clamp([[3,6],[8,2]], 1, 5, G),
    G = [[3,5],[5,2]].

% --- gm_modulo ---

test(modulo_2) :-
    gm_modulo([[1,2],[3,4]], 2, G),
    G = [[1,0],[1,0]].

test(modulo_3) :-
    gm_modulo([[3,6],[9,1]], 3, G),
    G = [[0,0],[0,1]].

test(modulo_10) :-
    gm_modulo([[11,22],[33,44]], 10, G),
    G = [[1,2],[3,4]].

% --- gm_sum ---

test(sum_2x2) :-
    gm_sum([[1,2],[3,4]], S),
    S = 10.

test(sum_zeros) :-
    gm_sum([[0,0],[0,0]], S),
    S = 0.

test(sum_single) :-
    gm_sum([[5]], S),
    S = 5.

% --- gm_product ---

test(product_2x2) :-
    gm_product([[1,2],[3,4]], P),
    P = 24.

test(product_ones) :-
    gm_product([[1,1],[1,1]], P),
    P = 1.

test(product_with_zero) :-
    gm_product([[2,3],[0,4]], P),
    P = 0.

:- end_tests(gridmath).
