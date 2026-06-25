% test_gravity.pl - PLUnit tests for the gravity pack (Layer 95: gv_* predicates).
:- use_module('../prolog/gravity').

% Tests for gv_pack_row_left/3

:- begin_tests(gv_pack_row_left).

test(mixed_row) :-
    gv_pack_row_left([0,1,0,2], 0, R),
    R = [1,2,0,0].

test(all_bg) :-
    gv_pack_row_left([0,0,0], 0, R),
    R = [0,0,0].

test(no_bg) :-
    gv_pack_row_left([1,2,3], 0, R),
    R = [1,2,3].

:- end_tests(gv_pack_row_left).

% Tests for gv_pack_row_right/3

:- begin_tests(gv_pack_row_right).

test(mixed_row) :-
    gv_pack_row_right([0,1,0,2], 0, R),
    R = [0,0,1,2].

test(all_bg) :-
    gv_pack_row_right([0,0,0], 0, R),
    R = [0,0,0].

test(no_bg) :-
    gv_pack_row_right([1,2,3], 0, R),
    R = [1,2,3].

:- end_tests(gv_pack_row_right).

% Tests for gv_pack_col_up/3

:- begin_tests(gv_pack_col_up).

test(mixed_col) :-
    gv_pack_col_up([0,1,0,2], 0, R),
    R = [1,2,0,0].

test(all_bg) :-
    gv_pack_col_up([0,0,0], 0, R),
    R = [0,0,0].

test(already_at_top) :-
    gv_pack_col_up([1,2,0,0], 0, R),
    R = [1,2,0,0].

:- end_tests(gv_pack_col_up).

% Tests for gv_pack_col_down/3

:- begin_tests(gv_pack_col_down).

test(mixed_col) :-
    gv_pack_col_down([0,1,0,2], 0, R),
    R = [0,0,1,2].

test(all_bg) :-
    gv_pack_col_down([0,0,0], 0, R),
    R = [0,0,0].

test(already_at_bottom) :-
    gv_pack_col_down([0,0,1,2], 0, R),
    R = [0,0,1,2].

:- end_tests(gv_pack_col_down).

% Tests for gv_fall_left/3

:- begin_tests(gv_fall_left).

test(scattered_grid) :-
    gv_fall_left([[0,1,0],[2,0,3]], 0, R),
    R = [[1,0,0],[2,3,0]].

test(all_bg_row) :-
    gv_fall_left([[0,0,0]], 0, R),
    R = [[0,0,0]].

test(no_bg_row) :-
    gv_fall_left([[1,2,3]], 0, R),
    R = [[1,2,3]].

:- end_tests(gv_fall_left).

% Tests for gv_fall_right/3

:- begin_tests(gv_fall_right).

test(scattered_grid) :-
    gv_fall_right([[0,1,0],[2,0,3]], 0, R),
    R = [[0,0,1],[0,2,3]].

test(all_bg_row) :-
    gv_fall_right([[0,0,0]], 0, R),
    R = [[0,0,0]].

test(no_bg_row) :-
    gv_fall_right([[1,2,3]], 0, R),
    R = [[1,2,3]].

:- end_tests(gv_fall_right).

% Tests for gv_fall_down/3

:- begin_tests(gv_fall_down).

test(basic_fall) :-
    gv_fall_down([[0,1],[2,0]], 0, R),
    R = [[0,0],[2,1]].

test(all_bg) :-
    gv_fall_down([[0,0],[0,0]], 0, R),
    R = [[0,0],[0,0]].

test(scattered_3x3) :-
    gv_fall_down([[1,0,2],[0,3,0],[4,0,5]], 0, R),
    R = [[0,0,0],[1,0,2],[4,3,5]].

:- end_tests(gv_fall_down).

% Tests for gv_fall_up/3

:- begin_tests(gv_fall_up).

test(basic_rise) :-
    gv_fall_up([[0,1],[2,0]], 0, R),
    R = [[2,1],[0,0]].

test(all_bg) :-
    gv_fall_up([[0,0],[0,0]], 0, R),
    R = [[0,0],[0,0]].

