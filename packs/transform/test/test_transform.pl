% PLUnit tests for the transform pack (tr_* predicates).
:- use_module(library(plunit)).
:- use_module(library(transform)).

% Helper grids.
% 2x3 grid: [[1,2,3],[4,5,6]]
g23([[1,2,3],[4,5,6]]).
% 3x3 identity-like grid
g33([[1,2,3],[4,5,6],[7,8,9]]).
% 2x2 grid
g22([[1,2],[3,4]]).
% 1x1 grid
g11([[7]]).
% 3x2 grid
g32([[1,2],[3,4],[5,6]]).
% Mask grids (0 = transparent, 1 = opaque)
mask22([[1,0],[0,1]]).
mask33([[1,0,0],[0,1,0],[0,0,1]]).

:- begin_tests(transform_scale_up).

test(scale_up_1x1_factor2) :-
    g11(G), transform_scale_up(G, 2, S),
    S = [[7,7],[7,7]].

test(scale_up_factor1_identity) :-
    g22(G), transform_scale_up(G, 1, S),
    S = [[1,2],[3,4]].

test(scale_up_1row_factor2) :-
    transform_scale_up([[1,2]], 2, S),
    S = [[1,1,2,2],[1,1,2,2]].

test(scale_up_dims) :-
    g23(G), transform_scale_up(G, 3, S),
    length(S, Rows), S = [R1|_], length(R1, Cols),
    Rows =:= 6, Cols =:= 9.

:- end_tests(transform_scale_up).

:- begin_tests(transform_scale_down).

test(scale_down_factor1_identity) :-
    g33(G), transform_scale_down(G, 1, S),
    S = [[1,2,3],[4,5,6],[7,8,9]].

test(scale_down_factor2_from_4x4) :-
    transform_scale_down([[1,2,3,4],[5,6,7,8],[9,10,11,12],[13,14,15,16]], 2, S),
    S = [[1,3],[9,11]].

test(scale_down_factor3_from_3x3) :-
    g33(G), transform_scale_down(G, 3, S),
    S = [[1]].

test(scale_down_dims) :-
    transform_scale_down([[1,2,3,4],[5,6,7,8],[9,10,11,12],[13,14,15,16]], 2, S),
    length(S, Rows), S = [R1|_], length(R1, Cols),
    Rows =:= 2, Cols =:= 2.

:- end_tests(transform_scale_down).

:- begin_tests(transform_tile_h).

test(tile_h_n1_identity) :-
    g22(G), transform_tile_h(G, 1, T),
    T = [[1,2],[3,4]].

test(tile_h_n2) :-
    g22(G), transform_tile_h(G, 2, T),
    T = [[1,2,1,2],[3,4,3,4]].

test(tile_h_n3_1row) :-
    transform_tile_h([[1,2,3]], 3, T),
    T = [[1,2,3,1,2,3,1,2,3]].

test(tile_h_dims) :-
    g23(G), transform_tile_h(G, 4, T),
    length(T, Rows), T = [R1|_], length(R1, Cols),
    Rows =:= 2, Cols =:= 12.

:- end_tests(transform_tile_h).

:- begin_tests(transform_tile_v).

test(tile_v_n1_identity) :-
    g22(G), transform_tile_v(G, 1, T),
    T = [[1,2],[3,4]].

test(tile_v_n2) :-
    g22(G), transform_tile_v(G, 2, T),
    T = [[1,2],[3,4],[1,2],[3,4]].

test(tile_v_n3) :-
    transform_tile_v([[5,6]], 3, T),
    T = [[5,6],[5,6],[5,6]].

test(tile_v_dims) :-
    g23(G), transform_tile_v(G, 3, T),
    length(T, Rows), T = [R1|_], length(R1, Cols),
    Rows =:= 6, Cols =:= 3.

:- end_tests(transform_tile_v).

:- begin_tests(transform_tile).

test(tile_n1_identity) :-
    g22(G), transform_tile(G, 1, T),
    T = [[1,2],[3,4]].

test(tile_n2) :-
    g22(G), transform_tile(G, 2, T),
    T = [[1,2,1,2],[3,4,3,4],[1,2,1,2],[3,4,3,4]].

test(tile_dims) :-
    g23(G), transform_tile(G, 2, T),
    length(T, Rows), T = [R1|_], length(R1, Cols),
    Rows =:= 4, Cols =:= 6.

:- end_tests(transform_tile).

:- begin_tests(transform_transpose).

test(transpose_1x1) :-
    g11(G), transform_transpose(G, T),
    T = [[7]].

test(transpose_2x2) :-
    g22(G), transform_transpose(G, T),
    T = [[1,3],[2,4]].

test(transpose_2x3) :-
    g23(G), transform_transpose(G, T),
    T = [[1,4],[2,5],[3,6]].

test(transpose_3x2) :-
    g32(G), transform_transpose(G, T),
    T = [[1,3,5],[2,4,6]].

test(transpose_involution) :-
    % Transposing twice returns the original.
    g33(G), transform_transpose(G, T1), transform_transpose(T1, T2),
    T2 = [[1,2,3],[4,5,6],[7,8,9]].

:- end_tests(transform_transpose).

:- begin_tests(transform_flip_h).

test(flip_h_1x1) :-
    g11(G), transform_flip_h(G, F),
    F = [[7]].

test(flip_h_row) :-
    transform_flip_h([[1,2,3]], F),
    F = [[3,2,1]].

test(flip_h_2x3) :-
    g23(G), transform_flip_h(G, F),
    F = [[3,2,1],[6,5,4]].

test(flip_h_involution) :-
    % Flipping twice = identity.
    g33(G), transform_flip_h(G, F1), transform_flip_h(F1, F2),
    F2 = [[1,2,3],[4,5,6],[7,8,9]].

