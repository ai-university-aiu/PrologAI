:- use_module('../prolog/cellset').

:- begin_tests(cellset).

% --- cellset_from_grid ---

test(from_grid_basic) :-
    cellset_from_grid([[0,1,0],[1,0,1]], 1, Cells),
    Cells = [0-1, 1-0, 1-2].

test(from_grid_block) :-
    cellset_from_grid([[1,1],[1,0]], 1, Cells),
    Cells = [0-0, 0-1, 1-0].

test(from_grid_absent) :-
    cellset_from_grid([[0,0],[0,0]], 1, Cells),
    Cells = [].

% --- cellset_to_grid ---

test(to_grid_diagonal) :-
    cellset_to_grid([0-0, 1-1], 2, 2, 1, 0, Grid),
    Grid = [[1,0],[0,1]].

test(to_grid_single) :-
    cellset_to_grid([0-1], 2, 3, 9, 0, Grid),
    Grid = [[0,9,0],[0,0,0]].

test(to_grid_empty_cells) :-
    cellset_to_grid([], 2, 2, 1, 0, Grid),
    Grid = [[0,0],[0,0]].

% --- cellset_union ---

test(union_disjoint) :-
    cellset_union([0-0, 0-1], [1-0], Union),
    Union = [0-0, 0-1, 1-0].

test(union_overlap) :-
    cellset_union([0-0, 0-1], [0-0, 1-1], Union),
    Union = [0-0, 0-1, 1-1].

test(union_empty) :-
    cellset_union([], [1-2, 3-4], Union),
    Union = [1-2, 3-4].

% --- cellset_intersect ---

test(intersect_partial) :-
    cellset_intersect([0-0, 0-1, 1-0], [0-1, 1-0, 2-2], Inter),
    Inter = [0-1, 1-0].

test(intersect_disjoint) :-
    cellset_intersect([0-0], [1-1], Inter),
    Inter = [].

test(intersect_identical) :-
    cellset_intersect([0-0, 1-1], [0-0, 1-1], Inter),
    Inter = [0-0, 1-1].

% --- cellset_subtract ---

test(subtract_one) :-
    cellset_subtract([0-0, 0-1, 1-0], [0-1], Diff),
    Diff = [0-0, 1-0].

test(subtract_none_common) :-
    cellset_subtract([0-0, 1-1], [2-2], Diff),
    Diff = [0-0, 1-1].

test(subtract_all) :-
    cellset_subtract([0-0, 1-1], [0-0, 1-1], Diff),
    Diff = [].

% --- cellset_translate ---

test(translate_positive) :-
    cellset_translate([0-0, 0-1, 1-0], 2, 3, S),
    S = [2-3, 2-4, 3-3].

test(translate_zero) :-
    cellset_translate([1-1, 2-2], 0, 0, S),
    S = [1-1, 2-2].

test(translate_negative) :-
    cellset_translate([2-3], -1, -2, S),
    S = [1-1].

% --- cellset_bbox ---

test(bbox_spread) :-
    cellset_bbox([0-1, 1-0, 1-2], R0, C0, R1, C1),
    R0 = 0, C0 = 0, R1 = 1, C1 = 2.

test(bbox_single) :-
    cellset_bbox([3-5], R0, C0, R1, C1),
    R0 = 3, C0 = 5, R1 = 3, C1 = 5.

test(bbox_square_corners) :-
    cellset_bbox([0-0, 0-4, 4-0, 4-4], R0, C0, R1, C1),
    R0 = 0, C0 = 0, R1 = 4, C1 = 4.

% --- cellset_normalize ---

test(normalize_basic) :-
    cellset_normalize([2-3, 2-4, 3-3], Norm, DR, DC),
    Norm = [0-0, 0-1, 1-0], DR = -2, DC = -3.

test(normalize_at_origin) :-
    cellset_normalize([0-0, 0-1, 1-0], Norm, DR, DC),
    Norm = [0-0, 0-1, 1-0], DR = 0, DC = 0.

test(normalize_empty) :-
    cellset_normalize([], Norm, DR, DC),
    Norm = [], DR = 0, DC = 0.

% --- cellset_size ---

test(size_three) :-
    cellset_size([0-0, 1-1, 2-2], N),
    N = 3.

test(size_empty) :-
    cellset_size([], N),
    N = 0.

test(size_one) :-
    cellset_size([0-0], N),
    N = 1.

% --- cellset_contains ---

test(contains_yes) :-
    cellset_contains([0-0, 1-1, 2-2], 1, 1).

test(contains_no) :-
    \+ cellset_contains([0-0, 1-1], 2, 2).

test(contains_corner) :-
    cellset_contains([0-1, 1-0], 0, 1).

% --- cellset_adjacent_bg ---

test(adjacent_single) :-
    cellset_adjacent_bg([2-2], Adj),
    Adj = [1-2, 2-1, 2-3, 3-2].

test(adjacent_pair) :-
    cellset_adjacent_bg([1-1, 1-2], Adj),
    Adj = [0-1, 0-2, 1-0, 1-3, 2-1, 2-2].

test(adjacent_no_negative_check) :-
    cellset_adjacent_bg([0-0, 0-1], Adj),
    length(Adj, N),
    N = 6.

% --- cellset_same_shape ---

test(same_shape_translated) :-
    cellset_same_shape([0-0, 0-1, 1-0], [2-3, 2-4, 3-3]).

test(same_shape_different_fails) :-
    \+ cellset_same_shape([0-0, 0-1], [0-0, 1-0]).

test(same_shape_empty) :-
    cellset_same_shape([], []).

% --- cellset_rotate_90 ---

test(rotate90_top_row_becomes_right_col) :-
    cellset_rotate_90([0-0, 0-1, 0-2], 3, Rot),
    Rot = [0-2, 1-2, 2-2].

test(rotate90_left_col_becomes_top_row) :-
    cellset_rotate_90([0-0, 1-0, 2-0], 3, Rot),
    Rot = [0-0, 0-1, 0-2].

test(rotate90_single) :-
    cellset_rotate_90([0-0], 3, Rot),
    Rot = [0-2].

% --- cellset_mirror_h ---

test(mirror_h_basic) :-
    cellset_mirror_h([0-0, 0-1, 1-2], 3, Mirrored),
    Mirrored = [0-1, 0-2, 1-0].

test(mirror_h_diagonal) :-
    cellset_mirror_h([0-0, 1-1, 2-2], 3, Mirrored),
    Mirrored = [0-2, 1-1, 2-0].

test(mirror_h_center_col) :-
    cellset_mirror_h([0-1, 1-1], 3, Mirrored),
    Mirrored = [0-1, 1-1].

:- end_tests(cellset).
