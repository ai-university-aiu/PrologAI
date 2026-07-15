:- use_module('../prolog/transformgen').
:- use_module(library(plunit)).

% Fixtures
red_obj(obj(r, [r(0,0)])).
blue_obj(obj(b, [r(0,1)])).
green_obj(obj(g, [r(1,0)])).

red_bar(obj(r, [r(0,0), r(0,1), r(0,2)])).
blue_dot(obj(b, [r(1,1)])).

two_color_scene([obj(r,[r(0,0)]), obj(b,[r(0,1)])]).
three_color_scene([obj(r,[r(0,0)]), obj(b,[r(0,1)]), obj(g,[r(1,0)])]).

:- begin_tests(transformgen).

% transformgen_scene_colors: extracts distinct colors
test(scene_colors_two) :-
    two_color_scene(S),
    transformgen_scene_colors(S, Colors),
    Colors == [b, r].

% transformgen_scene_colors: three colors
test(scene_colors_three) :-
    three_color_scene(S),
    transformgen_scene_colors(S, Colors),
    Colors == [b, g, r].

% transformgen_scene_colors: single color
test(scene_colors_single) :-
    red_obj(R),
    transformgen_scene_colors([R], Colors),
    Colors == [r].

% transformgen_scene_colors: empty scene
test(scene_colors_empty) :-
    transformgen_scene_colors([], Colors),
    Colors == [].

% transformgen_recolor_candidates: two colors produce two candidates
test(recolor_candidates_two_colors) :-
    two_color_scene(S),
    transformgen_recolor_candidates(S, Cands),
    msort(Cands, Sorted),
    Sorted == [recolor(b,r), recolor(r,b)].

% transformgen_recolor_candidates: single color produces no candidates
test(recolor_candidates_single_color) :-
    red_obj(R),
    transformgen_recolor_candidates([R], Cands),
    Cands == [].

% transformgen_recolor_candidates: empty scene
test(recolor_candidates_empty) :-
    transformgen_recolor_candidates([], Cands),
    Cands == [].

% transformgen_recolor_all_candidates: one per color
test(recolor_all_candidates) :-
    two_color_scene(S),
    transformgen_recolor_all_candidates(S, Cands),
    msort(Cands, Sorted),
    Sorted == [recolor_all(b), recolor_all(r)].

% transformgen_remove_candidates: one per color
test(remove_candidates) :-
    two_color_scene(S),
    transformgen_remove_candidates(S, Cands),
    msort(Cands, Sorted),
    Sorted == [remove_color(b), remove_color(r)].

% transformgen_keep_candidates: one per color
test(keep_candidates) :-
    two_color_scene(S),
    transformgen_keep_candidates(S, Cands),
    msort(Cands, Sorted),
    Sorted == [keep_color(b), keep_color(r)].

% transformgen_shift_candidates: correct count for 1x1 bounds
test(shift_candidates_1x1) :-
    transformgen_shift_candidates(1, 1, Cands),
    % 3x3 grid minus (0,0) = 8 candidates
    length(Cands, 8),
    member(shift(1,0), Cands),
    member(shift(-1,0), Cands),
    member(shift(0,1), Cands),
    member(shift(0,-1), Cands).

% transformgen_shift_candidates: excludes (0,0)
test(shift_candidates_no_zero) :-
    transformgen_shift_candidates(1, 1, Cands),
    \+ member(shift(0,0), Cands).

% transformgen_shift_candidates: MaxDR=0 MaxDC=0 gives empty
test(shift_candidates_zero_bounds) :-
    transformgen_shift_candidates(0, 0, Cands),
    Cands == [].

% transformgen_reflect_candidates: returns h and v variants
test(reflect_candidates) :-
    transformgen_reflect_candidates(5, 7, Cands),
    Cands == [reflect_h(7), reflect_v(5)].

