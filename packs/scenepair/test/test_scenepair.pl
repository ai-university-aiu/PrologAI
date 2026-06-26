:- use_module('../prolog/scenepair').
:- use_module(library(plunit)).

:- begin_tests(scenepair).

% --- Fixtures ---
red_dot(obj(r, [r(0,0)])).
blue_dot(obj(b, [r(0,1)])).
green_dot(obj(g, [r(1,0)])).
red_bar(obj(r, [r(0,0),r(0,1),r(0,2)])).
blue_bar(obj(b, [r(1,0),r(1,1),r(1,2)])).
lshape(obj(p, [r(0,0),r(1,0),r(1,1)])).

% shifted versions
red_dot_shifted(obj(r, [r(1,1)])).
blue_dot_shifted(obj(b, [r(1,2)])).
red_bar_shifted(obj(r, [r(1,0),r(1,1),r(1,2)])).
blue_bar_shifted(obj(b, [r(2,0),r(2,1),r(2,2)])).

% recolored versions
green_dot_from_red(obj(g, [r(0,0)])).
green_bar_from_red(obj(g, [r(0,0),r(0,1),r(0,2)])).

% --- ps_same_n_objs/2 ---

test(same_n_objs_equal) :-
    red_dot(R), blue_dot(B),
    ps_same_n_objs([R, B], [B, R]).

test(same_n_objs_unequal) :-
    red_dot(R), blue_dot(B),
    \+ ps_same_n_objs([R, B], [R]).

test(same_n_objs_empty) :-
    ps_same_n_objs([], []).

% --- ps_added_objs/3 ---

test(added_objs_one) :-
    red_dot(R), blue_dot(B),
    ps_added_objs([R], [R, B], Added),
    Added == [B].

test(added_objs_none) :-
    red_dot(R), blue_dot(B),
    ps_added_objs([R, B], [R, B], []).

test(added_objs_all) :-
    blue_dot(B),
    ps_added_objs([], [B], Added),
    Added == [B].

% --- ps_removed_objs/3 ---

test(removed_objs_one) :-
    red_dot(R), blue_dot(B),
    ps_removed_objs([R, B], [R], Removed),
    Removed == [B].

test(removed_objs_none) :-
    red_dot(R),
    ps_removed_objs([R], [R], []).

test(removed_objs_all) :-
    red_dot(R),
    ps_removed_objs([R], [], [R]).

% --- ps_n_added/3 and ps_n_removed/3 ---

test(n_added_basic) :-
    red_dot(R), blue_dot(B),
    ps_n_added([R], [R, B], 1).

test(n_removed_basic) :-
    red_dot(R), blue_dot(B),
    ps_n_removed([R, B], [R], 1).

test(n_added_zero) :-
    red_dot(R),
    ps_n_added([R], [R], 0).

% --- ps_color_set_before/2 and ps_color_set_after/2 ---

test(color_set_before_basic) :-
    red_dot(R), blue_dot(B),
    ps_color_set_before([R, B], Colors),
    Colors == [b, r].

test(color_set_after_basic) :-
    green_dot_from_red(G), blue_dot(B),
    ps_color_set_after([G, B], Colors),
    Colors == [b, g].

test(color_set_single) :-
    red_dot(R),
    ps_color_set_before([R], [r]).

% --- ps_same_color_set/2 ---

test(same_color_set_yes) :-
    red_dot(R), blue_dot(B),
    red_bar(RB),
    ps_same_color_set([R, B], [RB, B]).

test(same_color_set_no) :-
    red_dot(R), blue_dot(B), green_dot(G),
    \+ ps_same_color_set([R, B], [R, G]).

test(same_color_set_empty) :-
    ps_same_color_set([], []).

% --- ps_color_delta/3 ---

test(color_delta_basic) :-
    red_dot(R), blue_dot(B),
    green_dot_from_red(G),
    % R(r) -> G(g), B(b) stays
    ps_color_delta([R, B], [G, B], Delta),
    Delta == [r-g].

test(color_delta_no_change) :-
    red_dot(R), blue_dot(B),
    ps_color_delta([R, B], [R, B], []).

