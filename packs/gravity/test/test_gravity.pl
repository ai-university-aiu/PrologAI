% PLUnit tests for the gravity pack (gv_* predicates).
:- use_module(library(plunit)).
:- use_module(library(gravity)).

% Helper grids used across tests.
% 3x3 grid with scattered non-zero values.
grid_scattered([[0,1,0],[2,0,3],[0,4,0]]).
% 3x3 grid already compacted to bottom of each column.
grid_bottom([[0,0,0],[0,0,0],[2,4,3]]).
% 3x3 grid already compacted to top of each column.
grid_top([[2,4,3],[0,0,0],[0,0,0]]).
% 4x4 grid for fall tests.
grid_4x4([[0,0,5,0],[0,3,0,2],[7,0,0,0],[0,0,1,0]]).
% Grid where color 1 should fall down (no obstacles other than BG=0).
grid_color([[0,1,0],[0,0,1],[1,0,0]]).

:- begin_tests(gravity_gv_col_values).

test(col_0) :-
    grid_scattered(G), gv_col_values(G, 0, V),
    V = [0, 2, 0].

test(col_1) :-
    grid_scattered(G), gv_col_values(G, 1, V),
    V = [1, 0, 4].

test(col_2) :-
    grid_scattered(G), gv_col_values(G, 2, V),
    V = [0, 3, 0].

:- end_tests(gravity_gv_col_values).

:- begin_tests(gravity_gv_set_col).

test(set_col_0) :-
    grid_scattered(G),
    gv_set_col(G, 0, [9,8,7], R),
    R = [[9,1,0],[8,0,3],[7,4,0]].

test(set_col_1) :-
    grid_scattered(G),
    gv_set_col(G, 1, [5,5,5], R),
    R = [[0,5,0],[2,5,3],[0,5,0]].

:- end_tests(gravity_gv_set_col).

:- begin_tests(gravity_gv_compact_col).

test(compact_col_basic) :-
    % Non-zero values should sink to bottom of each column.
    grid_scattered(G),
    gv_compact_col(G, 0, R),
    % Column 0: [0,2,0] -> [0,0,2]; Column 1: [1,0,4] -> [0,1,4]; Col 2: [0,3,0] -> [0,0,3].
    R = [[0,0,0],[0,1,0],[2,4,3]].

test(compact_col_already_bottom) :-
    % Already compacted - should remain unchanged.
    grid_bottom(G),
    gv_compact_col(G, 0, R),
    R = G.

test(compact_col_4x4) :-
    grid_4x4(G),
    gv_compact_col(G, 0, R),
    % Column 0: [0,0,7,0] -> [0,0,0,7]
    % Column 1: [0,3,0,0] -> [0,0,0,3]
    % Column 2: [5,0,0,1] -> [0,0,5,1]
    % Column 3: [0,2,0,0] -> [0,0,0,2]
    R = [[0,0,0,0],[0,0,0,0],[0,0,5,0],[7,3,1,2]].

:- end_tests(gravity_gv_compact_col).

:- begin_tests(gravity_gv_compact_row).

test(compact_row_basic) :-
    % Non-zero values should shift to left of each row.
    grid_scattered(G),
    gv_compact_row(G, 0, R),
    % Row 0: [0,1,0] -> [1,0,0]; Row 1: [2,0,3] -> [2,3,0]; Row 2: [0,4,0] -> [4,0,0].
    R = [[1,0,0],[2,3,0],[4,0,0]].

test(compact_row_single_row) :-
    % Single row with sparse values.
    gv_compact_row([[0,1,0,2,0,3]], 0, R),
    R = [[1,2,3,0,0,0]].

:- end_tests(gravity_gv_compact_row).

:- begin_tests(gravity_gv_fall_down).

test(fall_down_basic) :-
    % Non-zero cells fall to bottom of each column.
    grid_scattered(G),
    gv_fall_down(G, 0, R),
    R = [[0,0,0],[0,1,0],[2,4,3]].

test(fall_down_uniform) :-
    % Uniform non-bg grid: no bg to fall through; stays same.
    G = [[5,5],[5,5]],
    gv_fall_down(G, 0, R),
    R = G.

test(fall_down_already_bottom) :-
    % Already at bottom: no change.
    grid_bottom(G),
    gv_fall_down(G, 0, R),
    R = G.

:- end_tests(gravity_gv_fall_down).

:- begin_tests(gravity_gv_fall_up).

test(fall_up_basic) :-
    % Non-zero cells rise to top of each column.
    grid_scattered(G),
    gv_fall_up(G, 0, R),
    R = [[2,1,3],[0,4,0],[0,0,0]].

test(fall_up_already_top) :-
    % Already at top: no change.
    grid_top(G),
    gv_fall_up(G, 0, R),
    R = G.

:- end_tests(gravity_gv_fall_up).

:- begin_tests(gravity_gv_fall_left).

test(fall_left_basic) :-
    % Non-zero cells shift to left of each row.
    grid_scattered(G),
    gv_fall_left(G, 0, R),
    R = [[1,0,0],[2,3,0],[4,0,0]].

test(fall_left_single_row) :-
    % Single row: sparse values compact left.
    gv_fall_left([[0,5,0,3,0]], 0, R),
    R = [[5,3,0,0,0]].