% transformgen_top_candidates: N=3 on 2-object scene gives top_n(1) and top_n(2)
test(top_candidates_capped) :-
    two_color_scene(S),
    transformgen_top_candidates(3, S, Cands),
    Cands == [top_n(1), top_n(2)].

% transformgen_top_candidates: empty scene gives empty
test(top_candidates_empty_scene) :-
    transformgen_top_candidates(3, [], Cands),
    Cands == [].

% transformgen_color_map_candidate: extracts changed-color map
test(color_map_candidate_basic) :-
    Before = [obj(r,[r(0,0)]), obj(b,[r(0,1)])],
    After  = [obj(g,[r(0,0)]), obj(y,[r(0,1)])],
    transformgen_color_map_candidate(Before, After, Rule),
    Rule = color_map(Map),
    msort(Map, Sorted),
    Sorted == [b-y, r-g].

% transformgen_color_map_candidate: identity pair fails (no changes)
test(color_map_candidate_identity_fails) :-
    Before = [obj(r,[r(0,0)])],
    After  = [obj(r,[r(0,0)])],
    \+ transformgen_color_map_candidate(Before, After, _).

% transformgen_color_map_candidate: length mismatch fails
test(color_map_candidate_length_mismatch_fails) :-
    Before = [obj(r,[r(0,0)]), obj(b,[r(0,1)])],
    After  = [obj(g,[r(0,0)])],
    \+ transformgen_color_map_candidate(Before, After, _).

% transformgen_from_scenes: contains recolor and shift rules
test(from_scenes_contains_recolors) :-
    Before = [obj(r,[r(0,0)])],
    After  = [obj(g,[r(0,0)])],
    transformgen_from_scenes(Before, After, Cands),
    member(recolor_all(g), Cands).

% transformgen_from_scenes: contains shift rules
test(from_scenes_contains_shifts) :-
    Before = [obj(r,[r(0,0)])],
    After  = [obj(r,[r(1,0)])],
    transformgen_from_scenes(Before, After, Cands),
    member(shift(1,0), Cands).

% transformgen_from_scenes: contains identity
test(from_scenes_contains_identity) :-
    Before = [obj(r,[r(0,0)])],
    After  = [obj(r,[r(0,0)])],
    transformgen_from_scenes(Before, After, Cands),
    member(identity, Cands).

% transformgen_from_pairs: empty pairs gives [identity]
test(from_pairs_empty) :-
    transformgen_from_pairs([], Cands),
    Cands == [identity].

% transformgen_from_pairs: single recolor pair
test(from_pairs_recolor) :-
    P1 = [obj(r,[r(0,0)])]-[obj(g,[r(0,0)])],
    P2 = [obj(r,[r(1,0)])]-[obj(g,[r(1,0)])],
    transformgen_from_pairs([P1, P2], Cands),
    member(recolor_all(g), Cands),
    member(identity, Cands).

% transformgen_from_pairs: shift pair
test(from_pairs_shift) :-
    P1 = [obj(r,[r(0,0)])]-[obj(r,[r(1,0)])],
    transformgen_from_pairs([P1], Cands),
    member(shift(1,0), Cands).

% transformgen_filter_consistent: returns matching rules
test(filter_consistent_basic) :-
    Pairs = [[obj(r,[r(0,0)])]-[obj(g,[r(0,0)])]],
    transformgen_filter_consistent([recolor(r,g), recolor(r,b)], Pairs, Consistent),
    Consistent == [recolor(r,g)].

% transformgen_filter_consistent: empty rules gives empty
test(filter_consistent_empty_rules) :-
    Pairs = [[obj(r,[r(0,0)])]-[obj(g,[r(0,0)])]],
    transformgen_filter_consistent([], Pairs, Consistent),
    Consistent == [].

% transformgen_filter_consistent: empty pairs - all rules are consistent
test(filter_consistent_empty_pairs) :-
    transformgen_filter_consistent([recolor(r,g), recolor(r,b)], [], Consistent),
    Consistent == [recolor(r,g), recolor(r,b)].

