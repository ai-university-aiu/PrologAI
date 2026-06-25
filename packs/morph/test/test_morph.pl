% test_morph.pl - Acceptance tests for the morph pack (Layer 84).
% 42 PLUnit tests: 3 per predicate across 14 predicates.
:- use_module('../prolog/morph.pl').

% Tests for mo_dilate/3: expand non-Bg regions by one 4-connected step.
:- begin_tests(morph_dilate).

% Single center cell dilates into a cross shape.
test(dilate_dot_to_cross) :-
    mo_dilate([[0,0,0],[0,1,0],[0,0,0]], 0, R),
    R = [[0,1,0],[1,1,1],[0,1,0]].

% All-fg grid has no Bg cells to fill; unchanged.
test(dilate_all_fg_unchanged) :-
    mo_dilate([[1,1],[1,1]], 0, R),
    R = [[1,1],[1,1]].

% Non-zero Bg value: color 2 dilates outward, Bg=9 cells adjacent to 2 become 2.
test(dilate_non_zero_bg) :-
    mo_dilate([[9,9,9],[9,2,9],[9,9,9]], 9, R),
    R = [[9,2,9],[2,2,2],[9,2,9]].

:- end_tests(morph_dilate).

% Tests for mo_erode/3: shrink non-Bg regions by one 4-connected step.
:- begin_tests(morph_erode).

% Cross shape erodes to single center cell (all arms have Bg neighbors).
test(erode_cross_to_dot) :-
    mo_erode([[0,1,0],[1,1,1],[0,1,0]], 0, R),
    R = [[0,0,0],[0,1,0],[0,0,0]].

% Single dot has Bg neighbors; erodes to all-Bg.
test(erode_dot_to_empty) :-
    mo_erode([[0,0,0],[0,1,0],[0,0,0]], 0, R),
    R = [[0,0,0],[0,0,0],[0,0,0]].

% Solid 3x3 block: no cell has an in-bounds Bg 4-neighbor; unchanged.
test(erode_solid_unchanged) :-
    mo_erode([[1,1,1],[1,1,1],[1,1,1]], 0, R),
    R = [[1,1,1],[1,1,1],[1,1,1]].

:- end_tests(morph_erode).

% Tests for mo_dilate_n/4: dilate N times.
:- begin_tests(morph_dilate_n).

% N=0: predicate returns the input grid unchanged.
test(dilate_n_zero_unchanged) :-
    mo_dilate_n([[0,1,0],[1,1,1],[0,1,0]], 0, 0, R),
    R = [[0,1,0],[1,1,1],[0,1,0]].

% N=1: result matches a single mo_dilate call.
test(dilate_n_one_matches_dilate) :-
    G = [[0,0,0],[0,1,0],[0,0,0]],
    mo_dilate_n(G, 0, 1, R),
    R = [[0,1,0],[1,1,1],[0,1,0]].

% N=2 from center dot in 5x5 grid: L1-diamond of radius 2 expands.
test(dilate_n_two_from_center) :-
    G = [[0,0,0,0,0],[0,0,0,0,0],[0,0,1,0,0],[0,0,0,0,0],[0,0,0,0,0]],
    mo_dilate_n(G, 0, 2, R),
    R = [[0,0,1,0,0],[0,1,1,1,0],[1,1,1,1,1],[0,1,1,1,0],[0,0,1,0,0]].

:- end_tests(morph_dilate_n).

% Tests for mo_erode_n/4: erode N times.
:- begin_tests(morph_erode_n).

% N=0: predicate returns the input grid unchanged.
test(erode_n_zero_unchanged) :-
    mo_erode_n([[0,1,0],[1,1,1],[0,1,0]], 0, 0, R),
    R = [[0,1,0],[1,1,1],[0,1,0]].

% N=1: result matches a single mo_erode call.
test(erode_n_one_matches_erode) :-
    mo_erode_n([[0,1,0],[1,1,1],[0,1,0]], 0, 1, R),
    R = [[0,0,0],[0,1,0],[0,0,0]].

% N=2 from single dot: erode once removes dot; erode again keeps all-Bg.
test(erode_n_two_empties_dot) :-
    mo_erode_n([[0,0,0],[0,1,0],[0,0,0]], 0, 2, R),
    R = [[0,0,0],[0,0,0],[0,0,0]].

:- end_tests(morph_erode_n).

% Tests for mo_open/3: morphological opening (erode then dilate).
:- begin_tests(morph_open).

% Single dot: erode removes it; dilate of empty grid stays empty.
test(open_dot_to_empty) :-
    mo_open([[0,0,0],[0,1,0],[0,0,0]], 0, R),
    R = [[0,0,0],[0,0,0],[0,0,0]].

% Cross shape: erode to center, dilate back to cross; cross is preserved.
test(open_cross_survives) :-
    mo_open([[0,1,0],[1,1,1],[0,1,0]], 0, R),
    R = [[0,1,0],[1,1,1],[0,1,0]].

