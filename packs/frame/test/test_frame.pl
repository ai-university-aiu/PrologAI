% PLUnit tests for the frame pack (fr_* predicates).
% All tests are self-contained and deterministic.
:- use_module(library(plunit)).
:- use_module(library(grid)).
:- use_module(library(frame)).

% Grid fixtures.
% A 4x4 grid with a uniform outer border of color 1 and interior of color 2.
framed_4x4(Grid) :-
    Grid = [[1,1,1,1],
            [1,2,2,1],
            [1,2,2,1],
            [1,1,1,1]].

% A 5x5 grid with outer border of 3 and interior of 0.
framed_5x5(Grid) :-
    Grid = [[3,3,3,3,3],
            [3,0,0,0,3],
            [3,0,0,0,3],
            [3,0,0,0,3],
            [3,3,3,3,3]].

% A 3x3 grid with border of 5 and interior cell of 7.
framed_3x3(Grid) :-
    Grid = [[5,5,5],
            [5,7,5],
            [5,5,5]].

% A 4x4 grid with non-uniform border (mixed colors).
nonuniform_4x4(Grid) :-
    Grid = [[1,1,1,1],
            [1,2,2,2],
            [1,2,2,1],
            [1,1,1,1]].

% A 5x5 nested frame: outer ring = 1, second ring = 2, center = 3.
nested_5x5(Grid) :-
    Grid = [[1,1,1,1,1],
            [1,2,2,2,1],
            [1,2,3,2,1],
            [1,2,2,2,1],
            [1,1,1,1,1]].

% A 7x7 triple nested frame: rings 1,2,3, center 0.
triple_7x7(Grid) :-
    Grid = [[1,1,1,1,1,1,1],
            [1,2,2,2,2,2,1],
            [1,2,3,3,3,2,1],
            [1,2,3,0,3,2,1],
            [1,2,3,3,3,2,1],
            [1,2,2,2,2,2,1],
            [1,1,1,1,1,1,1]].

% A plain 3x3 grid of all zeros (no border).
plain_3x3(Grid) :-
    Grid = [[0,0,0],
            [0,0,0],
            [0,0,0]].

% A 4x6 non-square framed grid: border of 9, interior of 0.
framed_4x6(Grid) :-
    Grid = [[9,9,9,9,9,9],
            [9,0,0,0,0,9],
            [9,0,0,0,0,9],
            [9,9,9,9,9,9]].

:- begin_tests(frame_border_color).

test(border_color_4x4) :-
    framed_4x4(G),
    fr_border_color(G, Color),
    Color =:= 1.

test(border_color_5x5) :-
    framed_5x5(G),
    fr_border_color(G, Color),
    Color =:= 3.

test(border_color_3x3) :-
    framed_3x3(G),
    fr_border_color(G, Color),
    Color =:= 5.

test(border_color_4x6) :-
    framed_4x6(G),
    fr_border_color(G, Color),
    Color =:= 9.

test(no_border_nonuniform, [fail]) :-
    nonuniform_4x4(G),
    fr_border_color(G, _).

:- end_tests(frame_border_color).

:- begin_tests(frame_has_border).

test(has_border_4x4) :-
    framed_4x4(G),
    fr_has_border(G, Color),
    Color =:= 1.

test(has_border_5x5) :-
    framed_5x5(G),
    fr_has_border(G, Color),
    Color =:= 3.

test(no_border_fails, [fail]) :-
    nonuniform_4x4(G),
    fr_has_border(G, _).

:- end_tests(frame_has_border).

:- begin_tests(frame_inner).

test(inner_4x4) :-
    framed_4x4(G),
    fr_inner(G, Inner),
    Inner = [[2,2],[2,2]].

test(inner_5x5) :-
    framed_5x5(G),
    fr_inner(G, Inner),
    Inner = [[0,0,0],[0,0,0],[0,0,0]].

test(inner_3x3) :-
    framed_3x3(G),
    fr_inner(G, Inner),
    Inner = [[7]].

test(inner_nested_5x5) :-
    nested_5x5(G),
    fr_inner(G, Inner),
    Inner = [[2,2,2],[2,3,2],[2,2,2]].

test(inner_too_small, [fail]) :-
    Grid = [[1,1],[1,1]],
    fr_inner(Grid, _).

test(inner_4x6) :-
    framed_4x6(G),
    fr_inner(G, Inner),
    Inner = [[0,0,0,0],[0,0,0,0]].

:- end_tests(frame_inner).

:- begin_tests(frame_interior).

test(interior_uniform_4x4) :-
    framed_4x4(G),
    fr_interior_uniform(G).

