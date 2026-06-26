:- use_module('../prolog/cellset').

:- begin_tests(cellset).

% --- cs_from_grid ---

test(from_grid_basic) :-
    cs_from_grid([[0,1,0],[1,0,1]], 1, Cells),
    Cells = [0-1, 1-0, 1-2].

test(from_grid_block) :-
    cs_from_grid([[1,1],[1,0]], 1, Cells),
    Cells = [0-0, 0-1, 1-0].

test(from_grid_absent) :-
    cs_from_grid([[0,0],[0,0]], 1, Cells),
    Cells = [].

% --- cs_to_grid ---

test(to_grid_diagonal) :-
    cs_to_grid([0-0, 1-1], 2, 2, 1, 0, Grid),
    Grid = [[1,0],[0,1]].

test(to_grid_single) :-
    cs_to_grid([0-1], 2, 3, 9, 0, Grid),
    Grid = [[0,9,0],[0,0,0]].

test(to_grid_empty_cells) :-
    cs_to_grid([], 2, 2, 1, 0, Grid),
    Grid = [[0,0],[0,0]].

% --- cs_union ---

test(union_disjoint) :-
    cs_union([0-0, 0-1], [1-0], Union),
    Union = [0-0, 0-1, 1-0].

test(union_overlap) :-
    cs_union([0-0, 0-1], [0-0, 1-1], Union),
    Union = [0-0, 0-1, 1-1].

test(union_empty) :-
    cs_union([], [1-2, 3-4], Union),
    Union = [1-2, 3-4].

% --- cs_intersect ---

test(intersect_partial) :-
    cs_intersect([0-0, 0-1, 1-0], [0-1, 1-0, 2-2], Inter),
    Inter = [0-1, 1-0].

test(intersect_disjoint) :-
    cs_intersect([0-0], [1-1], Inter),
    Inter = [].

test(intersect_identical) :-
    cs_intersect([0-0, 1-1], [0-0, 1-1], Inter),
    Inter = [0-0, 1-1].

% --- cs_subtract ---

test(subtract_one) :-
    cs_subtract([0-0, 0-1, 1-0], [0-1], Diff),
    Diff = [0-0, 1-0].

test(subtract_none_common) :-
    cs_subtract([0-0, 1-1], [2-2], Diff),
    Diff = [0-0, 1-1].

test(subtract_all) :-
    cs_subtract([0-0, 1-1], [0-0, 1-1], Diff),
    Diff = [].

% --- cs_translate ---

test(translate_positive) :-
    cs_translate([0-0, 0-1, 1-0], 2, 3, S),
    S = [2-3, 2-4, 3-3].

test(translate_zero) :-
    cs_translate([1-1, 2-2], 0, 0, S),
    S = [1-1, 2-2].

test(translate_negative) :-
    cs_translate([2-3], -1, -2, S),
    S = [1-1].

% --- cs_bbox ---

test(bbox_spread) :-
    cs_bbox([0-1, 1-0, 1-2], R0, C0, R1, C1),
    R0 = 0, C0 = 0, R1 = 1, C1 = 2.

test(bbox_single) :-
    cs_bbox([3-5], R0, C0, R1, C1),
    R0 = 3, C0 = 5, R1 = 3, C1 = 5.

test(bbox_square_corners) :-
    cs_bbox([0-0, 0-4, 4-0, 4-4], R0, C0, R1, C1),
    R0 = 0, C0 = 0, R1 = 4, C1 = 4.

% --- cs_normalize ---

test(normalize_basic) :-
    cs_normalize([2-3, 2-4, 3-3], Norm, DR, DC),
    Norm = [0-0, 0-1, 1-0], DR = -2, DC = -3.

test(normalize_at_origin) :-
    cs_normalize([0-0, 0-1, 1-0], Norm, DR, DC),
    Norm = [0-0, 0-1, 1-0], DR = 0, DC = 0.

test(normalize_empty) :-
    cs_normalize([], Norm, DR, DC),
    Norm = [], DR = 0, DC = 0.

% --- cs_size ---

test(size_three) :-
    cs_size([0-0, 1-1, 2-2], N),
    N = 3.

test(size_empty) :-
    cs_size([], N),
    N = 0.

test(size_one) :-
    cs_size([0-0], N),
    N = 1.

% --- cs_contains ---

test(contains_yes) :-
    cs_contains([0-0, 1-1, 2-2], 1, 1).

test(contains_no) :-
    \+ cs_contains([0-0, 1-1], 2, 2).

test(contains_corner) :-
    cs_contains([0-1, 1-0], 0, 1).

% --- cs_adjacent_bg ---

test(adjacent_single) :-
    cs_adjacent_bg([2-2], Adj),
    Adj = [1-2, 2-1, 2-3, 3-2].

test(adjacent_pair) :-
    cs_adjacent_bg([1-1, 1-2], Adj),
    Adj = [0-1, 0-2, 1-0, 1-3, 2-1, 2-2].

test(adjacent_no_negative_check) :-
    cs_adjacent_bg([0-0, 0-1], Adj),
    length(Adj, N),
    N = 6.

% --- cs_same_shape ---

test(same_shape_translated) :-
    cs_same_shape([0-0, 0-1, 1-0], [2-3, 2-4, 3-3]).

test(same_shape_different_fails) :-
    \+ cs_same_shape([0-0, 0-1], [0-0, 1-0]).

test(same_shape_empty) :-
    cs_same_shape([], []).

% --- cs_rotate_90 ---

test(rotate90_top_row_becomes_right_col) :-
    cs_rotate_90([0-0, 0-1, 0-2], 3, Rot),
    Rot = [0-2, 1-2, 2-2].

test(rotate90_left_col_becomes_top_row) :-
    cs_rotate_90([0-0, 1-0, 2-0], 3, Rot),
    Rot = [0-0, 0-1, 0-2].

test(rotate90_single) :-
    cs_rotate_90([0-0], 3, Rot),
    Rot = [0-2].

% --- cs_mirror_h ---

test(mirror_h_basic) :-
    cs_mirror_h([0-0, 0-1, 1-2], 3, Mirrored),
    Mirrored = [0-1, 0-2, 1-0].

test(mirror_h_diagonal) :-
    cs_mirror_h([0-0, 1-1, 2-2], 3, Mirrored),
    Mirrored = [0-2, 1-1, 2-0].

test(mirror_h_center_col) :-
    cs_mirror_h([0-1, 1-1], 3, Mirrored),
    Mirrored = [0-1, 1-1].

:- end_tests(cellset).
