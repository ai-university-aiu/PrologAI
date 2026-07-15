% test_edge.pl - 42 PLUnit tests for the edge pack (ed_* predicates).
:- use_module('../prolog/edge.pl').

% Shared test grids.
% G2: 2x2 uniform grid (no edges).
g2([[1,1],[1,1]]).
% G3c: 3x3 checkerboard (max edges).
g3c([[0,1,0],[1,0,1],[0,1,0]]).
% G3b: 3x3 with 2-color stripe (horizontal boundary at row 1).
g3b([[0,0,0],[1,1,1],[0,0,0]]).
% G4: 4x4 two-color left-right split.
g4([[0,0,1,1],[0,0,1,1],[0,0,1,1],[0,0,1,1]]).
% G3s: 3x3 single color (smooth).
g3s([[2,2,2],[2,2,2],[2,2,2]]).
% G3m: 3x3 with solid 1-center and 0-border.
g3m([[0,0,0],[0,1,0],[0,0,0]]).

% Tests for edge_h_edges/2.
:- begin_tests(edge_h_edges).
test(uniform_no_h_edges) :-
    g2(G), edge_h_edges(G, E), E = [].
test(stripe_h_edges) :-
    g3b(G), edge_h_edges(G, E),
    msort(E, S),
    S = [0-0,0-1,0-2,1-0,1-1,1-2].
test(checkerboard_h_edges) :-
    g3c(G), edge_h_edges(G, E),
    length(E, N), N =:= 6.
:- end_tests(edge_h_edges).

% Tests for edge_v_edges/2.
:- begin_tests(edge_v_edges).
test(uniform_no_v_edges) :-
    g2(G), edge_v_edges(G, E), E = [].
test(split_v_edges) :-
    g4(G), edge_v_edges(G, E),
    msort(E, S),
    S = [0-1,1-1,2-1,3-1].
test(checkerboard_v_edges) :-
    g3c(G), edge_v_edges(G, E),
    length(E, N), N =:= 6.
:- end_tests(edge_v_edges).

% Tests for edge_h_edge/4.
:- begin_tests(edge_h_edge).
test(h_edge_present) :-
    g3b(G), edge_h_edge(G, 0, 0, B), B =:= 1.
test(h_edge_absent) :-
    g2(G), edge_h_edge(G, 0, 0, B), B =:= 0.
test(h_edge_second_boundary) :-
    g3b(G), edge_h_edge(G, 1, 2, B), B =:= 1.
:- end_tests(edge_h_edge).

% Tests for edge_v_edge/4.
:- begin_tests(edge_v_edge).
test(v_edge_present) :-
    g4(G), edge_v_edge(G, 0, 1, B), B =:= 1.
test(v_edge_absent) :-
    g4(G), edge_v_edge(G, 0, 0, B), B =:= 0.
test(v_edge_last_row) :-
    g4(G), edge_v_edge(G, 3, 1, B), B =:= 1.
:- end_tests(edge_v_edge).

% Tests for edge_all_edges/2.
:- begin_tests(edge_all_edges).
test(uniform_no_edges) :-
    g2(G), edge_all_edges(G, E), E = [].
test(split_all_edges_count) :-
    g4(G), edge_all_edges(G, E),
    length(E, N), N =:= 4.
test(stripe_all_edges_count) :-
    g3b(G), edge_all_edges(G, E),
    length(E, N), N =:= 6.
:- end_tests(edge_all_edges).

% Tests for edge_boundary_cells/3.
:- begin_tests(edge_boundary_cells).
test(center_is_boundary) :-
    g3m(G), edge_boundary_cells(G, 1, Cells),
    Cells = [1-1].
test(border_ring_is_boundary) :-
    g3m(G), edge_boundary_cells(G, 0, Cells),
    length(Cells, N), N =:= 4.
test(uniform_no_boundary) :-
    g3s(G), edge_boundary_cells(G, 2, Cells), Cells = [].
