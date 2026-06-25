% PLUnit tests for the shape pack (sh_* predicates).
:- use_module(library(plunit)).
:- use_module(library(grid)).
:- use_module(library(shape)).

% Grid fixtures used across multiple tests.

% A 3x4 grid with an L-shape in color 1.
l_grid(Grid) :-
    Grid = [[1,0,0,0],
            [1,0,0,0],
            [1,1,0,0]].

% A 3x3 grid where color 2 forms a diagonal.
diag_grid(Grid) :-
    Grid = [[2,0,0],
            [0,2,0],
            [0,0,2]].

% A 2x2 fully filled grid.
full_2x2(Grid) :-
    Grid = [[1,1],
            [1,1]].

% A 5x5 grid used for placement tests.
empty_5x5(Grid) :-
    Grid = [[0,0,0,0,0],
            [0,0,0,0,0],
            [0,0,0,0,0],
            [0,0,0,0,0],
            [0,0,0,0,0]].

:- begin_tests(shape_from_cells).

test(normalize_l_shape) :-
    Cells = [r(2,3), r(3,3), r(4,3), r(4,4)],
    sh_from_cells(Cells, Shape),
    Shape = [r(0,0), r(1,0), r(2,0), r(2,1)].

test(single_cell) :-
    sh_from_cells([r(5,7)], Shape),
    Shape = [r(0,0)].

test(already_at_origin) :-
    Cells = [r(0,0), r(0,1), r(1,0)],
    sh_from_cells(Cells, Shape),
    Shape = [r(0,0), r(0,1), r(1,0)].

test(unordered_input) :-
    Cells = [r(3,3), r(2,3), r(4,3), r(4,4)],
    sh_from_cells(Cells, Shape),
    Shape = [r(0,0), r(1,0), r(2,0), r(2,1)].

:- end_tests(shape_from_cells).

:- begin_tests(shape_from_grid).

test(l_from_grid) :-
    l_grid(G),
    sh_from_grid(G, 1, Shape),
    Shape = [r(0,0), r(1,0), r(2,0), r(2,1)].

test(diag_from_grid) :-
    diag_grid(G),
    sh_from_grid(G, 2, Shape),
    Shape = [r(0,0), r(1,1), r(2,2)].

test(absent_color_fails, [fail]) :-
    l_grid(G),
    sh_from_grid(G, 9, _Shape).

:- end_tests(shape_from_grid).

:- begin_tests(shape_area).

test(area_l) :-
    l_grid(G),
    sh_from_grid(G, 1, Shape),
    sh_area(Shape, N),
    N =:= 4.

test(area_single) :-
    sh_from_cells([r(0,0)], Shape),
    sh_area(Shape, N),
    N =:= 1.

test(area_diag) :-
    diag_grid(G),
    sh_from_grid(G, 2, Shape),
    sh_area(Shape, N),
    N =:= 3.

:- end_tests(shape_area).

:- begin_tests(shape_bounding_size).

test(bbox_l) :-
    l_grid(G),
    sh_from_grid(G, 1, Shape),
    sh_bounding_size(Shape, Rows, Cols),
    Rows =:= 3,
    Cols =:= 2.

test(bbox_single) :-
    sh_from_cells([r(0,0)], Shape),
    sh_bounding_size(Shape, Rows, Cols),
    Rows =:= 1,
    Cols =:= 1.

test(bbox_diag) :-
    diag_grid(G),
    sh_from_grid(G, 2, Shape),
    sh_bounding_size(Shape, Rows, Cols),
    Rows =:= 3,
    Cols =:= 3.

:- end_tests(shape_bounding_size).

:- begin_tests(shape_contains_cell).

test(contains_yes) :-
    l_grid(G),
    sh_from_grid(G, 1, Shape),
    sh_contains_cell(Shape, r(0,0)).

test(contains_corner) :-
    l_grid(G),
    sh_from_grid(G, 1, Shape),
    sh_contains_cell(Shape, r(2,1)).

test(contains_no, [fail]) :-
    l_grid(G),
    sh_from_grid(G, 1, Shape),
    sh_contains_cell(Shape, r(0,1)).

:- end_tests(shape_contains_cell).

:- begin_tests(shape_equal).

