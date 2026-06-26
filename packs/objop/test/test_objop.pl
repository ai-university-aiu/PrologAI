:- use_module('../prolog/objop').

:- begin_tests(objop).

% oo_cells_of/3 tests.
test(cells_of_basic) :-
    oo_cells_of([[1,0,1],[0,1,0],[1,0,0]], 1, Cells),
    Cells = [0-0, 0-2, 1-1, 2-0].

test(cells_of_empty) :-
    oo_cells_of([[0,0],[0,0]], 1, Cells),
    Cells = [].

test(cells_of_all) :-
    oo_cells_of([[2,2],[2,2]], 2, Cells),
    Cells = [0-0, 0-1, 1-0, 1-1].

% oo_bbox/5 tests.
test(bbox_rect) :-
    oo_bbox([1-2, 1-4, 3-2, 3-4], R0, C0, R1, C1),
    R0 = 1, C0 = 2, R1 = 3, C1 = 4.

test(bbox_single) :-
    oo_bbox([2-3], R0, C0, R1, C1),
    R0 = 2, C0 = 3, R1 = 2, C1 = 3.

test(bbox_row) :-
    oo_bbox([0-0, 0-1, 0-2], R0, C0, R1, C1),
    R0 = 0, C0 = 0, R1 = 0, C1 = 2.

% oo_count/3 tests.
test(count_three) :-
    oo_count([[1,0],[1,0],[1,0]], 1, N),
    N = 3.

test(count_zero) :-
    oo_count([[0,0],[0,0]], 5, N),
    N = 0.

test(count_all) :-
    oo_count([[3,3,3]], 3, N),
    N = 3.

% oo_size/4 tests.
test(size_2x3) :-
    oo_size([[1,1,1],[1,1,1],[0,0,0]], 1, H, W),
    H = 2, W = 3.

test(size_single) :-
    oo_size([[0,1,0]], 1, H, W),
    H = 1, W = 1.

test(size_column) :-
    oo_size([[1],[1],[1]], 1, H, W),
    H = 3, W = 1.

% oo_center/4 tests.
test(center_3x3) :-
    oo_center([[1,1,1],[1,1,1],[1,1,1]], 1, R, C),
    R = 1, C = 1.

test(center_1x3) :-
    oo_center([[1,1,1]], 1, R, C),
    R = 0, C = 1.

test(center_4x4) :-
    oo_center([[1,1,1,1],[1,1,1,1],[1,1,1,1],[1,1,1,1]], 1, R, C),
    R = 1, C = 1.

% oo_erase/4 tests.
test(erase_cells) :-
    oo_erase([[1,2,1],[2,1,2],[1,2,1]], 1, 0, Out),
    Out = [[0,2,0],[2,0,2],[0,2,0]].

test(erase_absent) :-
    oo_erase([[2,2],[2,2]], 5, 0, Out),
    Out = [[2,2],[2,2]].

test(erase_all) :-
    oo_erase([[3,3],[3,3]], 3, 0, Out),
    Out = [[0,0],[0,0]].

% oo_repaint/4 tests.
test(repaint_basic) :-
    oo_repaint([[1,0,1],[0,1,0]], 1, 9, Out),
    Out = [[9,0,9],[0,9,0]].

test(repaint_identity) :-
    oo_repaint([[2,0],[0,2]], 2, 2, Out),
    Out = [[2,0],[0,2]].

test(repaint_partial) :-
    oo_repaint([[1,2,1],[1,2,1]], 2, 3, Out),
    Out = [[1,3,1],[1,3,1]].

% oo_swap/4 tests.
test(swap_basic) :-
    oo_swap([[1,2],[2,1]], 1, 2, Out),
    Out = [[2,1],[1,2]].

test(swap_2x2) :-
    oo_swap([[1,1],[2,2]], 1, 2, Out),
    Out = [[2,2],[1,1]].

test(swap_absent) :-
    oo_swap([[1,0],[0,1]], 1, 5, Out),
    Out = [[5,0],[0,5]].

% oo_move/6 tests.
test(move_right) :-
    oo_move([[1,0,0],[0,0,0]], 1, 0, 2, 0, Out),
    Out = [[0,0,1],[0,0,0]].

test(move_down) :-
    oo_move([[1,1],[0,0],[0,0]], 1, 2, 0, 0, Out),
    Out = [[0,0],[0,0],[1,1]].

test(move_clip) :-
    oo_move([[0,1],[0,0]], 1, 0, 2, 0, Out),
    Out = [[0,0],[0,0]].

% oo_copy/5 tests.
test(copy_right) :-
    oo_copy([[1,0,0],[0,0,0]], 1, 0, 1, Out),
    Out = [[1,1,0],[0,0,0]].

test(copy_down) :-
    oo_copy([[1,1],[0,0],[0,0]], 1, 1, 0, Out),
    Out = [[1,1],[1,1],[0,0]].

test(copy_diagonal) :-
    oo_copy([[1,0],[0,0]], 1, 1, 1, Out),
    Out = [[1,0],[0,1]].

% oo_rotate90/4 tests.
test(rotate90_column) :-
    oo_rotate90([[1,0],[1,0],[0,0]], 1, 0, Out),
    Out = [[1,1],[0,0],[0,0]].

test(rotate90_single) :-
    oo_rotate90([[0,0],[0,1]], 1, 0, Out),
    Out = [[0,0],[0,1]].

test(rotate90_lshape) :-
    oo_rotate90([[1,0],[1,1],[0,0]], 1, 0, Out),
    Out = [[1,1],[1,0],[0,0]].

% oo_rotate180/4 tests.
test(rotate180_row) :-
    oo_rotate180([[0,0,0,0],[1,1,0,1],[0,0,0,0]], 1, 0, Out),
    Out = [[0,0,0,0],[1,0,1,1],[0,0,0,0]].

test(rotate180_single) :-
    oo_rotate180([[1,0],[0,0]], 1, 0, Out),
    Out = [[1,0],[0,0]].

test(rotate180_2x2) :-
    oo_rotate180([[1,0],[0,1]], 1, 0, Out),
    Out = [[1,0],[0,1]].

% oo_mirror_h/4 tests.
test(mirror_h_row) :-
    oo_mirror_h([[0,1,0,1,1],[0,0,0,0,0]], 1, 0, Out),
    Out = [[0,1,1,0,1],[0,0,0,0,0]].

test(mirror_h_symmetric) :-
    oo_mirror_h([[1,0,1]], 1, 0, Out),
    Out = [[1,0,1]].

test(mirror_h_lshape) :-
    oo_mirror_h([[1,0],[1,1]], 1, 0, Out),
    Out = [[0,1],[1,1]].

% oo_mirror_v/4 tests.
test(mirror_v_col) :-
    oo_mirror_v([[1,0],[1,0],[0,0]], 1, 0, Out),
    Out = [[1,0],[1,0],[0,0]].

test(mirror_v_single) :-
    oo_mirror_v([[1],[0],[0]], 1, 0, Out),
    Out = [[1],[0],[0]].

test(mirror_v_lshape) :-
    oo_mirror_v([[1,1],[0,1],[0,0]], 1, 0, Out),
    Out = [[0,1],[1,1],[0,0]].

:- end_tests(objop).