:- end_tests(edge_boundary_cells).

% Tests for edge_outer_boundary/2.
:- begin_tests(edge_outer_boundary).
test(grid2x2_outer_all) :-
    g2(G), edge_outer_boundary(G, Cells),
    length(Cells, N), N =:= 4.
test(grid3x3_outer_count) :-
    g3s(G), edge_outer_boundary(G, Cells),
    length(Cells, N), N =:= 8.
test(outer_includes_corners) :-
    g3s(G), edge_outer_boundary(G, Cells),
    member(0-0, Cells), member(2-2, Cells).
:- end_tests(edge_outer_boundary).

% Tests for edge_inner_cells/3.
:- begin_tests(edge_inner_cells).
test(center_is_inner) :-
    g3s(G), edge_inner_cells(G, 2, Cells),
    length(Cells, N), N =:= 9.
test(mixed_no_inner_for_1) :-
    g3m(G), edge_inner_cells(G, 1, Cells),
    Cells = [].
test(grid2x2_no_inner) :-
    g2(G), edge_inner_cells(G, 1, Cells),
    length(Cells, N), N =:= 4.
:- end_tests(edge_inner_cells).

% Tests for edge_edge_count/2.
:- begin_tests(edge_edge_count).
test(uniform_zero_edges) :-
    g2(G), edge_edge_count(G, N), N =:= 0.
test(split_four_edges) :-
    g4(G), edge_edge_count(G, N), N =:= 4.
test(checkerboard_twelve_edges) :-
    g3c(G), edge_edge_count(G, N), N =:= 12.
:- end_tests(edge_edge_count).

% Tests for edge_is_smooth/1.
:- begin_tests(edge_is_smooth).
test(uniform_is_smooth) :-
    g3s(G), edge_is_smooth(G).
test(checkerboard_not_smooth) :-
    g3c(G), \+ edge_is_smooth(G).
test(grid2x2_uniform_smooth) :-
    g2(G), edge_is_smooth(G).
:- end_tests(edge_is_smooth).

% Tests for edge_label_edges/3.
:- begin_tests(edge_label_edges).
test(uniform_all_bg) :-
    g2(G), edge_label_edges(G, 0, G2),
    G2 = [[0,0],[0,0]].
test(border_ring_labeled) :-
    g3m(G), edge_label_edges(G, 0, G2),
    G2 = [[0,1,0],[1,1,1],[0,1,0]].
test(smooth_all_bg) :-
    g3s(G), edge_label_edges(G, 0, G2),
    G2 = [[0,0,0],[0,0,0],[0,0,0]].
:- end_tests(edge_label_edges).

% Tests for edge_has_edge/4.
:- begin_tests(edge_has_edge).
test(center_in_mixed_has_edge) :-
    g3m(G), edge_has_edge(G, 1, 1, B), B =:= 1.
test(uniform_center_no_edge) :-
    g3s(G), edge_has_edge(G, 1, 1, B), B =:= 0.
test(split_boundary_has_edge) :-
    g4(G), edge_has_edge(G, 0, 1, B), B =:= 1.
:- end_tests(edge_has_edge).

% Tests for edge_corners/2.
:- begin_tests(edge_corners).
test(uniform_no_corners) :-
    g2(G), edge_corners(G, C), C = [].
test(split_has_corners) :-
    g4(G), edge_corners(G, C),
    length(C, N), N =:= 3.
test(checkerboard_max_corners) :-
    g3c(G), edge_corners(G, C),
    length(C, N), N =:= 4.
:- end_tests(edge_corners).

% Tests for edge_corner_count/2.
:- begin_tests(edge_corner_count).
test(uniform_zero_corners) :-
    g2(G), edge_corner_count(G, N), N =:= 0.
test(split_three_corners) :-
    g4(G), edge_corner_count(G, N), N =:= 3.
test(smooth_zero_corners) :-
    g3s(G), edge_corner_count(G, N), N =:= 0.
:- end_tests(edge_corner_count).
