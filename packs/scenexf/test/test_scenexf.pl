:- use_module('../prolog/scenexf').
:- use_module(library(plunit)).

:- begin_tests(scenexf).

% --- Test fixtures ---
% red dot at r(0,0)
red_dot(obj(r, [r(0,0)])).
% blue dot at r(0,1)
blue_dot(obj(b, [r(0,1)])).
% green dot at r(1,0)
green_dot(obj(g, [r(1,0)])).
% red bar: r(0,0)..r(0,2)
red_bar(obj(r, [r(0,0),r(0,1),r(0,2)])).
% blue bar: r(1,0)..r(1,2)
blue_bar(obj(b, [r(1,0),r(1,1),r(1,2)])).
% L-shape: r(0,0),r(1,0),r(1,1)
lshape(obj(p, [r(0,0),r(1,0),r(1,1)])).
% L-shape far: same form at r(3,3)
lshape_far(obj(b, [r(3,3),r(4,3),r(4,4)])).

% --- sx_recolor/4 ---

test(recolor_basic) :-
    red_dot(R), blue_dot(B),
    sx_recolor([R, B], r, g, [obj(g,[r(0,0)]), B]).

test(recolor_no_match) :-
    red_dot(R),
    sx_recolor([R], b, g, [R]).

test(recolor_all_match) :-
    red_dot(D), red_bar(B),
    sx_recolor([D, B], r, y, [obj(y,[r(0,0)]), obj(y,[r(0,0),r(0,1),r(0,2)])]).

% --- sx_recolor_all/3 ---

test(recolor_all_basic) :-
    red_dot(R), blue_bar(B),
    sx_recolor_all([R, B], g, [obj(g,[r(0,0)]), obj(g,[r(1,0),r(1,1),r(1,2)])]).

test(recolor_all_empty) :-
    sx_recolor_all([], g, []).

% --- sx_apply_color_map/3 ---

test(apply_color_map_basic) :-
    red_dot(R), blue_dot(B),
    sx_apply_color_map([R, B], [r-g, b-y], [obj(g,[r(0,0)]), obj(y,[r(0,1)])]).

test(apply_color_map_partial) :-
    red_dot(R), blue_dot(B),
    % only r->g in map; b unchanged
    sx_apply_color_map([R, B], [r-g], [obj(g,[r(0,0)]), B]).

test(apply_color_map_empty_map) :-
    red_dot(R), blue_dot(B),
    sx_apply_color_map([R, B], [], [R, B]).

% --- sx_shift/4 ---

test(shift_basic) :-
    red_dot(R),
    sx_shift([R], 2, 3, [obj(r,[r(2,3)])]).

test(shift_negative) :-
    lshape(L),
    % L is at r(0,0),r(1,0),r(1,1) — shift down by -0 is no-op; shift right by 0
    sx_shift([L], 0, 0, [L]).

test(shift_multiple) :-
    red_dot(R), blue_dot(B),
    sx_shift([R, B], 1, 1, [obj(r,[r(1,1)]), obj(b,[r(1,2)])]).

% --- sx_to_origin/2 ---

test(to_origin_basic) :-
    Shifted = obj(r, [r(3,4)]),
    sx_to_origin([Shifted], [obj(r,[r(0,0)])]).

test(to_origin_scene) :-
    % Scene with min row=1, min col=1
    A = obj(r, [r(1,1)]), B = obj(b, [r(2,3)]),
    sx_to_origin([A, B], [obj(r,[r(0,0)]), obj(b,[r(1,2)])]).

test(to_origin_already_at_origin) :-
    red_dot(R), blue_dot(B),
    sx_to_origin([R, B], [R, B]).

test(to_origin_empty) :-
    sx_to_origin([], []).

% --- sx_reflect_h/3 ---

test(reflect_h_basic) :-
    % Width=5; dot at col 0 -> col 4
    red_dot(R),
    sx_reflect_h([R], 5, [obj(r,[r(0,4)])]).

test(reflect_h_bar) :-
    % Width=3; bar at cols 0,1,2 -> cols 2,1,0 (same cells sorted differently)
    red_bar(B),
    sx_reflect_h([B], 3, [obj(r,Cells)]),
    sort(Cells, Sorted),
    Sorted == [r(0,0),r(0,1),r(0,2)].

% --- sx_reflect_v/3 ---