test(equal_same) :-
    sh_from_cells([r(0,0), r(0,1), r(1,0)], Shape),
    sh_equal(Shape, Shape).

test(equal_two_copies) :-
    sh_from_cells([r(0,0), r(0,1)], S1),
    sh_from_cells([r(3,5), r(3,6)], S2),
    sh_equal(S1, S2).

test(equal_fails, [fail]) :-
    sh_from_cells([r(0,0), r(0,1)], S1),
    sh_from_cells([r(0,0), r(1,0)], S2),
    sh_equal(S1, S2).

:- end_tests(shape_equal).

:- begin_tests(shape_translate).

test(translate_basic) :-
    sh_from_cells([r(0,0), r(0,1)], Shape),
    sh_translate(Shape, 2, 3, Shape2),
    Shape2 = [r(2,3), r(2,4)].

test(translate_zero) :-
    sh_from_cells([r(0,0), r(1,0)], Shape),
    sh_translate(Shape, 0, 0, Shape2),
    Shape2 = Shape.

:- end_tests(shape_translate).

:- begin_tests(shape_rotate90).

test(rotate90_l) :-
    % L-shape: r(0,0), r(1,0), r(2,0), r(2,1)
    sh_from_cells([r(0,0), r(1,0), r(2,0), r(2,1)], Shape),
    sh_rotate90(Shape, Shape2),
    % CW 90: r(R,C) -> r(C, MaxR-R); MaxR=2
    % r(0,0)->(0,2), r(1,0)->(0,1), r(2,0)->(0,0), r(2,1)->(1,0)
    % Sorted: [r(0,0), r(0,1), r(0,2), r(1,0)]
    Shape2 = [r(0,0), r(0,1), r(0,2), r(1,0)].

test(rotate90_single) :-
    sh_from_cells([r(0,0)], Shape),
    sh_rotate90(Shape, Shape2),
    Shape2 = [r(0,0)].

test(rotate90_x4_identity) :-
    sh_from_cells([r(0,0), r(0,1), r(1,0)], Shape),
    sh_rotate90(Shape, R1),
    sh_rotate90(R1, R2),
    sh_rotate90(R2, R3),
    sh_rotate90(R3, R4),
    sh_equal(Shape, R4).

:- end_tests(shape_rotate90).

:- begin_tests(shape_reflect_h).

test(reflect_h_basic) :-
    % Horizontal bar: r(0,0), r(0,1), r(0,2)
    sh_from_cells([r(0,0), r(0,1), r(0,2)], Shape),
    sh_reflect_h(Shape, Shape2),
    Shape2 = Shape.

test(reflect_h_l) :-
    sh_from_cells([r(0,0), r(1,0), r(2,0), r(2,1)], Shape),
    % MaxC=1; r(R,C)->r(R,1-C): (0,0)->(0,1),(1,0)->(1,1),(2,0)->(2,1),(2,1)->(2,0)
    % Sorted: [r(0,1), r(1,1), r(2,0), r(2,1)]; min C=0 -> already ok
    sh_reflect_h(Shape, Shape2),
    Shape2 = [r(0,1), r(1,1), r(2,0), r(2,1)].

test(reflect_h_twice_identity) :-
    sh_from_cells([r(0,0), r(0,1), r(1,0)], Shape),
    sh_reflect_h(Shape, R1),
    sh_reflect_h(R1, R2),
    sh_equal(Shape, R2).

:- end_tests(shape_reflect_h).

:- begin_tests(shape_reflect_v).

test(reflect_v_bar) :-
    % Vertical bar: r(0,0), r(1,0), r(2,0)
    sh_from_cells([r(0,0), r(1,0), r(2,0)], Shape),
    sh_reflect_v(Shape, Shape2),
    Shape2 = Shape.

test(reflect_v_l) :-
    sh_from_cells([r(0,0), r(1,0), r(2,0), r(2,1)], Shape),
    % MaxR=2; r(R,C)->r(2-R,C): (0,0)->(2,0),(1,0)->(1,0),(2,0)->(0,0),(2,1)->(0,1)
    % Sorted: [r(0,0), r(0,1), r(1,0), r(2,0)]
    sh_reflect_v(Shape, Shape2),
    Shape2 = [r(0,0), r(0,1), r(1,0), r(2,0)].

