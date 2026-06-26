:- begin_tests(delta).
:- use_module('../prolog/delta').

% dl_added/3 - objects in S2 with no cell-set match in S1.
test(added_one_new) :-
    S1 = [obj(1,[r(0,0)])],
    S2 = [obj(1,[r(0,0)]), obj(2,[r(1,1)])],
    dl_added(S1, S2, [obj(2,[r(1,1)])]).

test(added_none) :-
    S1 = [obj(1,[r(0,0)]), obj(2,[r(1,1)])],
    S2 = [obj(3,[r(0,0)]), obj(4,[r(1,1)])],
    dl_added(S1, S2, []).

test(added_all) :-
    S1 = [obj(1,[r(0,0)])],
    S2 = [obj(2,[r(1,1)]), obj(3,[r(2,2)])],
    dl_added(S1, S2, [obj(2,[r(1,1)]), obj(3,[r(2,2)])]).

% dl_removed/3 - objects in S1 with no cell-set match in S2.
test(removed_one) :-
    S1 = [obj(1,[r(0,0)]), obj(2,[r(1,1)])],
    S2 = [obj(1,[r(0,0)])],
    dl_removed(S1, S2, [obj(2,[r(1,1)])]).

test(removed_none) :-
    S1 = [obj(1,[r(0,0)])],
    S2 = [obj(3,[r(0,0)])],
    dl_removed(S1, S2, []).

test(removed_all) :-
    S1 = [obj(1,[r(0,0)]), obj(2,[r(1,1)])],
    S2 = [obj(3,[r(2,2)])],
    dl_removed(S1, S2, [obj(1,[r(0,0)]), obj(2,[r(1,1)])]).

% dl_matched/3 - O1-O2 pairs with identical cell sets.
test(matched_one_pair) :-
    S1 = [obj(1,[r(0,0)])],
    S2 = [obj(3,[r(0,0)])],
    dl_matched(S1, S2, [obj(1,[r(0,0)])-obj(3,[r(0,0)])]).

test(matched_none) :-
    S1 = [obj(1,[r(0,0)])],
    S2 = [obj(2,[r(1,1)])],
    dl_matched(S1, S2, []).

test(matched_two_pairs) :-
    S1 = [obj(1,[r(0,0)]), obj(2,[r(1,1)])],
    S2 = [obj(5,[r(1,1)]), obj(6,[r(0,0)])],
    dl_matched(S1, S2, Pairs),
    length(Pairs, 2).

% dl_recolored/3 - From-To pairs where cells match but colors differ.
test(recolored_one) :-
    S1 = [obj(1,[r(0,0)])],
    S2 = [obj(3,[r(0,0)])],
    dl_recolored(S1, S2, [1-3]).

test(recolored_none) :-
    S1 = [obj(1,[r(0,0)])],
    S2 = [obj(1,[r(0,0)])],
    dl_recolored(S1, S2, []).

test(recolored_two) :-
    S1 = [obj(1,[r(0,0)]), obj(2,[r(1,1)])],
    S2 = [obj(5,[r(0,0)]), obj(6,[r(1,1)])],
    dl_recolored(S1, S2, [1-5, 2-6]).

% dl_unchanged/3 - objects identical in both scenes.
test(unchanged_one) :-
    S1 = [obj(1,[r(0,0)]), obj(2,[r(1,1)])],
    S2 = [obj(1,[r(0,0)]), obj(3,[r(1,1)])],
    dl_unchanged(S1, S2, [obj(1,[r(0,0)])]).

test(unchanged_none) :-
    S1 = [obj(1,[r(0,0)])],
    S2 = [obj(2,[r(0,0)])],
    dl_unchanged(S1, S2, []).

test(unchanged_all) :-
    Objs = [obj(1,[r(0,0)]), obj(2,[r(1,1)])],
    dl_unchanged(Objs, Objs, [obj(1,[r(0,0)]), obj(2,[r(1,1)])]).

% dl_color_gain/3 - colors in S2 absent from S1.
test(color_gain_one) :-
    S1 = [obj(1,[r(0,0)])],
    S2 = [obj(2,[r(0,0)])],
    dl_color_gain(S1, S2, [2]).

test(color_gain_none) :-
    S1 = [obj(1,[r(0,0)])],
    S2 = [obj(1,[r(1,1)])],
    dl_color_gain(S1, S2, []).

test(color_gain_two) :-
    S1 = [obj(1,[r(0,0)])],
    S2 = [obj(2,[r(0,0)]), obj(3,[r(1,1)])],
    dl_color_gain(S1, S2, [2, 3]).

% dl_color_loss/3 - colors in S1 absent from S2.
test(color_loss_one) :-
    S1 = [obj(1,[r(0,0)])],
    S2 = [obj(2,[r(0,0)])],
    dl_color_loss(S1, S2, [1]).

test(color_loss_none) :-
    S1 = [obj(1,[r(0,0)])],
    S2 = [obj(1,[r(1,1)])],
    dl_color_loss(S1, S2, []).