test(reflect_v_basic) :-
    % Height=5; dot at row 0 -> row 4
    red_dot(R),
    sx_reflect_v([R], 5, [obj(r,[r(4,0)])]).

% --- sx_remove_color/3 ---

test(remove_color_basic) :-
    red_dot(R), blue_dot(B), red_bar(RB),
    sx_remove_color([R, B, RB], r, [B]).

test(remove_color_none_match) :-
    red_dot(R), blue_dot(B),
    sx_remove_color([R, B], g, [R, B]).

test(remove_color_all_match) :-
    red_dot(R), red_bar(RB),
    sx_remove_color([R, RB], r, []).

% --- sx_keep_color/3 ---

test(keep_color_basic) :-
    red_dot(R), blue_dot(B), red_bar(RB),
    sx_keep_color([R, B, RB], r, [R, RB]).

test(keep_color_none) :-
    red_dot(R), blue_dot(B),
    sx_keep_color([R, B], g, []).

% --- sx_sort_size_desc/2 ---

test(sort_size_desc_basic) :-
    red_dot(D), red_bar(B), lshape(L),
    % sizes: 1, 3, 3
    sx_sort_size_desc([D, B, L], [First|_]),
    First \== D.  % smallest should not be first

test(sort_size_desc_empty) :-
    sx_sort_size_desc([], []).

test(sort_size_desc_order) :-
    red_dot(D), red_bar(B),
    sx_sort_size_desc([D, B], [B, D]).

% --- sx_sort_size_asc/2 ---

test(sort_size_asc_basic) :-
    red_dot(D), red_bar(B),
    sx_sort_size_asc([D, B], [D, B]).

test(sort_size_asc_reverse) :-
    red_dot(D), red_bar(B),
    sx_sort_size_asc([B, D], [D, B]).

% --- sx_sort_pos/2 ---

test(sort_pos_basic) :-
    green_dot(G),  % r(1,0)
    red_dot(R),    % r(0,0)
    blue_dot(B),   % r(0,1)
    sx_sort_pos([G, B, R], [R, B, G]).

% --- sx_top_n/3 ---

test(top_n_basic) :-
    red_dot(D), red_bar(B), blue_bar(BB),
    % sizes: 1, 3, 3 -> top 2 are bars
    sx_top_n([D, B, BB], 2, TopN),
    length(TopN, 2),
    \+ member(D, TopN).

test(top_n_one) :-
    red_dot(D), red_bar(B),
    sx_top_n([D, B], 1, [B]).

test(top_n_all) :-
    red_dot(D), red_bar(B),
    sx_top_n([D, B], 5, TopN),
    % when N > length, return all
    length(TopN, 2).

% --- sx_dedup_form/2 ---

test(dedup_form_basic) :-
    red_dot(R), blue_dot(B),
    % same form (single cell); keep first
    sx_dedup_form([R, B], [R]).

test(dedup_form_distinct) :-
    red_dot(D), red_bar(B),
    sx_dedup_form([D, B], [D, B]).

test(dedup_form_three_two_same) :-
    lshape(L), lshape_far(LF), red_dot(D),
    % L and LF same form; D different
    sx_dedup_form([L, LF, D], [L, D]).

test(dedup_form_empty) :-
    sx_dedup_form([], []).

% --- Additional edge-case tests ---

test(reflect_v_multiple) :-
    % Height=3; r(0,0)->r(2,0), r(2,1)->r(0,1)
    A = obj(r, [r(0,0)]), B = obj(b, [r(2,1)]),
    sx_reflect_v([A, B], 3, [obj(r,[r(2,0)]), obj(b,[r(0,1)])]).

test(apply_color_map_swap) :-
    % swap r<->b
    red_dot(R), blue_dot(B),
    sx_apply_color_map([R, B], [r-b, b-r], [obj(b,[r(0,0)]), obj(r,[r(0,1)])]).

test(top_n_exact) :-
    red_dot(D), red_bar(B),
    % exactly 2 objects, N=2 => return both sorted desc
    sx_top_n([D, B], 2, TopN),
    length(TopN, 2).

test(sort_pos_single) :-
    red_dot(R),
    sx_sort_pos([R], [R]).

test(recolor_all_single) :-
    red_dot(R),
    sx_recolor_all([R], b, [obj(b,[r(0,0)])]).

:- end_tests(scenexf).
