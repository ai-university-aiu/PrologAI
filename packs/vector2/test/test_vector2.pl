:- use_module('../prolog/vector2').

:- begin_tests(vector2).

% vector2_offset/6 tests

test(offset_basic) :-
    vector2_offset(0, 0, 3, 4, DR, DC),
    DR = 3, DC = 4.

test(offset_negative) :-
    vector2_offset(3, 4, 0, 0, DR, DC),
    DR = -3, DC = -4.

test(offset_same_cell) :-
    vector2_offset(2, 2, 2, 2, DR, DC),
    DR = 0, DC = 0.

% vector2_add/6 tests

test(add_basic) :-
    vector2_add(1, 1, 2, 3, NR, NC),
    NR = 3, NC = 4.

test(add_zero_vector) :-
    vector2_add(5, 7, 0, 0, NR, NC),
    NR = 5, NC = 7.

test(add_negative) :-
    vector2_add(3, 3, -1, -2, NR, NC),
    NR = 2, NC = 1.

% vector2_scale/5 tests

test(scale_basic) :-
    vector2_scale(2, 3, 4, SDR, SDC),
    SDR = 8, SDC = 12.

test(scale_zero) :-
    vector2_scale(5, 7, 0, SDR, SDC),
    SDR = 0, SDC = 0.

test(scale_negative) :-
    vector2_scale(1, 2, -3, SDR, SDC),
    SDR = -3, SDC = -6.

% vector2_neg/4 tests

test(neg_basic) :-
    vector2_neg(3, -4, NDR, NDC),
    NDR = -3, NDC = 4.

test(neg_zero) :-
    vector2_neg(0, 0, NDR, NDC),
    NDR = 0, NDC = 0.

test(neg_unit) :-
    vector2_neg(-1, 0, NDR, NDC),
    NDR = 1, NDC = 0.

% vector2_len_sq/3 tests

test(len_sq_basic) :-
    vector2_len_sq(3, 4, LSq),
    LSq = 25.

test(len_sq_zero) :-
    vector2_len_sq(0, 0, LSq),
    LSq = 0.

test(len_sq_unit) :-
    vector2_len_sq(1, 0, LSq),
    LSq = 1.

% vector2_manhattan/3 tests

test(manhattan_basic) :-
    vector2_manhattan(3, 4, M),
    M = 7.

test(manhattan_zero) :-
    vector2_manhattan(0, 0, M),
    M = 0.

test(manhattan_negative) :-
    vector2_manhattan(-2, -3, M),
    M = 5.

% vector2_chebyshev/3 tests

test(chebyshev_basic) :-
    vector2_chebyshev(3, 4, D),
    D = 4.

test(chebyshev_equal) :-
    vector2_chebyshev(3, 3, D),
    D = 3.

test(chebyshev_zero) :-
    vector2_chebyshev(0, 0, D),
    D = 0.

% vector2_rot90_cw/4 tests

test(rot90_cw_right) :-
    vector2_rot90_cw(0, 1, RDR, RDC),
    RDR = 1, RDC = 0.

test(rot90_cw_down) :-
    vector2_rot90_cw(1, 0, RDR, RDC),
    RDR = 0, RDC = -1.

test(rot90_cw_diag) :-
    vector2_rot90_cw(-1, 1, RDR, RDC),
    RDR = 1, RDC = 1.

% vector2_rot90_ccw/4 tests

test(rot90_ccw_right) :-
    vector2_rot90_ccw(0, 1, RDR, RDC),
    RDR = -1, RDC = 0.

test(rot90_ccw_down) :-
    vector2_rot90_ccw(1, 0, RDR, RDC),
    RDR = 0, RDC = 1.

test(rot90_ccw_diag) :-
    vector2_rot90_ccw(1, 1, RDR, RDC),
    RDR = -1, RDC = 1.

% vector2_rot180/4 tests

test(rot180_right) :-
    vector2_rot180(0, 1, RDR, RDC),
    RDR = 0, RDC = -1.

test(rot180_diag) :-
    vector2_rot180(1, 1, RDR, RDC),
    RDR = -1, RDC = -1.

test(rot180_zero) :-
    vector2_rot180(0, 0, RDR, RDC),
    RDR = 0, RDC = 0.

% vector2_dot/5 tests

test(dot_orthogonal) :-
    vector2_dot(1, 0, 0, 1, D),
    D = 0.

test(dot_parallel) :-
    vector2_dot(2, 3, 2, 3, D),
    D = 13.

test(dot_opposite) :-
    vector2_dot(1, 0, -1, 0, D),
    D = -1.

% vector2_cross/5 tests

test(cross_ccw) :-
    vector2_cross(1, 0, 0, 1, C),
    C = 1.

test(cross_cw) :-
    vector2_cross(0, 1, 1, 0, C),
    C = -1.

test(cross_parallel) :-
    vector2_cross(2, 4, 1, 2, C),
    C = 0.

% vector2_parallel/4 tests

test(parallel_same_dir) :-
    vector2_parallel(1, 2, 3, 6).

test(parallel_opposite) :-
    vector2_parallel(1, 1, -2, -2).

test(parallel_fails) :-
    \+ vector2_parallel(1, 0, 0, 1).

% vector2_translate_region/4 tests

test(translate_region_basic) :-
    vector2_translate_region([0-0, 0-1, 1-0], 2, 3, NewCells),
    NewCells = [2-3, 2-4, 3-3].

test(translate_region_zero) :-
    vector2_translate_region([1-1, 2-2], 0, 0, NewCells),
    NewCells = [1-1, 2-2].

test(translate_region_negative) :-
    vector2_translate_region([3-3, 4-4], -1, -2, NewCells),
    NewCells = [2-1, 3-2].

:- end_tests(vector2).
