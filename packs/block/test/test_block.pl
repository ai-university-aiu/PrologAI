:- use_module('../prolog/block').

% Helper for bk_map tests: identity on a block.
bk_test_identity_(Block, Block).

:- begin_tests(block).

% --- bk_extract ---

test(extract_2x2) :-
    bk_extract([[1,2,3],[4,5,6],[7,8,9]], 0, 0, 1, 1, B),
    B = [[1,2],[4,5]].

test(extract_corner) :-
    bk_extract([[1,2,3],[4,5,6],[7,8,9]], 1, 1, 2, 2, B),
    B = [[5,6],[8,9]].

test(extract_row) :-
    bk_extract([[1,2,3],[4,5,6]], 0, 1, 0, 2, B),
    B = [[2,3]].

% --- bk_dims ---

test(dims_3x3_into_1x1) :-
    bk_dims([[1,2,3],[4,5,6],[7,8,9]], 1, 1, NR, NC),
    NR = 3, NC = 3.

test(dims_4x4_into_2x2) :-
    bk_dims([[1,2,3,4],[5,6,7,8],[9,10,11,12],[13,14,15,16]], 2, 2, NR, NC),
    NR = 2, NC = 2.

test(dims_6x4_into_2x2) :-
    bk_dims([[0,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]], 2, 2, NR, NC),
    NR = 3, NC = 2.

% --- bk_split_h ---

test(split_h_two_strips) :-
    bk_split_h([[1,2],[3,4],[5,6],[7,8]], 2, Strips),
    Strips = [[[1,2],[3,4]], [[5,6],[7,8]]].

test(split_h_three_strips) :-
    bk_split_h([[1],[2],[3],[4],[5],[6]], 2, Strips),
    Strips = [[[1],[2]], [[3],[4]], [[5],[6]]].

test(split_h_one_strip) :-
    bk_split_h([[1,2],[3,4]], 2, Strips),
    Strips = [[[1,2],[3,4]]].

% --- bk_split_v ---

test(split_v_two_strips) :-
    bk_split_v([[1,2,3,4],[5,6,7,8]], 2, Strips),
    Strips = [[[1,2],[5,6]], [[3,4],[7,8]]].

test(split_v_one_strip) :-
    bk_split_v([[1,2],[3,4]], 2, Strips),
    Strips = [[[1,2],[3,4]]].

test(split_v_three_strips) :-
    bk_split_v([[1,2,3,4,5,6]], 2, Strips),
    Strips = [[[1,2]], [[3,4]], [[5,6]]].

% --- bk_tile_h ---

test(tile_h_twice) :-
    bk_tile_h([[1,2],[3,4]], 2, T),
    T = [[1,2],[3,4],[1,2],[3,4]].

test(tile_h_once) :-
    bk_tile_h([[1,2],[3,4]], 1, T),
    T = [[1,2],[3,4]].

test(tile_h_three) :-
    bk_tile_h([[1]], 3, T),
    T = [[1],[1],[1]].

% --- bk_tile_v ---

test(tile_v_twice) :-
    bk_tile_v([[1,2],[3,4]], 2, T),
    T = [[1,2,1,2],[3,4,3,4]].

test(tile_v_once) :-
    bk_tile_v([[1,2],[3,4]], 1, T),
    T = [[1,2],[3,4]].

test(tile_v_three) :-
    bk_tile_v([[1,2]], 3, T),
    T = [[1,2,1,2,1,2]].

% --- bk_count_h ---

test(count_h_exact) :-
    bk_count_h([[1],[2],[3],[4]], 2, N),
    N = 2.

test(count_h_one) :-
    bk_count_h([[1],[2]], 2, N),
    N = 1.

test(count_h_three) :-
    bk_count_h([[1],[2],[3],[4],[5],[6]], 2, N),
    N = 3.

% --- bk_count_v ---

test(count_v_exact) :-
    bk_count_v([[1,2,3,4]], 2, N),
    N = 2.

test(count_v_one) :-
    bk_count_v([[1,2]], 2, N),
    N = 1.

test(count_v_three) :-
    bk_count_v([[1,2,3,4,5,6]], 2, N),
    N = 3.

% --- bk_map ---

test(map_identity) :-
    bk_map([[[1,2],[3,4]], [[5,6],[7,8]]], bk_test_identity_, B2),
    B2 = [[[1,2],[3,4]], [[5,6],[7,8]]].

test(map_length) :-
    bk_map([[[1,2],[3,4]], [[5,6],[7,8]]], length, Ns),
    Ns = [2, 2].

test(map_single) :-
    bk_map([[[0,0]]], bk_test_identity_, B2),
    B2 = [[[0,0]]].

% --- bk_uniform ---

test(uniform_present) :-
    bk_uniform([[1,2],[3,4]], 0, 1, V),
    V = 2.

test(uniform_top_left) :-
    bk_uniform([[5,6],[7,8]], 0, 0, V),
    V = 5.

test(uniform_bottom_right) :-
    bk_uniform([[1,2],[3,9]], 1, 1, V),
    V = 9.

% --- bk_mode_color ---

test(mode_color_majority) :-
    bk_mode_color([[1,1],[1,2]], 0, 0, V),
    V = 1.

test(mode_color_all_same) :-
    bk_mode_color([[3,3],[3,3]], 0, 0, V),
    V = 3.

test(mode_color_tie_low) :-
    bk_mode_color([[1,2],[2,1]], 0, 0, V),
    (V = 1 ; V = 2).

% --- bk_border_color ---

test(border_color_surrounded) :-
    bk_border_color([[0,0,0],[0,1,0],[0,0,0]], 1, 1, Bg),
    Bg = 0.

test(border_color_corner) :-
    bk_border_color([[5,5,5],[5,9,5],[5,5,5]], 1, 1, Bg),
    Bg = 5.

test(border_color_edge) :-
    bk_border_color([[1,2],[3,4],[5,6]], 1, 0, _Bg).

% --- bk_is_solid ---

test(is_solid_yes) :-
    bk_is_solid([[3,3],[3,3]], 3, Bool),
    Bool = 1.

test(is_solid_no) :-
    bk_is_solid([[3,3],[3,4]], 3, Bool),
    Bool = 0.

test(is_solid_single) :-
    bk_is_solid([[7]], 7, Bool),
    Bool = 1.

% --- bk_is_border ---

test(is_border_top_left) :-
    bk_is_border([[1,2,3],[4,5,6],[7,8,9]], 0, 0, Bool),
    Bool = 1.

test(is_border_center) :-
    bk_is_border([[1,2,3],[4,5,6],[7,8,9]], 1, 1, Bool),
    Bool = 0.

test(is_border_bottom_right) :-
    bk_is_border([[1,2,3],[4,5,6],[7,8,9]], 2, 2, Bool),
    Bool = 1.

:- end_tests(block).
