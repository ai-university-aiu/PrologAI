% test_topology.pl - 42 PLUnit tests for the topology pack (tp_* predicates).
:- use_module('../prolog/topology.pl').

% Shared test grids.
% G3u: 3x3 uniform grid of 1s (one connected component).
g3u([[1,1,1],[1,1,1],[1,1,1]]).
% G3h: 3x3 with 1-border and 0-center (1 encloses one 0-hole).
g3h([[1,1,1],[1,0,1],[1,1,1]]).
% G4s: 4x4 split: left-half 1s, right-half 2s.
g4s([[1,1,2,2],[1,1,2,2],[1,1,2,2],[1,1,2,2]]).
% G3t: 3x3 two disconnected 1s at corners.
g3t([[1,0,0],[0,0,0],[0,0,1]]).
% G5h: 5x5 with 1-border, 3x3 inner of 0s (large hole).
g5h([[1,1,1,1,1],[1,0,0,0,1],[1,0,0,0,1],[1,0,0,0,1],[1,1,1,1,1]]).
% G3m: 3x3 mixed: 1 at center, 0 elsewhere.
g3m([[0,0,0],[0,1,0],[0,0,0]]).

% Tests for tp_component/4.
:- begin_tests(tp_component).
test(uniform_all_connected) :-
    g3u(G), tp_component(G, 1, 0-0, C), length(C, N), N =:= 9.
test(isolated_cell) :-
    g3t(G), tp_component(G, 1, 0-0, C), C = [0-0].
test(other_corner) :-
    g3t(G), tp_component(G, 1, 2-2, C), C = [2-2].
:- end_tests(tp_component).

% Tests for tp_all_components/3.
:- begin_tests(tp_all_components).
test(uniform_one_component) :-
    g3u(G), tp_all_components(G, 1, Comps), length(Comps, N), N =:= 1.
test(two_corners_two_components) :-
    g3t(G), tp_all_components(G, 1, Comps), length(Comps, N), N =:= 2.
test(split_one_per_color) :-
    g4s(G), tp_all_components(G, 1, Comps), length(Comps, N), N =:= 1.
:- end_tests(tp_all_components).

% Tests for tp_component_count/3.
:- begin_tests(tp_component_count).
test(uniform_one) :-
    g3u(G), tp_component_count(G, 1, N), N =:= 1.
test(two_isolated) :-
    g3t(G), tp_component_count(G, 1, N), N =:= 2.
test(no_val_zero) :-
    g3m(G), tp_component_count(G, 9, N), N =:= 0.
:- end_tests(tp_component_count).

% Tests for tp_component_size/4.
:- begin_tests(tp_component_size).
test(full_3x3) :-
    g3u(G), tp_component_size(G, 1, 0-0, N), N =:= 9.
test(single_cell) :-
    g3t(G), tp_component_size(G, 1, 0-0, N), N =:= 1.
test(split_half) :-
    g4s(G), tp_component_size(G, 1, 0-0, N), N =:= 8.
:- end_tests(tp_component_size).

% Tests for tp_largest_component/3.
:- begin_tests(tp_largest_component).
test(uniform_all) :-
    g3u(G), tp_largest_component(G, 1, Cells), length(Cells, N), N =:= 9.
test(two_equal_picks_first) :-
    g3t(G), tp_largest_component(G, 1, Cells), length(Cells, N), N =:= 1.
test(split_half) :-
    g4s(G), tp_largest_component(G, 1, Cells), length(Cells, N), N =:= 8.
:- end_tests(tp_largest_component).

% Tests for tp_reachable/5.
:- begin_tests(tp_reachable).
test(same_cell) :-
    g3u(G), tp_reachable(G, 1, 0-0, 0-0, B), B =:= 1.
test(reachable_far) :-
    g3u(G), tp_reachable(G, 1, 0-0, 2-2, B), B =:= 1.
test(not_reachable) :-
    g3t(G), tp_reachable(G, 1, 0-0, 2-2, B), B =:= 0.
:- end_tests(tp_reachable).

% Tests for tp_enclosed/4.
:- begin_tests(tp_enclosed).
test(center_hole) :-
    g3h(G), tp_enclosed(G, 1, 0, Cells), Cells = [1-1].
