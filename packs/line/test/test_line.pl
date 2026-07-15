:- use_module('../prolog/line').

:- begin_tests(line).

% line_hline/4 tests

test(hline_basic) :-
    line_hline(1, 0, 3, [1-0, 1-1, 1-2, 1-3]).

test(hline_single_cell) :-
    line_hline(2, 4, 4, [2-4]).

test(hline_reversed) :-
    line_hline(0, 5, 2, [0-2, 0-3, 0-4, 0-5]).

% line_vline/4 tests

test(vline_basic) :-
    line_vline(2, 0, 3, [0-2, 1-2, 2-2, 3-2]).

test(vline_single_cell) :-
    line_vline(3, 1, 1, [1-3]).

test(vline_reversed) :-
    line_vline(0, 4, 1, [1-0, 2-0, 3-0, 4-0]).

% line_diag_seg/5 tests

test(diag_seg_down_right) :-
    line_diag_seg(0, 0, 2, 2, [0-0, 1-1, 2-2]).

test(diag_seg_up_right) :-
    line_diag_seg(2, 0, 0, 2, [2-0, 1-1, 0-2]).

test(diag_seg_single) :-
    line_diag_seg(3, 3, 3, 3, [3-3]).

% line_draw_h/6 tests

test(draw_h_basic) :-
    Grid = [[0,0,0],[0,0,0],[0,0,0]],
    line_draw_h(Grid, 1, 0, 2, 5, [[0,0,0],[5,5,5],[0,0,0]]).

test(draw_h_single_col) :-
    Grid = [[0,0,0],[0,0,0]],
    line_draw_h(Grid, 0, 1, 1, 9, [[0,9,0],[0,0,0]]).

test(draw_h_full_row) :-
    Grid = [[1,2,3]],
    line_draw_h(Grid, 0, 0, 2, 7, [[7,7,7]]).

% line_draw_v/6 tests

test(draw_v_basic) :-
    Grid = [[0,0,0],[0,0,0],[0,0,0]],
    line_draw_v(Grid, 1, 0, 2, 4, [[0,4,0],[0,4,0],[0,4,0]]).

test(draw_v_single_row) :-
    Grid = [[0,0],[0,0],[0,0]],
    line_draw_v(Grid, 0, 2, 2, 3, [[0,0],[0,0],[3,0]]).

test(draw_v_full_col) :-
    Grid = [[0],[0],[0]],
    line_draw_v(Grid, 0, 0, 2, 6, [[6],[6],[6]]).

% line_draw_diag/7 tests

test(draw_diag_down_right) :-
    Grid = [[0,0,0],[0,0,0],[0,0,0]],
    line_draw_diag(Grid, 0, 0, 2, 2, 1, [[1,0,0],[0,1,0],[0,0,1]]).

test(draw_diag_up_right) :-
    Grid = [[0,0,0],[0,0,0],[0,0,0]],
    line_draw_diag(Grid, 2, 0, 0, 2, 1, [[0,0,1],[0,1,0],[1,0,0]]).

test(draw_diag_single) :-
    Grid = [[0,0],[0,0]],
    line_draw_diag(Grid, 1, 1, 1, 1, 9, [[0,0],[0,9]]).

% line_same_row/4 tests

test(same_row_true) :-
    line_same_row(2, 0, 2, 5).

test(same_row_false) :-
    \+ line_same_row(1, 3, 2, 3).

test(same_row_same_cell) :-
    line_same_row(4, 4, 4, 4).

% line_same_col/4 tests

test(same_col_true) :-
    line_same_col(0, 3, 4, 3).

test(same_col_false) :-
    \+ line_same_col(1, 2, 1, 3).

test(same_col_same_cell) :-
    line_same_col(2, 5, 2, 5).

% line_same_diag/4 tests

test(same_diag_true) :-
    line_same_diag(0, 0, 2, 2).

test(same_diag_false) :-
    \+ line_same_diag(0, 0, 1, 2).

test(same_diag_negative_offset) :-
    line_same_diag(2, 0, 4, 2).

% line_same_anti/4 tests

test(same_anti_true) :-
    line_same_anti(0, 4, 2, 2).

test(same_anti_false) :-
    \+ line_same_anti(0, 3, 1, 3).

test(same_anti_same_cell) :-
    line_same_anti(3, 1, 3, 1).

% line_collinear/6 tests

test(collinear_horizontal) :-
    line_collinear(2, 0, 2, 3, 2, 7).

test(collinear_diagonal) :-
    line_collinear(0, 0, 1, 1, 3, 3).

test(collinear_fails) :-
    \+ line_collinear(0, 0, 1, 2, 2, 2).

% line_endpoints/3 tests

test(endpoints_basic) :-
    line_endpoints([0-0, 1-1, 2-2], 0-0, 2-2).

test(endpoints_single) :-
    line_endpoints([3-5], 3-5, 3-5).

test(endpoints_horizontal) :-
    line_endpoints([1-0, 1-1, 1-2, 1-3], 1-0, 1-3).

% line_gap/5 tests

test(gap_horizontal) :-
    line_gap(1, 0, 1, 4, [1-1, 1-2, 1-3]).

test(gap_vertical) :-
    line_gap(0, 2, 3, 2, [1-2, 2-2]).

test(gap_adjacent) :-
    line_gap(0, 0, 0, 1, []).

% line_line_type/5 tests

test(line_type_horizontal) :-
    line_line_type(2, 0, 2, 5, horizontal).

test(line_type_vertical) :-
    line_line_type(0, 3, 4, 3, vertical).

test(line_type_diagonal) :-
    line_line_type(0, 0, 3, 3, diagonal).

:- end_tests(line).
