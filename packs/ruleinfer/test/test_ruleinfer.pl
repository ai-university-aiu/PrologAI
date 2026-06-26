:- use_module('../prolog/ruleinfer').
:- use_module(library(plunit)).

:- begin_tests(ruleinfer).

% --- Fixtures ---
% Simple one-object scenes
red_dot(obj(r, [r(0,0)])).
blue_dot(obj(b, [r(0,1)])).
green_dot(obj(g, [r(1,0)])).
red_bar(obj(r, [r(0,0),r(0,1),r(0,2)])).
blue_bar(obj(b, [r(1,0),r(1,1),r(1,2)])).
green_bar(obj(g, [r(0,0),r(0,1),r(0,2)])).
lshape(obj(p, [r(0,0),r(1,0),r(1,1)])).
lshape_shifted(obj(p, [r(2,3),r(3,3),r(3,4)])).

% --- ri_infer_recolor/4 ---

test(infer_recolor_basic) :-
    red_dot(R), green_dot(G), blue_dot(B),
    % red becomes green; blue unchanged
    ri_infer_recolor([R, B], [G, B], r, g).

test(infer_recolor_single) :-
    red_dot(R),
    ri_infer_recolor([R], [obj(g,[r(0,0)])], r, g).

test(infer_recolor_fails_no_change) :-
    red_dot(R), blue_dot(B),
    \+ ri_infer_recolor([R, B], [R, B], _, _).

test(infer_recolor_fails_two_changed) :-
    red_dot(R), blue_dot(B), green_dot(G),
    % both r and b changed
    \+ ri_infer_recolor([R, B], [G, obj(p,[r(0,1)])], _, _).

% --- ri_infer_recolor_all/3 ---

test(infer_recolor_all_basic) :-
    red_dot(R), blue_dot(B),
    ri_infer_recolor_all([R, B], [obj(g,[r(0,0)]), obj(g,[r(0,1)])], g).

test(infer_recolor_all_single) :-
    red_dot(R),
    ri_infer_recolor_all([R], [obj(g,[r(0,0)])], g).

test(infer_recolor_all_not_uniform) :-
    % After has two distinct colors — not recolor_all
    red_dot(R), blue_dot(B),
    \+ ri_infer_recolor_all([R], [R, B], _).

% --- ri_infer_color_map/3 ---

test(infer_color_map_single_change) :-
    red_dot(R),
    ri_infer_color_map([R], [obj(g,[r(0,0)])], Map),
    memberchk(r-g, Map).

test(infer_color_map_swap) :-
    red_dot(R), blue_dot(B),
    ri_infer_color_map([R, B], [obj(b,[r(0,0)]), obj(r,[r(0,1)])], Map),
    memberchk(r-b, Map),
    memberchk(b-r, Map).

test(infer_color_map_no_change) :-
    red_dot(R), blue_dot(B),
    ri_infer_color_map([R, B], [R, B], []).

% --- ri_infer_keep_color/3 ---

test(infer_keep_color_basic) :-
    red_dot(R), blue_dot(B), red_bar(RB),
    ri_infer_keep_color([R, B, RB], [R, RB], r).

test(infer_keep_color_one_object) :-
    red_dot(R), blue_dot(B), green_dot(G),
    ri_infer_keep_color([R, B, G], [B], b).

test(infer_keep_color_fails_no_filter) :-
    red_dot(R), blue_dot(B),
    % no objects removed
    \+ ri_infer_keep_color([R, B], [R, B], _).

% --- ri_infer_remove_color/3 ---

test(infer_remove_color_basic) :-
    red_dot(R), blue_dot(B), red_bar(RB),
    ri_infer_remove_color([R, B, RB], [B], r).

test(infer_remove_color_single) :-
    red_dot(R), blue_dot(B),
    ri_infer_remove_color([R, B], [B], r).

test(infer_remove_color_fails_no_removal) :-
    red_dot(R), blue_dot(B),
    \+ ri_infer_remove_color([R, B], [R, B], _).

% --- ri_infer_shift/4 ---

test(infer_shift_basic) :-
    red_dot(R),
    ri_infer_shift([R], [obj(r,[r(2,3)])], 2, 3).

test(infer_shift_zero) :-
    red_dot(R), blue_dot(B),
    ri_infer_shift([R, B], [R, B], 0, 0).

test(infer_shift_negative) :-
    lshape_shifted(LS),
    lshape(L),
    % lshape_shifted is lshape + r(2,3)
    ri_infer_shift([LS], [L], -2, -3).

test(infer_shift_multi_obj) :-
    red_dot(R), blue_dot(B),
    ri_infer_shift([R, B], [obj(r,[r(1,1)]), obj(b,[r(1,2)])], 1, 1).

% --- ri_infer_to_origin/2 ---

test(infer_to_origin_basic) :-
    Shifted = obj(r, [r(3,4)]),
    ri_infer_to_origin([Shifted], [obj(r,[r(0,0)])]).

test(infer_to_origin_scene) :-
    A = obj(r, [r(2,1)]), B = obj(b, [r(2,3)]),
    ri_infer_to_origin([A, B], [obj(r,[r(0,0)]), obj(b,[r(0,2)])]).

