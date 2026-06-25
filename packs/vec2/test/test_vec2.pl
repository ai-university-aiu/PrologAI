:- use_module('../prolog/vec2').

:- begin_tests(vec2).

% vv_offset/6 tests

test(offset_basic) :-
    vv_offset(0, 0, 3, 4, DR, DC),
    DR = 3, DC = 4.

test(offset_negative) :-
    vv_offset(3, 4, 0, 0, DR, DC),
    DR = -3, DC = -4.

test(offset_same_cell) :-
    vv_offset(2, 2, 2, 2, DR, DC),
    DR = 0, DC = 0.

% vv_add/6 tests

test(add_basic) :-
    vv_add(1, 1, 2, 3, NR, NC),
    NR = 3, NC = 4.

test(add_zero_vector) :-
    vv_add(5, 7, 0, 0, NR, NC),
    NR = 5, NC = 7.

test(add_negative) :-
    vv_add(3, 3, -1, -2, NR, NC),
    NR = 2, NC = 1.

% vv_scale/5 tests

test(scale_basic) :-
    vv_scale(2, 3, 4, SDR, SDC),
    SDR = 8, SDC = 12.

test(scale_zero) :-
    vv_scale(5, 7, 0, SDR, SDC),
    SDR = 0, SDC = 0.

test(scale_negative) :-
    vv_scale(1, 2, -3, SDR, SDC),
    SDR = -3, SDC = -6.

% vv_neg/4 tests

test(neg_basic) :-
    vv_neg(3, -4, NDR, NDC),
    NDR = -3, NDC = 4.

test(neg_zero) :-
    vv_neg(0, 0, NDR, NDC),
    NDR = 0, NDC = 0.

test(neg_unit) :-
    vv_neg(-1, 0, NDR, NDC),
    NDR = 1, NDC = 0.

% vv_len_sq/3 tests

test(len_sq_basic) :-
    vv_len_sq(3, 4, LSq),
    LSq = 25.

test(len_sq_zero) :-
    vv_len_sq(0, 0, LSq),
    LSq = 0.

test(len_sq_unit) :-
    vv_len_sq(1, 0, LSq),
    LSq = 1.

% vv_manhattan/3 tests

test(manhattan_basic) :-
    vv_manhattan(3, 4, M),
    M = 7.

test(manhattan_zero) :-
    vv_manhattan(0, 0, M),
    M = 0.

test(manhattan_negative) :-
    vv_manhattan(-2, -3, M),
    M = 5.

% vv_chebyshev/3 tests

test(chebyshev_basic) :-
    vv_chebyshev(3, 4, D),
    D = 4.

test(chebyshev_equal) :-
    vv_chebyshev(3, 3, D),
    D = 3.

test(chebyshev_zero) :-
    vv_chebyshev(0, 0, D),
    D = 0.

% vv_rot90_cw/4 tests

test(rot90_cw_right) :-
    vv_rot90_cw(0, 1, RDR, RDC),
    RDR = 1, RDC = 0.

test(rot90_cw_down) :-
    vv_rot90_cw(1, 0, RDR, RDC),
    RDR = 0, RDC = -1.

test(rot90_cw_diag) :-
    vv_rot90_cw(-1, 1, RDR, RDC),
    RDR = 1, RDC = 1.

% vv_rot90_ccw/4 tests

test(rot90_ccw_right) :-
    vv_rot90_ccw(0, 1, RDR, RDC),
    RDR = -1, RDC = 0.

test(rot90_ccw_down) :-
    vv_rot90_ccw(1, 0, RDR, RDC),
    RDR = 0, RDC = 1.

test(rot90_ccw_diag) :-
    vv_rot90_ccw(1, 1, RDR, RDC),
    RDR = -1, RDC = 1.

% vv_rot180/4 tests

test(rot180_right) :-
    vv_rot180(0, 1, RDR, RDC),
    RDR = 0, RDC = -1.

test(rot180_diag) :-
    vv_rot180(1, 1, RDR, RDC),
    RDR = -1, RDC = -1.

test(rot180_zero) :-
    vv_rot180(0, 0, RDR, RDC),
    RDR = 0, RDC = 0.

% vv_dot/5 tests

test(dot_orthogonal) :-
    vv_dot(1, 0, 0, 1, D),
    D = 0.

test(dot_parallel) :-
    vv_dot(2, 3, 2, 3, D),
    D = 13.

test(dot_opposite) :-
    vv_dot(1, 0, -1, 0, D),
    D = -1.

% vv_cross/5 tests

test(cross_ccw) :-
    vv_cross(1, 0, 0, 1, C),
    C = 1.

test(cross_cw) :-
    vv_cross(0, 1, 1, 0, C),
    C = -1.

test(cross_parallel) :-
    vv_cross(2, 4, 1, 2, C),
    C = 0.

% vv_parallel/4 tests

test(parallel_same_dir) :-
    vv_parallel(1, 2, 3, 6).

test(parallel_opposite) :-
    vv_parallel(1, 1, -2, -2).

test(parallel_fails) :-
    \+ vv_parallel(1, 0, 0, 1).

% vv_translate_region/4 tests

test(translate_region_basic) :-
    vv_translate_region([0-0, 0-1, 1-0], 2, 3, NewCells),
    NewCells = [2-3, 2-4, 3-3].

test(translate_region_zero) :-
    vv_translate_region([1-1, 2-2], 0, 0, NewCells),
    NewCells = [1-1, 2-2].

test(translate_region_negative) :-
    vv_translate_region([3-3, 4-4], -1, -2, NewCells),
    NewCells = [2-1, 3-2].

:- end_tests(vec2).
