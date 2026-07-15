:- use_module('../prolog/offset').

:- begin_tests(offset).

% offset_shift_row/4 tests

% Shift a 4-element row right by 1: [1,2,3,4] -> [0,1,2,3].
test(shift_row_right1) :-
    offset_shift_row([1,2,3,4], 1, 0, S),
    S = [0,1,2,3].

% Shift right by 2: [1,2,3,4] -> [0,0,1,2].
test(shift_row_right2) :-
    offset_shift_row([1,2,3,4], 2, 0, S),
    S = [0,0,1,2].

% Shift right by 0 is the identity.
test(shift_row_right0) :-
    offset_shift_row([5,6,7], 0, 0, S),
    S = [5,6,7].

% offset_shift_row_left/4 tests

% Shift a 4-element row left by 1: [1,2,3,4] -> [2,3,4,0].
test(shift_row_left1) :-
    offset_shift_row_left([1,2,3,4], 1, 0, S),
    S = [2,3,4,0].

% Shift left by 2: [1,2,3,4] -> [3,4,0,0].
test(shift_row_left2) :-
    offset_shift_row_left([1,2,3,4], 2, 0, S),
    S = [3,4,0,0].

% Shift left by 0 is the identity.
test(shift_row_left0) :-
    offset_shift_row_left([5,6,7], 0, 0, S),
    S = [5,6,7].

% offset_roll_row/3 tests

% Circular right shift of [1,2,3,4] by 1: [4,1,2,3].
test(roll_row_right1) :-
    offset_roll_row([1,2,3,4], 1, R),
    R = [4,1,2,3].

% Circular right shift by 4 (full cycle) is the identity.
test(roll_row_full_cycle) :-
    offset_roll_row([1,2,3,4], 4, R),
    R = [1,2,3,4].

% Circular right shift by 2: [1,2,3,4] -> [3,4,1,2].
test(roll_row_right2) :-
    offset_roll_row([1,2,3,4], 2, R),
    R = [3,4,1,2].

% offset_shift_right/4 tests

% Shift a 2x3 grid right by 1 with background 0.
test(shift_right_grid) :-
    offset_shift_right([[1,2,3],[4,5,6]], 1, 0, S),
    S = [[0,1,2],[0,4,5]].

% Shift right by 0 is the identity.
test(shift_right_0) :-
    offset_shift_right([[1,2],[3,4]], 0, 0, S),
    S = [[1,2],[3,4]].

% Shift right by full width produces all-background grid.
test(shift_right_full) :-
    offset_shift_right([[1,2],[3,4]], 2, 0, S),
    S = [[0,0],[0,0]].

% offset_shift_left/4 tests

% Shift a 2x3 grid left by 1.
test(shift_left_grid) :-
    offset_shift_left([[1,2,3],[4,5,6]], 1, 0, S),
    S = [[2,3,0],[5,6,0]].

% Shift left by 0 is the identity.
test(shift_left_0) :-
    offset_shift_left([[1,2],[3,4]], 0, 0, S),
    S = [[1,2],[3,4]].

% Shift left by 2 in a 2x2 grid produces all-background.
test(shift_left_full) :-
    offset_shift_left([[1,2],[3,4]], 2, 0, S),
    S = [[0,0],[0,0]].

% offset_shift_down/4 tests

% Shift a 3x2 grid down by 1.
test(shift_down_1) :-
    offset_shift_down([[1,2],[3,4],[5,6]], 1, 0, S),
    S = [[0,0],[1,2],[3,4]].

% Shift down by 0 is the identity.
test(shift_down_0) :-
    offset_shift_down([[1,2],[3,4]], 0, 0, S),
    S = [[1,2],[3,4]].

% Shift down by full height produces all-background grid.
test(shift_down_full) :-
    offset_shift_down([[1,2],[3,4]], 2, 0, S),
    S = [[0,0],[0,0]].

% offset_shift_up/4 tests

% Shift a 3x2 grid up by 1.
test(shift_up_1) :-
    offset_shift_up([[1,2],[3,4],[5,6]], 1, 0, S),
    S = [[3,4],[5,6],[0,0]].

% Shift up by 0 is the identity.
test(shift_up_0) :-
    offset_shift_up([[1,2],[3,4]], 0, 0, S),
    S = [[1,2],[3,4]].

% Shift up by full height produces all-background grid.
test(shift_up_full) :-
    offset_shift_up([[1,2],[3,4]], 2, 0, S),
    S = [[0,0],[0,0]].

% offset_shift_dir/5 tests