:- end_tests(gravity_gv_fall_left).

:- begin_tests(gravity_gv_fall_right).

test(fall_right_basic) :-
    % Non-zero cells shift to right of each row.
    grid_scattered(G),
    gv_fall_right(G, 0, R),
    R = [[0,0,1],[0,2,3],[0,0,4]].

test(fall_right_single_row) :-
    % Single row: sparse values compact right.
    gv_fall_right([[0,5,0,3,0]], 0, R),
    R = [[0,0,0,5,3]].

:- end_tests(gravity_gv_fall_right).

:- begin_tests(gravity_gv_settle_color).

test(settle_color_basic) :-
    % Color 1 falls to bottom of each column.
    % grid_color = [[0,1,0],[0,0,1],[1,0,0]]
    % Column 0: [0,0,1] -> Others=[], Bgs=[0,0], Colors=[1] -> []+[0,0]+[1]=[0,0,1]
    % Column 1: [1,0,0] -> Others=[], Bgs=[0,0], Colors=[1] -> [0,0,1]
    % Column 2: [0,1,0] -> Others=[], Bgs=[0,0], Colors=[1] -> [0,0,1]
    grid_color(G),
    gv_settle_color(G, 1, 0, R),
    R = [[0,0,0],[0,0,0],[1,1,1]].

test(settle_color_with_obstacle) :-
    % Color 2 falls but Other cell (3) stays above it.
    % Column 0: [0,2,3,0] -> Others=[3], Bgs=[0,0], Colors=[2] -> [3]+[0,0]+[2]=[3,0,0,2]
    G = [[0,0],[2,0],[3,0],[0,0]],
    gv_settle_color(G, 2, 0, R),
    R = [[3,0],[0,0],[0,0],[2,0]].

test(settle_color_no_bg) :-
    % No BG cells: Color still sinks below Other cells.
    % Column 0: [1,2,3] -> Others=[2,3], Bgs=[], Colors=[1] -> [2,3]+[]+[1]=[2,3,1]
    G = [[1],[2],[3]],
    gv_settle_color(G, 1, 0, R),
    R = [[2],[3],[1]].

:- end_tests(gravity_gv_settle_color).

:- begin_tests(gravity_gv_float_color).

test(float_color_basic) :-
    % Color 1 rises to top of each column.
    % grid_color = [[0,1,0],[0,0,1],[1,0,0]]
    % Column 0: [0,0,1] -> Colors=[1], Others=[], Bgs=[0,0] -> [1]+[]+[0,0]=[1,0,0]
    % Column 1: [1,0,0] -> Colors=[1], Others=[], Bgs=[0,0] -> [1,0,0]
    % Column 2: [0,1,0] -> Colors=[1], Others=[], Bgs=[0,0] -> [1,0,0]
    grid_color(G),
    gv_float_color(G, 1, 0, R),
    R = [[1,1,1],[0,0,0],[0,0,0]].

test(float_color_with_obstacle) :-
    % Color 2 floats above Other cell (3).
    % Column 0: [0,0,3,2] -> Colors=[2], Others=[3], Bgs=[0,0]
    %   -> [2]+[3]+[0,0] = [2,3,0,0]
    G = [[0,0],[0,0],[3,0],[2,0]],
    gv_float_color(G, 2, 0, R),
    R = [[2,0],[3,0],[0,0],[0,0]].

test(float_color_no_bg) :-
    % No BG: Color rises above Other cells.
    % Column 0: [3,2,1] -> Colors=[1], Others=[3,2], Bgs=[] -> [1]+[3,2]+[]=[1,3,2]
    G = [[3],[2],[1]],
    gv_float_color(G, 1, 0, R),
    R = [[1],[3],[2]].

:- end_tests(gravity_gv_float_color).

:- begin_tests(gravity_gv_stack_down).

test(stack_down_same_as_settle) :-
    % stack_down is an alias for settle_color.
    grid_color(G),
    gv_stack_down(G, 1, 0, R),
    R = [[0,0,0],[0,0,0],[1,1,1]].

:- end_tests(gravity_gv_stack_down).

:- begin_tests(gravity_gv_stack_up).

test(stack_up_same_as_float) :-
    % stack_up is an alias for float_color.
    grid_color(G),
    gv_stack_up(G, 1, 0, R),
    R = [[1,1,1],[0,0,0],[0,0,0]].

:- end_tests(gravity_gv_stack_up).

:- begin_tests(gravity_gv_apply_col).

test(apply_col_compact_bottom) :-
    % Use gv_compact_list_bottom_ as the transform for each column.
    grid_scattered(G),
    gv_apply_col(G, 0, gv_compact_list_bottom_, R),
    R = [[0,0,0],[0,1,0],[2,4,3]].

:- end_tests(gravity_gv_apply_col).

:- begin_tests(gravity_gv_apply_row).

test(apply_row_compact_left) :-
    % Use gv_compact_list_top_ as the transform for each row.
    grid_scattered(G),
    gv_apply_row(G, 0, gv_compact_list_top_, R),
    R = [[1,0,0],[2,3,0],[4,0,0]].

:- end_tests(gravity_gv_apply_row).
