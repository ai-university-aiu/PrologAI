:- use_module('../prolog/object_operation').

:- begin_tests(object_operation).

% object_operation_cells_of/3 tests.
test(cells_of_basic) :-
    object_operation_cells_of([[1,0,1],[0,1,0],[1,0,0]], 1, Cells),
    Cells = [0-0, 0-2, 1-1, 2-0].

test(cells_of_empty) :-
    object_operation_cells_of([[0,0],[0,0]], 1, Cells),
    Cells = [].

test(cells_of_all) :-
    object_operation_cells_of([[2,2],[2,2]], 2, Cells),
    Cells = [0-0, 0-1, 1-0, 1-1].

% object_operation_bbox/5 tests.
test(bbox_rect) :-
    object_operation_bbox([1-2, 1-4, 3-2, 3-4], R0, C0, R1, C1),
    R0 = 1, C0 = 2, R1 = 3, C1 = 4.

test(bbox_single) :-
    object_operation_bbox([2-3], R0, C0, R1, C1),
    R0 = 2, C0 = 3, R1 = 2, C1 = 3.

test(bbox_row) :-
    object_operation_bbox([0-0, 0-1, 0-2], R0, C0, R1, C1),
    R0 = 0, C0 = 0, R1 = 0, C1 = 2.

% object_operation_count/3 tests.
test(count_three) :-
    object_operation_count([[1,0],[1,0],[1,0]], 1, N),
    N = 3.

test(count_zero) :-
    object_operation_count([[0,0],[0,0]], 5, N),
    N = 0.

test(count_all) :-
    object_operation_count([[3,3,3]], 3, N),
    N = 3.

% object_operation_size/4 tests.
test(size_2x3) :-
    object_operation_size([[1,1,1],[1,1,1],[0,0,0]], 1, H, W),
    H = 2, W = 3.

test(size_single) :-
    object_operation_size([[0,1,0]], 1, H, W),
    H = 1, W = 1.

test(size_column) :-
    object_operation_size([[1],[1],[1]], 1, H, W),
    H = 3, W = 1.

% object_operation_center/4 tests.
test(center_3x3) :-
    object_operation_center([[1,1,1],[1,1,1],[1,1,1]], 1, R, C),
    R = 1, C = 1.

test(center_1x3) :-
    object_operation_center([[1,1,1]], 1, R, C),
    R = 0, C = 1.

test(center_4x4) :-
    object_operation_center([[1,1,1,1],[1,1,1,1],[1,1,1,1],[1,1,1,1]], 1, R, C),
    R = 1, C = 1.

% object_operation_erase/4 tests.
test(erase_cells) :-
    object_operation_erase([[1,2,1],[2,1,2],[1,2,1]], 1, 0, Out),
    Out = [[0,2,0],[2,0,2],[0,2,0]].

test(erase_absent) :-
    object_operation_erase([[2,2],[2,2]], 5, 0, Out),
    Out = [[2,2],[2,2]].

test(erase_all) :-
    object_operation_erase([[3,3],[3,3]], 3, 0, Out),
    Out = [[0,0],[0,0]].

% object_operation_repaint/4 tests.
test(repaint_basic) :-
    object_operation_repaint([[1,0,1],[0,1,0]], 1, 9, Out),
    Out = [[9,0,9],[0,9,0]].

test(repaint_identity) :-
    object_operation_repaint([[2,0],[0,2]], 2, 2, Out),
    Out = [[2,0],[0,2]].

test(repaint_partial) :-
    object_operation_repaint([[1,2,1],[1,2,1]], 2, 3, Out),
    Out = [[1,3,1],[1,3,1]].

% object_operation_swap/4 tests.
test(swap_basic) :-
    object_operation_swap([[1,2],[2,1]], 1, 2, Out),
    Out = [[2,1],[1,2]].

test(swap_2x2) :-
    object_operation_swap([[1,1],[2,2]], 1, 2, Out),
    Out = [[2,2],[1,1]].

test(swap_absent) :-
    object_operation_swap([[1,0],[0,1]], 1, 5, Out),
    Out = [[5,0],[0,5]].

% object_operation_move/6 tests.
test(move_right) :-
    object_operation_move([[1,0,0],[0,0,0]], 1, 0, 2, 0, Out),
    Out = [[0,0,1],[0,0,0]].

test(move_down) :-
    object_operation_move([[1,1],[0,0],[0,0]], 1, 2, 0, 0, Out),
    Out = [[0,0],[0,0],[1,1]].

test(move_clip) :-
    object_operation_move([[0,1],[0,0]], 1, 0, 2, 0, Out),
    Out = [[0,0],[0,0]].

% object_operation_copy/5 tests.
test(copy_right) :-
    object_operation_copy([[1,0,0],[0,0,0]], 1, 0, 1, Out),
    Out = [[1,1,0],[0,0,0]].

test(copy_down) :-
    object_operation_copy([[1,1],[0,0],[0,0]], 1, 1, 0, Out),
    Out = [[1,1],[1,1],[0,0]].

test(copy_diagonal) :-
    object_operation_copy([[1,0],[0,0]], 1, 1, 1, Out),
    Out = [[1,0],[0,1]].

% object_operation_rotate90/4 tests.
test(rotate90_column) :-
    object_operation_rotate90([[1,0],[1,0],[0,0]], 1, 0, Out),
    Out = [[1,1],[0,0],[0,0]].

test(rotate90_single) :-
    object_operation_rotate90([[0,0],[0,1]], 1, 0, Out),
    Out = [[0,0],[0,1]].

test(rotate90_lshape) :-
    object_operation_rotate90([[1,0],[1,1],[0,0]], 1, 0, Out),
    Out = [[1,1],[1,0],[0,0]].

% object_operation_rotate180/4 tests.
test(rotate180_row) :-
    object_operation_rotate180([[0,0,0,0],[1,1,0,1],[0,0,0,0]], 1, 0, Out),
    Out = [[0,0,0,0],[1,0,1,1],[0,0,0,0]].

test(rotate180_single) :-
    object_operation_rotate180([[1,0],[0,0]], 1, 0, Out),
    Out = [[1,0],[0,0]].

test(rotate180_2x2) :-
    object_operation_rotate180([[1,0],[0,1]], 1, 0, Out),
    Out = [[1,0],[0,1]].

% object_operation_mirror_h/4 tests.
test(mirror_h_row) :-
    object_operation_mirror_h([[0,1,0,1,1],[0,0,0,0,0]], 1, 0, Out),
    Out = [[0,1,1,0,1],[0,0,0,0,0]].

test(mirror_h_symmetric) :-
    object_operation_mirror_h([[1,0,1]], 1, 0, Out),
    Out = [[1,0,1]].

test(mirror_h_lshape) :-
    object_operation_mirror_h([[1,0],[1,1]], 1, 0, Out),
    Out = [[0,1],[1,1]].

% object_operation_mirror_v/4 tests.
test(mirror_v_col) :-
    object_operation_mirror_v([[1,0],[1,0],[0,0]], 1, 0, Out),
    Out = [[1,0],[1,0],[0,0]].

test(mirror_v_single) :-
    object_operation_mirror_v([[1],[0],[0]], 1, 0, Out),
    Out = [[1],[0],[0]].

test(mirror_v_lshape) :-
    object_operation_mirror_v([[1,1],[0,1],[0,0]], 1, 0, Out),
    Out = [[0,1],[1,1],[0,0]].

:- end_tests(object_operation).
