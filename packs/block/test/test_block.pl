:- use_module('../prolog/block').

% Helper for block_map tests: identity on a block.
bk_test_identity_(Block, Block).

:- begin_tests(block).

% --- block_extract ---

test(extract_2x2) :-
    block_extract([[1,2,3],[4,5,6],[7,8,9]], 0, 0, 1, 1, B),
    B = [[1,2],[4,5]].

test(extract_corner) :-
    block_extract([[1,2,3],[4,5,6],[7,8,9]], 1, 1, 2, 2, B),
    B = [[5,6],[8,9]].

test(extract_row) :-
    block_extract([[1,2,3],[4,5,6]], 0, 1, 0, 2, B),
    B = [[2,3]].

% --- block_dims ---

test(dims_3x3_into_1x1) :-
    block_dims([[1,2,3],[4,5,6],[7,8,9]], 1, 1, NR, NC),
    NR = 3, NC = 3.

test(dims_4x4_into_2x2) :-
    block_dims([[1,2,3,4],[5,6,7,8],[9,10,11,12],[13,14,15,16]], 2, 2, NR, NC),
    NR = 2, NC = 2.

test(dims_6x4_into_2x2) :-
    block_dims([[0,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]], 2, 2, NR, NC),
    NR = 3, NC = 2.

% --- block_split_h ---

test(split_h_two_strips) :-
    block_split_h([[1,2],[3,4],[5,6],[7,8]], 2, Strips),
    Strips = [[[1,2],[3,4]], [[5,6],[7,8]]].

test(split_h_three_strips) :-
    block_split_h([[1],[2],[3],[4],[5],[6]], 2, Strips),
    Strips = [[[1],[2]], [[3],[4]], [[5],[6]]].

test(split_h_one_strip) :-
    block_split_h([[1,2],[3,4]], 2, Strips),
    Strips = [[[1,2],[3,4]]].

% --- block_split_v ---

test(split_v_two_strips) :-
    block_split_v([[1,2,3,4],[5,6,7,8]], 2, Strips),
    Strips = [[[1,2],[5,6]], [[3,4],[7,8]]].

test(split_v_one_strip) :-
    block_split_v([[1,2],[3,4]], 2, Strips),
    Strips = [[[1,2],[3,4]]].

test(split_v_three_strips) :-
    block_split_v([[1,2,3,4,5,6]], 2, Strips),
    Strips = [[[1,2]], [[3,4]], [[5,6]]].

% --- block_tile_h ---

test(tile_h_twice) :-
    block_tile_h([[1,2],[3,4]], 2, T),
    T = [[1,2],[3,4],[1,2],[3,4]].

test(tile_h_once) :-
    block_tile_h([[1,2],[3,4]], 1, T),
    T = [[1,2],[3,4]].

test(tile_h_three) :-
    block_tile_h([[1]], 3, T),
    T = [[1],[1],[1]].

% --- block_tile_v ---

test(tile_v_twice) :-
    block_tile_v([[1,2],[3,4]], 2, T),
    T = [[1,2,1,2],[3,4,3,4]].

test(tile_v_once) :-
    block_tile_v([[1,2],[3,4]], 1, T),
    T = [[1,2],[3,4]].

test(tile_v_three) :-
    block_tile_v([[1,2]], 3, T),
    T = [[1,2,1,2,1,2]].

% --- block_count_h ---

test(count_h_exact) :-
    block_count_h([[1],[2],[3],[4]], 2, N),
    N = 2.

test(count_h_one) :-
    block_count_h([[1],[2]], 2, N),
    N = 1.

test(count_h_three) :-
    block_count_h([[1],[2],[3],[4],[5],[6]], 2, N),
    N = 3.

% --- block_count_v ---

test(count_v_exact) :-
    block_count_v([[1,2,3,4]], 2, N),
    N = 2.

test(count_v_one) :-
    block_count_v([[1,2]], 2, N),
    N = 1.

test(count_v_three) :-
    block_count_v([[1,2,3,4,5,6]], 2, N),
    N = 3.

% --- block_map ---

test(map_identity) :-
    block_map([[[1,2],[3,4]], [[5,6],[7,8]]], bk_test_identity_, B2),
    B2 = [[[1,2],[3,4]], [[5,6],[7,8]]].

test(map_length) :-
    block_map([[[1,2],[3,4]], [[5,6],[7,8]]], length, Ns),
    Ns = [2, 2].

test(map_single) :-
    block_map([[[0,0]]], bk_test_identity_, B2),
    B2 = [[[0,0]]].

% --- block_uniform ---

test(uniform_present) :-
    block_uniform([[1,2],[3,4]], 0, 1, V),
    V = 2.

test(uniform_top_left) :-
    block_uniform([[5,6],[7,8]], 0, 0, V),
    V = 5.

test(uniform_bottom_right) :-
    block_uniform([[1,2],[3,9]], 1, 1, V),
    V = 9.

% --- block_mode_color ---

test(mode_color_majority) :-
    block_mode_color([[1,1],[1,2]], 0, 0, V),
    V = 1.

test(mode_color_all_same) :-
    block_mode_color([[3,3],[3,3]], 0, 0, V),
    V = 3.

test(mode_color_tie_low) :-
    block_mode_color([[1,2],[2,1]], 0, 0, V),
    (V = 1 ; V = 2).

% --- block_border_color ---

test(border_color_surrounded) :-
    block_border_color([[0,0,0],[0,1,0],[0,0,0]], 1, 1, Bg),
    Bg = 0.

test(border_color_corner) :-
    block_border_color([[5,5,5],[5,9,5],[5,5,5]], 1, 1, Bg),
    Bg = 5.

test(border_color_edge) :-
    block_border_color([[1,2],[3,4],[5,6]], 1, 0, _Bg).

% --- block_is_solid ---

test(is_solid_yes) :-
    block_is_solid([[3,3],[3,3]], 3, Bool),
    Bool = 1.

test(is_solid_no) :-
    block_is_solid([[3,3],[3,4]], 3, Bool),
    Bool = 0.

test(is_solid_single) :-
    block_is_solid([[7]], 7, Bool),
    Bool = 1.

% --- block_is_border ---

test(is_border_top_left) :-
    block_is_border([[1,2,3],[4,5,6],[7,8,9]], 0, 0, Bool),
    Bool = 1.

test(is_border_center) :-
    block_is_border([[1,2,3],[4,5,6],[7,8,9]], 1, 1, Bool),
    Bool = 0.

test(is_border_bottom_right) :-
    block_is_border([[1,2,3],[4,5,6],[7,8,9]], 2, 2, Bool),
    Bool = 1.

:- end_tests(block).
