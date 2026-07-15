:- use_module('../prolog/color_table').
:- use_module(library(plunit)).

% Fixtures
red_at_00(obj(r, [r(0,0)])).
blue_at_00(obj(b, [r(0,0)])).
green_at_00(obj(g, [r(0,0)])).

red_at_01(obj(r, [r(0,1)])).
blue_at_01(obj(b, [r(0,1)])).
green_at_01(obj(g, [r(0,1)])).

red_bar(obj(r, [r(0,0), r(0,1), r(0,2)])).
blue_bar(obj(b, [r(0,0), r(0,1), r(0,2)])).
green_bar(obj(g, [r(0,0), r(0,1), r(0,2)])).

yellow_at_10(obj(y, [r(1,0)])).
purple_at_10(obj(p, [r(1,0)])).
yellow_bar(obj(y, [r(1,0), r(1,1), r(1,2)])).
purple_bar(obj(p, [r(1,0), r(1,1), r(1,2)])).

:- begin_tests(color_table).

% color_table_infer_from_pair: single object, color changes
test(infer_single_changed) :-
    red_at_00(R), green_at_00(G),
    color_table_infer_from_pair([R], [G], Map),
    Map == [r-g].

% color_table_infer_from_pair: single object, same color (identity not recorded)
test(infer_single_unchanged) :-
    red_at_00(R), red_at_00(R2),
    color_table_infer_from_pair([R], [R2], Map),
    Map == [].

% color_table_infer_from_pair: two objects, both change
test(infer_two_objects_both_change) :-
    red_at_00(R), blue_at_01(B),
    green_at_00(G), yellow_at_10(Y),
    color_table_infer_from_pair([R, B], [G, Y], Map),
    msort(Map, Sorted),
    Sorted == [b-y, r-g].

% color_table_infer_from_pair: two objects, one changes one stays
test(infer_two_objects_one_change) :-
    red_at_00(R), blue_at_01(B),
    green_at_00(G), blue_at_01(B2),
    color_table_infer_from_pair([R, B], [G, B2], Map),
    Map == [r-g].

% color_table_infer_from_pair: deduplicates duplicate entries
test(infer_dedup_entries) :-
    red_at_00(R), red_at_00(R2),
    green_at_00(G), green_at_00(G2),
    color_table_infer_from_pair([R, R2], [G, G2], Map),
    Map == [r-g].

% color_table_consistent_map: empty map is consistent
test(consistent_empty) :-
    color_table_consistent_map([]).

% color_table_consistent_map: single entry is consistent
test(consistent_single) :-
    color_table_consistent_map([r-g]).

% color_table_consistent_map: two distinct sources are consistent
test(consistent_two_sources) :-
    color_table_consistent_map([r-g, b-y]).

% color_table_consistent_map: same source to same target is consistent (dedup needed upstream)
test(consistent_same_pair) :-
    color_table_consistent_map([r-g, r-g]).

% color_table_consistent_map: conflict fails
test(consistent_conflict_fails) :-
    \+ color_table_consistent_map([r-g, r-b]).

% color_table_merge_maps: two disjoint maps merge cleanly
test(merge_disjoint) :-
    color_table_merge_maps([r-g], [b-y], Merged),
    msort(Merged, S),
    S == [b-y, r-g].

% color_table_merge_maps: same pair in both merges to one
test(merge_duplicate_pair) :-
    color_table_merge_maps([r-g], [r-g], Merged),
    Merged == [r-g].

% color_table_merge_maps: conflict fails
test(merge_conflict_fails) :-
    \+ color_table_merge_maps([r-g], [r-b], _).

% color_table_extend_map: adds new entries
test(extend_adds_new) :-
    color_table_extend_map([r-g], [b-y], Extended),
    msort(Extended, S),
    S == [b-y, r-g].

% color_table_extend_map: conflict fails
test(extend_conflict_fails) :-
    \+ color_table_extend_map([r-g], [r-b], _).

% color_table_learn_map: two consistent pairs
test(learn_two_consistent_pairs) :-
    red_at_00(R), green_at_00(G),
    blue_at_01(B), yellow_at_10(Y),
    color_table_learn_map([[R]-[G], [B]-[Y]], Map, Bad),
    msort(Map, S),
    S == [b-y, r-g],
    Bad == [].

% color_table_learn_map: one pair with no change
test(learn_one_identity_pair) :-
    red_at_00(R), red_at_00(R2),
    color_table_learn_map([[R]-[R2]], Map, Bad),
    Map == [],
    Bad == [].

% color_table_learn_map: conflicting second pair goes to Inconsistent
test(learn_conflicting_second_pair) :-
    red_at_00(R), green_at_00(G), blue_at_00(B),
    color_table_learn_map([[R]-[G], [R]-[B]], Map, Bad),
    Map == [r-g],
    Bad = [_-_].

