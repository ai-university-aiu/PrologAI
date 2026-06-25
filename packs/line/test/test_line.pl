:- use_module('../prolog/line').

:- begin_tests(line).

% li_hline/4 tests

test(hline_basic) :-
    li_hline(1, 0, 3, [1-0, 1-1, 1-2, 1-3]).

test(hline_single_cell) :-
    li_hline(2, 4, 4, [2-4]).

test(hline_reversed) :-
    li_hline(0, 5, 2, [0-2, 0-3, 0-4, 0-5]).

% li_vline/4 tests

test(vline_basic) :-
    li_vline(2, 0, 3, [0-2, 1-2, 2-2, 3-2]).

test(vline_single_cell) :-
    li_vline(3, 1, 1, [1-3]).

test(vline_reversed) :-
    li_vline(0, 4, 1, [1-0, 2-0, 3-0, 4-0]).

% li_diag_seg/5 tests

test(diag_seg_down_right) :-
    li_diag_seg(0, 0, 2, 2, [0-0, 1-1, 2-2]).

test(diag_seg_up_right) :-
    li_diag_seg(2, 0, 0, 2, [2-0, 1-1, 0-2]).

test(diag_seg_single) :-
    li_diag_seg(3, 3, 3, 3, [3-3]).

% li_draw_h/6 tests

test(draw_h_basic) :-
    Grid = [[0,0,0],[0,0,0],[0,0,0]],
    li_draw_h(Grid, 1, 0, 2, 5, [[0,0,0],[5,5,5],[0,0,0]]).

test(draw_h_single_col) :-
    Grid = [[0,0,0],[0,0,0]],
    li_draw_h(Grid, 0, 1, 1, 9, [[0,9,0],[0,0,0]]).

test(draw_h_full_row) :-
    Grid = [[1,2,3]],
    li_draw_h(Grid, 0, 0, 2, 7, [[7,7,7]]).

% li_draw_v/6 tests

test(draw_v_basic) :-
    Grid = [[0,0,0],[0,0,0],[0,0,0]],
    li_draw_v(Grid, 1, 0, 2, 4, [[0,4,0],[0,4,0],[0,4,0]]).

test(draw_v_single_row) :-
    Grid = [[0,0],[0,0],[0,0]],
    li_draw_v(Grid, 0, 2, 2, 3, [[0,0],[0,0],[3,0]]).

test(draw_v_full_col) :-
    Grid = [[0],[0],[0]],
    li_draw_v(Grid, 0, 0, 2, 6, [[6],[6],[6]]).

% li_draw_diag/7 tests

test(draw_diag_down_right) :-
    Grid = [[0,0,0],[0,0,0],[0,0,0]],
    li_draw_diag(Grid, 0, 0, 2, 2, 1, [[1,0,0],[0,1,0],[0,0,1]]).

test(draw_diag_up_right) :-
    Grid = [[0,0,0],[0,0,0],[0,0,0]],
    li_draw_diag(Grid, 2, 0, 0, 2, 1, [[0,0,1],[0,1,0],[1,0,0]]).

test(draw_diag_single) :-
    Grid = [[0,0],[0,0]],
    li_draw_diag(Grid, 1, 1, 1, 1, 9, [[0,0],[0,9]]).

% li_same_row/4 tests

test(same_row_true) :-
    li_same_row(2, 0, 2, 5).

test(same_row_false) :-
    \+ li_same_row(1, 3, 2, 3).

test(same_row_same_cell) :-
    li_same_row(4, 4, 4, 4).

% li_same_col/4 tests

test(same_col_true) :-
    li_same_col(0, 3, 4, 3).

test(same_col_false) :-
    \+ li_same_col(1, 2, 1, 3).

test(same_col_same_cell) :-
    li_same_col(2, 5, 2, 5).

% li_same_diag/4 tests

test(same_diag_true) :-
    li_same_diag(0, 0, 2, 2).

test(same_diag_false) :-
    \+ li_same_diag(0, 0, 1, 2).

test(same_diag_negative_offset) :-
    li_same_diag(2, 0, 4, 2).

% li_same_anti/4 tests

test(same_anti_true) :-
    li_same_anti(0, 4, 2, 2).

test(same_anti_false) :-
    \+ li_same_anti(0, 3, 1, 3).

test(same_anti_same_cell) :-
    li_same_anti(3, 1, 3, 1).

% li_collinear/6 tests

test(collinear_horizontal) :-
    li_collinear(2, 0, 2, 3, 2, 7).

test(collinear_diagonal) :-
    li_collinear(0, 0, 1, 1, 3, 3).

test(collinear_fails) :-
    \+ li_collinear(0, 0, 1, 2, 2, 2).

% li_endpoints/3 tests

test(endpoints_basic) :-
    li_endpoints([0-0, 1-1, 2-2], 0-0, 2-2).

test(endpoints_single) :-
    li_endpoints([3-5], 3-5, 3-5).

test(endpoints_horizontal) :-
    li_endpoints([1-0, 1-1, 1-2, 1-3], 1-0, 1-3).

% li_gap/5 tests

test(gap_horizontal) :-
    li_gap(1, 0, 1, 4, [1-1, 1-2, 1-3]).

test(gap_vertical) :-
    li_gap(0, 2, 3, 2, [1-2, 2-2]).

test(gap_adjacent) :-
    li_gap(0, 0, 0, 1, []).

% li_line_type/5 tests

test(line_type_horizontal) :-
    li_line_type(2, 0, 2, 5, horizontal).

test(line_type_vertical) :-
    li_line_type(0, 3, 4, 3, vertical).

test(line_type_diagonal) :-
    li_line_type(0, 0, 3, 3, diagonal).

:- end_tests(line).
