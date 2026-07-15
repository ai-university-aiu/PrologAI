% test_border.pl - Acceptance tests for the border pack (Layer 146).
% 42 tests covering all 14 exported predicates.
:- use_module('../prolog/border.pl').

:- begin_tests(border).

% border_ring_cells tests.

% Test 1: ring 0 of 3x3 grid has 8 border cells in row-major order.
test(ring_cells_0_3x3) :-
    G = [[0,0,0],[0,0,0],[0,0,0]],
    border_ring_cells(G, 0, Cells),
    length(Cells, 8).

% Test 2: ring 1 of 5x5 grid has 8 cells (the middle ring).
test(ring_cells_1_5x5) :-
    G = [[0,0,0,0,0],[0,0,0,0,0],[0,0,0,0,0],[0,0,0,0,0],[0,0,0,0,0]],
    border_ring_cells(G, 1, Cells),
    length(Cells, 8).

% Test 3: ring 0 of 1x1 grid has exactly 1 cell.
test(ring_cells_1x1) :-
    border_ring_cells([[5]], 0, Cells),
    Cells == [0-0].

% border_ring_vals tests.

% Test 4: ring 0 of [[1,1,1],[1,2,1],[1,1,1]] has 8 values all equal to 1.
test(ring_vals_0_all_ones) :-
    G = [[1,1,1],[1,2,1],[1,1,1]],
    border_ring_vals(G, 0, Vals),
    length(Vals, 8),
    sort(Vals, [1]).

% Test 5: ring 1 of [[1,1,1],[1,2,1],[1,1,1]] has exactly 1 value equal to 2.
test(ring_vals_1_center) :-
    G = [[1,1,1],[1,2,1],[1,1,1]],
    border_ring_vals(G, 1, Vals),
    Vals == [2].

% Test 6: ring 0 of 2x2 grid has 4 values.
test(ring_vals_2x2) :-
    G = [[a,b],[c,d]],
    border_ring_vals(G, 0, Vals),
    length(Vals, 4).

% border_ring_color tests.

% Test 7: ring 0 of all-1 border grid is color 1.
test(ring_color_0_uniform) :-
    G = [[1,1],[1,1]],
    border_ring_color(G, 0, Color),
    Color == 1.

% Test 8: ring 1 of 3x3 nested grid is color 2.
test(ring_color_1_center) :-
    G = [[1,1,1],[1,2,1],[1,1,1]],
    border_ring_color(G, 1, Color),
    Color == 2.

% Test 9: ring 0 of non-uniform grid fails.
test(ring_color_nonuniform_fails, [fail]) :-
    G = [[1,2,1],[1,1,1],[1,1,1]],
    border_ring_color(G, 0, _).

% border_is_uniform_ring tests.

% Test 10: ring 0 of uniform 2x2 succeeds.
test(uniform_ring_succeeds) :-
    border_is_uniform_ring([[2,2],[2,2]], 0).

% Test 11: ring 0 with mixed values fails.
test(uniform_ring_fails, [fail]) :-
    border_is_uniform_ring([[1,2,1],[1,1,1],[1,1,1]], 0).

% Test 12: ring 2 (center) of 5x5 is always uniform (single cell).
test(uniform_ring_center) :-
    G = [[0,0,0,0,0],[0,1,1,1,0],[0,1,2,1,0],[0,1,1,1,0],[0,0,0,0,0]],
    border_is_uniform_ring(G, 2).

% border_add_border tests.

% Test 13: add border V=0 around [[1,2],[3,4]] gives 4x4 grid.
test(add_border_2x2) :-
    border_add_border([[1,2],[3,4]], 0, Out),
    Out == [[0,0,0,0],[0,1,2,0],[0,3,4,0],[0,0,0,0]].

% Test 14: add border V=5 around [[1]] gives 3x3.
test(add_border_1x1) :-
    border_add_border([[1]], 5, Out),
    Out == [[5,5,5],[5,1,5],[5,5,5]].

% Test 15: add border V=1 around [[2,3]] gives 3x4.
test(add_border_1x2) :-
    border_add_border([[2,3]], 1, Out),
    Out == [[1,1,1,1],[1,2,3,1],[1,1,1,1]].

% border_strip_border tests.

% Test 16: strip border from 4x4 frame gives 2x2 inner.
test(strip_border_4x4) :-
    G = [[0,0,0,0],[0,1,2,0],[0,3,4,0],[0,0,0,0]],
    border_strip_border(G, Inner),
    Inner == [[1,2],[3,4]].

% Test 17: strip border from 3x3 gives 1x1 center.
test(strip_border_3x3) :-
    G = [[1,2,3],[4,5,6],[7,8,9]],
    border_strip_border(G, Inner),
    Inner == [[5]].

% Test 18: strip border from 2x2 gives empty list.
test(strip_border_2x2) :-
    border_strip_border([[1,2],[3,4]], Inner),
    Inner == [].

% border_inner_n tests.

% Test 19: inner_n with N=0 is identity.
test(inner_n_zero) :-
    G = [[1,2],[3,4]],
    border_inner_n(G, 0, Out),
    Out == G.

% Test 20: inner_n with N=1 strips one ring from 5x5 giving 3x3.
test(inner_n_1_5x5) :-
    G = [[0,0,0,0,0],[0,1,1,1,0],[0,1,2,1,0],[0,1,1,1,0],[0,0,0,0,0]],
    border_inner_n(G, 1, Inner),
    Inner == [[1,1,1],[1,2,1],[1,1,1]].