test(color_loss_two) :-
    S1 = [obj(1,[r(0,0)]), obj(2,[r(1,1)])],
    S2 = [obj(3,[r(0,0)])],
    dl_color_loss(S1, S2, [1, 2]).

% dl_count_diff/3 - object count change.
test(count_diff_positive) :-
    S1 = [obj(1,[r(0,0)])],
    S2 = [obj(1,[r(0,0)]), obj(2,[r(1,1)])],
    dl_count_diff(S1, S2, 1).

test(count_diff_zero) :-
    S1 = [obj(1,[r(0,0)])],
    S2 = [obj(2,[r(1,1)])],
    dl_count_diff(S1, S2, 0).

test(count_diff_negative) :-
    S1 = [obj(1,[r(0,0)]), obj(2,[r(1,1)])],
    S2 = [obj(3,[r(2,2)])],
    dl_count_diff(S1, S2, -1).

% dl_size_diff/3 - total cell count change.
test(size_diff_positive) :-
    S1 = [obj(1,[r(0,0)])],
    S2 = [obj(1,[r(0,0),r(0,1)])],
    dl_size_diff(S1, S2, 1).

test(size_diff_zero) :-
    S1 = [obj(1,[r(0,0)])],
    S2 = [obj(2,[r(1,1)])],
    dl_size_diff(S1, S2, 0).

test(size_diff_negative) :-
    S1 = [obj(1,[r(0,0),r(0,1)])],
    S2 = [obj(1,[r(0,0)])],
    dl_size_diff(S1, S2, -1).

% dl_is_added_only/2 - only additions occurred.
test(is_added_only_yes) :-
    S1 = [obj(1,[r(0,0)])],
    S2 = [obj(1,[r(0,0)]), obj(2,[r(1,1)])],
    dl_is_added_only(S1, S2).

test(is_added_only_removal_fails, [fail]) :-
    S1 = [obj(1,[r(0,0)]), obj(2,[r(1,1)])],
    S2 = [obj(1,[r(0,0)])],
    dl_is_added_only(S1, S2).

test(is_added_only_recolor_fails, [fail]) :-
    S1 = [obj(1,[r(0,0)])],
    S2 = [obj(2,[r(0,0)])],
    dl_is_added_only(S1, S2).

% dl_is_removed_only/2 - only removals occurred.
test(is_removed_only_yes) :-
    S1 = [obj(1,[r(0,0)]), obj(2,[r(1,1)])],
    S2 = [obj(1,[r(0,0)])],
    dl_is_removed_only(S1, S2).

test(is_removed_only_addition_fails, [fail]) :-
    S1 = [obj(1,[r(0,0)])],
    S2 = [obj(1,[r(0,0)]), obj(2,[r(1,1)])],
    dl_is_removed_only(S1, S2).

test(is_removed_only_recolor_fails, [fail]) :-
    S1 = [obj(1,[r(0,0)])],
    S2 = [obj(2,[r(0,0)])],
    dl_is_removed_only(S1, S2).

% dl_is_recolor_only/2 - only recolorings occurred (no adds or removals).
test(is_recolor_only_yes) :-
    S1 = [obj(1,[r(0,0)])],
    S2 = [obj(2,[r(0,0)])],
    dl_is_recolor_only(S1, S2).

test(is_recolor_only_addition_fails, [fail]) :-
    S1 = [obj(1,[r(0,0)])],
    S2 = [obj(1,[r(0,0)]), obj(2,[r(1,1)])],
    dl_is_recolor_only(S1, S2).

test(is_recolor_only_removal_fails, [fail]) :-
    S1 = [obj(1,[r(0,0)]), obj(2,[r(1,1)])],
    S2 = [obj(1,[r(0,0)])],
    dl_is_recolor_only(S1, S2).

% dl_is_stable/2 - scenes are identical.
test(is_stable_yes) :-
    S = [obj(1,[r(0,0)]), obj(2,[r(1,1)])],
    dl_is_stable(S, S).

test(is_stable_recolor_fails, [fail]) :-
    S1 = [obj(1,[r(0,0)])],
    S2 = [obj(2,[r(0,0)])],
    dl_is_stable(S1, S2).

test(is_stable_empty) :-
    dl_is_stable([], []).

% dl_scene_diff/3 - composite delta.
test(scene_diff_full) :-
    S1 = [obj(1,[r(0,0)]), obj(2,[r(1,1)])],
    S2 = [obj(3,[r(0,0)]), obj(4,[r(2,2)])],
    dl_scene_diff(S1, S2, delta(Added, Removed, Recolored, [])),
    Added = [obj(4,[r(2,2)])],
    Removed = [obj(2,[r(1,1)])],
    Recolored = [1-3].

test(scene_diff_recolor_only) :-
    S1 = [obj(1,[r(0,0)])],
    S2 = [obj(5,[r(0,0)])],
    dl_scene_diff(S1, S2, delta([], [], [1-5], [])).

test(scene_diff_stable) :-
    S = [obj(1,[r(0,0)])],
    dl_scene_diff(S, S, delta([], [], [], [obj(1,[r(0,0)])])).

:- end_tests(delta).