% All-Bg grid: opening of empty stays empty.
test(open_all_bg_unchanged) :-
    mo_open([[0,0],[0,0]], 0, R),
    R = [[0,0],[0,0]].

:- end_tests(morph_open).

% Tests for mo_close/3: morphological closing (dilate then erode).
:- begin_tests(morph_close).

% Single dot: dilate to cross, erode back to center; dot is preserved.
test(close_dot_survives) :-
    mo_close([[0,0,0],[0,1,0],[0,0,0]], 0, R),
    R = [[0,0,0],[0,1,0],[0,0,0]].

% Two-cell gap [[1,0,1]]: dilate connects them; erode yields solid bar.
test(close_fills_gap) :-
    mo_close([[1,0,1]], 0, R),
    R = [[1,1,1]].

% All-Bg grid: closing of empty stays empty.
test(close_all_bg_unchanged) :-
    mo_close([[0,0],[0,0]], 0, R),
    R = [[0,0],[0,0]].

:- end_tests(morph_close).

% Tests for mo_smooth/3: morphological smoothing (open then close).
:- begin_tests(morph_smooth).

% Single dot: open removes it; close of empty stays empty.
test(smooth_dot_removed) :-
    mo_smooth([[0,0,0],[0,1,0],[0,0,0]], 0, R),
    R = [[0,0,0],[0,0,0],[0,0,0]].

% Solid 3x3 block: erode/dilate/dilate/erode cycle leaves it unchanged.
test(smooth_solid_unchanged) :-
    mo_smooth([[1,1,1],[1,1,1],[1,1,1]], 0, R),
    R = [[1,1,1],[1,1,1],[1,1,1]].

% Cross: open preserves cross; close fills corners; result is 3x3 solid block.
test(smooth_cross_fills) :-
    mo_smooth([[0,1,0],[1,1,1],[0,1,0]], 0, R),
    R = [[1,1,1],[1,1,1],[1,1,1]].

:- end_tests(morph_smooth).

% Tests for mo_boundary/3: keep only perimeter non-Bg cells.
:- begin_tests(morph_boundary).

% 3x3 inner block in 5x5: center cell (2,2) is interior; all others are boundary.
test(boundary_inner_block_5x5) :-
    G = [[0,0,0,0,0],[0,1,1,1,0],[0,1,1,1,0],[0,1,1,1,0],[0,0,0,0,0]],
    mo_boundary(G, 0, R),
    R = [[0,0,0,0,0],[0,1,1,1,0],[0,1,0,1,0],[0,1,1,1,0],[0,0,0,0,0]].

% Solid 3x3: only center cell (1,1) is not on edge and has no Bg neighbors; it becomes Bg.
test(boundary_solid_3x3) :-
    mo_boundary([[1,1,1],[1,1,1],[1,1,1]], 0, R),
    R = [[1,1,1],[1,0,1],[1,1,1]].

% Single dot: dot has Bg neighbors so it is a boundary cell; result unchanged.
test(boundary_dot_is_boundary) :-
    mo_boundary([[0,0,0],[0,1,0],[0,0,0]], 0, R),
    R = [[0,0,0],[0,1,0],[0,0,0]].

:- end_tests(morph_boundary).

% Tests for mo_interior/3: keep only non-perimeter non-Bg cells.
:- begin_tests(morph_interior).

% 3x3 inner block in 5x5: only center cell (2,2) is interior.
test(interior_inner_block_5x5) :-
    G = [[0,0,0,0,0],[0,1,1,1,0],[0,1,1,1,0],[0,1,1,1,0],[0,0,0,0,0]],
    mo_interior(G, 0, R),
    R = [[0,0,0,0,0],[0,0,0,0,0],[0,0,1,0,0],[0,0,0,0,0],[0,0,0,0,0]].

% Solid 3x3: center (1,1) has no Bg neighbors and is not on edge; only interior.
test(interior_solid_3x3) :-
    mo_interior([[1,1,1],[1,1,1],[1,1,1]], 0, R),
    R = [[0,0,0],[0,1,0],[0,0,0]].

% Single dot: dot is a boundary cell; interior is all-Bg.
test(interior_dot_is_empty) :-
    mo_interior([[0,0,0],[0,1,0],[0,0,0]], 0, R),
    R = [[0,0,0],[0,0,0],[0,0,0]].

:- end_tests(morph_interior).

% Tests for mo_dilate_val/4: dilate using a fixed fill value.
:- begin_tests(morph_dilate_val).

% Dot with Val=9: adjacent Bg cells become 9, original non-Bg cell keeps its value.
test(dilate_val_dot_to_cross) :-
    mo_dilate_val([[0,0,0],[0,1,0],[0,0,0]], 0, 9, R),
    R = [[0,9,0],[9,1,9],[0,9,0]].

% All-fg grid: no Bg cells to fill; unchanged regardless of Val.
test(dilate_val_all_fg_unchanged) :-
    mo_dilate_val([[1,1],[1,1]], 0, 5, R),
    R = [[1,1],[1,1]].

