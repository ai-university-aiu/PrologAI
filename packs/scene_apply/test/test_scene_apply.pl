:- use_module('../prolog/scene_apply').
:- use_module(library(plunit)).

:- begin_tests(scene_apply).

% --- Fixtures ---
red_dot(obj(r, [r(0,0)])).
blue_dot(obj(b, [r(0,1)])).
green_dot(obj(g, [r(1,0)])).
red_bar(obj(r, [r(0,0),r(0,1),r(0,2)])).
blue_bar(obj(b, [r(1,0),r(1,1),r(1,2)])).
lshape(obj(p, [r(0,0),r(1,0),r(1,1)])).

% --- scene_apply_apply: recolor ---

test(apply_recolor) :-
    red_dot(R), blue_dot(B),
    scene_apply_apply(recolor(r,g), [R, B], [obj(g,[r(0,0)]), B]).

test(apply_recolor_no_match) :-
    red_dot(R),
    scene_apply_apply(recolor(b,g), [R], [R]).

test(apply_recolor_all) :-
    red_dot(R), blue_dot(B),
    scene_apply_apply(recolor_all(g), [R, B], [obj(g,[r(0,0)]), obj(g,[r(0,1)])]).

% --- scene_apply_apply: color_map ---

test(apply_color_map) :-
    red_dot(R), blue_dot(B),
    scene_apply_apply(color_map([r-g, b-y]), [R, B], [obj(g,[r(0,0)]), obj(y,[r(0,1)])]).

test(apply_color_map_empty) :-
    red_dot(R),
    scene_apply_apply(color_map([]), [R], [R]).

% --- scene_apply_apply: shift ---

test(apply_shift) :-
    red_dot(R),
    scene_apply_apply(shift(2,3), [R], [obj(r,[r(2,3)])]).

test(apply_shift_zero) :-
    red_dot(R), blue_dot(B),
    scene_apply_apply(shift(0,0), [R, B], [R, B]).

% --- scene_apply_apply: to_origin ---

test(apply_to_origin) :-
    scene_apply_apply(to_origin, [obj(r,[r(3,4)])], [obj(r,[r(0,0)])]).

test(apply_to_origin_empty) :-
    scene_apply_apply(to_origin, [], []).

% --- scene_apply_apply: reflect_h ---

test(apply_reflect_h) :-
    red_dot(R),
    scene_apply_apply(reflect_h(5), [R], [obj(r,[r(0,4)])]).

% --- scene_apply_apply: reflect_v ---

test(apply_reflect_v) :-
    red_dot(R),
    scene_apply_apply(reflect_v(5), [R], [obj(r,[r(4,0)])]).

% --- scene_apply_apply: remove_color / keep_color ---

test(apply_remove_color) :-
    red_dot(R), blue_dot(B), red_bar(RB),
    scene_apply_apply(remove_color(r), [R, B, RB], [B]).

test(apply_keep_color) :-
    red_dot(R), blue_dot(B), red_bar(RB),
    scene_apply_apply(keep_color(r), [R, B, RB], [R, RB]).

% --- scene_apply_apply: sort_size_desc / sort_size_asc ---

test(apply_sort_size_desc) :-
    red_dot(R), red_bar(RB),
    scene_apply_apply(sort_size_desc, [R, RB], [RB, R]).

test(apply_sort_size_asc) :-
    red_dot(R), red_bar(RB),
    scene_apply_apply(sort_size_asc, [RB, R], [R, RB]).

% --- scene_apply_apply: sort_pos ---

test(apply_sort_pos) :-
    green_dot(G), blue_dot(B), red_dot(R),
    scene_apply_apply(sort_pos, [G, B, R], [R, B, G]).

% --- scene_apply_apply: top_n ---

test(apply_top_n) :-
    red_dot(R), red_bar(RB), blue_bar(BB),
    scene_apply_apply(top_n(2), [R, RB, BB], TopN),
    length(TopN, 2),
    \+ member(R, TopN).

test(apply_top_n_overflow) :-
    red_dot(R),
    scene_apply_apply(top_n(5), [R], TopN),
    length(TopN, 1).

% --- scene_apply_apply: dedup_form ---