:- end_tests(transform_flip_h).

:- begin_tests(transform_flip_v).

test(flip_v_1x1) :-
    g11(G), transform_flip_v(G, F),
    F = [[7]].

test(flip_v_2x2) :-
    g22(G), transform_flip_v(G, F),
    F = [[3,4],[1,2]].

test(flip_v_3x3) :-
    g33(G), transform_flip_v(G, F),
    F = [[7,8,9],[4,5,6],[1,2,3]].

test(flip_v_involution) :-
    g33(G), transform_flip_v(G, F1), transform_flip_v(F1, F2),
    F2 = [[1,2,3],[4,5,6],[7,8,9]].

:- end_tests(transform_flip_v).

:- begin_tests(transform_rot90).

test(rot90_1x1) :-
    g11(G), transform_rot90(G, R),
    R = [[7]].

test(rot90_2x2) :-
    % [[1,2],[3,4]] CW 90 -> [[3,1],[4,2]]
    g22(G), transform_rot90(G, R),
    R = [[3,1],[4,2]].

test(rot90_2x3) :-
    % [[1,2,3],[4,5,6]] CW 90 -> [[4,1],[5,2],[6,3]]
    g23(G), transform_rot90(G, R),
    R = [[4,1],[5,2],[6,3]].

test(rot90_4x_identity) :-
    % Four 90-degree rotations return to original.
    g33(G), transform_rot90(G, R1), transform_rot90(R1, R2), transform_rot90(R2, R3), transform_rot90(R3, R4),
    R4 = [[1,2,3],[4,5,6],[7,8,9]].

:- end_tests(transform_rot90).

:- begin_tests(transform_rot180).

test(rot180_1x1) :-
    g11(G), transform_rot180(G, R),
    R = [[7]].

test(rot180_2x2) :-
    % [[1,2],[3,4]] 180 -> [[4,3],[2,1]]
    g22(G), transform_rot180(G, R),
    R = [[4,3],[2,1]].

test(rot180_3x3) :-
    g33(G), transform_rot180(G, R),
    R = [[9,8,7],[6,5,4],[3,2,1]].

test(rot180_involution) :-
    g33(G), transform_rot180(G, R1), transform_rot180(R1, R2),
    R2 = [[1,2,3],[4,5,6],[7,8,9]].

:- end_tests(transform_rot180).

:- begin_tests(transform_shift).

test(shift_zero) :-
    % Zero shift = identity.
    g22(G), transform_shift(G, 0, 0, 0, S),
    S = [[1,2],[3,4]].

test(shift_down_1) :-
    % Shift down by 1: row 0 becomes Fill, row 1 gets row 0.
    g22(G), transform_shift(G, 1, 0, 0, S),
    S = [[0,0],[1,2]].

test(shift_right_1) :-
    % Shift right by 1: col 0 becomes Fill, col 1 gets col 0.
    g22(G), transform_shift(G, 0, 1, 0, S),
    S = [[0,1],[0,3]].

test(shift_up_1) :-
    % Shift up by 1 (DR=-1): row 1 of output = row 0 of input.
    g22(G), transform_shift(G, -1, 0, 9, S),
    S = [[3,4],[9,9]].

test(shift_large) :-
    % Shift by more than grid size: all Fill.
    g22(G), transform_shift(G, 5, 5, 0, S),
    S = [[0,0],[0,0]].

:- end_tests(transform_shift).

:- begin_tests(transform_apply_map).

test(apply_map_empty) :-
    % Empty map = identity.
    g22(G), transform_apply_map(G, [], R),
    R = [[1,2],[3,4]].

test(apply_map_single) :-
    transform_apply_map([[0,1,0],[1,0,1]], [0-9], R),
    R = [[9,1,9],[1,9,1]].

test(apply_map_swap) :-
    transform_apply_map([[0,1],[1,0]], [0-1, 1-0], R),
    R = [[1,0],[0,1]].

test(apply_map_absent_kept) :-
    % Values not in the map are kept unchanged.
    transform_apply_map([[5,6]], [5-9], R),
    R = [[9,6]].

:- end_tests(transform_apply_map).

:- begin_tests(transform_replace_color).

test(replace_nothing_matches) :-
    g22(G), transform_replace_color(G, 9, 0, R),
    R = [[1,2],[3,4]].

test(replace_single) :-
    transform_replace_color([[0,1,0],[0,0,1]], 0, 5, R),
    R = [[5,1,5],[5,5,1]].

test(replace_all_same) :-
    transform_replace_color([[2,2],[2,2]], 2, 7, R),
    R = [[7,7],[7,7]].

test(replace_no_other_change) :-
    transform_replace_color([[1,2,3]], 2, 9, R),
    R = [[1,9,3]].

:- end_tests(transform_replace_color).

:- begin_tests(transform_mask_grid).

test(mask_all_transparent) :-
    % All mask cells 0 -> all Fill.
    g22(G), transform_mask_grid(G, [[0,0],[0,0]], 9, R),
    R = [[9,9],[9,9]].

test(mask_all_opaque) :-
    % All mask cells non-zero -> all Grid values kept.
    g22(G), transform_mask_grid(G, [[1,1],[1,1]], 9, R),
    R = [[1,2],[3,4]].

test(mask_diagonal) :-
    mask22(M), g22(G), transform_mask_grid(G, M, 0, R),
    % M = [[1,0],[0,1]]: keep (0,0)=1 and (1,1)=4; fill (0,1) and (1,0).
    R = [[1,0],[0,4]].

test(mask_3x3_diagonal) :-
    mask33(M), g33(G), transform_mask_grid(G, M, 0, R),
    R = [[1,0,0],[0,5,0],[0,0,9]].

:- end_tests(transform_mask_grid).
