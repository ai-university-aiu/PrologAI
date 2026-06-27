% PLUnit tests for the hyp pack (hy_* predicates).
:- use_module(library(plunit)).
:- use_module('../prolog/hyp').

% Helper hypotheses.
flip_colors_(Grid, Grid2) :-
    hy_color_sub([1-5, 5-1], Grid, Grid2).

:- begin_tests(hy_color_sub).

test(color_sub_basic) :-
    % Replace color 1 with color 5.
    hy_color_sub([1-5], [[1,0],[0,1]], Grid2),
    Grid2 = [[5,0],[0,5]].

test(color_sub_two) :-
    % Replace 1->5 and 2->6.
    hy_color_sub([1-5, 2-6], [[1,2],[2,1]], Grid2),
    Grid2 = [[5,6],[6,5]].

test(color_sub_identity) :-
    % Empty map: grid unchanged.
    hy_color_sub([], [[1,2],[3,4]], Grid2),
    Grid2 = [[1,2],[3,4]].

test(color_sub_no_match) :-
    % Color not in map: cell unchanged.
    hy_color_sub([9-1], [[1,2],[3,4]], Grid2),
    Grid2 = [[1,2],[3,4]].

:- end_tests(hy_color_sub).

:- begin_tests(hy_identity).

test(identity_basic) :-
    hy_identity([[1,2],[3,4]], Grid2),
    Grid2 = [[1,2],[3,4]].

test(identity_single) :-
    hy_identity([[5]], Grid2),
    Grid2 = [[5]].

:- end_tests(hy_identity).

:- begin_tests(hy_from_map).

test(from_map_basic) :-
    % hy_from_map applies the map like hy_color_sub.
    hy_from_map([1-2], [[1,0],[0,1]], Grid2),
    Grid2 = [[2,0],[0,2]].

:- end_tests(hy_from_map).

:- begin_tests(hy_test).

test(test_perfect) :-
    % Identity hypothesis on matching pair: accuracy = 1.0.
    hy_test(hy_identity, [[1,2],[3,4]], [[1,2],[3,4]], Acc),
    Acc =:= 1.0.

test(test_zero) :-
    % Identity hypothesis on non-matching pair: accuracy = 0.0.
    hy_test(hy_identity, [[1,2],[3,4]], [[5,6],[7,8]], Acc),
    Acc =:= 0.0.

test(test_half) :-
    % Half cells match.
    hy_test(hy_identity, [[1,2],[3,4]], [[1,9],[3,9]], Acc),
    Acc =:= 0.5.

test(test_color_sub) :-
    % Color substitution hypothesis: color 1 -> 5.
    hy_test(hy_color_sub([1-5]), [[1,0],[0,1]], [[5,0],[0,5]], Acc),
    Acc =:= 1.0.

:- end_tests(hy_test).

:- begin_tests(hy_test_all).

test(test_all_perfect) :-
    % Identity on all-matching pairs: mean = 1.0.
    Pairs = [[[1,2],[3,4]]-[[1,2],[3,4]], [[5,6],[7,8]]-[[5,6],[7,8]]],
    hy_test_all(hy_identity, Pairs, Mean, Accs),
    Mean =:= 1.0,
    Accs = [1.0, 1.0].

test(test_all_mixed) :-
    % One perfect, one zero: mean = 0.5.
    Pairs = [[[1,2]]-[[1,2]], [[1,2]]-[[5,6]]],
    hy_test_all(hy_identity, Pairs, Mean, _Accs),
    Mean =:= 0.5.

:- end_tests(hy_test_all).

:- begin_tests(hy_verify).

test(verify_yes) :-
    % Identity hypothesis on matching pair: verified.
    hy_verify(hy_identity, [[1,2],[3,4]], [[1,2],[3,4]]).

test(verify_no) :-
    % Identity hypothesis on non-matching pair: fails.
    \+ hy_verify(hy_identity, [[1,2],[3,4]], [[5,6],[7,8]]).

test(verify_color_sub) :-
    % Color substitution hypothesis verified.
    hy_verify(hy_color_sub([1-5]), [[1,0]], [[5,0]]).

:- end_tests(hy_verify).

:- begin_tests(hy_verify_all).

test(verify_all_yes) :-
    % Identity on all-matching pairs.
    Pairs = [[[1,2]]-[[1,2]], [[3,4]]-[[3,4]]],
    hy_verify_all(hy_identity, Pairs).

test(verify_all_no) :-
    % One non-matching pair: fails.
    Pairs = [[[1,2]]-[[1,2]], [[1,2]]-[[5,6]]],
    \+ hy_verify_all(hy_identity, Pairs).

:- end_tests(hy_verify_all).

:- begin_tests(hy_select).

test(select_best) :-
    % Select between identity and a bad hypothesis.
    Pairs = [[[1,2]]-[[1,2]], [[3,4]]-[[3,4]]],
    Goals = [hy_identity, hy_color_sub([1-9])],
    hy_select(Goals, Pairs, Best),
    Best = hy_identity.

:- end_tests(hy_select).

:- begin_tests(hy_rank).

test(rank_basic) :-
    % Identity should rank first.
    Pairs = [[[1,2]]-[[1,2]], [[3,4]]-[[3,4]]],
    Goals = [hy_color_sub([1-9]), hy_identity],
    hy_rank(Goals, Pairs, Ranked),
    Ranked = [1.0-hy_identity|_].

:- end_tests(hy_rank).

:- begin_tests(hy_apply_map).

test(apply_map_basic) :-
    % Same as hy_color_sub.
    hy_apply_map([3-7], [[3,0],[3,0]], Grid2),
    Grid2 = [[7,0],[7,0]].

:- end_tests(hy_apply_map).