test(color_delta_diff_length) :-
    red_dot(R), blue_dot(B),
    ps_color_delta([R, B], [R], []).

test(color_delta_two_changes) :-
    red_dot(R), blue_dot(B),
    green_dot_from_red(G), lshape(L),
    % R->G (r->g), B->L (b->p) — L is a p-colored obj
    ps_color_delta([R, B], [G, L], Delta),
    msort(Delta, Sorted),
    Sorted == [b-p, r-g].

% --- ps_is_recolor/2 ---

test(is_recolor_yes) :-
    red_dot(R), blue_dot(B),
    green_dot_from_red(G),
    ps_is_recolor([R, B], [G, B]).

test(is_recolor_no_two_changes) :-
    red_dot(R), blue_dot(B),
    green_dot_from_red(G), lshape(L),
    \+ ps_is_recolor([R, B], [G, L]).

test(is_recolor_no_length_diff) :-
    red_dot(R), blue_dot(B),
    \+ ps_is_recolor([R, B], [R]).

% --- ps_is_recolor_all/2 ---

test(is_recolor_all_yes) :-
    red_dot(R), red_bar(RB),
    green_dot_from_red(G), green_bar_from_red(GB),
    ps_is_recolor_all([R, RB], [G, GB]).

test(is_recolor_all_already_one_color) :-
    green_dot_from_red(G),
    ps_is_recolor_all([G], [G]).

test(is_recolor_all_no) :-
    red_dot(R), blue_dot(B),
    green_dot_from_red(G),
    % After has r and g — not recolor_all
    \+ ps_is_recolor_all([R, B], [G, R]).

% --- ps_is_shift/3 ---

test(is_shift_yes) :-
    red_dot(R), blue_dot(B),
    red_dot_shifted(RS), blue_dot_shifted(BS),
    ps_is_shift([R, B], [RS, BS], DR, DC),
    DR == 1, DC == 1.

test(is_shift_zero) :-
    red_dot(R),
    ps_is_shift([R], [R], DR, DC),
    DR == 0, DC == 0.

test(is_shift_no) :-
    red_dot(R), red_bar(RB),
    \+ ps_is_shift([R], [RB], _, _).

% --- ps_is_to_origin/2 ---

test(is_to_origin_yes) :-
    % Before: dot at r(2,3); After: dot at r(0,0)
    Before = [obj(r,[r(2,3)])],
    After  = [obj(r,[r(0,0)])],
    ps_is_to_origin(Before, After).

test(is_to_origin_already) :-
    red_dot(R),
    ps_is_to_origin([R], [R]).

test(is_to_origin_no) :-
    red_dot(R), blue_dot(B),
    \+ ps_is_to_origin([R], [B]).

% --- ps_size_preserved/2 ---

test(size_preserved_yes) :-
    red_dot(R), green_dot_from_red(G),
    ps_size_preserved([R], [G]).

test(size_preserved_bars) :-
    red_bar(RB), blue_bar(BB),
    ps_size_preserved([RB], [BB]).

test(size_preserved_no) :-
    red_dot(R), red_bar(RB),
    \+ ps_size_preserved([R], [RB]).

test(size_preserved_diff_length) :-
    red_dot(R), blue_dot(B),
    \+ ps_size_preserved([R, B], [R]).

% --- Additional coverage tests ---

test(color_delta_swap) :-
    % r->b in first position, b->r in second position
    red_dot(R), blue_dot(B),
    ps_color_delta([R, B], [B, R], Delta),
    msort(Delta, Sorted),
    Sorted == [b-r, r-b].

test(added_objs_form_match) :-
    % obj(r,[r(0,0)]) and obj(r,[r(0,0)]) are same color+form -> not added
    red_dot(R),
    ps_added_objs([R], [R], []).

test(is_shift_multi_obj_bar) :-
    red_bar(RB), blue_bar(BB),
    red_bar_shifted(RBS),
    % shift [RB, BB] down by 1: expect ps_is_shift to detect DR=1, DC=0
    blue_bar_shifted(BBS),
    ps_is_shift([RB, BB], [RBS, BBS], DR, DC),
    DR == 1, DC == 0.

:- end_tests(scenepair).
