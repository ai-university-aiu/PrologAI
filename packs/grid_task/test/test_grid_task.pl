:- use_module('../prolog/grid_task').
:- use_module(library(plunit)).

% Grid fixtures.
% G_UNIFORM: 2x2 all-r grid
g_uniform([[r,r],[r,r]]).

% G_ONE_B: 2x2 grid with one b cell at (0,1)
g_one_b([[r,b],[r,r]]).

% G_ONE_G: 2x2 grid with one g cell at (0,1) (b recolored to g)
g_one_g([[r,g],[r,r]]).

% G_CENTER: 3x3 grid with b at center (1,1)
g_center([[r,r,r],[r,b,r],[r,r,r]]).

% G_TWO: 3x3 grid with g at (1,1) and b at (2,2) — two diffs vs g_center
g_two([[r,r,r],[r,g,r],[r,r,b]]).

% G_SCALE2: 2x2 grid for scale tests
g_scale2([[b,r],[r,b]]).

% G_SCALE2_X2: 4x4 grid = g_scale2 scaled by 2
g_scale2_x2([[b,b,r,r],[b,b,r,r],[r,r,b,b],[r,r,b,b]]).

% G_SCALE1: 1x1 grid
g_scale1([[r]]).

% G_SCALE1_X3: 3x3 = g_scale1 scaled by 3
g_scale1_x3([[r,r,r],[r,r,r],[r,r,r]]).

% G_SHIFT_LEFT: 3x3 with b at (1,0) — for shift tests
g_shift_left([[r,r,r],[b,r,r],[r,r,r]]).

% G_SHIFT_CENTER: 3x3 with b at (1,1) — shift right by 1
g_shift_center([[r,r,r],[r,b,r],[r,r,r]]).

% G_SHIFT_DOWN: 3x3 with b at (2,0) — shift down by 1 from g_shift_left
g_shift_down([[r,r,r],[r,r,r],[b,r,r]]).

% G_ALLB: 2x2 all-b grid
g_allb([[b,b],[b,b]]).

% G_ALLB_G: 2x2 all-g grid (b recolored to g)
g_allb_g([[g,g],[g,g]]).

:- begin_tests(grid_task).

% grid_task_diff_cells: same grids yield empty list
test(difference_cells_same) :-
    g_uniform(G), grid_task_diff_cells(G, G, Diffs), Diffs == [].

% grid_task_diff_cells: one differing cell detected
test(difference_cells_one) :-
    g_uniform(G1), g_one_b(G2),
    grid_task_diff_cells(G1, G2, Diffs),
    length(Diffs, 1),
    Diffs = [r(0,1)].

% grid_task_diff_cells: multiple differing cells detected
test(difference_cells_multiple) :-
    g_center(G1), g_two(G2),
    grid_task_diff_cells(G1, G2, Diffs),
    length(Diffs, 2).

% grid_task_diff_cells: 2x2 entirely different grids
test(difference_cells_all_different) :-
    g_uniform(G1), g_allb(G2),
    grid_task_diff_cells(G1, G2, Diffs),
    length(Diffs, 4).

% grid_task_n_changed: same grids yield zero
test(n_changed_zero) :-
    g_uniform(G), grid_task_n_changed(G, G, N), N == 0.

% grid_task_n_changed: one cell changed
test(n_changed_one) :-
    g_uniform(G1), g_one_b(G2),
    grid_task_n_changed(G1, G2, N), N == 1.

% grid_task_n_changed: all cells changed
test(n_changed_all) :-
    g_uniform(G1), g_allb(G2),
    grid_task_n_changed(G1, G2, N), N == 4.

% grid_task_unchanged_cells: same grid — all 4 cells unchanged
test(unchanged_cells_all) :-
    g_uniform(G), grid_task_unchanged_cells(G, G, Cells),
    length(Cells, 4).

% grid_task_unchanged_cells: one changed — three unchanged
test(unchanged_cells_three) :-
    g_uniform(G1), g_one_b(G2),
    grid_task_unchanged_cells(G1, G2, Cells),
    length(Cells, 3).

% grid_task_unchanged_cells: no unchanged cells when all differ
test(unchanged_cells_none) :-
    g_uniform(G1), g_allb(G2),
    grid_task_unchanged_cells(G1, G2, Cells),
    Cells == [].

% grid_task_bg_color: uniform grid
test(bg_color_uniform) :-
    g_uniform(G), grid_task_bg_color(G, C), C == r.