% Dispatch shift right via direction atom.
test(shift_dir_right) :-
    offset_shift_dir([[1,2,3]], right, 1, 0, S),
    S = [[0,1,2]].

% Dispatch shift down via direction atom.
test(shift_dir_down) :-
    offset_shift_dir([[1,2],[3,4],[5,6]], down, 1, 0, S),
    S = [[0,0],[1,2],[3,4]].

% Dispatch shift up via direction atom.
test(shift_dir_up) :-
    offset_shift_dir([[1,2],[3,4]], up, 1, 0, S),
    S = [[3,4],[0,0]].

% offset_roll_right/3 tests

% Circular right shift of each row in a 2x4 grid by 1.
test(roll_right_grid) :-
    offset_roll_right([[1,2,3,4],[5,6,7,8]], 1, R),
    R = [[4,1,2,3],[8,5,6,7]].

% Shift by full width is identity.
test(roll_right_identity) :-
    offset_roll_right([[1,2,3],[4,5,6]], 3, R),
    R = [[1,2,3],[4,5,6]].

% Shift by 2 in a 4-element row: [1,2,3,4] -> [3,4,1,2].
test(roll_right_2) :-
    offset_roll_right([[1,2,3,4]], 2, R),
    R = [[3,4,1,2]].

% offset_roll_left/3 tests

% Circular left shift by 1: [1,2,3,4] -> [2,3,4,1].
test(roll_left_grid) :-
    offset_roll_left([[1,2,3,4]], 1, R),
    R = [[2,3,4,1]].

% Left shift by 0 is identity.
test(roll_left_0) :-
    offset_roll_left([[1,2],[3,4]], 0, R),
    R = [[1,2],[3,4]].

% Left shift by 2 in a 4-element row: [1,2,3,4] -> [3,4,1,2].
test(roll_left_2) :-
    offset_roll_left([[1,2,3,4]], 2, R),
    R = [[3,4,1,2]].

% offset_roll_down/3 tests

% Circular down shift of a 4x1 grid by 1: last row wraps to top.
test(roll_down_1) :-
    offset_roll_down([[1],[2],[3],[4]], 1, R),
    R = [[4],[1],[2],[3]].

% Roll down by full height is identity.
test(roll_down_full) :-
    offset_roll_down([[1,2],[3,4],[5,6]], 3, R),
    R = [[1,2],[3,4],[5,6]].

% Roll down by 2 in a 4-row grid.
test(roll_down_2) :-
    offset_roll_down([[1],[2],[3],[4]], 2, R),
    R = [[3],[4],[1],[2]].

% offset_roll_up/3 tests

% Circular up shift of a 4x1 grid by 1: first row wraps to bottom.
test(roll_up_1) :-
    offset_roll_up([[1],[2],[3],[4]], 1, R),
    R = [[2],[3],[4],[1]].

% Roll up by 0 is identity.
test(roll_up_0) :-
    offset_roll_up([[1,2],[3,4]], 0, R),
    R = [[1,2],[3,4]].

% Roll up by 2 in a 4-row grid.
test(roll_up_2) :-
    offset_roll_up([[1],[2],[3],[4]], 2, R),
    R = [[3],[4],[1],[2]].

% offset_shift_color/6 tests

% Shift color 1 rightward by 1 in a 1x3 grid.
test(shift_color_right) :-
    offset_shift_color([[0,1,0]], 1, 0, 1, 0, R),
    R = [[0,0,1]].

% Shift color 2 downward by 1 in a 3x1 grid.
test(shift_color_down) :-
    offset_shift_color([[2],[0],[0]], 2, 1, 0, 0, R),
    R = [[0],[2],[0]].

% Shift color that goes out of bounds disappears.
test(shift_color_clip) :-
    offset_shift_color([[1,0]], 1, 0, 2, 0, R),
    R = [[0,0]].

% offset_infer_shift/5 tests

% Infer a rightward shift of 1.
test(infer_shift_right) :-
    offset_infer_shift([[0,1,0],[0,0,0]], [[0,0,1],[0,0,0]], 0, DR, DC),
    DR = 0, DC = 1.

% Infer a downward shift of 1.
test(infer_shift_down) :-
    offset_infer_shift([[1,0],[0,0],[0,0]], [[0,0],[1,0],[0,0]], 0, DR, DC),
    DR = 1, DC = 0.

% Infer zero shift (identity).
test(infer_shift_zero) :-
    offset_infer_shift([[1,2],[3,4]], [[1,2],[3,4]], 0, DR, DC),
    DR = 0, DC = 0.

:- end_tests(offset).