test(reflect_v_twice_identity) :-
    sh_from_cells([r(0,0), r(0,1), r(1,0)], Shape),
    sh_reflect_v(Shape, R1),
    sh_reflect_v(R1, R2),
    sh_equal(Shape, R2).

:- end_tests(shape_reflect_v).

:- begin_tests(shape_orbit).

test(orbit_asymmetric) :-
    % An asymmetric L-shape has 8 distinct orientations.
    sh_from_cells([r(0,0), r(1,0), r(2,0), r(2,1)], Shape),
    sh_orbit(Shape, Orbit),
    length(Orbit, N),
    N =:= 8.

test(orbit_square) :-
    % A 2x2 square has only 1 distinct orientation.
    full_2x2(G),
    sh_from_grid(G, 1, Shape),
    sh_orbit(Shape, Orbit),
    length(Orbit, N),
    N =:= 1.

test(orbit_bar) :-
    % A 1x3 bar has 2 distinct orientations (horizontal and vertical).
    sh_from_cells([r(0,0), r(0,1), r(0,2)], Shape),
    sh_orbit(Shape, Orbit),
    length(Orbit, N),
    N =:= 2.

:- end_tests(shape_orbit).

:- begin_tests(shape_canonical).

test(canonical_same_for_rotations, [nondet]) :-
    sh_from_cells([r(0,0), r(1,0), r(2,0), r(2,1)], Shape),
    sh_rotate90(Shape, R90),
    sh_canonical(Shape, C1),
    sh_canonical(R90, C2),
    sh_equal(C1, C2).

test(canonical_same_for_reflections, [nondet]) :-
    sh_from_cells([r(0,0), r(1,0), r(2,0), r(2,1)], Shape),
    sh_reflect_h(Shape, HFlip),
    sh_canonical(Shape, C1),
    sh_canonical(HFlip, C2),
    sh_equal(C1, C2).

test(canonical_different_shapes, [fail]) :-
    sh_from_cells([r(0,0), r(0,1), r(0,2)], Bar),
    sh_from_cells([r(0,0), r(1,0), r(2,0), r(2,1)], L),
    sh_canonical(Bar, C1),
    sh_canonical(L, C2),
    sh_equal(C1, C2).

:- end_tests(shape_canonical).

:- begin_tests(shape_equivalent).

test(equivalent_rotation, [nondet]) :-
    sh_from_cells([r(0,0), r(1,0), r(2,0), r(2,1)], Shape),
    sh_rotate90(Shape, R90),
    sh_equivalent(Shape, R90).

test(equivalent_reflection, [nondet]) :-
    sh_from_cells([r(0,0), r(1,0), r(2,0), r(2,1)], Shape),
    sh_reflect_v(Shape, VFlip),
    sh_equivalent(Shape, VFlip).

test(equivalent_different, [fail]) :-
    sh_from_cells([r(0,0), r(0,1), r(0,2)], Bar),
    sh_from_cells([r(0,0), r(1,0), r(2,0), r(2,1)], L),
    sh_equivalent(Bar, L).

:- end_tests(shape_equivalent).

:- begin_tests(shape_to_grid).

test(place_dot) :-
    empty_5x5(G),
    sh_from_cells([r(0,0)], Shape),
    sh_to_grid(Shape, 2, 3, 7, G, G2),
    gd_cell(G2, 2, 3, 7).

test(place_bar) :-
    empty_5x5(G),
    sh_from_cells([r(0,0), r(0,1), r(0,2)], Shape),
    sh_to_grid(Shape, 1, 1, 5, G, G2),
    gd_cell(G2, 1, 1, 5),
    gd_cell(G2, 1, 2, 5),
    gd_cell(G2, 1, 3, 5).

test(place_l) :-
    empty_5x5(G),
    sh_from_cells([r(0,0), r(1,0), r(2,0), r(2,1)], Shape),
    sh_to_grid(Shape, 0, 0, 3, G, G2),
    gd_cell(G2, 0, 0, 3),
    gd_cell(G2, 1, 0, 3),
    gd_cell(G2, 2, 0, 3),
    gd_cell(G2, 2, 1, 3).

:- end_tests(shape_to_grid).