:- begin_tests(hy_compose).

test(compose_basic) :-
    % Apply map1 (1->2) then map2 (2->3).
    hy_compose([1-2], [2-3], [[1,0],[0,1]], Grid2),
    Grid2 = [[3,0],[0,3]].

test(compose_order) :-
    % Apply map1 (1->5) then map2 (5->9).
    hy_compose([1-5], [5-9], [[1,1],[1,1]], Grid2),
    Grid2 = [[9,9],[9,9]].

:- end_tests(hy_compose).

:- begin_tests(hy_invert_map).

test(invert_basic) :-
    % Swap keys and values.
    hy_invert_map([1-5, 2-6], Inv),
    Inv = [5-1, 6-2].

test(invert_empty) :-
    hy_invert_map([], Inv),
    Inv = [].

:- end_tests(hy_invert_map).

:- begin_tests(hy_map_lookup).

test(lookup_found) :-
    % Color in map.
    hy_map_lookup([1-5, 2-6], 1, New),
    New =:= 5.

test(lookup_fallback) :-
    % Color not in map: identity fallback.
    hy_map_lookup([1-5], 9, New),
    New =:= 9.

test(lookup_zero) :-
    % Zero (background) not in map: stays zero.
    hy_map_lookup([1-5], 0, New),
    New =:= 0.

:- end_tests(hy_map_lookup).

:- begin_tests(hy_describe).

test(describe_identity) :-
    hy_describe(hy_identity, Desc),
    Desc = identity.

test(describe_generic) :-
    hy_describe(some_goal(arg), Desc),
    atom(Desc).

:- end_tests(hy_describe).

:- begin_tests(hy_spatial_hyp).

% Shift right by 1: non-zero cell moves from col 0 to col 1.
test(spatial_shift_right) :-
    In  = [[0,0,0],[1,0,0],[0,0,0]],
    Out = [[0,0,0],[0,1,0],[0,0,0]],
    hy_spatial_hyp([pair(In, Out)], [0-1, 1-0, 0-(-1)], shift(0, 1)).

% Shift down by 1.
test(spatial_shift_down) :-
    In  = [[1,0],[0,0]],
    Out = [[0,0],[1,0]],
    hy_spatial_hyp([pair(In, Out)], [1-0, 0-1, (-1)-0], shift(1, 0)).

% Consistent shift across two pairs.
test(spatial_consistent_two_pairs) :-
    A = pair([[1,0],[0,0]], [[0,0],[1,0]]),
    B = pair([[2,0],[0,0]], [[0,0],[2,0]]),
    hy_spatial_hyp([A, B], [1-0, 0-1], shift(1, 0)).

% Fails when no candidate move explains all pairs.
test(spatial_no_match_fails) :-
    A = pair([[1,0],[0,0]], [[0,0],[0,1]]),
    \+ hy_spatial_hyp([A], [0-1, 1-0], _).

:- end_tests(hy_spatial_hyp).

:- begin_tests(hy_structural_hyp).

% dims_preserved: same size in and out.
test(structural_dims) :-
    A = pair([[1,0],[0,2]], [[2,0],[0,1]]),
    hy_structural_hyp([A], [dims_preserved], structural(dims_preserved)).

% colors_preserved: exact same color set.
test(structural_colors) :-
    A = pair([[1,2],[2,1]], [[2,1],[1,2]]),
    hy_structural_hyp([A], [colors_preserved], structural(colors_preserved)).

% monotone_output: output has only one non-zero color.
test(structural_monotone_output) :-
    A = pair([[1,2],[0,3]], [[5,5],[0,5]]),
    hy_structural_hyp([A], [monotone_output], structural(monotone_output)).

% output_subset_of_input: output colors are a subset of input colors.
test(structural_output_subset) :-
    A = pair([[1,2],[3,0]], [[1,2],[0,0]]),
    hy_structural_hyp([A], [output_subset_of_input], structural(output_subset_of_input)).

% Fails when no pattern in the candidate list matches (only colors_preserved checked,
% but input colors {1,2,0} differ from output colors {3,4,5}).
test(structural_no_match_fails) :-
    A = pair([[1,2],[0,0]], [[3,4],[5,0]]),
    \+ hy_structural_hyp([A], [colors_preserved], _).

:- end_tests(hy_structural_hyp).

:- begin_tests(hy_sequence_hyp).

% Two-step: apply 1->2, then 2->3. Net: 1->3.
test(sequence_two_step) :-
    In  = [[1,0],[0,1]],
    Out = [[3,0],[0,3]],
    Maps1 = [[1-2]],
    Maps2 = [[2-3]],
    hy_sequence_hyp([pair(In, Out)], Maps1, Maps2, seq([1-2], [2-3])).

% Consistent across two pairs.
test(sequence_two_pairs) :-
    A = pair([[1,0],[0,0]], [[3,0],[0,0]]),
    B = pair([[0,1],[0,0]], [[0,3],[0,0]]),
    Maps1 = [[1-2]],
    Maps2 = [[2-3]],
    hy_sequence_hyp([A, B], Maps1, Maps2, seq([1-2], [2-3])).

% Identity maps leave grid unchanged.
test(sequence_identity_maps) :-
    P = pair([[1,2],[0,0]], [[1,2],[0,0]]),
    hy_sequence_hyp([P], [[]], [[]], seq([], [])).

% Fails when no combination explains all pairs.
test(sequence_no_match_fails) :-
    A = pair([[1,0],[0,0]], [[9,0],[0,0]]),
    Maps1 = [[1-2]],
    Maps2 = [[2-3]],
    \+ hy_sequence_hyp([A], Maps1, Maps2, _).

:- end_tests(hy_sequence_hyp).