% grid_task_bg_color: majority color is background
test(bg_color_majority) :-
    g_one_b(G), grid_task_bg_color(G, C), C == r.

% grid_task_bg_color: all-b grid
test(bg_color_allb) :-
    g_allb(G), grid_task_bg_color(G, C), C == b.

% grid_task_bg_color: center grid (8 r cells vs 1 b cell)
test(bg_color_center) :-
    g_center(G), grid_task_bg_color(G, C), C == r.

% grid_task_infer_color_map: identical grids produce only identity pairs
test(infer_color_map_identity) :-
    g_uniform(G),
    grid_task_infer_color_map(G, G, Map),
    Map == [r-r].

% grid_task_infer_color_map: partial recolor (r→b in one cell, r→r in others) is inconsistent — fails
test(infer_color_map_partial_fails, [fail]) :-
    g_uniform(G1), g_one_b(G2),
    grid_task_infer_color_map(G1, G2, _).

% grid_task_infer_color_map: all-b recolored to all-g
test(infer_color_map_full_recolor) :-
    g_allb(G1), g_allb_g(G2),
    grid_task_infer_color_map(G1, G2, Map),
    Map == [b-g].

% grid_task_infer_color_map: inconsistent map fails
test(infer_color_map_inconsistent, [fail]) :-
    % r maps to b in first cell but to g in second cell — inconsistent
    Before = [[r, r]],
    After  = [[b, g]],
    grid_task_infer_color_map(Before, After, _).

% grid_task_test_color_map: correct map succeeds
test(test_color_map_success) :-
    g_allb(G1), g_allb_g(G2),
    Map = [b-g],
    grid_task_test_color_map(Map, G1, G2).

% grid_task_test_color_map: wrong map fails
test(test_color_map_fail, [fail]) :-
    g_allb(G1), g_allb_g(G2),
    Map = [b-r],
    grid_task_test_color_map(Map, G1, G2).

% grid_task_apply_color_map: empty map is identity
test(apply_color_map_empty) :-
    g_uniform(G),
    grid_task_apply_color_map([], G, NewG),
    NewG == G.

% grid_task_apply_color_map: recolor r to b
test(apply_color_map_recolor) :-
    g_uniform(G),
    grid_task_apply_color_map([r-b], G, NewG),
    NewG == [[b,b],[b,b]].

% grid_task_apply_color_map: unmapped colors unchanged
test(apply_color_map_partial) :-
    g_one_b([[r,b],[r,r]]),
    grid_task_apply_color_map([b-g], [[r,b],[r,r]], NewG),
    NewG == [[r,g],[r,r]].

% grid_task_color_map_pairs: single pair produces same map as infer_color_map
test(color_map_pairs_single) :-
    g_allb(G1), g_allb_g(G2),
    grid_task_color_map_pairs([G1-G2], Map),
    memberchk(b-g, Map).

% grid_task_color_map_pairs: two pairs with consistent maps
test(color_map_pairs_two_consistent) :-
    G1a = [[r]], G1b = [[b]],
    G2a = [[r,g]], G2b = [[b,g]],
    grid_task_color_map_pairs([G1a-G1b, G2a-G2b], Map),
    memberchk(r-b, Map).

% grid_task_color_map_pairs: inconsistent pairs fail
test(color_map_pairs_inconsistent, [fail]) :-
    G1 = [[r]], G2a = [[b]], G2b = [[g]],
    grid_task_color_map_pairs([G1-G2a, G1-G2b], _).

% grid_task_is_color_sub: simple recolor is a color substitution
test(is_color_sub_true) :-
    G1 = [[r,r],[r,r]], G2 = [[b,b],[b,b]],
    grid_task_is_color_sub([G1-G2]).

% grid_task_is_color_sub: inconsistent pairs fail
test(is_color_sub_false, [fail]) :-
    G1 = [[r]], G2a = [[b]], G2b = [[g]],
    grid_task_is_color_sub([G1-G2a, G1-G2b]).

% grid_task_is_identity: same grids succeed
test(is_identity_true) :-
    g_uniform(G), grid_task_is_identity(G, G).

% grid_task_is_identity: different grids fail
test(is_identity_false, [fail]) :-
    g_uniform(G1), g_one_b(G2),
    grid_task_is_identity(G1, G2).

% grid_task_is_scale: 2x2 scaled to 4x4 by factor 2
test(is_scale_two) :-
    g_scale2(G), g_scale2_x2(GS),
    grid_task_is_scale(G, GS, N), N == 2.

