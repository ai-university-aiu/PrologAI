:- use_module('../prolog/objop').

:- begin_tests(objop).

% objop_cells_of/3 tests.
test(cells_of_basic) :-
    objop_cells_of([[1,0,1],[0,1,0],[1,0,0]], 1, Cells),
    Cells = [0-0, 0-2, 1-1, 2-0].

test(cells_of_empty) :-
    objop_cells_of([[0,0],[0,0]], 1, Cells),
    Cells = [].

test(cells_of_all) :-
    objop_cells_of([[2,2],[2,2]], 2, Cells),
    Cells = [0-0, 0-1, 1-0, 1-1].

% objop_bbox/5 tests.
test(bbox_rect) :-
    objop_bbox([1-2, 1-4, 3-2, 3-4], R0, C0, R1, C1),
    R0 = 1, C0 = 2, R1 = 3, C1 = 4.

test(bbox_single) :-
    objop_bbox([2-3], R0, C0, R1, C1),
    R0 = 2, C0 = 3, R1 = 2, C1 = 3.

test(bbox_row) :-
    objop_bbox([0-0, 0-1, 0-2], R0, C0, R1, C1),
    R0 = 0, C0 = 0, R1 = 0, C1 = 2.

% objop_count/3 tests.
test(count_three) :-
    objop_count([[1,0],[1,0],[1,0]], 1, N),
    N = 3.

test(count_zero) :-
    objop_count([[0,0],[0,0]], 5, N),
    N = 0.

test(count_all) :-
    objop_count([[3,3,3]], 3, N),
    N = 3.

% objop_size/4 tests.
test(size_2x3) :-
    objop_size([[1,1,1],[1,1,1],[0,0,0]], 1, H, W),
    H = 2, W = 3.

test(size_single) :-
    objop_size([[0,1,0]], 1, H, W),
    H = 1, W = 1.

test(size_column) :-
    objop_size([[1],[1],[1]], 1, H, W),
    H = 3, W = 1.

% objop_center/4 tests.
test(center_3x3) :-
    objop_center([[1,1,1],[1,1,1],[1,1,1]], 1, R, C),
    R = 1, C = 1.

test(center_1x3) :-
    objop_center([[1,1,1]], 1, R, C),
    R = 0, C = 1.

test(center_4x4) :-
    objop_center([[1,1,1,1],[1,1,1,1],[1,1,1,1],[1,1,1,1]], 1, R, C),
    R = 1, C = 1.

% objop_erase/4 tests.
test(erase_cells) :-
    objop_erase([[1,2,1],[2,1,2],[1,2,1]], 1, 0, Out),
    Out = [[0,2,0],[2,0,2],[0,2,0]].

test(erase_absent) :-
    objop_erase([[2,2],[2,2]], 5, 0, Out),
    Out = [[2,2],[2,2]].

test(erase_all) :-
    objop_erase([[3,3],[3,3]], 3, 0, Out),
    Out = [[0,0],[0,0]].

% objop_repaint/4 tests.
test(repaint_basic) :-
    objop_repaint([[1,0,1],[0,1,0]], 1, 9, Out),
    Out = [[9,0,9],[0,9,0]].

test(repaint_identity) :-
    objop_repaint([[2,0],[0,2]], 2, 2, Out),
    Out = [[2,0],[0,2]].

test(repaint_partial) :-
    objop_repaint([[1,2,1],[1,2,1]], 2, 3, Out),
    Out = [[1,3,1],[1,3,1]].

% objop_swap/4 tests.
test(swap_basic) :-
    objop_swap([[1,2],[2,1]], 1, 2, Out),
    Out = [[2,1],[1,2]].

test(swap_2x2) :-
    objop_swap([[1,1],[2,2]], 1, 2, Out),
    Out = [[2,2],[1,1]].

test(swap_absent) :-
    objop_swap([[1,0],[0,1]], 1, 5, Out),
    Out = [[5,0],[0,5]].

% objop_move/6 tests.
test(move_right) :-
    objop_move([[1,0,0],[0,0,0]], 1, 0, 2, 0, Out),
    Out = [[0,0,1],[0,0,0]].

test(move_down) :-
    objop_move([[1,1],[0,0],[0,0]], 1, 2, 0, 0, Out),
    Out = [[0,0],[0,0],[1,1]].

test(move_clip) :-
    objop_move([[0,1],[0,0]], 1, 0, 2, 0, Out),
    Out = [[0,0],[0,0]].

% objop_copy/5 tests.
test(copy_right) :-
    objop_copy([[1,0,0],[0,0,0]], 1, 0, 1, Out),
    Out = [[1,1,0],[0,0,0]].

test(copy_down) :-
    objop_copy([[1,1],[0,0],[0,0]], 1, 1, 0, Out),
    Out = [[1,1],[1,1],[0,0]].

test(copy_diagonal) :-
    objop_copy([[1,0],[0,0]], 1, 1, 1, Out),
    Out = [[1,0],[0,1]].

% objop_rotate90/4 tests.
test(rotate90_column) :-
    objop_rotate90([[1,0],[1,0],[0,0]], 1, 0, Out),
    Out = [[1,1],[0,0],[0,0]].

test(rotate90_single) :-
    objop_rotate90([[0,0],[0,1]], 1, 0, Out),
    Out = [[0,0],[0,1]].

test(rotate90_lshape) :-
    objop_rotate90([[1,0],[1,1],[0,0]], 1, 0, Out),
    Out = [[1,1],[1,0],[0,0]].

% objop_rotate180/4 tests.
test(rotate180_row) :-
    objop_rotate180([[0,0,0,0],[1,1,0,1],[0,0,0,0]], 1, 0, Out),
    Out = [[0,0,0,0],[1,0,1,1],[0,0,0,0]].

test(rotate180_single) :-
    objop_rotate180([[1,0],[0,0]], 1, 0, Out),
    Out = [[1,0],[0,0]].

test(rotate180_2x2) :-
    objop_rotate180([[1,0],[0,1]], 1, 0, Out),
    Out = [[1,0],[0,1]].

% objop_mirror_h/4 tests.
test(mirror_h_row) :-
    objop_mirror_h([[0,1,0,1,1],[0,0,0,0,0]], 1, 0, Out),
    Out = [[0,1,1,0,1],[0,0,0,0,0]].

test(mirror_h_symmetric) :-
    objop_mirror_h([[1,0,1]], 1, 0, Out),
    Out = [[1,0,1]].

test(mirror_h_lshape) :-
    objop_mirror_h([[1,0],[1,1]], 1, 0, Out),
    Out = [[0,1],[1,1]].

% objop_mirror_v/4 tests.
test(mirror_v_col) :-
    objop_mirror_v([[1,0],[1,0],[0,0]], 1, 0, Out),
    Out = [[1,0],[1,0],[0,0]].

test(mirror_v_single) :-
    objop_mirror_v([[1],[0],[0]], 1, 0, Out),
    Out = [[1],[0],[0]].

test(mirror_v_lshape) :-
    objop_mirror_v([[1,1],[0,1],[0,0]], 1, 0, Out),
    Out = [[0,1],[1,1],[0,0]].

:- end_tests(objop).
