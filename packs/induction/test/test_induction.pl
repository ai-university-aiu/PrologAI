% PLUnit tests for the induction pack (id_* predicates).
:- use_module(library(plunit)).
:- use_module(library(induction)).

% Helper grids.
% 3x3 uniform-output grid (all 5s).
out_uniform([[5,5,5],[5,5,5],[5,5,5]]).
% 3x3 input with mixed colors.
in_mixed([[0,1,0],[2,0,2],[0,1,0]]).
% 3x3 recolored: 0->5, 1->3, 2->7.
out_recolored([[5,3,5],[7,5,7],[5,3,5]]).
% 2x2 input.
in_2x2([[0,1],[1,0]]).
% 4x4 output (scale 2 of in_2x2).
out_4x4([[0,0,1,1],[0,0,1,1],[1,1,0,0],[1,1,0,0]]).
% 1x1 input.
in_1x1([[3]]).
% 3x3 output (scale 3 of in_1x1).
out_3x3_scaled([[3,3,3],[3,3,3],[3,3,3]]).

:- begin_tests(induction_id_grid_dims).

test(dims_3x3) :-
    in_mixed(G), induction_grid_dims(G, R, C), R =:= 3, C =:= 3.

test(dims_2x2) :-
    in_2x2(G), induction_grid_dims(G, R, C), R =:= 2, C =:= 2.

test(dims_1x1) :-
    in_1x1(G), induction_grid_dims(G, R, C), R =:= 1, C =:= 1.

:- end_tests(induction_id_grid_dims).

:- begin_tests(induction_id_input_colors).

test(mixed_colors) :-
    in_mixed(G), induction_input_colors(G, C),
    C = [0, 1, 2].

test(uniform_color) :-
    out_uniform(G), induction_input_colors(G, C),
    C = [5].

:- end_tests(induction_id_input_colors).

:- begin_tests(induction_id_output_colors).

test(recolored_colors) :-
    out_recolored(G), induction_output_colors(G, C),
    C = [3, 5, 7].

:- end_tests(induction_id_output_colors).

:- begin_tests(induction_id_new_colors).

test(new_colors_recolor) :-
    % in has 0,1,2; out has 3,5,7; new = {3,5,7}.
    in_mixed(In), out_recolored(Out),
    induction_new_colors(In, Out, New),
    New = [3, 5, 7].

test(no_new_colors) :-
    % Same colors in and out.
    in_2x2(G), induction_new_colors(G, G, New),
    New = [].

:- end_tests(induction_id_new_colors).

:- begin_tests(induction_id_lost_colors).

test(lost_colors_recolor) :-
    % in has 0,1,2; out has 3,5,7; lost = {0,1,2}.
    in_mixed(In), out_recolored(Out),
    induction_lost_colors(In, Out, Lost),
    Lost = [0, 1, 2].

test(no_lost_colors) :-
    in_2x2(G), induction_lost_colors(G, G, Lost),
    Lost = [].

:- end_tests(induction_id_lost_colors).

:- begin_tests(induction_id_changed_cells).

test(changed_one_cell) :-
    G1 = [[0,0],[0,0]], G2 = [[0,0],[0,1]],
    induction_changed_cells(G1, G2, Changed),
    Changed = [r(1,1)].

test(changed_none) :-
    in_2x2(G), induction_changed_cells(G, G, Changed),
    Changed = [].

test(changed_all) :-
    G1 = [[0,0],[0,0]], G2 = [[1,1],[1,1]],
    induction_changed_cells(G1, G2, Changed),
    length(Changed, N), N =:= 4.

:- end_tests(induction_id_changed_cells).

:- begin_tests(induction_id_unchanged_cells).

test(unchanged_all) :-
    in_2x2(G), induction_unchanged_cells(G, G, Unchanged),
    length(Unchanged, N), N =:= 4.

test(unchanged_none) :-
    G1 = [[0,0],[0,0]], G2 = [[1,1],[1,1]],
    induction_unchanged_cells(G1, G2, Unchanged),
    Unchanged = [].

test(unchanged_partial) :-
    G1 = [[0,1],[0,0]], G2 = [[0,1],[1,0]],
    induction_unchanged_cells(G1, G2, Unchanged),
    msort(Unchanged, Sorted),
    Sorted = [r(0,0), r(0,1), r(1,1)].

:- end_tests(induction_id_unchanged_cells).

:- begin_tests(induction_id_color_map).

test(map_recolor) :-
    in_mixed(In), out_recolored(Out),
    induction_color_map(In, Out, Map),
    % Map should contain 0-5, 1-3, 2-7 pairs.
    msort(Map, Sorted),
    Sorted = [0-5, 1-3, 2-7].

test(map_identity) :-
    in_2x2(G), induction_color_map(G, G, Map),
    % No changes -> empty map.
    Map = [].

test(map_one_change) :-
    G1 = [[0,0],[0,0]], G2 = [[0,0],[0,1]],
    induction_color_map(G1, G2, Map),
    Map = [0-1].

:- end_tests(induction_id_color_map).

:- begin_tests(induction_id_is_recolor).

test(recolor_true) :-
    in_mixed(In), out_recolored(Out),
    induction_is_recolor(In, Out).

test(recolor_identity) :-
    in_2x2(G), induction_is_recolor(G, G).

test(recolor_false_inconsistent) :-
    % G1 has two cells with color 0; G2 maps them to different values.
    G1 = [[0,0],[1,1]],
    G2 = [[1,2],[1,1]],  % 0 maps to 1 at (0,0) but to 2 at (0,1) -- inconsistent
    \+ induction_is_recolor(G1, G2).