% Test 21: inner_n with N=2 strips two rings from 5x5 giving 1x1 center.
test(inner_n_2_5x5) :-
    G = [[0,0,0,0,0],[0,1,1,1,0],[0,1,2,1,0],[0,1,1,1,0],[0,0,0,0,0]],
    border_inner_n(G, 2, Inner),
    Inner == [[2]].

% border_outer_color tests.

% Test 22: outer color of 3x3 all-1-border grid is 1.
test(outer_color_uniform) :-
    G = [[1,1,1],[1,2,1],[1,1,1]],
    border_outer_color(G, V),
    V == 1.

% Test 23: outer color of non-uniform ring fails.
test(outer_color_nonuniform, [fail]) :-
    G = [[1,2,1],[1,1,1],[1,1,1]],
    border_outer_color(G, _).

% Test 24: outer color of 2x2 uniform grid is that value.
test(outer_color_2x2) :-
    border_outer_color([[5,5],[5,5]], V),
    V == 5.

% border_is_uniform_outer tests.

% Test 25: 3x3 all-border same color -> success.
test(is_uniform_outer_success) :-
    border_is_uniform_outer([[3,3],[3,3]]).

% Test 26: mixed border -> failure.
test(is_uniform_outer_fail, [fail]) :-
    border_is_uniform_outer([[3,4],[3,3]]).

% Test 27: uniform border in larger grid -> success.
test(is_uniform_outer_3x3) :-
    border_is_uniform_outer([[1,1,1],[1,2,1],[1,1,1]]).

% border_ring_colors tests.

% Test 28: 3x3 nested grid gives [1, 2].
test(ring_colors_3x3) :-
    G = [[1,1,1],[1,2,1],[1,1,1]],
    border_ring_colors(G, Colors),
    Colors == [1, 2].

% Test 29: 5x5 three-ring nested grid gives [1, 2, 3].
test(ring_colors_5x5) :-
    G = [[1,1,1,1,1],[1,2,2,2,1],[1,2,3,2,1],[1,2,2,2,1],[1,1,1,1,1]],
    border_ring_colors(G, Colors),
    Colors == [1, 2, 3].

% Test 30: non-uniform outer ring gives [].
test(ring_colors_nonuniform) :-
    G = [[1,2,1],[1,1,1],[1,1,1]],
    border_ring_colors(G, Colors),
    Colors == [].

% border_max_ring tests.

% Test 31: 3x3 grid has max ring 1.
test(max_ring_3x3) :-
    border_max_ring([[0,0,0],[0,0,0],[0,0,0]], N),
    N == 1.

% Test 32: 5x5 grid has max ring 2.
test(max_ring_5x5) :-
    border_max_ring([[0,0,0,0,0],[0,0,0,0,0],[0,0,0,0,0],[0,0,0,0,0],[0,0,0,0,0]], N),
    N == 2.

% Test 33: 1x1 grid has max ring 0.
test(max_ring_1x1) :-
    border_max_ring([[5]], N),
    N == 0.

% border_is_nested tests.

% Test 34: 3x3 two-ring nested grid is nested.
test(is_nested_3x3) :-
    border_is_nested([[1,1,1],[1,2,1],[1,1,1]]).

% Test 35: 3x3 with non-uniform ring is not nested.
test(is_nested_fail, [fail]) :-
    border_is_nested([[1,1,1],[1,2,1],[1,2,1]]).

% Test 36: 5x5 three-ring nested grid is nested.
test(is_nested_5x5) :-
    G = [[1,1,1,1,1],[1,2,2,2,1],[1,2,3,2,1],[1,2,2,2,1],[1,1,1,1,1]],
    border_is_nested(G).

% border_depth_map tests.

% Test 37: 3x3 depth map has 0s on the border and 1 in the center.
test(depth_map_3x3) :-
    border_depth_map([[0,0,0],[0,0,0],[0,0,0]], DM),
    DM == [[0,0,0],[0,1,0],[0,0,0]].

% Test 38: 4x4 depth map has ring 0 at border, ring 1 inside.
test(depth_map_4x4) :-
    border_depth_map([[0,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]], DM),
    DM == [[0,0,0,0],[0,1,1,0],[0,1,1,0],[0,0,0,0]].

% Test 39: 1x5 grid depth map: all zeros (single row, only ring 0).
test(depth_map_1x5) :-
    border_depth_map([[a,b,c,d,e]], DM),
    DM == [[0,0,0,0,0]].

% border_fill_ring tests.

% Test 40: fill ring 0 of [[1,2,1],[3,4,3],[1,2,1]] with 9 replaces border.
test(fill_ring_0) :-
    G = [[1,2,1],[3,4,3],[1,2,1]],
    border_fill_ring(G, 0, 9, Out),
    Out == [[9,9,9],[9,4,9],[9,9,9]].

% Test 41: fill ring 1 of [[1,1,1],[1,2,1],[1,1,1]] with 0 changes center.
test(fill_ring_1_center) :-
    G = [[1,1,1],[1,2,1],[1,1,1]],
    border_fill_ring(G, 1, 0, Out),
    Out == [[1,1,1],[1,0,1],[1,1,1]].

% Test 42: fill ring 0 of a uniform grid with the same value is identity.
test(fill_ring_identity) :-
    G = [[1,1],[1,1]],
    border_fill_ring(G, 0, 1, Out),
    Out == G.

:- end_tests(border).