% color_table_learn_map: empty pairs
test(learn_empty_pairs) :-
    color_table_learn_map([], Map, Bad),
    Map == [],
    Bad == [].

% color_table_mapped_color: color in map returns target
test(mapped_color_found) :-
    color_table_mapped_color([r-g, b-y], r, g).

% color_table_mapped_color: color not in map returns itself
test(mapped_color_identity) :-
    color_table_mapped_color([r-g], b, b).

% color_table_mapped_color: empty map returns identity
test(mapped_color_empty_map) :-
    color_table_mapped_color([], r, r).

% color_table_apply_map: single object color changed
test(apply_map_single_obj) :-
    red_at_00(R), green_at_00(G),
    color_table_apply_map([r-g], R, Result),
    Result == G.

% color_table_apply_map: color not in map stays same
test(apply_map_identity) :-
    red_at_00(R),
    color_table_apply_map([b-y], R, Result),
    Result == R.

% color_table_apply_to_scene: map applied to full scene
test(apply_to_scene_two_objects) :-
    red_at_00(R), blue_at_01(B),
    green_at_00(G),
    color_table_apply_to_scene([r-g, b-y], [R, B], Scene),
    msort(Scene, S),
    msort([G, obj(y, [r(0,1)])], Expected),
    S == Expected.

% color_table_apply_to_scene: empty scene
test(apply_to_scene_empty) :-
    color_table_apply_to_scene([r-g], [], Scene),
    Scene == [].

% color_table_apply_to_scene: empty map preserves scene
test(apply_to_scene_empty_map) :-
    red_at_00(R), blue_at_01(B),
    color_table_apply_to_scene([], [R, B], Scene),
    Scene == [R, B].

% color_table_map_covers: all colors covered
test(map_covers_all) :-
    red_at_00(R), blue_at_01(B),
    color_table_map_covers([r-g, b-y], [R, B]).

% color_table_map_covers: missing color fails
test(map_covers_missing_fails) :-
    red_at_00(R), blue_at_01(B),
    \+ color_table_map_covers([r-g], [R, B]).

% color_table_map_covers: empty scene always covered
test(map_covers_empty_scene) :-
    color_table_map_covers([], []).

% color_table_complete_map: adds identity for missing color
test(complete_map_adds_identity) :-
    blue_at_01(B),
    color_table_complete_map([r-g], [B], Complete),
    msort(Complete, S),
    S == [b-b, r-g].

% color_table_complete_map: no new entries when already complete
test(complete_map_already_complete) :-
    red_at_00(R), blue_at_01(B),
    color_table_complete_map([r-g, b-y], [R, B], Complete),
    msort(Complete, S),
    S == [b-y, r-g].

% color_table_complete_map: empty scene, map unchanged
test(complete_map_empty_scene) :-
    color_table_complete_map([r-g], [], Complete),
    Complete == [r-g].

% color_table_invert_map: swap from-to
test(invert_map_basic) :-
    color_table_invert_map([r-g, b-y], Inverted),
    msort(Inverted, S),
    S == [g-r, y-b].

% color_table_invert_map: single entry
test(invert_map_single) :-
    color_table_invert_map([r-g], Inverted),
    Inverted == [g-r].

% color_table_identity_map: produces identity entries
test(identity_map_basic) :-
    color_table_identity_map([r, b, g], Map),
    msort(Map, S),
    S == [b-b, g-g, r-r].

% color_table_identity_map: deduplicates colors
test(identity_map_dedup) :-
    color_table_identity_map([r, r, b], Map),
    msort(Map, S),
    S == [b-b, r-r].

% color_table_identity_map: empty list
test(identity_map_empty) :-
    color_table_identity_map([], Map),
    Map == [].

% color_table_restrict_map: keeps only matching colors
test(restrict_map_basic) :-
    color_table_restrict_map([r-g, b-y, p-w], [r, p], Restricted),
    msort(Restricted, S),
    S == [p-w, r-g].

% color_table_restrict_map: empty color list
test(restrict_map_empty_colors) :-
    color_table_restrict_map([r-g, b-y], [], Restricted),
    Restricted == [].

% color_table_restrict_map: all colors present
test(restrict_map_all_present) :-
    color_table_restrict_map([r-g, b-y], [r, b], Restricted),
    msort(Restricted, S),
    S == [b-y, r-g].

% color_table_map_colors: lists source colors
test(map_colors_basic) :-
    color_table_map_colors([r-g, b-y, p-w], Colors),
    msort(Colors, S),
    S == [b, p, r].

% color_table_map_colors: empty map
test(map_colors_empty) :-
    color_table_map_colors([], Colors),
    Colors == [].

% color_table_map_colors: deduplicates repeated sources
test(map_colors_dedup) :-
    color_table_map_colors([r-g, r-g], Colors),
    Colors == [r].

:- end_tests(color_table).