% transformgen_n_candidates: count
test(n_candidates_count) :-
    transformgen_n_candidates([recolor(r,g), recolor(r,b), identity], 3).

% transformgen_n_candidates: empty
test(n_candidates_empty) :-
    transformgen_n_candidates([], 0).

% transformgen_all_scene_candidates: contains key rules
test(all_scene_candidates_basic) :-
    two_color_scene(S),
    transformgen_all_scene_candidates(S, 1, Cands),
    member(recolor(r,b), Cands),
    member(remove_color(r), Cands),
    member(shift(1,0), Cands),
    member(to_origin, Cands),
    member(identity, Cands).

% transformgen_all_scene_candidates: empty scene gives shift + extras only
test(all_scene_candidates_empty_scene) :-
    transformgen_all_scene_candidates([], 1, Cands),
    member(shift(1,0), Cands),
    member(identity, Cands).

% transformgen_all_scene_candidates: zero shift gives no shifts
test(all_scene_candidates_no_shift) :-
    red_obj(R),
    transformgen_all_scene_candidates([R], 0, Cands),
    \+ member(shift(_,_), Cands).

% transformgen_filter_consistent: color_map from training pair
test(filter_consistent_color_map) :-
    P1 = [obj(r,[r(0,0)]),obj(b,[r(0,1)])]-[obj(g,[r(0,0)]),obj(y,[r(0,1)])],
    transformgen_filter_consistent([color_map([r-g, b-y]), color_map([r-b])], [P1], Consistent),
    Consistent == [color_map([r-g, b-y])].

% transformgen_shift_candidates: 2x2 bounds give 24 candidates
test(shift_candidates_2x2) :-
    transformgen_shift_candidates(2, 2, Cands),
    % 5x5 = 25, minus (0,0) = 24
    length(Cands, 24).

% Internal apply: recolor works
test(apply_recolor_internal) :-
    transformgen_filter_consistent([recolor(r,g)], [[obj(r,[r(0,0)])]-[obj(g,[r(0,0)])]], Consistent),
    Consistent == [recolor(r,g)].

% Internal apply: remove_color works
test(apply_remove_color_internal) :-
    P = [obj(r,[r(0,0)]),obj(b,[r(0,1)])]-[obj(b,[r(0,1)])],
    transformgen_filter_consistent([remove_color(r)], [P], Consistent),
    Consistent == [remove_color(r)].

% Internal apply: keep_color works
test(apply_keep_color_internal) :-
    P = [obj(r,[r(0,0)]),obj(b,[r(0,1)])]-[obj(r,[r(0,0)])],
    transformgen_filter_consistent([keep_color(r)], [P], Consistent),
    Consistent == [keep_color(r)].

% Internal apply: shift works
test(apply_shift_internal) :-
    P = [obj(r,[r(0,0)])]-[obj(r,[r(1,0)])],
    transformgen_filter_consistent([shift(1,0)], [P], Consistent),
    Consistent == [shift(1,0)].

% Internal apply: to_origin works
test(apply_to_origin_internal) :-
    P = [obj(r,[r(2,3)])]-[obj(r,[r(0,0)])],
    transformgen_filter_consistent([to_origin], [P], Consistent),
    Consistent == [to_origin].

% transformgen_recolor_candidates: three colors produces 6 candidates
test(recolor_candidates_three_colors) :-
    three_color_scene(S),
    transformgen_recolor_candidates(S, Cands),
    length(Cands, 6).

% transformgen_from_pairs: color_map from multi-color pair
test(from_pairs_color_map) :-
    P1 = [obj(r,[r(0,0)]),obj(b,[r(0,1)])]-[obj(g,[r(0,0)]),obj(y,[r(0,1)])],
    transformgen_from_pairs([P1], Cands),
    member(color_map([r-g,b-y]), Cands).

:- end_tests(transformgen).