test(infer_to_origin_already) :-
    red_dot(R), blue_dot(B),
    ri_infer_to_origin([R, B], [R, B]).

% --- ri_consistent_recolor/3 ---

test(consistent_recolor_two_pairs) :-
    P1 = [obj(r,[r(0,0)])] - [obj(g,[r(0,0)])],
    P2 = [obj(r,[r(1,1)])] - [obj(g,[r(1,1)])],
    ri_consistent_recolor(r, g, [P1, P2]).

test(consistent_recolor_fails) :-
    P1 = [obj(r,[r(0,0)])] - [obj(g,[r(0,0)])],
    P2 = [obj(b,[r(1,1)])] - [obj(b,[r(1,1)])],
    % second pair: r->g should not change blue
    ri_consistent_recolor(r, g, [P1, P2]).

test(consistent_recolor_inconsistent) :-
    P1 = [obj(r,[r(0,0)])] - [obj(g,[r(0,0)])],
    P2 = [obj(r,[r(1,1)])] - [obj(b,[r(1,1)])],
    % second pair applies r->b, not r->g
    \+ ri_consistent_recolor(r, g, [P1, P2]).

% --- ri_consistent_color_map/2 ---

test(consistent_color_map_basic) :-
    P1 = [obj(r,[r(0,0)]), obj(b,[r(0,1)])] - [obj(g,[r(0,0)]), obj(y,[r(0,1)])],
    ri_consistent_color_map([r-g, b-y], [P1]).

test(consistent_color_map_fails) :-
    P1 = [obj(r,[r(0,0)])] - [obj(b,[r(0,0)])],
    \+ ri_consistent_color_map([r-g], [P1]).

% --- ri_consistent_keep_color/2 ---

test(consistent_keep_color_basic) :-
    P1 = [obj(r,[r(0,0)]), obj(b,[r(0,1)])] - [obj(r,[r(0,0)])],
    ri_consistent_keep_color(r, [P1]).

test(consistent_keep_fails) :-
    P1 = [obj(r,[r(0,0)]), obj(b,[r(0,1)])] - [obj(b,[r(0,1)])],
    \+ ri_consistent_keep_color(r, [P1]).

% --- ri_consistent_remove_color/2 ---

test(consistent_remove_color_basic) :-
    P1 = [obj(r,[r(0,0)]), obj(b,[r(0,1)])] - [obj(b,[r(0,1)])],
    ri_consistent_remove_color(r, [P1]).

test(consistent_remove_fails) :-
    P1 = [obj(r,[r(0,0)]), obj(b,[r(0,1)])] - [obj(r,[r(0,0)])],
    \+ ri_consistent_remove_color(r, [P1]).

% --- ri_consistent_shift/3 ---

test(consistent_shift_basic) :-
    P1 = [obj(r,[r(0,0)])] - [obj(r,[r(2,3)])],
    ri_consistent_shift(2, 3, [P1]).

test(consistent_shift_two_pairs) :-
    P1 = [obj(r,[r(0,0)])] - [obj(r,[r(1,1)])],
    P2 = [obj(b,[r(2,2)])] - [obj(b,[r(3,3)])],
    ri_consistent_shift(1, 1, [P1, P2]).

test(consistent_shift_fails) :-
    P1 = [obj(r,[r(0,0)])] - [obj(r,[r(2,3)])],
    P2 = [obj(r,[r(0,0)])] - [obj(r,[r(1,1)])],
    \+ ri_consistent_shift(2, 3, [P1, P2]).

% --- ri_all_same_n_objs/1 ---

test(all_same_n_objs_basic) :-
    P1 = [obj(r,[r(0,0)]), obj(b,[r(0,1)])] - [obj(g,[r(0,0)]), obj(y,[r(0,1)])],
    P2 = [obj(p,[r(1,0)])] - [obj(q,[r(1,0)])],
    ri_all_same_n_objs([P1, P2]).

test(all_same_n_objs_fails) :-
    P1 = [obj(r,[r(0,0)]), obj(b,[r(0,1)])] - [obj(g,[r(0,0)])],
    \+ ri_all_same_n_objs([P1]).

% --- ri_all_same_colors/1 ---

test(all_same_colors_basic) :-
    P1 = [obj(r,[r(0,0)]), obj(b,[r(0,1)])] - [obj(r,[r(1,0)]), obj(b,[r(1,1)])],
    ri_all_same_colors([P1]).

test(all_same_colors_fails) :-
    P1 = [obj(r,[r(0,0)])] - [obj(b,[r(0,0)])],
    \+ ri_all_same_colors([P1]).

test(all_same_colors_empty_pairs) :-
    ri_all_same_colors([]).

test(infer_recolor_multiple_same_color) :-
    % Two red objects become green
    R1 = obj(r,[r(0,0)]), R2 = obj(r,[r(1,0)]),
    ri_infer_recolor([R1, R2], [obj(g,[r(0,0)]), obj(g,[r(1,0)])], r, g).

:- end_tests(ruleinfer).