test(scattered_3x3) :-
    gv_fall_up([[1,0,2],[0,3,0],[4,0,5]], 0, R),
    R = [[1,3,2],[4,0,5],[0,0,0]].

:- end_tests(gv_fall_up).

% Tests for gv_fall_dir/4

:- begin_tests(gv_fall_dir).

test(dir_down) :-
    gv_fall_dir([[0,1],[2,0]], 0, down, R),
    R = [[0,0],[2,1]].

test(dir_up) :-
    gv_fall_dir([[0,1],[2,0]], 0, up, R),
    R = [[2,1],[0,0]].

test(dir_left) :-
    gv_fall_dir([[0,1,0],[2,0,3]], 0, left, R),
    R = [[1,0,0],[2,3,0]].

:- end_tests(gv_fall_dir).

% Tests for gv_fall_color_left/4

:- begin_tests(gv_fall_color_left).

test(no_wall) :-
    gv_fall_color_left([[0,1,0,1]], 0, 1, R),
    R = [[1,1,0,0]].

test(wall_stops_color) :-
    gv_fall_color_left([[0,1,0,2,0,1]], 0, 1, R),
    R = [[1,0,0,2,1,0]].

test(multi_row) :-
    gv_fall_color_left([[0,0,1],[0,1,0],[1,0,0]], 0, 1, R),
    R = [[1,0,0],[1,0,0],[1,0,0]].

:- end_tests(gv_fall_color_left).

% Tests for gv_fall_color_right/4

:- begin_tests(gv_fall_color_right).

test(no_wall) :-
    gv_fall_color_right([[1,0,1,0]], 0, 1, R),
    R = [[0,0,1,1]].

test(wall_stops_color) :-
    gv_fall_color_right([[1,0,2,0,1]], 0, 1, R),
    R = [[0,1,2,0,1]].

test(all_bg_row_unchanged) :-
    gv_fall_color_right([[0,0,1]], 0, 1, R),
    R = [[0,0,1]].

:- end_tests(gv_fall_color_right).

% Tests for gv_fall_color_down/4

:- begin_tests(gv_fall_color_down).

test(basic_fall_to_bottom) :-
    gv_fall_color_down([[1,0],[0,1],[0,0]], 0, 1, R),
    R = [[0,0],[0,0],[1,1]].

test(wall_stops_color) :-
    gv_fall_color_down([[1,0],[0,0],[2,0]], 0, 1, R),
    R = [[0,0],[1,0],[2,0]].

test(already_at_bottom) :-
    gv_fall_color_down([[0,0],[0,0],[1,1]], 0, 1, R),
    R = [[0,0],[0,0],[1,1]].

:- end_tests(gv_fall_color_down).

% Tests for gv_fall_color_up/4

:- begin_tests(gv_fall_color_up).

test(basic_rise_to_top) :-
    gv_fall_color_up([[0,0],[0,1],[1,0]], 0, 1, R),
    R = [[1,1],[0,0],[0,0]].

test(wall_stops_color) :-
    gv_fall_color_up([[0,0],[1,0],[2,0]], 0, 1, R),
    R = [[1,0],[0,0],[2,0]].

test(already_at_top) :-
    gv_fall_color_up([[1,1],[0,0],[0,0]], 0, 1, R),
    R = [[1,1],[0,0],[0,0]].

:- end_tests(gv_fall_color_up).

% Tests for gv_fall_color_dir/5

:- begin_tests(gv_fall_color_dir).

test(dir_down) :-
    gv_fall_color_dir([[1,0],[0,1],[0,0]], 0, 1, down, R),
    R = [[0,0],[0,0],[1,1]].

test(dir_up) :-
    gv_fall_color_dir([[0,0],[0,1],[1,0]], 0, 1, up, R),
    R = [[1,1],[0,0],[0,0]].

test(dir_right) :-
    gv_fall_color_dir([[1,0,1,0]], 0, 1, right, R),
    R = [[0,0,1,1]].

:- end_tests(gv_fall_color_dir).