test(apply_dedup_form) :-
    red_dot(R), blue_dot(B),
    scene_apply_apply(dedup_form, [R, B], [R]).

test(apply_dedup_form_distinct) :-
    red_dot(D), red_bar(Bar),
    scene_apply_apply(dedup_form, [D, Bar], [D, Bar]).

% --- scene_apply_apply_seq ---

test(apply_seq_two_rules) :-
    red_dot(R),
    scene_apply_apply_seq([recolor(r,g), shift(1,1)], [R], [obj(g,[r(1,1)])]).

test(apply_seq_empty) :-
    red_dot(R),
    scene_apply_apply_seq([], [R], [R]).

% --- scene_apply_verify ---

test(verify_basic) :-
    red_dot(R),
    scene_apply_verify(recolor(r,g), [R], [obj(g,[r(0,0)])]).

test(verify_fails) :-
    red_dot(R),
    \+ scene_apply_verify(recolor(r,g), [R], [R]).

% --- scene_apply_verify_seq ---

test(verify_seq_basic) :-
    red_dot(R),
    scene_apply_verify_seq([recolor(r,g), shift(2,3)], [R], [obj(g,[r(2,3)])]).

% --- scene_apply_verify_all ---

test(verify_all_basic) :-
    P1 = [obj(r,[r(0,0)])] - [obj(g,[r(0,0)])],
    P2 = [obj(r,[r(1,1)])] - [obj(g,[r(1,1)])],
    scene_apply_verify_all(recolor(r,g), [P1, P2]).

test(verify_all_fails) :-
    P1 = [obj(r,[r(0,0)])] - [obj(g,[r(0,0)])],
    P2 = [obj(r,[r(1,1)])] - [obj(b,[r(1,1)])],
    \+ scene_apply_verify_all(recolor(r,g), [P1, P2]).

% --- scene_apply_verify_seq_all ---

test(verify_seq_all_basic) :-
    P1 = [obj(r,[r(0,0)])] - [obj(g,[r(2,3)])],
    scene_apply_verify_seq_all([recolor(r,g), shift(2,3)], [P1]).

% --- scene_apply_rule_type ---

test(rule_type_color) :-
    scene_apply_rule_type(recolor(r,g), color).

test(rule_type_spatial) :-
    scene_apply_rule_type(shift(1,2), spatial).

test(rule_type_filter) :-
    scene_apply_rule_type(keep_color(r), filter).

test(rule_type_order) :-
    scene_apply_rule_type(sort_size_desc, order).

test(rule_type_dedup) :-
    scene_apply_rule_type(dedup_form, dedup).

% --- scene_apply_is_color_rule / scene_apply_is_spatial_rule / scene_apply_is_filter_rule ---

test(is_color_rule) :-
    scene_apply_is_color_rule(recolor_all(g)).

test(is_spatial_rule) :-
    scene_apply_is_spatial_rule(to_origin).

test(is_filter_rule) :-
    scene_apply_is_filter_rule(remove_color(b)).

% --- scene_apply_colors_affected ---

test(colors_affected_recolor) :-
    scene_apply_colors_affected(recolor(r,g), [r,g]).

test(colors_affected_map) :-
    scene_apply_colors_affected(color_map([r-g, b-y]), Colors),
    sort(Colors, Sorted),
    Sorted == [b, g, r, y].

test(colors_affected_shift) :-
    scene_apply_colors_affected(shift(1,1), []).

% --- scene_apply_compose / scene_apply_seq_len ---

test(compose_two) :-
    scene_apply_compose(recolor(r,g), shift(1,1), Seq),
    Seq == [recolor(r,g), shift(1,1)].

test(seq_len_basic) :-
    scene_apply_seq_len([recolor(r,g), shift(1,1)], 2).

test(seq_len_empty) :-
    scene_apply_seq_len([], 0).

% --- scene_apply_rule_invertible ---

test(invertible_recolor) :-
    scene_apply_rule_invertible(recolor(r,g)).

test(invertible_shift) :-
    scene_apply_rule_invertible(shift(2,3)).

test(invertible_reflect_h) :-
    scene_apply_rule_invertible(reflect_h(5)).

test(not_invertible_filter) :-
    \+ scene_apply_rule_invertible(keep_color(r)).

:- end_tests(scene_apply).