% Two different fg colors; both Bg cells between them get Val, not neighbor's color.
test(dilate_val_fixed_not_neighbor_color) :-
    mo_dilate_val([[2,0,3]], 0, 5, R),
    R = [[2,5,3]].

:- end_tests(morph_dilate_val).

% Tests for mo_grow_from/5: BFS flood from seeds into connected Bg territory.
:- begin_tests(morph_grow_from).

% All-Bg 3x3 with seed at center: BFS reaches and marks all cells with Val.
test(grow_from_center_all_bg) :-
    mo_grow_from([[0,0,0],[0,0,0],[0,0,0]], [1-1], 0, 3, R),
    R = [[3,3,3],[3,3,3],[3,3,3]].

% Vertical wall of 1s blocks flood: only left column Bg cells are reached.
test(grow_from_blocked_by_wall) :-
    mo_grow_from([[0,1,0],[0,1,0],[0,1,0]], [0-0], 0, 5, R),
    R = [[5,1,0],[5,1,0],[5,1,0]].

% Empty seed list: no BFS expansion; result equals input.
test(grow_from_empty_seeds_unchanged) :-
    G = [[0,1,0],[1,1,1],[0,1,0]],
    mo_grow_from(G, [], 0, 9, R),
    R = G.

:- end_tests(morph_grow_from).

% Tests for mo_dist_to_bg/3: L1 Manhattan distance to nearest Bg cell.
:- begin_tests(morph_dist_to_bg).

% Single non-Bg dot: nearest Bg is 1 step away; dist=1.
test(dist_to_bg_single_dot) :-
    mo_dist_to_bg([[0,0,0],[0,1,0],[0,0,0]], 0, D),
    D = [[0,0,0],[0,1,0],[0,0,0]].

% 3x3 block in 5x5: center cell (2,2) is 2 steps from nearest Bg.
test(dist_to_bg_inner_block) :-
    G = [[0,0,0,0,0],[0,1,1,1,0],[0,1,1,1,0],[0,1,1,1,0],[0,0,0,0,0]],
    mo_dist_to_bg(G, 0, D),
    D = [[0,0,0,0,0],[0,1,1,1,0],[0,1,2,1,0],[0,1,1,1,0],[0,0,0,0,0]].

% All-Bg grid: no non-Bg cells; all distances are 0.
test(dist_to_bg_all_bg_zero) :-
    mo_dist_to_bg([[0,0],[0,0]], 0, D),
    D = [[0,0],[0,0]].

:- end_tests(morph_dist_to_bg).

% Tests for mo_ring/4: cells at exactly N dilation steps from non-Bg cells.
:- begin_tests(morph_ring).

% Ring at N=0 is all-Bg (no cells are "newly added" at step 0).
test(ring_n0_all_bg) :-
    mo_ring([[0,1,0],[1,1,1],[0,1,0]], 0, 0, R),
    R = [[0,0,0],[0,0,0],[0,0,0]].

% Ring at N=1 from center dot in 3x3: 4 cardinal neighbors; center excluded.
test(ring_n1_from_dot) :-
    mo_ring([[0,0,0],[0,1,0],[0,0,0]], 0, 1, R),
    R = [[0,1,0],[1,0,1],[0,1,0]].

% Ring at N=2 from center of 5x5: L1-diamond shell at distance 2.
test(ring_n2_from_center_5x5) :-
    G = [[0,0,0,0,0],[0,0,0,0,0],[0,0,1,0,0],[0,0,0,0,0],[0,0,0,0,0]],
    mo_ring(G, 0, 2, R),
    R = [[0,0,1,0,0],[0,1,0,1,0],[1,0,0,0,1],[0,1,0,1,0],[0,0,1,0,0]].

:- end_tests(morph_ring).

% Tests for mo_fill_holes/4: fill enclosed background regions.
:- begin_tests(morph_fill_holes).

% 3x3 ring of 1s encloses a single Bg cell; that cell becomes FillVal.
test(fill_holes_single_hole) :-
    mo_fill_holes([[1,1,1],[1,0,1],[1,1,1]], 0, 5, R),
    R = [[1,1,1],[1,5,1],[1,1,1]].

% Open cross: all Bg cells are reachable from the border; nothing is filled.
test(fill_holes_no_interior_bg) :-
    G = [[0,1,0],[1,1,1],[0,1,0]],
    mo_fill_holes(G, 0, 5, R),
    R = G.

% 5x5 grid with two enclosed holes and open exterior Bg at bottom.
test(fill_holes_two_holes) :-
    G = [[1,1,1,1,1],[1,0,1,0,1],[1,1,1,1,1],[0,0,0,0,0],[0,0,0,0,0]],
    mo_fill_holes(G, 0, 5, R),
    R = [[1,1,1,1,1],[1,5,1,5,1],[1,1,1,1,1],[0,0,0,0,0],[0,0,0,0,0]].

:- end_tests(morph_fill_holes).