test(no_hole_open) :-
    g3t(G), tp_enclosed(G, 1, 0, Cells), Cells = [].
test(large_hole) :-
    g5h(G), tp_enclosed(G, 1, 0, Cells), length(Cells, N), N =:= 9.
:- end_tests(tp_enclosed).

% Tests for tp_has_hole/4.
:- begin_tests(tp_has_hole).
test(has_hole) :-
    g3h(G), tp_has_hole(G, 1, 0, Bool), Bool =:= 1.
test(no_hole) :-
    g3t(G), tp_has_hole(G, 1, 0, Bool), Bool =:= 0.
test(no_hole_open_border) :-
    g3u(G), tp_has_hole(G, 1, 0, Bool), Bool =:= 0.
:- end_tests(tp_has_hole).

% Tests for tp_hole_count/4.
:- begin_tests(tp_hole_count).
test(one_hole) :-
    g3h(G), tp_hole_count(G, 1, 0, N), N =:= 1.
test(no_hole) :-
    g3t(G), tp_hole_count(G, 1, 0, N), N =:= 0.
test(large_hole_one) :-
    g5h(G), tp_hole_count(G, 1, 0, N), N =:= 1.
:- end_tests(tp_hole_count).

% Tests for tp_fill_holes/4.
:- begin_tests(tp_fill_holes).
test(fill_center) :-
    g3h(G), tp_fill_holes(G, 1, 0, G2),
    nth0(1, G2, Row), nth0(1, Row, V), V =:= 1.
test(no_fill_open) :-
    g3t(G), tp_fill_holes(G, 1, 0, G2), G2 = G.
test(fill_large) :-
    g5h(G), tp_fill_holes(G, 1, 0, G2),
    nth0(2, G2, Row), nth0(2, Row, V), V =:= 1.
:- end_tests(tp_fill_holes).

% Tests for tp_border_components/3.
:- begin_tests(tp_border_components).
test(uniform_touches_border) :-
    g3u(G), tp_border_components(G, 1, Comps), length(Comps, N), N =:= 1.
test(center_does_not_touch) :-
    g3m(G), tp_border_components(G, 1, Comps), Comps = [].
test(border_ring_touches) :-
    g3h(G), tp_border_components(G, 1, Comps), length(Comps, N), N =:= 1.
:- end_tests(tp_border_components).

% Tests for tp_interior_components/3.
:- begin_tests(tp_interior_components).
test(uniform_not_interior) :-
    g3u(G), tp_interior_components(G, 1, Comps), Comps = [].
test(center_is_interior) :-
    g3m(G), tp_interior_components(G, 1, Comps), length(Comps, N), N =:= 1.
test(border_ring_not_interior) :-
    g3h(G), tp_interior_components(G, 1, Comps), Comps = [].
:- end_tests(tp_interior_components).

% Tests for tp_label_components/3.
:- begin_tests(tp_label_components).
test(uniform_all_label1) :-
    g3u(G), tp_label_components(G, 1, L),
    nth0(0, L, Row), nth0(0, Row, V), V =:= 1.
test(zero_for_nonval) :-
    g3h(G), tp_label_components(G, 1, L),
    nth0(1, L, Row), nth0(1, Row, V), V =:= 0.
test(two_cells_distinct_labels) :-
    g3t(G), tp_label_components(G, 1, L),
    nth0(0, L, R0), nth0(0, R0, V1),
    nth0(2, L, R2), nth0(2, R2, V2),
    V1 =\= V2, V1 > 0, V2 > 0.
:- end_tests(tp_label_components).

% Tests for tp_same_component/5.
:- begin_tests(tp_same_component).
test(uniform_same) :-
    g3u(G), tp_same_component(G, 1, 0-0, 2-2, B), B =:= 1.
test(split_different) :-
    g3t(G), tp_same_component(G, 1, 0-0, 2-2, B), B =:= 0.
test(same_cell) :-
    g3m(G), tp_same_component(G, 1, 1-1, 1-1, B), B =:= 1.
:- end_tests(tp_same_component).