test(interior_uniform_5x5) :-
    framed_5x5(G),
    fr_interior_uniform(G).

test(interior_color_4x4) :-
    framed_4x4(G),
    fr_interior_color(G, Color),
    Color =:= 2.

test(interior_color_5x5) :-
    framed_5x5(G),
    fr_interior_color(G, Color),
    Color =:= 0.

test(interior_color_3x3) :-
    framed_3x3(G),
    fr_interior_color(G, Color),
    Color =:= 7.

:- end_tests(frame_interior).

:- begin_tests(frame_add_border).

test(add_border_basic, [nondet]) :-
    Inner = [[2,2],[2,2]],
    fr_add_border(Inner, 1, 1, Grid2),
    Grid2 = [[1,1,1,1],[1,2,2,1],[1,2,2,1],[1,1,1,1]].

test(add_border_zero, [nondet]) :-
    Inner = [[5,5],[5,5]],
    fr_add_border(Inner, 0, 9, Grid2),
    Grid2 = [[5,5],[5,5]].

test(add_border_single_cell, [nondet]) :-
    fr_add_border([[7]], 1, 3, Grid2),
    Grid2 = [[3,3,3],[3,7,3],[3,3,3]].

:- end_tests(frame_add_border).

:- begin_tests(frame_make_framed).

test(make_framed_4x4, [nondet]) :-
    fr_make_framed(4, 4, 1, 2, Grid),
    framed_4x4(Expected),
    Grid = Expected.

test(make_framed_3x3, [nondet]) :-
    fr_make_framed(3, 3, 5, 7, Grid),
    framed_3x3(Expected),
    Grid = Expected.

test(make_framed_5x5, [nondet]) :-
    fr_make_framed(5, 5, 3, 0, Grid),
    framed_5x5(Expected),
    Grid = Expected.

test(make_framed_no_interior, [nondet]) :-
    % 2x2 has no interior.
    fr_make_framed(2, 2, 4, 0, Grid),
    Grid = [[4,4],[4,4]].

:- end_tests(frame_make_framed).

:- begin_tests(frame_region).

test(region_has_border) :-
    Grid = [[0,0,0,0,0],
            [0,1,1,1,0],
            [0,1,2,1,0],
            [0,1,1,1,0],
            [0,0,0,0,0]],
    fr_region_has_border(Grid, 1, 1, 3, 3, Color),
    Color =:= 1.

test(region_border_color) :-
    Grid = [[0,0,0,0,0],
            [0,3,3,3,0],
            [0,3,9,3,0],
            [0,3,3,3,0],
            [0,0,0,0,0]],
    fr_region_border_color(Grid, 1, 1, 3, 3, Color),
    Color =:= 3.

:- end_tests(frame_region).

:- begin_tests(frame_nested).

test(is_nested_5x5) :-
    nested_5x5(G),
    fr_is_nested(G, ColorA, ColorB),
    ColorA =:= 1,
    ColorB =:= 2.

test(not_nested_plain, [fail]) :-
    plain_3x3(G),
    fr_is_nested(G, _, _).

test(not_nested_uniform, [fail]) :-
    Grid = [[5,5,5],[5,5,5],[5,5,5]],
    fr_is_nested(Grid, _, _).

:- end_tests(frame_nested).

:- begin_tests(frame_ring_count).

test(ring_count_single) :-
    framed_4x4(G),
    fr_ring_count(G, N),
    N =:= 1.

test(ring_count_nested) :-
    nested_5x5(G),
    fr_ring_count(G, N),
    N =:= 2.

test(ring_count_triple) :-
    triple_7x7(G),
    fr_ring_count(G, N),
    N =:= 3.

test(ring_count_plain) :-
    plain_3x3(G),
    fr_ring_count(G, N),
    N =:= 1.

test(ring_count_tiny) :-
    % A 2x2 grid has no extractable interior, so ring count is 0.
    Grid = [[1,1],[1,1]],
    fr_ring_count(Grid, N),
    N =:= 0.

:- end_tests(frame_ring_count).

:- begin_tests(frame_bounding_box).

test(bounding_box_full, [nondet]) :-
    framed_4x4(G),
    fr_bounding_box(G, 1, R0, C0, R1, C1),
    R0 =:= 0, C0 =:= 0, R1 =:= 3, C1 =:= 3.

test(bounding_box_nested_outer, [nondet]) :-
    nested_5x5(G),
    fr_bounding_box(G, 1, R0, C0, R1, C1),
    R0 =:= 0, C0 =:= 0, R1 =:= 4, C1 =:= 4.

:- end_tests(frame_bounding_box).