% grid_task_is_scale: 1x1 scaled to 3x3 by factor 3
test(is_scale_three) :-
    g_scale1(G), g_scale1_x3(GS),
    grid_task_is_scale(G, GS, N), N == 3.

% grid_task_is_scale: same-size grids fail (N=1 not allowed)
test(is_scale_one_fails, [fail]) :-
    g_uniform(G), grid_task_is_scale(G, G, _).

% grid_task_is_scale: non-uniform block fails
test(is_scale_non_uniform, [fail]) :-
    Before = [[r]], After = [[r,b],[b,r]],
    grid_task_is_scale(Before, After, _).

% grid_task_infer_shift: shift right by 1 column
test(infer_shift_right) :-
    g_shift_left(G1), g_shift_center(G2),
    grid_task_infer_shift(G1, G2, r, dr(DR, DC)),
    DR == 0, DC == 1.

% grid_task_infer_shift: shift down by 1 row
test(infer_shift_down) :-
    g_shift_left(G1), g_shift_down(G2),
    grid_task_infer_shift(G1, G2, r, dr(DR, DC)),
    DR == 1, DC == 0.

% grid_task_infer_shift: no valid shift fails
test(infer_shift_no_match, [fail]) :-
    % All cells are background, so no non-bg cell to anchor
    g_uniform(G),
    grid_task_infer_shift(G, G, r, _).

% grid_task_pair_score: perfect match scores 1.0
test(pair_score_perfect) :-
    g_uniform(G),
    grid_task_pair_score(identity, G, G, Score),
    Score =:= 1.0.

% grid_task_pair_score: wrong color map scores 0.0 on all-r grid
test(pair_score_zero) :-
    g_allb(G1), g_uniform(G2),
    grid_task_pair_score(identity, G1, G2, Score),
    Score =:= 0.0.

% grid_task_pair_score: color map rule on exact match
test(pair_score_color_map) :-
    g_allb(G1), g_allb_g(G2),
    grid_task_pair_score(color_map([b-g]), G1, G2, Score),
    Score =:= 1.0.

% grid_task_pair_score: partial match
test(pair_score_partial) :-
    % [[r,b]] → expected [[r,r]] — one of two cells matches
    Before = [[r,b]], After = [[r,r]],
    grid_task_pair_score(identity, Before, After, Score),
    Score =:= 0.5.

% grid_task_solve: identity pairs resolved to identity rule
test(solve_identity) :-
    G = [[r,b],[g,r]],
    grid_task_solve([G-G], G, Out, Rule),
    Rule == identity, Out == G.

% grid_task_solve: color substitution resolved
test(solve_color_map) :-
    G1 = [[r,r]], G2 = [[b,b]],
    grid_task_solve([G1-G2], G1, Out, Rule),
    Rule = color_map(_), Out == [[b,b]].

% grid_task_solve: scale-2 pairs resolved
test(solve_scale) :-
    g_scale2(G), g_scale2_x2(GS),
    grid_task_solve([G-GS], G, Out, Rule),
    Rule == scale(2), Out == GS.

% grid_task_solve: shift pairs resolved
test(solve_shift) :-
    g_shift_left(G1), g_shift_center(G2),
    grid_task_solve([G1-G2], G1, Out, Rule),
    Rule = shift(0, 1, r), Out == G2.

% grid_task_solve: inconsistent color map (r maps to b and g) falls back to identity
test(solve_fallback) :-
    Before = [[r,r]],
    After  = [[b,g]],  % r maps to b in col 0, to g in col 1 — inconsistent
    grid_task_solve([Before-After], Before, Out, Rule),
    Rule == identity, Out == Before.

% grid_task_diff_cells: 1x1 same
test(difference_cells_1x1_same) :-
    grid_task_diff_cells([[r]], [[r]], D), D == [].

% grid_task_diff_cells: 1x1 different
test(difference_cells_1x1_diff) :-
    grid_task_diff_cells([[r]], [[b]], D), D == [r(0,0)].

% grid_task_unchanged_cells: 1x1 same
test(unchanged_1x1) :-
    grid_task_unchanged_cells([[r]], [[r]], C), C == [r(0,0)].

% grid_task_is_scale: scale-2 correct uniform block
test(is_scale_uniform_block) :-
    Before = [[b]], After = [[b,b],[b,b]],
    grid_task_is_scale(Before, After, 2).

% grid_task_color_map_pairs: identity on uniform grids
test(color_map_pairs_identity) :-
    G = [[r,r]],
    grid_task_color_map_pairs([G-G], Map),
    Map == [r-r].

:- end_tests(grid_task).