:- end_tests(induction_id_is_recolor).

:- begin_tests(induction_id_uniform_output).

test(uniform_true) :-
    out_uniform(G), induction_uniform_output(G, Color), Color =:= 5.

test(uniform_single_cell) :-
    induction_uniform_output([[7]], Color), Color =:= 7.

test(not_uniform) :-
    in_mixed(G), \+ induction_uniform_output(G, _).

:- end_tests(induction_id_uniform_output).

:- begin_tests(induction_id_output_color).

test(output_color) :-
    out_uniform(G), induction_output_color(G, Color), Color =:= 5.

test(not_uniform_fails) :-
    in_mixed(G), \+ induction_output_color(G, _).

:- end_tests(induction_id_output_color).

:- begin_tests(induction_id_size_ratio).

test(same_size) :-
    % Integer / Integer = Integer in SWI-Prolog when exact.
    in_2x2(G), induction_size_ratio(G, G, RR-RC), RR =:= 1, RC =:= 1.

test(scale_2) :-
    in_2x2(In), out_4x4(Out),
    induction_size_ratio(In, Out, RR-RC), RR =:= 2, RC =:= 2.

test(scale_3) :-
    in_1x1(In), out_3x3_scaled(Out),
    induction_size_ratio(In, Out, RR-RC), RR =:= 3, RC =:= 3.

:- end_tests(induction_id_size_ratio).

:- begin_tests(induction_id_is_scale).

test(scale_2_true) :-
    in_2x2(In), out_4x4(Out), induction_is_scale(In, Out).

test(scale_3_true) :-
    in_1x1(In), out_3x3_scaled(Out), induction_is_scale(In, Out).

test(scale_same_true) :-
    in_2x2(G), induction_is_scale(G, G).

test(not_scale_different_ratios) :-
    % 2x2 to 4x6 is not a uniform integer scale.
    In = [[0,0],[0,0]],
    Out = [[0,0,0,0,0,0],[0,0,0,0,0,0],[0,0,0,0,0,0],[0,0,0,0,0,0]],
    \+ induction_is_scale(In, Out).

:- end_tests(induction_id_is_scale).

:- begin_tests(induction_id_scale_factor).

test(factor_2) :-
    in_2x2(In), out_4x4(Out), induction_scale_factor(In, Out, K), K =:= 2.

test(factor_3) :-
    in_1x1(In), out_3x3_scaled(Out), induction_scale_factor(In, Out, K), K =:= 3.

test(factor_1) :-
    in_2x2(G), induction_scale_factor(G, G, K), K =:= 1.

:- end_tests(induction_id_scale_factor).

:- begin_tests(induction_cross_pair_invariants).

% Swap colors 1 and 2: dims preserved, colors preserved, total nonzero preserved.
test(swap_pairs_invariants) :-
    A = pair([[1,2],[2,1]], [[2,1],[1,2]]),
    B = pair([[1,2],[0,0]], [[2,1],[0,0]]),
    induction_cross_pair_invariants([A, B], Inv),
    member(dims_preserved, Inv),
    member(colors_preserved, Inv),
    member(total_nonzero_preserved, Inv).

% All background to color 5: monotone_output holds.
test(fill_task_invariants) :-
    A = pair([[0,0],[0,0]], [[5,5],[5,5]]),
    B = pair([[0,0,0]], [[5,5,5]]),
    induction_cross_pair_invariants([A, B], Inv),
    member(monotone_output, Inv).

% Returns a list.
test(invariants_returns_list) :-
    P = pair([[1,0],[0,1]], [[1,0],[0,1]]),
    induction_cross_pair_invariants([P], Inv),
    is_list(Inv).

% Empty pairs list gives all properties as invariants (vacuously true).
test(invariants_empty_pairs) :-
    induction_cross_pair_invariants([], Inv),
    is_list(Inv),
    length(Inv, N), N > 0.

% dims_preserved absent when sizes differ.
test(invariants_dims_absent_when_changed) :-
    A = pair([[1,2]], [[1,2],[3,4]]),
    induction_cross_pair_invariants([A], Inv),
    \+ member(dims_preserved, Inv).

:- end_tests(induction_cross_pair_invariants).

:- begin_tests(induction_cross_pair_variants).

% bg_preserved holds for some swap pairs but not all when one pair changes bg.
test(variants_bg_sometimes) :-
    A = pair([[1,2],[2,1]], [[2,1],[1,2]]),
    B = pair([[0,1],[0,0]], [[1,0],[0,0]]),
    % bg_preserved holds for A (bg 0 unchanged) but not B (cell (0,0) changed).
    induction_cross_pair_variants([A, B], Var),
    is_list(Var).

% Variants and invariants are disjoint.
test(variants_disjoint_from_invariants) :-
    A = pair([[1,2]], [[2,1]]),
    induction_cross_pair_invariants([A], Inv),
    induction_cross_pair_variants([A], Var),
    subtract(Var, Inv, Diff),
    Diff = Var.

% Returns a list.
test(variants_returns_list) :-
    P = pair([[1,0],[0,1]], [[2,0],[0,2]]),
    induction_cross_pair_variants([P], Var),
    is_list(Var).

% Uniform pairs (no change) have all properties as invariants; variants is empty.
test(variants_empty_for_stable_pair) :-
    P = pair([[1,2],[0,0]], [[1,2],[0,0]]),
    induction_cross_pair_variants([P], Var),
    Var = [].

:- end_tests(induction_cross_pair_variants).
